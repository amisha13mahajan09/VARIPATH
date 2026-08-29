import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';

import 'services/location_service.dart';
import 'services/weather_service.dart';
import 'services/vari_route_data.dart';
import 'models/volunteer.dart';
import 'models/weather_data.dart';
import 'models/medical_stock.dart';
import 'models/weather_route_suggestion.dart';
import 'widgets/varkari_weather_sheet.dart';
import 'widgets/medical_stock_sheet.dart';
import 'services/app_language.dart';

class MapScreen extends StatefulWidget {
  final LatLng? focusTargetLocation;
  final String? focusTargetTitle;
  final String? focusTargetSubtitle;

  final LatLng? sosVarkariLocation;
  final String? sosVarkariName;
  final LatLng? sosVolunteerLocation;
  final String? sosVolunteerName;

  final LatLng? missingReporterLocation;
  final String? missingReporterName;
  final LatLng? missingSightingLocation;
  final String? missingSightingName;
  final String? missingPersonName;

  const MapScreen({
    super.key,
    this.focusTargetLocation,
    this.focusTargetTitle,
    this.focusTargetSubtitle,
    this.sosVarkariLocation,
    this.sosVarkariName,
    this.sosVolunteerLocation,
    this.sosVolunteerName,
    this.missingReporterLocation,
    this.missingReporterName,
    this.missingSightingLocation,
    this.missingSightingName,
    this.missingPersonName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // ------------------------------------------------------------
  // BRAND COLORS & CONSTANTS
  // ------------------------------------------------------------
  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);
  static const Color successGreen = Color(0xFF2E7D32);

  // Pandharpur destination coordinates & Key Waypoints
  static final LatLng _pandharpurCenter = LatLng(17.6775, 75.3278);



  static final List<Map<String, dynamic>> _palkhiMilestones = [
    {'name': 'Saswad Halt', 'loc': LatLng(18.3440, 74.0300)},
    {'name': 'Jejuri Halt', 'loc': LatLng(18.2750, 74.1590)},
    {'name': 'Lonand Ringan', 'loc': LatLng(18.0400, 74.1880)},
    {'name': 'Phaltan Halt', 'loc': LatLng(17.9890, 74.4320)},
    {'name': 'Malshiras Halt', 'loc': LatLng(17.8450, 74.9080)},
    {'name': 'Wakhari Ringan', 'loc': LatLng(17.7050, 75.2200)},
  ];

  // ------------------------------------------------------------
  // CONTROLLERS & SERVICES
  // ------------------------------------------------------------
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();

  // ------------------------------------------------------------
  // STATE VARIABLES
  // ------------------------------------------------------------
  Position? _currentPosition;
  bool _isTracking = false;
  bool _isLoadingInitialLocation = true;
  String? _errorMessage;

  // Filter state: ALL, VOLUNTEERS, MEDICAL, WEATHER
  String _activeFilter = 'ALL';

  // Data lists
  List<Volunteer> _nearbyVolunteers = [];
  List<MedicalStock> _medicalStocks = [];
  List<WeatherRouteSuggestion> _weatherRouteSuggestions = [];

  // High-density turn-by-turn road geometry (5,197 real OSM road points)
  List<LatLng> _roadGeometry = VariRouteData.precachedRoadRoute;

  // Weather state
  WeatherData? _currentWeather;
  WeatherData? _pandharpurWeather;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initStaticDummyData();
    _initializeLocationAndMap();
    _loadLiveRoadRoute();
  }

