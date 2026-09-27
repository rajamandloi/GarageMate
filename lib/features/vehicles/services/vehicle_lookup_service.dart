import '../models/vehicle.dart';

class VehicleLookupService {
  // ============================================================
  // NORMALIZE REGISTRATION NUMBER
  // ============================================================

  static String normalize(String registrationNumber) {
    return registrationNumber
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  // ============================================================
  // FIND VEHICLE BY NUMBER
  // ============================================================

  static Vehicle? findByNumber({
    required List<Vehicle> vehicles,
    required String registrationNumber,
  }) {
    if (registrationNumber.trim().isEmpty) return null;

    final target = normalize(registrationNumber);

    if (target.isEmpty) return null;

    for (final vehicle in vehicles) {
      final current = normalize(vehicle.registrationNumber);

      if (current == target) {
        return vehicle;
      }
    }

    return null;
  }

  // ============================================================
  // CHECK IF EXISTS
  // ============================================================

  static bool exists({
    required List<Vehicle> vehicles,
    required String registrationNumber,
  }) {
    return findByNumber(
          vehicles: vehicles,
          registrationNumber: registrationNumber,
        ) !=
        null;
  }
}