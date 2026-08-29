import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_screen.dart';
import 'services/app_language.dart';

class MissingScreen extends StatefulWidget {
  final String? userType;
  final Map<String, dynamic>? userData;

  const MissingScreen({
    super.key,
    this.userType,
    this.userData,
  });

  @override
  State<MissingScreen> createState() => _MissingScreenState();
}

class _MissingScreenState extends State<MissingScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);
  static const Color alertAmber = Color(0xFFE65100);

  // ================================================================
  // BACKEND URL (Android emulator maps localhost to 10.0.2.2)
  // ================================================================

  static const String backendUrl = 'http://10.0.2.2:5001';

  // ================================================================
  // STATE
  // ================================================================

  List<Map<String, dynamic>> _missingCases = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All Active'; // 'All Active', 'Under Verification', 'My Reports'

  bool get isVolunteer =>
      widget.userType == 'VT' || widget.userData?['user_type'] == 'VT';

  String get currentUserId =>
      widget.userData?['username'] ??
      (widget.userType == 'VT' ? 'VT101' : 'VK100001');

  String get currentUserType =>
      widget.userType ?? widget.userData?['user_type'] ?? 'VK';

  @override
  void initState() {
    super.initState();
    _fetchMissingPersons();
  }

  // ================================================================
  // FETCH ACTIVE MISSING PERSONS (PostgreSQL)
  // ================================================================

  Future<void> _fetchMissingPersons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('$backendUrl/missing-persons'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          if (!mounted) return;
          setState(() {
            _missingCases = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Backend not running or unreachable: use prototype dataset fallback
    }

    if (!mounted) return;

    // Fallback prototype dataset if backend is unreachable
    if (_missingCases.isEmpty) {
      _missingCases = [
        {
          'id': 1,
          'missing_person_id': 'MP-10001',
          'name': 'Anusuya Pandurang Patil',
          'age': 68,
          'gender': 'Female',
          'contact_number': '9822012345',
          'last_seen_location': 'Dive Ghat - Near Annachhatra',
          'last_seen_datetime': 'Today • 08:30 AM',
          'physical_description':
              'Wearing yellow Navari saree and tulsi mala. Carrying a copper water lota.',
          'clothes_description': 'Yellow saree, red blouse, green bangles',
          'other_info': 'Speaks Marathi only, mild hearing difficulty',
          'photo': '',
          'reporter_id': 'VK100022',
          'reporter_type': 'VK',
          'reporter_location': 'Saswad Road',
          'status': 'Missing',
          'verification_status': 'None',
        },
        {
          'id': 2,
          'missing_person_id': 'MP-10002',
          'name': 'Raju Dnyandev Shinde',
          'age': 11,
          'gender': 'Male',
          'contact_number': '9890123456',
          'last_seen_location': 'Hadapsar Palkhi Stand',
          'last_seen_datetime': 'Today • 09:15 AM',
          'physical_description':
              'Wearing white kurta pajama and orange Gandhi cap. Carrying brass chimta.',
          'clothes_description': 'White kurta, orange cap',
          'other_info': 'Separated from Dindi #08',
          'photo': '',
          'reporter_id': 'VT105',
          'reporter_type': 'VT',
          'reporter_location': 'Hadapsar Camp',
          'status': 'Found - Verification Pending',
          'found_by': 'VK100055',
          'found_location': 'Near Dive Ghat Entry',
          'found_datetime': '10 mins ago',
          'verification_status': 'Pending',
        },
      ];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ================================================================
  // GET CURRENT GPS POSITION HELPER
  // ================================================================

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // 1. REPORT MISSING PERSON FLOW
  // ================================================================

  void _showReportDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final physicalDescCtrl = TextEditingController();
    final clothesDescCtrl = TextEditingController();
    final otherInfoCtrl = TextEditingController();

    String selectedGender = 'Male';
    String? base64Photo;
    String photoPreviewText = 'No photo chosen';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 75,
                );

                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final encoded = base64Encode(bytes);
                  setModalState(() {
                    base64Photo = 'data:image/jpeg;base64,$encoded';
                    photoPreviewText = 'Photo selected (${(bytes.length / 1024).round()} KB)';
                  });
                }
              } catch (e) {
                _showSnackbar('Could not access image picker: $e', isError: true);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, color: orange, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Report Missing Person',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: blue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Name
                    _buildInputField('Full Name of Missing Person *', nameCtrl, 'e.g. Tukaram Patil'),
                    const SizedBox(height: 10),

                    // Age & Gender
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField('Age *', ageCtrl, 'e.g. 62', isNumber: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender *',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: blue,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: blue.withOpacity(0.2)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedGender,
                                    isExpanded: true,
                                    items: ['Male', 'Female', 'Other'].map((g) {
                                      return DropdownMenuItem(
                                        value: g,
                                        child: Text(g, style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, color: blue)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() => selectedGender = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Contact Phone
                    _buildInputField('Contact Phone Number', contactCtrl, '10-digit emergency contact', isNumber: true),
                    const SizedBox(height: 10),

                    // Last Seen Location
                    _buildInputField('Last Seen Location *', locationCtrl, 'e.g. Dive Ghat Annachhatra / Saswad Palkhi तळ'),
                    const SizedBox(height: 10),

                    // Physical Description
                    _buildInputField('Physical Characteristics', physicalDescCtrl, 'e.g. Height, beard, walking stick, spectacles', maxLines: 2),
                    const SizedBox(height: 10),

                    // Clothes / Appearance
                    _buildInputField('Clothes & Appearance at Time of Loss', clothesDescCtrl, 'e.g. White dhoti kurta, green scarf, tulsi mala', maxLines: 2),
                    const SizedBox(height: 10),

                    // Other Info
                    _buildInputField('Other Identifying Details / Dindi No.', otherInfoCtrl, 'e.g. Dindi #14, speaks Marathi/Kannada'),
                    const SizedBox(height: 14),

                    // Photo Picker Section
                    const Text(
                      'Missing Person Photograph',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: blue.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: base64Photo != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(base64Photo!.split(',').last),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined, color: orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              photoPreviewText,
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                color: base64Photo != null ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined, color: blue),
                            tooltip: 'Take Camera Photo',
                            onPressed: () => pickImage(ImageSource.camera),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library_outlined, color: orange),
                            tooltip: 'Pick from Gallery',
                            onPressed: () => pickImage(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final age = ageCtrl.text.trim();
                                final location = locationCtrl.text.trim();

                                if (name.isEmpty || age.isEmpty || location.isEmpty) {
                                  _showSnackbar('Please fill in required fields (Name, Age, Location).', isError: true);
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                // Capture reporter location
                                final pos = await _getCurrentLocation();
                                final reporterLocation = pos != null
                                    ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                                    : 'Live Wari Route';

                                try {
                                  final response = await http.post(
                                    Uri.parse('$backendUrl/missing-persons'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      'name': name,
                                      'age': int.tryParse(age) ?? 50,
                                      'gender': selectedGender,
                                      'contact_number': contactCtrl.text.trim(),
                                      'last_seen_location': location,
                                      'last_seen_datetime': DateTime.now().toString().substring(0, 16),
                                      'physical_description': physicalDescCtrl.text.trim(),
                                      'clothes_description': clothesDescCtrl.text.trim(),
                                      'other_info': otherInfoCtrl.text.trim(),
                                      'photo': base64Photo ?? '',
                                      'reporter_id': currentUserId,
                                      'reporter_type': currentUserType,
                                      'reporter_location': reporterLocation,
                                      'reporter_latitude': pos?.latitude,
                                      'reporter_longitude': pos?.longitude,
                                    }),
                                  );

                                  final data = jsonDecode(response.body);
                                  if (response.statusCode == 201 && data['success'] == true) {
                                    if (mounted) Navigator.pop(context);
                                    _showSnackbar('Report submitted! ID: ${data['missing_person_id']}');
                                    _fetchMissingPersons();
                                    return;
                                  }
                                } catch (_) {}

                                // Local fallback insertion if backend is offline
                                if (mounted) Navigator.pop(context);
                                final localId = 'MP-${10000 + _missingCases.length + 1}';
                                setState(() {
                                  _missingCases.insert(0, {
                                    'id': _missingCases.length + 1,
                                    'missing_person_id': localId,
                                    'name': name,
                                    'age': int.tryParse(age) ?? 50,
                                    'gender': selectedGender,
                                    'contact_number': contactCtrl.text.trim(),
                                    'last_seen_location': location,
                                    'last_seen_datetime': 'Just now',
                                    'physical_description': physicalDescCtrl.text.trim(),
                                    'clothes_description': clothesDescCtrl.text.trim(),
                                    'other_info': otherInfoCtrl.text.trim(),
                                    'photo': base64Photo ?? '',
                                    'reporter_id': currentUserId,
                                    'reporter_type': currentUserType,
                                    'reporter_location': reporterLocation,
                                    'status': 'Missing',
                                    'verification_status': 'None',
                                  });
                                });
                                _showSnackbar('Report recorded locally! ID: $localId');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'SUBMIT REPORT (नोंदणी करा)',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // 2. VARKARI "FOUND PERSON" ACTION FLOW
  // ================================================================

  void _handleVarkariFoundPerson(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.location_on_rounded, color: orange, size: 26),
              SizedBox(width: 8),
              Text(
                'I Found This Person',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  color: blue,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you have located ${person['name']} (${person['missing_person_id']})?\n\nYour current GPS location will be captured and shared with the nearest volunteer response team to assist you on the spot.',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13.5,
              height: 1.4,
              color: blue.withOpacity(0.9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Lexend', color: blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _showSnackbar('Capturing your location and notifying volunteers...');

                final pos = await _getCurrentLocation();
                final foundLocation = pos != null
                    ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                    : 'Reported by Varkari at Wari Route';

                final mpId = person['missing_person_id'];

                try {
                  final response = await http.post(
                    Uri.parse('$backendUrl/missing-persons/$mpId/found'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'found_by': currentUserId,
                      'found_location': foundLocation,
                      'found_latitude': pos?.latitude,
                      'found_longitude': pos?.longitude,
                      'found_datetime': DateTime.now().toString().substring(0, 16),
                    }),
                  );

                  if (response.statusCode == 200) {
                    _showSnackbar('Volunteer alert dispatched! Case is now Under Verification.');
                    _fetchMissingPersons();
                    return;
                  }
                } catch (_) {}

                // Local state update fallback
                setState(() {
                  final index = _missingCases.indexWhere((c) => c['missing_person_id'] == mpId);
                  if (index != -1) {
                    _missingCases[index]['status'] = 'Found - Verification Pending';
                    _missingCases[index]['found_by'] = currentUserId;
                    _missingCases[index]['found_location'] = foundLocation;
                    _missingCases[index]['found_datetime'] = 'Just now';
                  }
                });
                _showSnackbar('Case status updated to "Under Verification". Nearby volunteers notified.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONFIRM & NOTIFY',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // 3. VOLUNTEER "MARK AS FOUND" WITH LIVE PHOTO CAPTURE FLOW
  // ================================================================

  void _handleVolunteerMarkAsFound(Map<String, dynamic> person) {
    String? base64LivePhoto;
    String livePhotoText = 'Optional: Take live photo to confirm';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLivePhoto(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 75,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final encoded = base64Encode(bytes);
                  setDialogState(() {
                    base64LivePhoto = 'data:image/jpeg;base64,$encoded';
                    livePhotoText = 'Live photo captured!';
                  });
                }
              } catch (_) {}
            }

            return AlertDialog(
              backgroundColor: background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: orange, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'Mark Person as Located',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
                      color: blue,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'As a Volunteer, confirm that you have located ${person['name']}. You can attach a live photograph for verification.',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 13,
                      height: 1.35,
                      color: blue.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Photo capture button
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: blue.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: base64LivePhoto != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(base64LivePhoto!.split(',').last),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo_rounded, color: orange, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            livePhotoText,
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 11.5,
                              color: base64LivePhoto != null ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: blue, size: 22),
                          onPressed: () => pickLivePhoto(ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'Lexend', color: blue)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final pos = await _getCurrentLocation();
                    final foundLocation = pos != null
                        ? 'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                        : 'Volunteer Field Desk';

                    final mpId = person['missing_person_id'];

                    try {
                      final response = await http.post(
                        Uri.parse('$backendUrl/missing-persons/$mpId/found'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'found_by': currentUserId,
                          'found_location': foundLocation,
                          'found_latitude': pos?.latitude,
                          'found_longitude': pos?.longitude,
                          'found_datetime': DateTime.now().toString().substring(0, 16),
                          'found_photo': base64LivePhoto ?? '',
                        }),
                      );

                      if (response.statusCode == 200) {
                        _showSnackbar('Case updated to Under Verification.');
                        _fetchMissingPersons();
                        return;
                      }
                    } catch (_) {}

                    setState(() {
                      final index = _missingCases.indexWhere((c) => c['missing_person_id'] == mpId);
                      if (index != -1) {
                        _missingCases[index]['status'] = 'Found - Verification Pending';
                        _missingCases[index]['found_by'] = currentUserId;
                        _missingCases[index]['found_location'] = foundLocation;
                        _missingCases[index]['found_datetime'] = 'Just now';
                        _missingCases[index]['found_photo'] = base64LivePhoto ?? '';
                      }
                    });
                    _showSnackbar('Case status updated to "Under Verification".');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SUBMIT STATUS',
                    style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================================================
  // 4. VOLUNTEER "VERIFY & RESOLVE CASE" FLOW
  // ================================================================

  void _handleVerifyAndResolve(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.green, size: 26),
              SizedBox(width: 8),
              Text(
                'Verify & Close Case',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  color: blue,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Confirm that ${person['name']} (${person['missing_person_id']}) has been safely reunited or verified at the volunteer post.\n\nThis case will be marked as "Found/Resolved", archived to resolved records, and removed from the active search list.',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13.5,
              height: 1.4,
              color: blue.withOpacity(0.85),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Lexend', color: blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final mpId = person['missing_person_id'];

                try {
                  final response = await http.post(
                    Uri.parse('$backendUrl/missing-persons/$mpId/verify'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'resolved_by': currentUserId,
                    }),
                  );

                  if (response.statusCode == 200) {
                    _showSnackbar('Case $mpId verified and permanently resolved! 🎉');
                    _fetchMissingPersons();
                    return;
                  }
                } catch (_) {}

                // Fallback local removal
                setState(() {
                  _missingCases.removeWhere((c) => c['missing_person_id'] == mpId);
                });
                _showSnackbar('Case $mpId marked as Resolved and archived.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'VERIFY & RESOLVE',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // 5. VOLUNTEER "FLAG FALSE REPORT" FLOW
  // ================================================================

  void _handleFlagFalse(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Flag False Report',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  color: blue,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Revert case ${person['missing_person_id']} back to active "Missing" search status?',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13.5,
              color: blue.withOpacity(0.85),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Lexend', color: blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final mpId = person['missing_person_id'];

                try {
                  final response = await http.post(
                    Uri.parse('$backendUrl/missing-persons/$mpId/flag-false'),
                  );

                  if (response.statusCode == 200) {
                    _showSnackbar('Case reverted back to active search.');
                    _fetchMissingPersons();
                    return;
                  }
                } catch (_) {}

                setState(() {
                  final index = _missingCases.indexWhere((c) => c['missing_person_id'] == mpId);
                  if (index != -1) {
                    _missingCases[index]['status'] = 'Missing';
                    _missingCases[index]['verification_status'] = 'Rejected';
                    _missingCases[index]['found_by'] = null;
                    _missingCases[index]['found_location'] = null;
                  }
                });
                _showSnackbar('Case reverted back to active Missing status.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'REVERT CASE',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // SNACKBAR HELPER
  // ================================================================

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Lexend'),
          ),
          backgroundColor: isError ? Colors.red.shade700 : blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ================================================================
  // BUILD INPUT FIELD WIDGET
  // ================================================================

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: blue,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: blue.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'Lexend', fontSize: 13.5, color: blue),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Lexend', fontSize: 12.5, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    // Filter cases
    final filteredCases = _missingCases.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final loc = (c['last_seen_location'] ?? '').toString().toLowerCase();
      final id = (c['missing_person_id'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || loc.contains(q) || id.contains(q);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Under Verification') {
        return c['status'] == 'Found - Verification Pending';
      } else if (_selectedFilter == 'My Reports') {
        return c['reporter_id'] == currentUserId;
      }
      return true;
    }).toList();

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
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh Cases',
            icon: const Icon(Icons.refresh_rounded, color: blue),
            onPressed: _fetchMissingPersons,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // EMERGENCY HELPLINE BANNER
            // ======================================================
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: blue.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Emergency Helplines (आणीबाणी संपर्क)',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '24x7',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelplineTile(
                          icon: Icons.local_police_outlined,
                          title: 'Police',
                          number: '112',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHelplineTile(
                          icon: Icons.medical_services_outlined,
                          title: 'Medical',
                          number: '108',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHelplineTile(
                          icon: Icons.support_agent_outlined,
                          title: 'Wari Help',
                          number: '1077',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ======================================================
            // SEARCH & REPORT ROW
            // ======================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: blue.withOpacity(0.12)),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, color: blue),
                        decoration: InputDecoration(
                          hintText: 'Search by name or location...',
                          hintStyle: TextStyle(fontFamily: 'Lexend', fontSize: 12.5, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Report Button
                  ElevatedButton.icon(
                    onPressed: _showReportDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Report',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ======================================================
            // FILTER CHIPS
            // ======================================================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _buildFilterChip('All Active', appLanguageNotifier.t('tab_reported')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Under Verification', appLanguageNotifier.t('tab_sightings')),
                  const SizedBox(width: 8),
                  _buildFilterChip('My Reports', 'My Reports'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ======================================================
            // CASES LIST
            // ======================================================
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: orange),
                    )
                  : filteredCases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 48, color: blue.withOpacity(0.3)),
                              const SizedBox(height: 10),
                              Text(
                                'No matching missing person reports found.',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 14,
                                  color: blue.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchMissingPersons,
                          color: orange,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                            itemCount: filteredCases.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final person = filteredCases[index];
                              return _buildCaseCard(person);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FILTER CHIP WIDGET
  // ================================================================

  Widget _buildFilterChip(String key, [String? displayLabel]) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? blue : blue.withOpacity(0.15),
          ),
        ),
        child: Text(
          displayLabel ?? key,
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : blue,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MISSING PERSON CARD WIDGET
  // ================================================================

  Widget _buildCaseCard(Map<String, dynamic> person) {
    final isPendingVerification = person['status'] == 'Found - Verification Pending';
    final photoStr = person['photo']?.toString() ?? '';
    final hasPhoto = photoStr.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPendingVerification ? alertAmber.withOpacity(0.4) : blue.withOpacity(0.09),
          width: isPendingVerification ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Photo, Name, ID & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo or Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPendingVerification ? alertAmber : orange,
                      width: 1.5,
                    ),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: photoStr.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(photoStr.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: orange, size: 30),
                                )
                              : Image.network(
                                  photoStr,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: orange, size: 30),
                                ),
                        )
                      : Center(
                          child: Text(
                            person['name']?[0] ?? 'V',
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: orange,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 12),

                // Name & Basic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              person['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPendingVerification
                                  ? alertAmber.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPendingVerification ? 'VERIFICATION PENDING' : 'MISSING',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isPendingVerification ? alertAmber : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: ${person['missing_person_id']} • ${person['age']} yrs • ${person['gender']}',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: blue.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reported by: ${person['reporter_id']} (${person['reporter_type'] == 'VT' ? 'Volunteer' : 'Varkari'})',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 11,
                          color: blue.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Last Seen Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: orange, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Last Seen: ${person['last_seen_location']}',
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Text(
                'Time: ${person['last_seen_datetime'] ?? 'Today'}',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 11,
                  color: blue.withOpacity(0.45),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Description / Clothes Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (person['physical_description'] != null && person['physical_description'].toString().isNotEmpty)
                    Text(
                      '• Description: ${person['physical_description']}',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11.5,
                        height: 1.3,
                        color: blue.withOpacity(0.85),
                      ),
                    ),
                  if (person['clothes_description'] != null && person['clothes_description'].toString().isNotEmpty)
                    Text(
                      '• Clothes: ${person['clothes_description']}',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11.5,
                        height: 1.3,
                        color: blue.withOpacity(0.85),
                      ),
                    ),
                  if (person['other_info'] != null && person['other_info'].toString().isNotEmpty)
                    Text(
                      '• Note: ${person['other_info']}',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11.5,
                        height: 1.3,
                        color: blue.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),

            // Found status banner if verification pending
            if (isPendingVerification) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: alertAmber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: alertAmber.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: alertAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Spotted by ${person['found_by'] ?? 'User'} at ${person['found_location'] ?? 'Wari route'} (${person['found_datetime'] ?? 'Recently'})',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: alertAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // View Reporter & Sighting Map Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final double rLat = (person['reporter_latitude'] != null)
                      ? (double.tryParse('${person['reporter_latitude']}') ?? 18.4420)
                      : 18.4420;
                  final double rLng = (person['reporter_longitude'] != null)
                      ? (double.tryParse('${person['reporter_longitude']}') ?? 73.9680)
                      : 73.9680;

                  final double? fLat = (person['found_latitude'] != null)
                      ? double.tryParse('${person['found_latitude']}')
                      : null;
                  final double? fLng = (person['found_longitude'] != null)
                      ? double.tryParse('${person['found_longitude']}')
                      : null;

                  final reporterPos = LatLng(rLat, rLng);
                  final sightingPos = (fLat != null && fLng != null) ? LatLng(fLat, fLng) : null;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        missingReporterLocation: reporterPos,
                        missingReporterName: 'Reporter (${person['reporter_id'] ?? 'User'})',
                        missingSightingLocation: sightingPos,
                        missingSightingName: 'Sighting (${person['found_by'] ?? 'User'})',
                        missingPersonName: '${person['name']} (${person['missing_person_id']})',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded, color: blue, size: 18),
                label: const Text(
                  'VIEW REPORTER & SIGHTING MAP',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: blue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: BorderSide(color: blue.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Action Buttons
            if (!isPendingVerification) ...[
              // Case is Active MISSING:
              if (!isVolunteer)
                // VARKARI OPTION:
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleVarkariFoundPerson(person),
                    icon: const Icon(Icons.location_searching_rounded, size: 18),
                    label: const Text(
                      'I SPOTTED THIS PERSON (मला सापडले)',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                // VOLUNTEER OPTION:
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleVolunteerMarkAsFound(person),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text(
                      'MARK AS FOUND (CAPTURE LIVE PHOTO)',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // Case is UNDER VERIFICATION:
              if (isVolunteer)
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleVerifyAndResolve(person),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text(
                            'VERIFY & RESOLVE',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleFlagFalse(person),
                          icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.redAccent),
                          label: const Text(
                            'FALSE ALARM',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Volunteers are currently verifying this report on site.',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: blue.withOpacity(0.65),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineTile({
    required IconData icon,
    required String title,
    required String number,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            number,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}