import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Data model representing a volunteer on the Wari route.
class Volunteer {
  final String id;
  final String name;
  final String role;
  final LatLng location;
  final double distanceMeters;
  final bool isAvailable;
  final IconData icon;

  const Volunteer({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.distanceMeters,
    required this.icon,
    this.isAvailable = true,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }
}
