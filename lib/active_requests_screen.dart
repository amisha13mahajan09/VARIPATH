import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'map_screen.dart';
import 'services/app_language.dart';

class ActiveRequestsScreen extends StatefulWidget {
  final String volunteerUsername;

  const ActiveRequestsScreen({
    super.key,
    required this.volunteerUsername,
  });

  @override
  State<ActiveRequestsScreen> createState() =>
      _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState
    extends State<ActiveRequestsScreen> {
  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);
  static const Color sosRed = Color(0xFFE53935);

  static const String baseUrl =
      'http://10.0.2.2:5001';

  Position? _currentPosition;

  bool _isLoading = true;

  String _statusText =
      'Getting your live location...';

  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getVolunteerLocation();

    await _loadRequests();
  }

  // ================================================================
  // GET GPS
  // ================================================================

  Future<void> _getVolunteerLocation() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _statusText =
            'Location services are disabled.';
          });
        }

        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _statusText =
            'Location permission is required.';
          });
        }

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;

        _statusText =
        'Your live location is active.';
      });

      _updateVolunteerLocationOnBackend(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText =
          'Unable to detect GPS location.';
        });
      }
    }
  }

  Future<void> _updateVolunteerLocationOnBackend(
      double lat,
      double lng,
      ) async {
    if (widget.volunteerUsername.isEmpty) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/volunteer-location'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'volunteer_username': widget.volunteerUsername,
          'latitude': lat,
          'longitude': lng,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // ================================================================
  // LOAD REQUESTS ASSIGNED TO THIS VOLUNTEER
  // ================================================================

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/assistance-requests/volunteer/'
              '${widget.volunteerUsername}',
        ),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        setState(() {
          _requests = data['requests'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _requests = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _requests = [];
        _isLoading = false;
      });
    }
  }

  // ================================================================
  // ACCEPT REQUEST
  // ================================================================

  Future<void> _acceptRequest(
      int requestId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/assistance-requests/'
              '$requestId/accept',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'volunteer_username':
          widget.volunteerUsername,
        }),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'You are now assigned to help this Varkari.',
            ),
          ),
        );

        await _loadRequests();
      } else {
        throw Exception(
          data['message'] ??
              'Unable to accept request.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sosRed,
          content: Text(
            '$e',
          ),
        ),
      );
    }
  }

  // ================================================================
  // COMPLETE REQUEST
  // ================================================================

  Future<void> _completeRequest(
      int requestId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/assistance-requests/'
              '$requestId/complete',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'volunteer_username':
          widget.volunteerUsername,
        }),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Assistance completed successfully.',
            ),
          ),
        );

        await _loadRequests();
      } else {
        throw Exception(
          data['message'] ??
              'Unable to complete request.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sosRed,
          content: Text('$e'),
        ),
      );
    }
  }

  // ================================================================
  // CONFIRM COMPLETE
  // ================================================================

  void _confirmComplete(
      int requestId,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mark Assistance as Done?',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),
          content: const Text(
            'This request will be completed and removed '
                'from both your screen and the Varkari\'s screen.',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              color: blue,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: blue,
                  fontFamily: 'Lexend',
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await _completeRequest(requestId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,

        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'वारी',
                style: TextStyle(
                  fontFamily: 'YatraOne',
                  color: orange,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: ' पथ',
                style: TextStyle(
                  fontFamily: 'Kalam',
                  color: blue,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        iconTheme: const IconThemeData(
          color: blue,
        ),

        actions: [
          IconButton(
            onPressed: _initializeScreen,
            icon: const Icon(
              Icons.refresh_rounded,
              color: orange,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _initializeScreen,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: orange,
          ),
        )
            : _requests.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 140),

            const Icon(
              Icons.check_circle_outline,
              size: 70,
              color: Colors.green,
            ),

            const SizedBox(height: 18),

            const Center(
              child: Text(
                'No Active Requests',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                _statusText,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: blue.withOpacity(0.55),
                ),
              ),
            ),
          ],
        )
            : ListView.builder(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(18),

          itemCount: _requests.length,

          itemBuilder:
              (context, index) {
            final request =
            Map<String, dynamic>.from(
              _requests[index],
            );

            return _requestCard(request);
          },
        ),
      ),
    );
  }

  // ================================================================
  // REQUEST CARD
  // ================================================================

  Widget _requestCard(
      Map<String, dynamic> request,
      ) {
    final int requestId =
    int.parse('${request['id']}');

    final status =
        request['status']?.toString() ?? 'PENDING';

    final String name =
        '${request['first_name'] ?? ''} '
        '${request['last_name'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color: status == 'ASSIGNED'
              ? Colors.green.withOpacity(0.35)
              : orange.withOpacity(0.25),
        ),

        boxShadow: [
          BoxShadow(
            color: blue.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: sosRed.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.warning_rounded,
                  color: sosRed,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                        color: blue,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      request['varkari_username']
                          ?.toString() ??
                          '',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11.5,
                        color:
                        blue.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: status == 'ASSIGNED'
                      ? Colors.green.withOpacity(0.10)
                      : orange.withOpacity(0.10),

                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: status == 'ASSIGNED'
                        ? Colors.green
                        : orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Emergency Details',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: blue.withOpacity(0.55),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            request['problem_description']
                ?.toString() ??
                'No description provided.',
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              height: 1.4,
              color: blue,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.bloodtype_outlined,
                color: orange,
                size: 18,
              ),

              const SizedBox(width: 7),

              Text(
                'Blood Group: '
                    '${request['blood_group'] ?? 'N/A'}',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  color: blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final double? vLat = (request['varkari_latitude'] != null)
                    ? double.tryParse('${request['varkari_latitude']}')
                    : 18.4902;
                final double? vLng = (request['varkari_longitude'] != null)
                    ? double.tryParse('${request['varkari_longitude']}')
                    : 73.8130;

                final varkariPos = (vLat != null && vLng != null) ? LatLng(vLat, vLng) : const LatLng(18.4902, 73.8130);
                final volunteerPos = _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      sosVarkariLocation: varkariPos,
                      sosVarkariName: '$name (${request['varkari_username']})',
                      sosVolunteerLocation: volunteerPos,
                      sosVolunteerName: '${widget.volunteerUsername} (You)',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, color: blue, size: 18),
              label: const Text(
                'VIEW LIVE MAP & TRACK VARKARI',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: blue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: blue.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,

            child: status == 'ASSIGNED'
                ? ((request['volunteer_done'] == true)
                ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.30),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marked as Done. Waiting for Varkari confirmation.',
                      textAlign: TextAlign.center,
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
                : ElevatedButton.icon(
              onPressed: () =>
                  _confirmComplete(requestId),

              icon: const Icon(
                Icons.check_circle_outline,
              ),

              label: const Text(
                'MARK AS DONE',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.green,
                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ))
                : ElevatedButton.icon(
              onPressed: () =>
                  _acceptRequest(requestId),

              icon: const Icon(
                Icons.volunteer_activism,
              ),

              label: Text(
                appLanguageNotifier.t('accept_request'),
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}