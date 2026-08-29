import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum HazardLevel {
  extremeHeat, // 38°C+ 🔥 Red
  highWarmth,  // 33°C - 37°C ☀️ Orange
  pleasant,    // 25°C - 32°C ⛅ Green
  rainRisk,    // Rain / Slippery 🌧️ Blue
}

class WeatherRouteSuggestion {
  final String id;
  final String title;
  final String locationName;
  final LatLng location;
  final double dummyTemperature;
  final HazardLevel hazardLevel;
  final String suggestionEnglish;
  final String suggestionMarathi;
  final IconData icon;
  final String nearbyFacility;

  WeatherRouteSuggestion({
    required this.id,
    required this.title,
    required this.locationName,
    required this.location,
    required this.dummyTemperature,
    required this.hazardLevel,
    required this.suggestionEnglish,
    required this.suggestionMarathi,
    required this.icon,
    required this.nearbyFacility,
  });

  Color get hazardColor {
    switch (hazardLevel) {
      case HazardLevel.extremeHeat:
        return const Color(0xFFD32F2F); // Red
      case HazardLevel.highWarmth:
        return const Color(0xFFF57C00); // Orange
      case HazardLevel.pleasant:
        return const Color(0xFF2E7D32); // Green
      case HazardLevel.rainRisk:
        return const Color(0xFF1976D2); // Blue
    }
  }

  String get hazardLabel {
    switch (hazardLevel) {
      case HazardLevel.extremeHeat:
        return 'EXTREME HEAT DANGER';
      case HazardLevel.highWarmth:
        return 'HIGH TEMPERATURE ALERT';
      case HazardLevel.pleasant:
        return 'PLEASANT WALKING ZONE';
      case HazardLevel.rainRisk:
        return 'SLIPPERY ROAD / RAIN WARNING';
    }
  }
}