  Future<void> _loadLiveRoadRoute() async {
    final points = await VariRouteData.fetchLiveRoadRoute();
    if (mounted && points.isNotEmpty) {
      setState(() {
        _roadGeometry = points;
      });
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _mapController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DUMMY DATA INITIALIZATION
  // ------------------------------------------------------------
  void _initStaticDummyData() {
    // Medical Live Stocks along the route
    _medicalStocks = [
      MedicalStock(
        id: 'MED-100',
        campName: 'एमएमसीओई प्रथमोपचार केंद्र (MMCOE First Aid Post)',
        locationName: 'MMCOE Campus, Karve Nagar, Pune',
        location: LatLng(18.4905, 73.8135),
        status: MedicalStockStatus.adequate, // Green 🟢
        doctorInCharge: 'Dr. Shruti Joshi (MMCOE Medical Team)',
        contactPhone: '+91 98230 55667',
        inventory: [
          InventoryItem(name: 'ORS Packets (ओआरएस)', availableQuantity: 300, totalCapacity: 300, unit: 'packs'),
          InventoryItem(name: 'First Aid Kit & Bandages', availableQuantity: 150, totalCapacity: 150, unit: 'kits'),
          InventoryItem(name: 'Emergency Glucose Powder', availableQuantity: 100, totalCapacity: 100, unit: 'packs'),
          InventoryItem(name: 'Paracetamol & Antacids', availableQuantity: 250, totalCapacity: 250, unit: 'tabs'),
        ],
      ),
      MedicalStock(
        id: 'MED-101',
        campName: 'पर्गना मेडिकल कॅम्प (Pargao Camp)',
        locationName: 'Pargao Rest Stop (km 28)',
        location: LatLng(18.3900, 74.0050),
        status: MedicalStockStatus.critical, // Red 🔴
        doctorInCharge: 'Dr. Ramesh Kulkarni',
        contactPhone: '+91 98220 11223',
        inventory: [
          InventoryItem(name: 'ORS Packets (ओआरएस)', availableQuantity: 8, totalCapacity: 200, unit: 'packs'),
          InventoryItem(name: 'Painkillers (पॅरासिटामॉल)', availableQuantity: 15, totalCapacity: 300, unit: 'tabs'),
          InventoryItem(name: 'Saline Bottles (सलाईन)', availableQuantity: 2, totalCapacity: 50, unit: 'bottles'),
          InventoryItem(name: 'Bandages & Dressings', availableQuantity: 25, totalCapacity: 150, unit: 'rolls'),
        ],
      ),
      MedicalStock(
        id: 'MED-102',
        campName: 'दिवे घाट आरोग्य केंद्र (Dive Ghat Base)',
        locationName: 'Dive Ghat Top (km 18)',
        location: LatLng(18.4350, 73.9820),
        status: MedicalStockStatus.warning, // Yellow 🟡
        doctorInCharge: 'Dr. Anjali Patil',
        contactPhone: '+91 94231 44556',
        inventory: [
          InventoryItem(name: 'ORS Packets (ओआरएस)', availableQuantity: 45, totalCapacity: 250, unit: 'packs'),
          InventoryItem(name: 'Foot Blister Ointment', availableQuantity: 12, totalCapacity: 100, unit: 'tubes'),
          InventoryItem(name: 'First Aid Bandages', availableQuantity: 30, totalCapacity: 200, unit: 'rolls'),
          InventoryItem(name: 'Glucose Powder', availableQuantity: 18, totalCapacity: 80, unit: 'packs'),
        ],
      ),
      MedicalStock(
        id: 'MED-103',
        campName: 'सासवड मध्यवर्ती रुग्णालय (Saswad Main Base)',
        locationName: 'Saswad City Ground (km 35)',
        location: LatLng(18.3440, 74.0300),
        status: MedicalStockStatus.adequate, // Green 🟢
        doctorInCharge: 'Dr. Suresh Deshmukh',
        contactPhone: '+91 98900 88776',
        inventory: [
          InventoryItem(name: 'ORS Packets (ओआरएस)', availableQuantity: 480, totalCapacity: 500, unit: 'packs'),
          InventoryItem(name: 'Painkillers & Antibiotics', availableQuantity: 650, totalCapacity: 700, unit: 'tabs'),
          InventoryItem(name: 'Saline Bottles (सलाईन)', availableQuantity: 120, totalCapacity: 150, unit: 'bottles'),
          InventoryItem(name: 'Emergency Oxygen Cylinders', availableQuantity: 12, totalCapacity: 15, unit: 'units'),
        ],
      ),
      MedicalStock(
        id: 'MED-104',
        campName: 'वाखारी वैद्यकीय छावणी (Wakhari Medical Post)',
        locationName: 'Wakhari Pandharpur Border (km 190)',
        location: LatLng(17.8200, 75.1200),
        status: MedicalStockStatus.warning, // Yellow 🟡
        doctorInCharge: 'Dr. Vikas Shinde',
        contactPhone: '+91 97654 33221',
        inventory: [
          InventoryItem(name: 'ORS Packets (ओआरएस)', availableQuantity: 55, totalCapacity: 300, unit: 'packs'),
          InventoryItem(name: 'Muscle Relaxant Spray', availableQuantity: 10, totalCapacity: 80, unit: 'cans'),
          InventoryItem(name: 'Dehydration IV Sets', availableQuantity: 14, totalCapacity: 60, unit: 'sets'),
        ],
      ),
    ];

    // Weather Route Suggestions & Hazard Points along Vari route
    _weatherRouteSuggestions = [
      WeatherRouteSuggestion(
        id: 'WX-200',
        title: 'एमएमसीओई कर्वेनगर परिसर (MMCOE Karve Nagar Base)',
        locationName: 'MMCOE Karve Nagar, Pune',
        location: LatLng(18.4902, 73.8130),
        dummyTemperature: 29.5,
        hazardLevel: HazardLevel.pleasant, // 🟢
        suggestionEnglish: 'Optimal Walking Conditions (29.5°C): MMCOE Karve Nagar start zone. Hydration counter & volunteer hub active.',
        suggestionMarathi: 'उत्तम वातावरण (२९.५°C): एमएमसीओई कर्वेनगर परिसर. पिण्याचे पाणी व मदत केंद्र उपलब्ध.',
        icon: Icons.school_rounded,
        nearbyFacility: 'MMCOE Campus Helpdesk & Water Station',
      ),
      WeatherRouteSuggestion(
        id: 'WX-201',
        title: 'तीव्र उष्णता धोका (Extreme Heat Alert)',
        locationName: 'Dive Ghat Stretch (दिवे घाट परिसर)',
        location: LatLng(18.4280, 73.9720),
        dummyTemperature: 39.2,
        hazardLevel: HazardLevel.extremeHeat, // 🔴
        suggestionEnglish: 'Extreme Heat (39.2°C): High risk of heat stroke! Drink water + ORS every 15 mins. Use cap/towel cover.',
        suggestionMarathi: 'तीव्र उष्णता (३९°C): उष्माघाताचा धोका! दर १५ मिनिटांनी ओआरएस पाणी प्या. सावलीत विश्रांती घ्या.',
        icon: Icons.wb_sunny_rounded,
        nearbyFacility: 'Shade Tent & ORS Counter (300m ahead)',
      ),
      WeatherRouteSuggestion(
        id: 'WX-202',
        title: 'दमटपणा व घाम येण्याचा धोका (Dehydration Risk)',
        locationName: 'Wakhari Stretch (वाखारी टप्पा)',
        location: LatLng(17.8350, 75.1050),
        dummyTemperature: 34.8,
        hazardLevel: HazardLevel.highWarmth, // 🟠
        suggestionEnglish: 'Dehydration Alert (34.8°C): Heavy sweat loss. Drink Lemon Water or Electrolytes before foot pain starts.',
        suggestionMarathi: 'दमट हवामान (३५°C): भरपूर पाणी व लिंबू सरबत घ्या. पाय दुखल्यास वैद्यकीय केंद्राशी संपर्क साधा.',
        icon: Icons.water_drop_rounded,
        nearbyFacility: 'Wakhari Drinking Water Tank & Aid Booth',
      ),
      WeatherRouteSuggestion(
        id: 'WX-203',
        title: 'सुखद पायी मार्ग (Pleasant Rest Stop)',
        locationName: 'Saswad Tree Canopy (सासवड छायदार मार्ग)',
        location: LatLng(18.3550, 74.0220),
        dummyTemperature: 28.0,
        hazardLevel: HazardLevel.pleasant, // 🟢
        suggestionEnglish: 'Pleasant Walking Conditions (28°C): Shaded tree canopy. Ideal pace segment toward Saswad stay camp.',
        suggestionMarathi: 'सुखद वातावरण (२८°C): झाडांची सावली व थंड वारा. चालण्याचा वेग कायम ठेवा.',
        icon: Icons.park_rounded,
        nearbyFacility: 'Dindi Refreshment Camp & Tea Stall',
      ),
      WeatherRouteSuggestion(
        id: 'WX-204',
        title: 'घसरणारा रस्ता इशारा (Slippery Rain Slope)',
        locationName: 'Jejuri Slope Ghat (जेजुरी घाट)',
        location: LatLng(18.2800, 74.1500),
        dummyTemperature: 26.5,
        hazardLevel: HazardLevel.rainRisk, // 🔵
        suggestionEnglish: 'Slippery Slope Warning: Light rain reported near ghat slope. Walk in single file carefully.',
        suggestionMarathi: 'रस्ता घसरडा (पाऊस): घाटात हळू चाला व पकड मजबूत ठेवा. दिंडी सोबत राहा.',
        icon: Icons.thunderstorm_rounded,
        nearbyFacility: 'Jejuri Emergency Volunteers',
      ),
    ];
  }

  // ------------------------------------------------------------
  // INITIALIZATION & LOCATION FLOW
  // ------------------------------------------------------------
  Future<void> _initializeLocationAndMap() async {
    setState(() {
      _isLoadingInitialLocation = true;
      _errorMessage = null;
    });

    final status = await _locationService.checkAndRequestPermission();

    if (status != LocationStatus.granted) {
      // Fallback to MMCOE Karve Nagar, Pune
      final fallbackPos = Position(
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
      _handlePositionUpdate(fallbackPos);
      _animateToPosition(LatLng(18.4902, 73.8130), zoom: 15.5);
      setState(() {
        _isLoadingInitialLocation = false;
        _errorMessage = _getFriendlyErrorMessage(status);
      });
      return;
    }

    Position? initialPos = await _locationService.getCurrentLocation();
    if (!mounted) return;

    // Check if initialPos is outside Pune region (e.g. emulator default in California), snap to MMCOE Karve Nagar, Pune
    if (initialPos == null ||
        initialPos.latitude < 18.0 ||
        initialPos.latitude > 19.5 ||
        initialPos.longitude < 73.0 ||
        initialPos.longitude > 74.5) {
      initialPos = Position(
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
    }

    _handlePositionUpdate(initialPos);

    if (widget.sosVarkariLocation != null) {
      _animateToPosition(widget.sosVarkariLocation!, zoom: 15.0);
    } else if (widget.focusTargetLocation != null) {
      _animateToPosition(widget.focusTargetLocation!, zoom: 15.5);
    } else if (widget.missingReporterLocation != null) {
      _animateToPosition(widget.missingReporterLocation!, zoom: 15.0);
    } else if (widget.missingSightingLocation != null) {
      _animateToPosition(widget.missingSightingLocation!, zoom: 15.0);
    } else {
      _animateToPosition(
        LatLng(initialPos.latitude, initialPos.longitude),
        zoom: 15.5,
      );
    }

    _fetchLiveWeather(initialPos.latitude, initialPos.longitude);
    _startLiveTracking();

    setState(() {
      _isLoadingInitialLocation = false;
    });
  }

  // ------------------------------------------------------------
  // WEATHER FLOW
  // ------------------------------------------------------------
  Future<void> _fetchLiveWeather(double lat, double lng, {bool force = false}) async {
    if (_isLoadingWeather && !force) return;
    setState(() => _isLoadingWeather = true);

    try {
      final cur = await _weatherService.fetchWeather(lat, lng, forceRefresh: force);
      final pan = await _weatherService.fetchPandharpurWeather(forceRefresh: force);
      if (mounted) {
        setState(() {
          _currentWeather = cur;
          _pandharpurWeather = pan;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  void _openWeatherAdvisorySheet() {
    final lat = _currentPosition?.latitude ?? 18.5204;
    final lng = _currentPosition?.longitude ?? 73.8567;
    VarkariWeatherSheet.show(
      context,
      currentWeather: _currentWeather,
      pandharpurWeather: _pandharpurWeather,
      currentLat: lat,
      currentLng: lng,
      onRefresh: () => _fetchLiveWeather(lat, lng, force: true),
    );
  }

  // ------------------------------------------------------------
  // LIVE TRACKING CONTROLS
  // ------------------------------------------------------------
  Future<void> _startLiveTracking() async {
    final started = await _locationService.startTracking(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
      onLocationChanged: (pos) {
        if (!mounted) return;
        _handlePositionUpdate(pos);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _errorMessage = err);
      },
    );

    if (started && mounted) {
      setState(() {
        _isTracking = true;
        _errorMessage = null;
      });
    }
  }

  void _stopLiveTracking() {
    _locationService.stopTracking();
    setState(() => _isTracking = false);
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopLiveTracking();
    } else {
      _startLiveTracking();
    }
  }

  void _handlePositionUpdate(Position pos) {
    // If incoming GPS location is outside Pune region (e.g. emulator default in California), snap to MMCOE Karve Nagar, Pune
    final bool isOutsidePune = pos.latitude < 18.0 ||
        pos.latitude > 19.5 ||
        pos.longitude < 73.0 ||
        pos.longitude > 74.5;

    final Position effectivePos = isOutsidePune
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
        : pos;

    final userLatLng = LatLng(effectivePos.latitude, effectivePos.longitude);
    final volunteers = _generateNearbyVolunteers(userLatLng);

    setState(() {
      _currentPosition = effectivePos;
      _nearbyVolunteers = volunteers;
    });

    _fetchLiveWeather(effectivePos.latitude, effectivePos.longitude);
  }

  List<Volunteer> _generateNearbyVolunteers(LatLng userLocation) {
    final rawVolunteers = [
      {
        'id': 'VT-100',
        'name': 'MMCOE Campus Volunteer',
        'role': 'Karve Nagar Route Guide',
        'latOffset': 0.0008,
        'lngOffset': 0.0006,
        'icon': Icons.school_rounded,
      },
      {
        'id': 'VT-101',
        'name': 'Rahul Deshmukh',
        'role': 'Safety Volunteer',
        'latOffset': 0.0018,
        'lngOffset': 0.0015,
        'icon': Icons.security_rounded,
      },
      {
        'id': 'VT-104',
        'name': 'Dr. Priya Shinde',
        'role': 'Medical Volunteer',
        'latOffset': -0.0012,
        'lngOffset': 0.0022,
        'icon': Icons.medical_services_rounded,
      },
      {
        'id': 'VT-202',
        'name': 'Anand Patil',
        'role': 'Route Guide Volunteer',
        'latOffset': 0.0025,
        'lngOffset': -0.0018,
        'icon': Icons.assistant_direction_rounded,
      },
      {
        'id': 'VT-305',
        'name': 'Sunita Kulkarni',
        'role': 'First Aid Volunteer',
        'latOffset': -0.0020,
        'lngOffset': -0.0015,
        'icon': Icons.healing_rounded,
      },
    ];

    final list = rawVolunteers.map((item) {
      final vLoc = LatLng(
        userLocation.latitude + (item['latOffset'] as double),
        userLocation.longitude + (item['lngOffset'] as double),
      );
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        vLoc.latitude,
        vLoc.longitude,
      );

      return Volunteer(
        id: item['id'] as String,
        name: item['name'] as String,
        role: item['role'] as String,
        location: vLoc,
        distanceMeters: distance,
        icon: item['icon'] as IconData,
        isAvailable: true,
      );
    }).toList();

    list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return list;
  }

  void _animateToPosition(LatLng latLng, {double zoom = 16.0}) {
    try {
      _mapController.move(latLng, zoom);
    } catch (e) {
      debugPrint('Map move error: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    if (_currentPosition != null) {
      _animateToPosition(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      );
    } else {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null && mounted) {
        _handlePositionUpdate(pos);
        _animateToPosition(
          LatLng(pos.latitude, pos.longitude),
          zoom: 16.0,
        );
      }
    }
  }

  String _formatPandharpurDistance(LatLng? userLoc) {
    if (userLoc == null) return 'Calculating...';
    final meters = Geolocator.distanceBetween(
      userLoc.latitude,
      userLoc.longitude,
      _pandharpurCenter.latitude,
      _pandharpurCenter.longitude,
    );
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _getFriendlyErrorMessage(LocationStatus status) {
    switch (status) {
      case LocationStatus.serviceDisabled:
        return 'GPS Location service is disabled. Please turn on Location.';
      case LocationStatus.permissionDenied:
        return 'Location permission was denied.';
      case LocationStatus.permissionDeniedForever:
        return 'Location permission permanently denied. Enable in Settings.';
      case LocationStatus.error:
      default:
        return 'Unable to access location services.';
    }
  }

  // ------------------------------------------------------------
  // VOLUNTEER DETAIL MODAL
  // ------------------------------------------------------------
  void _showVolunteerDetails(Volunteer volunteer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: blue.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: blue.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: blue.withValues(alpha: 0.2)),
                    ),
                    child: Icon(volunteer.icon, color: blue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer.name,
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          volunteer.role,
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 13,
                            color: orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      volunteer.id,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(
                    label: 'DISTANCE',
                    value: volunteer.formattedDistance,
                    icon: Icons.straighten_rounded,
                  ),
                  _buildDetailItem(
                    label: 'STATUS',
                    value: volunteer.isAvailable ? 'Available' : 'Busy',
                    icon: Icons.check_circle_outline_rounded,
                    valueColor: volunteer.isAvailable ? successGreen : Colors.grey,
                  ),
                  _buildDetailItem(
                    label: 'ASSIGNMENT',
                    value: 'Wari Route',
                    icon: Icons.map_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // WEATHER ROUTE SUGGESTION DETAIL MODAL
  // ------------------------------------------------------------
  void _showWeatherSuggestionDetails(WeatherRouteSuggestion sugg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sugg.hazardColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: sugg.hazardColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sugg.hazardColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: sugg.hazardColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(sugg.icon, color: sugg.hazardColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sugg.title,
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sugg.locationName} • ${sugg.dummyTemperature.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: sugg.hazardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sugg.hazardColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sugg.hazardColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sugg.suggestionMarathi,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: blue,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sugg.suggestionEnglish,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 11.5,
                        color: blue.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.local_hospital_rounded, color: orange, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nearby Help: ${sugg.nearbyFacility}',
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    Color valueColor = blue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD MARKERS FOR flutter_map
  // ------------------------------------------------------------
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    // 0a. Focus Searched Target Marker
    if (widget.focusTargetLocation != null) {
      markers.add(
        Marker(
          point: widget.focusTargetLocation!,
          width: 200,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: blue.withValues(alpha: 0.3), blurRadius: 6),
                  ],
                ),
                child: Text(
                  widget.focusTargetTitle ?? 'Target User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      );
    }

    // 0b. SOS Varkari & Volunteer Markers
    if (widget.sosVarkariLocation != null) {
      markers.add(
        Marker(
          point: widget.sosVarkariLocation!,
          width: 200,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  '🚨 ${widget.sosVarkariName ?? "Varkari (SOS)"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.sosVolunteerLocation != null) {
      markers.add(
        Marker(
          point: widget.sosVolunteerLocation!,
          width: 200,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: successGreen,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: successGreen.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  '👮 ${widget.sosVolunteerName ?? "Assigned Volunteer"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    // 0c. Missing Person Reporter & Sighting Markers
    if (widget.missingReporterLocation != null) {
      markers.add(
        Marker(
          point: widget.missingReporterLocation!,
          width: 200,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '📌 ${widget.missingReporterName ?? "Reporter Location"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.missingSightingLocation != null) {
      markers.add(
        Marker(
          point: widget.missingSightingLocation!,
          width: 200,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: successGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '👁️ ${widget.missingSightingName ?? "Sighting Location"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      );
    }

    // 1. User Live Position Marker
    if (userLatLng != null) {
      markers.add(
        Marker(
          point: userLatLng,
          width: 36,
          height: 36,
          child: _UserLocationDot(isTracking: _isTracking),
        ),
      );
    }

    // 2. Pandharpur Destination Marker
    markers.add(
      Marker(
        point: _pandharpurCenter,
        width: 48,
        height: 56,
        child: GestureDetector(
          onTap: () => _animateToPosition(_pandharpurCenter, zoom: 13.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: orange, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.temple_hindu_rounded, color: orange, size: 20),
              ),
              CustomPaint(
                size: const Size(12, 8),
                painter: _TrianglePainter(color: orange),
              ),
            ],
          ),
        ),
      ),
    );

    // 3. Volunteer Markers (Filter: ALL or VOLUNTEERS)
    if (_activeFilter == 'ALL' || _activeFilter == 'VOLUNTEERS') {
      for (final v in _nearbyVolunteers) {
        markers.add(
          Marker(
            point: v.location,
            width: 44,
            height: 52,
            child: GestureDetector(
              onTap: () => _showVolunteerDetails(v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: blue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(v.icon, color: blue, size: 18),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _TrianglePainter(color: blue),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 4. Medical Stock Markers (Filter: ALL or MEDICAL)
    if (_activeFilter == 'ALL' || _activeFilter == 'MEDICAL') {
      for (final stock in _medicalStocks) {
        markers.add(
          Marker(
            point: stock.location,
            width: 46,
            height: 54,
            child: GestureDetector(
              onTap: () => MedicalStockSheet.show(context, stock),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: stock.statusColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: stock.statusColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: stock.statusColor,
                      size: 20,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _TrianglePainter(color: stock.statusColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 5. Weather Route Suggestion Markers (Filter: ALL or WEATHER)
    if (_activeFilter == 'ALL' || _activeFilter == 'WEATHER') {
      for (final sugg in _weatherRouteSuggestions) {
        markers.add(
          Marker(
            point: sugg.location,
            width: 48,
            height: 56,
            child: GestureDetector(
              onTap: () => _showWeatherSuggestionDetails(sugg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sugg.hazardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: sugg.hazardColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(sugg.icon, color: Colors.white, size: 20),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _TrianglePainter(color: sugg.hazardColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 6. Palkhi Milestone Stop Markers
    for (final milestone in _palkhiMilestones) {
      final loc = milestone['loc'] as LatLng;
      final name = milestone['name'] as String;
      markers.add(
        Marker(
          point: loc,
          width: 80,
          height: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: orange, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: orange.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded, color: orange, size: 12),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ------------------------------------------------------------
  // BUILD AUTHENTIC WARI PALKHI ROUTE POLYLINES
  // ------------------------------------------------------------
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    final routePoints = _roadGeometry.isNotEmpty
        ? _roadGeometry
        : VariRouteData.precachedRoadRoute;

    // 1. Real Road Highway Corridor Background Glow (Wide orange tint)
    polylines.add(
      Polyline(
        points: routePoints,
        color: orange.withValues(alpha: 0.25),
        strokeWidth: 8.0,
      ),
    );

    // 2. Turn-by-turn Real OSM Road Polyline (5,197 exact road geometry points)
    polylines.add(
      Polyline(
        points: routePoints,
        color: orange,
        strokeWidth: 4.0,
      ),
    );

    // 3. User Connection Line (Dashed blue path from live user position to MMCOE start of Wari route)
    if (_currentPosition != null && routePoints.isNotEmpty) {
      final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      polylines.add(
        Polyline(
          points: [userLatLng, routePoints.first],
          color: blue,
          strokeWidth: 2.5,
          pattern: StrokePattern.dashed(segments: const [8, 6]),
        ),
      );
    }

    // 4. Connect SOS Varkari & Volunteer with line
    if (widget.sosVarkariLocation != null && widget.sosVolunteerLocation != null) {
      polylines.add(
        Polyline(
          points: [widget.sosVarkariLocation!, widget.sosVolunteerLocation!],
          color: Colors.redAccent,
          strokeWidth: 3.5,
          pattern: StrokePattern.dashed(segments: const [10, 6]),
        ),
      );
    }

    // 5. Connect Missing Reporter & Sighting with line
    if (widget.missingReporterLocation != null && widget.missingSightingLocation != null) {
      polylines.add(
        Polyline(
          points: [widget.missingReporterLocation!, widget.missingSightingLocation!],
          color: orange,
          strokeWidth: 3.0,
          pattern: StrokePattern.dashed(segments: const [8, 5]),
        ),
      );
    }

    return polylines;
  }

  // ------------------------------------------------------------
  // FILTER CHIP WIDGET
  // ------------------------------------------------------------
  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _activeFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : blue,
        ),
      ),
      selected: isSelected,
      selectedColor: blue,
      backgroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? blue : blue.withValues(alpha: 0.15),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _activeFilter = filterKey);
        }
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            RichText(
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
                    text: ' मार्ग',
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Route Map',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Weather Advisory',
            onPressed: _openWeatherAdvisorySheet,
            icon: Icon(
              _currentWeather?.conditionIcon ?? Icons.wb_sunny_rounded,
              color: _currentWeather?.conditionColor ?? orange,
              size: 24,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _isTracking ? 'Pause Tracking' : 'Start Tracking',
              onPressed: _toggleTracking,
              icon: Icon(
                _isTracking ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                color: _isTracking ? orange : blue,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLatLng ?? _pandharpurCenter,
              initialZoom: 12.0,
              maxZoom: 18.0,
              minZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.varipath',
                maxZoom: 19,
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Top Status Badge & Destination Info Bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: blue.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isTracking ? successGreen : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isTracking ? appLanguageNotifier.t('live_tracking') : appLanguageNotifier.t('tracking_paused'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: _isTracking ? successGreen : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _animateToPosition(_pandharpurCenter, zoom: 13.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: blue.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.temple_hindu_rounded, color: orange, size: 16),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${appLanguageNotifier.t('pandharpur_dist')}: ${_formatPandharpurDistance(userLatLng)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Interactive Filter Bar Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', appLanguageNotifier.t('filter_all')),
                      const SizedBox(width: 6),
                      _buildFilterChip('VOLUNTEERS', '👮 ${appLanguageNotifier.t('filter_volunteers')} (${_nearbyVolunteers.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('MEDICAL', '🏥 ${appLanguageNotifier.t('filter_medical')} (${_medicalStocks.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('WEATHER', '☀️ ${appLanguageNotifier.t('filter_weather')} (${_weatherRouteSuggestions.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error Overlay Banner
          if (_errorMessage != null)
            Positioned(
              top: 105,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Bar & Info Cards
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Weather Banner snippet
                if (_currentWeather != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentWeather!.conditionColor.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentWeather!.conditionIcon,
                          color: _currentWeather!.conditionColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentWeather!.temperature.toStringAsFixed(1)}°C • ${_currentWeather!.conditionText}',
                                style: const TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: blue,
                                ),
                              ),
                              Text(
                                _currentWeather!.varkariAdvisory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 11.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _openWeatherAdvisorySheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DETAILS',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Bottom Action Bar Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: blue.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Re-center on My Location
                      ElevatedButton(
                        onPressed: _goToMyLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.my_location_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              appLanguageNotifier.t('my_spot'),
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Weather Advisory Modal Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openWeatherAdvisorySheet,
                          icon: const Icon(Icons.wb_sunny_rounded, color: orange, size: 18),
                          label: Text(
                            appLanguageNotifier.t('weather_advisory_btn'),
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: blue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: orange.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoadingInitialLocation)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: orange),
                    SizedBox(height: 16),
                    Text(
                      'Acquiring live GPS & loading Vari route map...',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// CUSTOM WIDGETS
// ================================================================

/// Pulsating orange dot for user's live location
class _UserLocationDot extends StatefulWidget {
  final bool isTracking;

  const _UserLocationDot({required this.isTracking});

  @override
  State<_UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<_UserLocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFD8620F);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isTracking)
              Container(
                width: 36 * _animation.value,
                height: 36 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orange.withValues(alpha: 0.18 * (1 - _animation.value)),
                ),
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: orange.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: orange,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Small triangle pointer below markers
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}