import 'package:flutter/material.dart';

// ============================================================
// SEARCH RESULT TYPE
// ============================================================

enum SearchResultType {
  customer,
  vehicle,
  service,
}

// ============================================================
// UNIFIED SEARCH RESULT
// ============================================================

class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? extraInfo;
  final IconData icon;
  final Color color;

  // Original objects for navigation
  final dynamic originalData;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.extraInfo,
    required this.icon,
    required this.color,
    required this.originalData,
  });

  // ============================================================
  // FACTORY: FROM CUSTOMER
  // ============================================================

  factory SearchResult.fromCustomer({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? address,
    required dynamic original,
  }) {
    return SearchResult(
      id: id,
      type: SearchResultType.customer,
      title: name.isNotEmpty ? name : 'Unknown',
      subtitle: phone.isNotEmpty ? phone : 'No phone',
      extraInfo: email?.isNotEmpty == true ? email : address,
      icon: Icons.person_outline_rounded,
      color: Colors.blue,
      originalData: original,
    );
  }

  // ============================================================
  // FACTORY: FROM VEHICLE
  // ============================================================

  factory SearchResult.fromVehicle({
    required String id,
    required String registrationNumber,
    required String brand,
    required String model,
    String? customerName,
    required dynamic original,
  }) {
    final vehicleName = [brand, model]
        .where((e) => e.trim().isNotEmpty)
        .join(' ');

    return SearchResult(
      id: id,
      type: SearchResultType.vehicle,
      title: registrationNumber.isNotEmpty
          ? registrationNumber
          : 'Unknown Vehicle',
      subtitle: vehicleName.isNotEmpty
          ? vehicleName
          : 'No brand/model',
      extraInfo: customerName,
      icon: Icons.directions_car_outlined,
      color: Colors.green,
      originalData: original,
    );
  }

  // ============================================================
  // FACTORY: FROM SERVICE
  // ============================================================

  factory SearchResult.fromService({
    required String id,
    required String serviceType,
    required double totalAmount,
    required DateTime serviceDate,
    String? customerName,
    String? registrationNumber,
    required dynamic original,
  }) {
    final dateStr =
        '${serviceDate.day.toString().padLeft(2, '0')}/'
        '${serviceDate.month.toString().padLeft(2, '0')}/'
        '${serviceDate.year}';

    final vehicleInfo = registrationNumber?.isNotEmpty == true
        ? registrationNumber
        : null;

    return SearchResult(
      id: id,
      type: SearchResultType.service,
      title: serviceType.isNotEmpty
          ? serviceType
          : 'Service',
      subtitle: '₹${totalAmount.toStringAsFixed(0)} • $dateStr',
      extraInfo: customerName != null && vehicleInfo != null
          ? '$customerName • $vehicleInfo'
          : customerName ?? vehicleInfo,
      icon: Icons.build_outlined,
      color: Colors.orange,
      originalData: original,
    );
  }
}

// ============================================================
// SEARCH RESULT GROUP
// ============================================================

class SearchResultGroup {
  final SearchResultType type;
  final String label;
  final IconData icon;
  final Color color;
  final List<SearchResult> results;

  SearchResultGroup({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.results,
  });

  int get count => results.length;
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
}