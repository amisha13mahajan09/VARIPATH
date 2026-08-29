import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum MedicalStockStatus {
  critical, // Red 🔴 - Stock shortage
  warning,  // Yellow 🟡 - Shortage to occur soon
  adequate, // Green 🟢 - Adequate stock
}

class InventoryItem {
  final String name;
  final int availableQuantity;
  final int totalCapacity;
  final String unit;

  InventoryItem({
    required this.name,
    required this.availableQuantity,
    required this.totalCapacity,
    this.unit = 'units',
  });

  double get fillPercentage => totalCapacity > 0 ? (availableQuantity / totalCapacity) : 0.0;

  bool get isLow => fillPercentage < 0.3;
}

class MedicalStock {
  final String id;
  final String campName;
  final String locationName;
  final LatLng location;
  final MedicalStockStatus status;
  final String doctorInCharge;
  final String contactPhone;
  final List<InventoryItem> inventory;

  MedicalStock({
    required this.id,
    required this.campName,
    required this.locationName,
    required this.location,
    required this.status,
    required this.doctorInCharge,
    required this.contactPhone,
    required this.inventory,
  });

  Color get statusColor {
    switch (status) {
      case MedicalStockStatus.critical:
        return const Color(0xFFD32F2F); // Red
      case MedicalStockStatus.warning:
        return const Color(0xFFF57C00); // Yellow/Orange
      case MedicalStockStatus.adequate:
        return const Color(0xFF2E7D32); // Green
    }
  }

  String get statusLabel {
    switch (status) {
      case MedicalStockStatus.critical:
        return 'Critical Stock Shortage';
      case MedicalStockStatus.warning:
        return 'Shortage Expected Soon';
      case MedicalStockStatus.adequate:
        return 'Adequate Medical Stock';
    }
  }

  String get statusLabelMarathi {
    switch (status) {
      case MedicalStockStatus.critical:
        return 'औषधांचा तुटवडा (मदत हवी आहे)';
      case MedicalStockStatus.warning:
        return 'साठा लवकरच संपणार';
      case MedicalStockStatus.adequate:
        return 'पुरेसा साठा उपलब्ध';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case MedicalStockStatus.critical:
        return Icons.error_rounded;
      case MedicalStockStatus.warning:
        return Icons.warning_amber_rounded;
      case MedicalStockStatus.adequate:
        return Icons.check_circle_rounded;
    }
  }
}
