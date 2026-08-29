import 'package:flutter/material.dart';

/// Model representing real-time weather metrics for Varkaris on the Wari route.
class WeatherData {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final DateTime timestamp;
  final String locationName;

  const WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    required this.timestamp,
    this.locationName = 'Current Location',
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, {String locationName = 'Current Location'}) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
      locationName: locationName,
    );
  }

  /// Human-friendly condition name (Marathi + English)
  String get conditionText {
    switch (weatherCode) {
      case 0:
        return 'स्वच्छ आकाश (Clear Sky)';
      case 1:
      case 2:
        return 'अंशतः ढगाळ (Partly Cloudy)';
      case 3:
        return 'ढगाळ हवामान (Overcast)';
      case 45:
      case 48:
        return 'धुके (Foggy)';
      case 51:
      case 53:
      case 55:
        return 'रिमझिम पाऊस (Light Drizzle)';
      case 61:
      case 63:
      case 65:
        return 'पाऊस (Rain)';
      case 80:
      case 81:
      case 82:
        return 'मुसळधार पाऊस (Heavy Rain)';
      case 95:
      case 96:
      case 99:
        return 'वादळी पाऊस (Thunderstorm)';
      default:
        return 'सामान्य हवामान (Moderate)';
    }
  }

  /// Relevant Weather Icon
  IconData get conditionIcon {
    switch (weatherCode) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
        return Icons.cloud_queue_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  /// Condition Theme Color
  Color get conditionColor {
    if (weatherCode >= 95) return const Color(0xFFD32F2F); // Red for thunderstorm
    if (weatherCode >= 51 || precipitation > 0.5) return const Color(0xFF1976D2); // Blue for rain
    if (temperature >= 33) return const Color(0xFFE65100); // Dark Orange for high heat
    if (weatherCode == 0) return const Color(0xFFF57C00); // Orange for bright sun
    return const Color(0xFF2D4678); // VariPath Blue
  }

  /// Tailored safety advisory for Varkari walking pilgrims
  String get varkariAdvisory {
    if (weatherCode >= 95) {
      return '⚠️ वादळी पाऊस: सुरक्षित ठिकाणी आश्रय घ्या. झाडांखाली थांबू नका.';
    }
    if (precipitation > 1.0 || weatherCode >= 61) {
      return '🌧️ पाऊस सुरू आहे: रेनकोट/छत्री वापरा आणि सामान कोरडे ठेवा.';
    }
    if (temperature >= 34) {
      return '☀️ तीव्र ऊन: दर १५ मिनिटांनी पाणी प्या. डोक्यावर टोपी किंवा रुमाल वापरा.';
    }
    if (humidity >= 80 && temperature >= 28) {
      return '💧 दमट हवामान: डिहायड्रेशन टाळण्यासाठी लिंबू पाणी / ओआरएस घ्या.';
    }
    return '🚩 वारीसाठी अनुकूल वातावरण: पायी प्रवासासाठी हवामान सुखद आहे.';
  }

  /// Sub-tip for Varkari advisory
  String get varkariTip {
    if (weatherCode >= 95 || precipitation > 1.0) {
      return 'Keep mobile in waterproof pouch & stay with your Dindi group.';
    }
    if (temperature >= 33) {
      return 'Hydrate frequently with water & stay in shaded stops during noon.';
    }
    return 'Maintain regular walking pace & stay hydrated along the route.';
  }
}
