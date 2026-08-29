import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

/// Service for fetching live weather data using Open-Meteo REST API (free, no API key).
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  WeatherData? _cachedCurrentWeather;
  WeatherData? _cachedPandharpurWeather;
  DateTime? _lastFetchTime;
  double? _lastLat;
  double? _lastLng;

  WeatherData? get currentWeather => _cachedCurrentWeather;
  WeatherData? get pandharpurWeather => _cachedPandharpurWeather;

  /// Fetches weather for given latitude and longitude from Open-Meteo
  Future<WeatherData?> fetchWeather(
    double lat,
    double lng, {
    String locationName = 'Current Location',
    bool forceRefresh = false,
  }) async {
    // Check in-memory cache if requested recently within 5 mins for same coordinates
    if (!forceRefresh &&
        _cachedCurrentWeather != null &&
        _lastFetchTime != null &&
        _lastLat != null &&
        _lastLng != null) {
      final isRecent = DateTime.now().difference(_lastFetchTime!).inMinutes < 5;
      final isSameLocation = (lat - _lastLat!).abs() < 0.01 && (lng - _lastLng!).abs() < 0.01;
      if (isRecent && isSameLocation) {
        return _cachedCurrentWeather;
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m'
        '&timezone=auto',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = WeatherData.fromJson(data, locationName: locationName);
        _cachedCurrentWeather = weather;
        _lastFetchTime = DateTime.now();
        _lastLat = lat;
        _lastLng = lng;
        return weather;
      } else {
        debugPrint('Open-Meteo HTTP error: ${response.statusCode}');
        return _fallbackWeather(lat, lng, locationName);
      }
    } catch (e) {
      debugPrint('WeatherService error: $e');
      return _cachedCurrentWeather ?? _fallbackWeather(lat, lng, locationName);
    }
  }

  /// Fetches weather for Pandharpur destination (17.6775, 75.3278)
  Future<WeatherData?> fetchPandharpurWeather({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPandharpurWeather != null) {
      return _cachedPandharpurWeather;
    }
    try {
      final weather = await fetchWeather(
        17.6775,
        75.3278,
        locationName: 'पंढरपूर (Pandharpur)',
        forceRefresh: true,
      );
      if (weather != null) {
        _cachedPandharpurWeather = weather;
      }
      return _cachedPandharpurWeather;
    } catch (e) {
      return _cachedPandharpurWeather;
    }
  }

  /// Fallback weather data in case of offline/network issues
  WeatherData _fallbackWeather(double lat, double lng, String locationName) {
    return WeatherData(
      temperature: 28.5,
      apparentTemperature: 30.2,
      humidity: 62,
      precipitation: 0.0,
      weatherCode: 1, // Partly cloudy
      windSpeed: 12.4,
      timestamp: DateTime.now(),
      locationName: locationName,
    );
  }
}
