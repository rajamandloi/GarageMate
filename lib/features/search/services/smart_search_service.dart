import 'package:flutter/material.dart';

import '../../customers/models/customer.dart';
import '../../vehicles/models/vehicle.dart';
import '../../services/models/service_record.dart';

import '../models/search_result.dart';

class SmartSearchService {
  // ============================================================
  // NORMALIZE QUERY
  // ============================================================

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // ============================================================
  // MATCH: FUZZY (contains)
  // ============================================================

  static bool _matches(String haystack, String query) {
    if (haystack.isEmpty || query.isEmpty) return false;

    final h = _normalize(haystack);
    final q = _normalize(query);

    if (h.isEmpty || q.isEmpty) return false;

    return h.contains(q);
  }

  // ============================================================
  // SCORE: How well does this match?
  // ============================================================

  static int _score(String haystack, String query) {
    if (haystack.isEmpty || query.isEmpty) return 0;

    final h = _normalize(haystack);
    final q = _normalize(query);

    if (h.isEmpty || q.isEmpty) return 0;

    // Exact match → highest score
    if (h == q) return 100;

    // Starts with → high score
    if (h.startsWith(q)) return 80;

    // Contains → medium score
    if (h.contains(q)) return 50;

    return 0;
  }

  // ============================================================
  // SEARCH CUSTOMERS
  // ============================================================

  static List<SearchResult> searchCustomers({
    required List<Customer> customers,
    required String query,
  }) {
    if (query.trim().isEmpty) return [];

    final scored = <MapEntry<Customer, int>>[];

    for (final customer in customers) {
      final nameScore = _score(customer.name, query);
      final phoneScore = _score(customer.phone, query);
      final emailScore = _score(customer.email, query);

      final maxScore = [
        nameScore,
        phoneScore,
        emailScore,
      ].reduce((a, b) => a > b ? a : b);

      if (maxScore > 0) {
        scored.add(MapEntry(customer, maxScore));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .map(
          (e) => SearchResult.fromCustomer(
            id: e.key.id,
            name: e.key.name,
            phone: e.key.phone,
            email: e.key.email,
            address: e.key.address,
            original: e.key,
          ),
        )
        .toList();
  }

  // ============================================================
  // SEARCH VEHICLES
  // ============================================================

  static List<SearchResult> searchVehicles({
    required List<Vehicle> vehicles,
    required String query,
  }) {
    if (query.trim().isEmpty) return [];

    final scored = <MapEntry<Vehicle, int>>[];

    for (final vehicle in vehicles) {
      final regScore =
          _score(vehicle.registrationNumber, query);
      final brandScore = _score(vehicle.brand, query);
      final modelScore = _score(vehicle.model, query);
      final variantScore = _score(vehicle.variant, query);
      final customerScore =
          _score(vehicle.customerName ?? '', query);

      final maxScore = [
        regScore,
        brandScore,
        modelScore,
        variantScore,
        customerScore,
      ].reduce((a, b) => a > b ? a : b);

      if (maxScore > 0) {
        scored.add(MapEntry(vehicle, maxScore));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .map(
          (e) => SearchResult.fromVehicle(
            id: e.key.id,
            registrationNumber: e.key.registrationNumber,
            brand: e.key.brand,
            model: e.key.model,
            customerName: e.key.customerName,
            original: e.key,
          ),
        )
        .toList();
  }

  // ============================================================
  // SEARCH SERVICES
  // ============================================================

  static List<SearchResult> searchServices({
    required List<ServiceRecord> services,
    required String query,
  }) {
    if (query.trim().isEmpty) return [];

    final scored = <MapEntry<ServiceRecord, int>>[];

    for (final service in services) {
      final typeScore = _score(service.serviceType, query);
      final customerScore =
          _score(service.customerName ?? '', query);
      final regScore =
          _score(service.registrationNumber ?? '', query);
      final brandScore =
          _score(service.vehicleBrand ?? '', query);
      final modelScore =
          _score(service.vehicleModel ?? '', query);
      final mechanicScore = _score(service.mechanic, query);
      final descScore = _score(service.description, query);

      final maxScore = [
        typeScore,
        customerScore,
        regScore,
        brandScore,
        modelScore,
        mechanicScore,
        descScore,
      ].reduce((a, b) => a > b ? a : b);

      if (maxScore > 0) {
        scored.add(MapEntry(service, maxScore));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .map(
          (e) => SearchResult.fromService(
            id: e.key.id,
            serviceType: e.key.serviceType,
            totalAmount: e.key.totalAmount,
            serviceDate: e.key.serviceDate,
            customerName: e.key.customerName,
            registrationNumber: e.key.registrationNumber,
            original: e.key,
          ),
        )
        .toList();
  }

  // ============================================================
  // COMBINED SEARCH
  // ============================================================

  static List<SearchResultGroup> searchAll({
    required List<Customer> customers,
    required List<Vehicle> vehicles,
    required List<ServiceRecord> services,
    required String query,
  }) {
    if (query.trim().isEmpty) return [];

    final customerResults = searchCustomers(
      customers: customers,
      query: query,
    );

    final vehicleResults = searchVehicles(
      vehicles: vehicles,
      query: query,
    );

    final serviceResults = searchServices(
      services: services,
      query: query,
    );

    final groups = <SearchResultGroup>[];

    if (customerResults.isNotEmpty) {
      groups.add(
        SearchResultGroup(
          type: SearchResultType.customer,
          label: 'Customers',
          icon: Icons.person_outline_rounded,
          color: Colors.blue,
          results: customerResults,
        ),
      );
    }

    if (vehicleResults.isNotEmpty) {
      groups.add(
        SearchResultGroup(
          type: SearchResultType.vehicle,
          label: 'Vehicles',
          icon: Icons.directions_car_outlined,
          color: Colors.green,
          results: vehicleResults,
        ),
      );
    }

    if (serviceResults.isNotEmpty) {
      groups.add(
        SearchResultGroup(
          type: SearchResultType.service,
          label: 'Services',
          icon: Icons.build_outlined,
          color: Colors.orange,
          results: serviceResults,
        ),
      );
    }

    return groups;
  }
}