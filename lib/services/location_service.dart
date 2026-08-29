import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result status of location permission check and request
enum LocationStatus {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  granted,
  error,
}

/// Service class responsible for managing GPS permissions,
/// fetching current location, and streaming live location updates.
class LocationService {
  // Singleton pattern for centralized access
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Position? _lastKnownPosition;
  bool _isTracking = false;

  /// Stream of live position updates
  Stream<Position> get positionStream => _positionController.stream;

  /// Last known GPS position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Whether continuous live tracking is active
  bool get isTracking => _isTracking;

  /// Checks device location service status and requests foreground location permissions.
  Future<LocationStatus> checkAndRequestPermission() async {
    try {
      // 1. Check if location services (GPS hardware) are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationStatus.serviceDisabled;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationStatus.permissionDenied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationStatus.permissionDeniedForever;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return LocationStatus.granted;
      }

      return LocationStatus.permissionDenied;
    } catch (e) {
      debugPrint('LocationService checkAndRequestPermission error: $e');
      return LocationStatus.error;
    }
  }

  /// Fetches the user's current GPS position once.
  Future<Position?> getCurrentLocation() async {
    try {
      final status = await checkAndRequestPermission();
      if (status != LocationStatus.granted) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('LocationService getCurrentLocation error: $e');
      return null;
    }
  }

  /// Starts continuous foreground location tracking.
  /// Subscribes to location updates with high accuracy and small distance filter.
  Future<bool> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 2, // meters
    Function(Position)? onLocationChanged,
    Function(String)? onError,
  }) async {
    if (_isTracking) {
      return true;
    }

    final status = await checkAndRequestPermission();
    if (status != LocationStatus.granted) {
      if (onError != null) {
        onError(_getErrorMessageForStatus(status));
      }
      return false;
    }

    // Cancel any existing subscription before creating a new one
    await _positionStreamSubscription?.cancel();

    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _positionController.add(position);
          if (onLocationChanged != null) {
            onLocationChanged(position);
          }
        },
        onError: (dynamic error) {
          debugPrint('LocationService positionStream error: $error');
          if (onError != null) {
            onError(error.toString());
          }
        },
      );

      _isTracking = true;
      return true;
    } catch (e) {
      debugPrint('LocationService startTracking error: $e');
      if (onError != null) {
        onError(e.toString());
      }
      return false;
    }
  }

  /// Stops continuous location tracking and cancels the subscription.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  /// Opens the native OS App Settings page for manual permission grant.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens the native OS Location Settings page to enable GPS.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Maps LocationStatus to user-friendly messages.
  String _getErrorMessageForStatus(LocationStatus status) {
    switch (status) {
      case LocationStatus.serviceDisabled:
        return 'Location services are disabled on your device. Please turn on GPS.';
      case LocationStatus.permissionDenied:
        return 'Location permission was denied. Please allow location access.';
      case LocationStatus.permissionDeniedForever:
        return 'Location permission is permanently denied. Please enable it from App Settings.';
      case LocationStatus.error:
        return 'An error occurred while accessing location.';
      case LocationStatus.granted:
        return '';
    }
  }

  /// Disposes the stream controller and subscription.
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
