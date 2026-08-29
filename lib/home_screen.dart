import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'profile_screen.dart';
import 'active_requests_screen.dart';
import 'map_screen.dart';
import 'services/app_language.dart';
import 'widgets/language_selection_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String userType;
  final Map<String, dynamic>? userData;

  const HomeScreen({
    super.key,
    required this.userType,
    this.userData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);
  static const Color sosRed = Color(0xFFE53935);

  // ================================================================
  // BACKEND URL & METHOD CHANNEL
  // ================================================================

  static const String baseUrl = 'http://10.0.2.2:5001';

  static const MethodChannel _criticalAlarmChannel =
      MethodChannel('com.example.varipath/critical_alarm');

  // ================================================================
  // LOCATION STATE
  // ================================================================

  Position? _currentPosition;
  String _liveLocationText = 'Acquiring device GPS...';

  // ================================================================
  // SOS STATE
  // ================================================================

  bool _isSosActive = false;
  bool _isSendingSos = false;
  Timer? _sosPollingTimer;
  String? _lastSosStatus;

  String? _selectedSosCategory;
  String? _selectedSosLabel;
  String? _selectedSosDescription;
  AudioPlayer? _criticalAlarmPlayer;

  // ================================================================
  // SEARCH STATE
  // ================================================================

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // ================================================================
  // ROLE HELPERS
  // ================================================================

  bool get isVarkari => widget.userType == 'VK';
  bool get isVolunteer => widget.userType == 'VT';
  String get currentUsername =>
      widget.userData?['username']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _initDeviceLocation();
    if (isVarkari) {
      _checkActiveSos();
    }
  }

  @override
  void dispose() {
    _silenceCriticalAlarm();
    _sosPollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // LIVE GPS
  // ================================================================

  Future<void> _initDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _liveLocationText = 'Location services disabled';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _liveLocationText = 'GPS Permission Denied';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _liveLocationText = 'GPS Permission Denied Permanently';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      // Smart check: If GPS returns emulator location outside Pune region, snap to MMCOE Karve Nagar, Pune
      final bool isOutsidePune = position.latitude < 18.0 ||
          position.latitude > 19.5 ||
          position.longitude < 73.0 ||
          position.longitude > 74.5;

      final actualPosition = isOutsidePune
          ? Position(
              latitude: 18.4902,
              longitude: 73.8130,
              timestamp: DateTime.now(),
              accuracy: 5.0,
              altitude: 560.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            )
          : position;

      setState(() {
        _currentPosition = actualPosition;
        _liveLocationText =
            'MMCOE, Karve Nagar, Pune (${actualPosition.latitude.toStringAsFixed(4)}° N, ${actualPosition.longitude.toStringAsFixed(4)}° E)';
      });

      _updateUserLocationOnBackend(
        actualPosition.latitude,
        actualPosition.longitude,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: 18.4902,
            longitude: 73.8130,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 560.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          _liveLocationText = 'MMCOE, Karve Nagar, Pune (18.4902° N, 73.8130° E)';
        });
      }
    }
  }

  Future<void> _updateVolunteerLocationOnBackend(
    double lat,
    double lng,
  ) async {
    _updateUserLocationOnBackend(lat, lng);
  }

  Future<void> _updateUserLocationOnBackend(
    double lat,
    double lng,
  ) async {
    if (currentUsername.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/user-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': currentUsername,
          'latitude': lat,
          'longitude': lng,
        }),
      );
      if (isVolunteer) {
        await http.post(
          Uri.parse('$baseUrl/volunteer-location'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'volunteer_username': currentUsername,
            'latitude': lat,
            'longitude': lng,
          }),
        );
      }
    } catch (_) {}
  }

  // ================================================================
  // CRITICAL ALARM & SOS AUDIO
  // ================================================================

  Future<void> _playSOSBeeps() async {
    try {
      final player = AudioPlayer();
      for (int i = 0; i < 3; i++) {
        await player.play(AssetSource('audio/sos_beep.wav'));
        await Future.delayed(const Duration(milliseconds: 380));
      }
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _playCriticalAlarm() async {
    try {
      await _criticalAlarmChannel.invokeMethod('prepareCriticalAlarm');
    } catch (_) {}

    try {
      _criticalAlarmPlayer = AudioPlayer();
      if (mounted) setState(() {});

      await _criticalAlarmPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );

      await _criticalAlarmPlayer!.setVolume(1.0);
      await _criticalAlarmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _criticalAlarmPlayer!.play(AssetSource('audio/sos_beep.wav'));

      await Future.delayed(const Duration(seconds: 15));
      if (_criticalAlarmPlayer != null) {
        await _silenceCriticalAlarm();
      }
    } catch (_) {
      await _silenceCriticalAlarm();
      _playSOSBeeps();
    }
  }

  Future<void> _silenceCriticalAlarm() async {
    try {
      await _criticalAlarmPlayer?.stop();
      await _criticalAlarmPlayer?.dispose();
    } catch (_) {}
    _criticalAlarmPlayer = null;
    try {
      await _criticalAlarmChannel.invokeMethod('restoreAudio');
    } catch (_) {}
    if (mounted) setState(() {});
  }

  // ================================================================
  // SOS CATEGORIES & SHEETS
  // ================================================================

  static const List<Map<String, dynamic>> _sosCategories = [
    {
      'id': 'medical',
      'label': 'Medical Assist',
      'marathi': 'वैद्यकीय मदत — आजार / शारीरिक त्रास',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFE53935),
      'critical': true,
    },
    {
      'id': 'accident',
      'label': 'Accident Alert',
      'marathi': 'अपघात / गंभीर दुखापत',
      'icon': Icons.warning_rounded,
      'color': Color(0xFFB71C1C),
      'critical': true,
    },
    {
      'id': 'other',
      'label': 'Other Assistance',
      'marathi': 'इतर मदत — हरवलेले सामान / इतर समस्या',
      'icon': Icons.help_outline_rounded,
      'color': Color(0xFF2D4678),
      'critical': false,
    },
  ];

  void _showSOSCategorySheet(BuildContext context) {
    final descriptionController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 22,
                right: 22,
                top: 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sosRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: sosRed, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Emergency Type',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: sosRed,
                              ),
                            ),
                            Text(
                              'आणीबाणीचा प्रकार निवडा',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 13,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: blue),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._sosCategories.map((cat) {
                    final isSelected = selectedCategory == cat['id'];
                    final isCritical = cat['critical'] as bool;
                    final catColor = cat['color'] as Color;

                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedCategory = cat['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.09)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : blue.withValues(alpha: 0.12),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: catColor.withValues(
                                    alpha: isSelected ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(cat['icon'] as IconData,
                                  color: catColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['label'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: catColor,
                                    ),
                                  ),
                                  Text(
                                    cat['marathi'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 11.5,
                                      color: catColor.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCritical)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sosRed.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CRITICAL',
                                  style: TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: sosRed,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Radio<String>(
                              value: cat['id'] as String,
                              groupValue: selectedCategory,
                              activeColor: catColor,
                              onChanged: (val) =>
                                  setSheetState(() => selectedCategory = val),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (selectedCategory == 'other') ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Describe your situation (परिस्थिती सांगा) *',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: blue.withValues(alpha: 0.20)),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        onChanged: (_) => setSheetState(() {}),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 13.5,
                          color: blue,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Lost baggage/phone, need water/shelter...',
                          hintStyle: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12.5,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedCategory == null ||
                              (selectedCategory == 'other' &&
                                  descriptionController.text.trim().isEmpty)
                          ? null
                          : () {
                              Navigator.pop(sheetCtx);
                              final catDef = _sosCategories.firstWhere(
                                  (c) => c['id'] == selectedCategory);
                              _showSOSConfirmation(
                                context,
                                category: catDef,
                                description: descriptionController.text.trim(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sosRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'PROCEED TO CONFIRM',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(descriptionController.dispose);
  }

  void _showSOSConfirmation(
    BuildContext context, {
    required Map<String, dynamic> category,
    String description = '',
  }) {
    final bool isCritical = category['critical'] as bool;
    final Color catColor = category['color'] as Color;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: sosRed, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm SOS Alert',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w800,
                    color: sosRed,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(category['icon'] as IconData,
                        color: catColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: catColor,
                            ),
                          ),
                          Text(
                            category['marathi'] as String,
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 11.5,
                              color: catColor.withValues(alpha: 0.70),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12.5,
                                color: blue.withValues(alpha: 0.80),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: sosRed.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CRITICAL',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: sosRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isCritical
                    ? 'This is a high-priority emergency. Your live GPS will be sent to nearby volunteers. A loud alarm will sound for 15 seconds.'
                    : 'Your request and live GPS location will be sent to nearby volunteers.',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13.5,
                  height: 1.4,
                  color: blue.withValues(alpha: 0.90),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Lexend', color: blue)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _sendSOSRequest(category: category, description: description);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sosRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('SEND ALERT', style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BACKEND INTEGRATION & SOS DISPATCH
  // ================================================================

  void _startSosPolling() {
    _sosPollingTimer?.cancel();
    _sosPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _isSosActive) {
        _checkActiveSos();
      } else {
        _sosPollingTimer?.cancel();
      }
    });
  }

  Future<void> _checkActiveSos() async {
    if (currentUsername.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assistance-requests/varkari/$currentUsername'),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['request'] != null) {
        final req = data['request'];
        final currentStatus = req['status']?.toString();
        final volunteerId = req['assigned_volunteer_username']?.toString();

        if (_lastSosStatus == 'PENDING' && currentStatus == 'ASSIGNED') {
          _playSOSBeeps();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              content: Text(
                '✅ Volunteer ($volunteerId) has accepted your SOS request!',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        _lastSosStatus = currentStatus;
        if (!_isSosActive) {
          setState(() {
            _isSosActive = true;
          });
        }
        _startSosPolling();
      } else {
        _lastSosStatus = null;
        if (_isSosActive) {
          setState(() {
            _isSosActive = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _sendSOSRequest({
    required Map<String, dynamic> category,
    required String description,
  }) async {
    if (_isSendingSos) return;
    final bool isCritical = category['critical'] as bool;

    setState(() {
      _isSendingSos = true;
      _selectedSosCategory = category['id'] as String;
      _selectedSosLabel = category['label'] as String;
      _selectedSosDescription = description.isEmpty ? category['label'] as String : description;
    });

    try {
      Position? position = _currentPosition;
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/assistance-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'varkari_username': currentUsername,
          'problem_description': '${category['label']}: $description',
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['success'] == true) {
        _lastSosStatus = 'PENDING';
        setState(() {
          _isSosActive = true;
        });

        if (isCritical) {
          _playCriticalAlarm();
        } else {
          _playSOSBeeps();
        }
        _startSosPolling();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: sosRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            content: Text(
              '🚨 ${_selectedSosLabel} Alert Sent! Waiting for nearby volunteer.',
              style: const TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'Unable to send SOS');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sosRed,
          content: Text('Unable to send SOS: $e', style: const TextStyle(fontFamily: 'Lexend')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSos = false;
        });
      }
    }
  }

  // ================================================================
  // SEARCH USERS
  // ================================================================

  Future<void> _searchUsers(String query) async {
    final searchQuery = query.trim();

    if (searchQuery.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(searchQuery);
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?query=$encodedQuery'),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _searchResults = data['users'] ?? [];
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final healthConditions = user['health_conditions'] is List
        ? (user['health_conditions'] as List).join(', ')
        : '${user['health_conditions'] ?? 'Not available'}';
    final isVT = user['user_type'] == 'VT';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 22),
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: orange.withValues(alpha: 0.12),
                    child: Icon(
                      isVT ? Icons.volunteer_activism_outlined : Icons.person_outline_rounded,
                      color: orange,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${user['username'] ?? ''} • ${isVT ? 'Volunteer' : 'Varkari'}',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: blue.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _detailRow(Icons.phone_outlined, 'Phone', '${user['phone'] ?? 'Not available'}'),
                  _detailRow(Icons.bloodtype_outlined, 'Blood Group', '${user['blood_group'] ?? 'Not available'}'),
                  _detailRow(Icons.person_outline, 'Age', '${user['age'] ?? 'Not available'}'),
                  _detailRow(Icons.medical_information_outlined, 'Health Conditions', healthConditions),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final double lat = user['latitude'] != null
                            ? (double.tryParse('${user['latitude']}') ?? 18.4902)
                            : 18.4902;
                        final double lng = user['longitude'] != null
                            ? (double.tryParse('${user['longitude']}') ?? 73.8130)
                            : 73.8130;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              focusTargetLocation: LatLng(lat, lng),
                              focusTargetTitle: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                              focusTargetSubtitle: '${user['username'] ?? ''} (${user['user_type'] ?? ''})',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'VIEW LIVE MAP LOCATION',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: blue.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Lexend', fontSize: 11, color: blue.withValues(alpha: 0.55))),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, fontWeight: FontWeight.w600, color: blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ROUTING NAVIGATION
  // ================================================================

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userData: widget.userData,
          userType: widget.userType,
        ),
      ),
    );
  }

  void _openActiveRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRequestsScreen(
          volunteerUsername: currentUsername,
        ),
      ),
    );
  }

  void _openMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userData?['first_name']?.toString() ??
        (isVarkari ? 'Varkari' : 'Volunteer');

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // HEADER
              // ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'वारी',
                          style: TextStyle(
                            fontFamily: 'YatraOne',
                            fontSize: 31,
                            color: orange,
                          ),
                        ),
                        TextSpan(
                          text: 'पथ',
                          style: TextStyle(
                            fontFamily: 'Kalam',
                            fontSize: 31,
                            fontWeight: FontWeight.bold,
                            color: blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => LanguageSelectionDialog.show(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: orange.withValues(alpha: 0.25)),
                          ),
                          child: const Icon(Icons.language_rounded, color: orange, size: 22),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openMapScreen(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: blue.withValues(alpha: 0.18)),
                          ),
                          child: const Icon(Icons.map_outlined, color: blue, size: 22),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openProfile(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.09),
                            shape: BoxShape.circle,
                            border: Border.all(color: blue.withValues(alpha: 0.18)),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: blue, size: 25),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (isVolunteer) ...[
                const SizedBox(height: 18),
                _buildVolunteerSearch(),
              ],

              const SizedBox(height: 22),

              Text(
                isVarkari
                    ? '${appLanguageNotifier.t('varkari_welcome')}, $displayName! 🙏'
                    : '${appLanguageNotifier.t('volunteer_welcome')}, $displayName! 👋',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isVarkari
                    ? appLanguageNotifier.t('varkari_sub')
                    : appLanguageNotifier.t('volunteer_sub'),
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13,
                  color: blue.withValues(alpha: 0.60),
                ),
              ),

              const SizedBox(height: 25),

              if (isVarkari)
                _buildVarkariHome(context)
              else
                _buildVolunteerHome(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // VOLUNTEER SEARCH WIDGET
  // ================================================================

  Widget _buildVolunteerSearch() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: blue.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, color: blue),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 24),
              hintText: 'Search Anyone by Name or ID',
              hintStyle: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 13,
                color: blue.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        if (_hasSearched)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: blue.withValues(alpha: 0.10)),
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(fontFamily: 'Lexend', color: blue),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = Map<String, dynamic>.from(_searchResults[index]);
                          final isVT = user['user_type'] == 'VT';

                          return ListTile(
                            onTap: () => _showUserDetails(user),
                            leading: CircleAvatar(
                              backgroundColor: (isVT ? orange : blue).withValues(alpha: 0.10),
                              child: Icon(
                                isVT ? Icons.volunteer_activism_outlined : Icons.person_outline_rounded,
                                color: isVT ? orange : blue,
                              ),
                            ),
                            title: Text(
                              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                            subtitle: Text(
                              '${user['username'] ?? ''} • ${isVT ? 'Volunteer' : 'Varkari'}',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 11.5,
                                color: blue.withValues(alpha: 0.55),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.map_rounded, color: orange, size: 20),
                                  tooltip: 'View Live Location',
                                  onPressed: () {
                                    final double lat = user['latitude'] != null
                                        ? (double.tryParse('${user['latitude']}') ?? 18.4902)
                                        : 18.4902;
                                    final double lng = user['longitude'] != null
                                        ? (double.tryParse('${user['longitude']}') ?? 73.8130)
                                        : 73.8130;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapScreen(
                                          focusTargetLocation: LatLng(lat, lng),
                                          focusTargetTitle: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                                          focusTargetSubtitle: '${user['username'] ?? ''} (${user['user_type'] ?? ''})',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: blue,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
      ],
    );
  }

  // ================================================================
  // VARKARI HOME VIEW WITH IMPROVISED SOS
  // ================================================================

  Widget _buildVarkariHome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SILENCE ALARM BANNER (shown when critical alarm is ringing) ──
        if (_criticalAlarmPlayer != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sosRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sosRed.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: sosRed, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '🔊 Critical alarm sounding at full volume...',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: sosRed,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _silenceCriticalAlarm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sosRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SILENCE',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── BRIGHT RED SOS BUTTON ──
        Center(
          child: GestureDetector(
            onTap: _isSosActive ? null : () => _showSOSCategorySheet(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                color: sosRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: sosRed.withValues(alpha: _isSosActive ? 0.60 : 0.38),
                    blurRadius: _isSosActive ? 28 : 22,
                    spreadRadius: _isSosActive ? 6 : 4,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSendingSos)
                    const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SOS',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      _isSosActive ? 'ALERT SENT' : 'Need Help?',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: Text(
            _isSosActive
                ? '${_selectedSosLabel ?? 'Emergency'} alert dispatched — Help is on the way'
                : appLanguageNotifier.t('tap_for_help'),
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: sosRed.withValues(alpha: 0.90),
            ),
          ),
        ),

        const SizedBox(height: 28),

        _sectionTitle(appLanguageNotifier.t('todays_vaari'), Icons.directions_walk_rounded),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: blue.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              _locationRow(
                icon: Icons.my_location_rounded,
                title: appLanguageNotifier.t('live_gps_loc'),
                value: _liveLocationText,
                iconColor: _currentPosition != null ? Colors.green : blue,
                iconBackground: (_currentPosition != null ? Colors.green : blue).withValues(alpha: 0.09),
              ),
              const SizedBox(height: 15),
              Divider(color: blue.withValues(alpha: 0.10)),
              const SizedBox(height: 15),
              _locationRow(
                icon: Icons.temple_hindu_rounded,
                title: appLanguageNotifier.t('next_checkpoint'),
                value: 'Saswad Checkpoint',
                iconColor: orange,
                iconBackground: orange.withValues(alpha: 0.10),
                showArrow: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        _buildVarkariSosStatus(),
      ],
    );
  }

  Future<void> _confirmVarkariReached(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assistance-requests/$requestId/varkari-reached'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final req = data['request'];
        final isCompleted = req != null && req['status'] == 'COMPLETED';

        setState(() {
          if (isCompleted) {
            _isSosActive = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              isCompleted
                  ? 'Emergency request completed and closed! 🙏'
                  : 'Volunteer arrival confirmed! Waiting for volunteer to mark as done.',
              style: const TextStyle(fontFamily: 'Lexend'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sosRed,
          content: Text('Unable to confirm arrival: $e'),
        ),
      );
    }
  }

  Widget _buildVarkariSosStatus() {
    if (!_isSosActive) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: http.get(
        Uri.parse('$baseUrl/assistance-requests/varkari/$currentUsername'),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        try {
          final response = snapshot.data as http.Response;
          final data = jsonDecode(response.body);
          final requestData = data['request'];

          if (requestData == null) {
            return const SizedBox.shrink();
          }

          final int requestId = int.parse('${requestData['id']}');
          final status = requestData['status']?.toString() ?? 'PENDING';
          final volunteer = requestData['assigned_volunteer_username'];
          final bool varkariReached = requestData['varkari_reached'] == true;
          final bool volunteerDone = requestData['volunteer_done'] == true;

          if (status == 'COMPLETED' || (varkariReached && volunteerDone)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isSosActive) {
                setState(() {
                  _isSosActive = false;
                });
              }
            });
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: status == 'ASSIGNED'
                  ? Colors.green.withValues(alpha: 0.08)
                  : orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: status == 'ASSIGNED'
                    ? Colors.green.withValues(alpha: 0.30)
                    : orange.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'ASSIGNED'
                      ? 'Volunteer Assigned! ✅'
                      : 'Looking for the nearest volunteer...',
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: blue,
                  ),
                ),
                const SizedBox(height: 8),
                if (status == 'ASSIGNED') ...[
                  Text(
                    'Volunteer ID: $volunteer\nThis volunteer has been assigned to help you.',
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12.5,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final double? vLat = (requestData['varkari_latitude'] != null)
                            ? double.tryParse('${requestData['varkari_latitude']}')
                            : _currentPosition?.latitude ?? 18.4902;
                        final double? vLng = (requestData['varkari_longitude'] != null)
                            ? double.tryParse('${requestData['varkari_longitude']}')
                            : _currentPosition?.longitude ?? 73.8130;

                        final double? volLat = (requestData['volunteer_latitude'] != null)
                            ? double.tryParse('${requestData['volunteer_latitude']}')
                            : null;
                        final double? volLng = (requestData['volunteer_longitude'] != null)
                            ? double.tryParse('${requestData['volunteer_longitude']}')
                            : null;

                        final varkariPos = (vLat != null && vLng != null) ? LatLng(vLat, vLng) : null;
                        final volunteerPos = (volLat != null && volLng != null) ? LatLng(volLat, volLng) : null;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              sosVarkariLocation: varkariPos,
                              sosVarkariName: 'Your Location (SOS Alert)',
                              sosVolunteerLocation: volunteerPos,
                              sosVolunteerName: volunteer != null ? 'Volunteer ($volunteer)' : 'Assigned Volunteer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, color: blue, size: 18),
                      label: const Text(
                        'TRACK VOLUNTEER & SOS MAP',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: blue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: blue.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (varkariReached)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Arrival Confirmed. Waiting for volunteer to finish.',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmVarkariReached(requestId),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                        label: const Text(
                          'VOLUNTEER REACHED (स्वयंसेवक पोहोचला)',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ] else
                  const Text(
                    'Your SOS has been sent successfully. Waiting for a nearby volunteer to accept your request...',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12.5,
                      color: blue,
                    ),
                  ),
              ],
            ),
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  // ================================================================
  // VOLUNTEER HOME VIEW
  // ================================================================

  Widget _buildVolunteerHome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(appLanguageNotifier.t('active_alerts'), Icons.warning_amber_rounded),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _openActiveRequests(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: orange.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: orange,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLanguageNotifier.t('nearby_requests'),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLanguageNotifier.t('view_assigned_sos'),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: orange,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 27),
        _sectionTitle(appLanguageNotifier.t('volunteer_status_title'), Icons.volunteer_activism_outlined),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: blue.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 6, backgroundColor: Colors.green),
              const SizedBox(width: 10),
              Text(
                appLanguageNotifier.t('active_on_duty'),
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),
              const Spacer(),
              Text(
                appLanguageNotifier.t('online'),
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: blue.withValues(alpha: 0.10)),
          ),
          child: _locationRow(
            icon: Icons.my_location_rounded,
            title: appLanguageNotifier.t('live_gps_loc'),
            value: _liveLocationText,
            iconColor: _currentPosition != null ? Colors.green : blue,
            iconBackground: (_currentPosition != null ? Colors.green : blue).withValues(alpha: 0.09),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SECTION TITLE & HELPERS
  // ================================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: orange, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: blue,
          ),
        ),
      ],
    );
  }

  Widget _locationRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color iconBackground,
    bool showArrow = false,
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Lexend', fontSize: 11.5, color: Colors.grey)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),
            ],
          ),
        ),
        if (showArrow) const Icon(Icons.arrow_forward_ios_rounded, color: blue, size: 15),
      ],
    );
  }
}