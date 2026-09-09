import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];

  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/vehicles');

      final data = response['vehicles'];

      if (data is List) {
        _vehicles = data
            .map(
              (item) => Vehicle.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _vehicles = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomerVehicles(
    String customerId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/vehicles/customer/$customerId',
      );

      final data = response['vehicles'];

      if (data is List) {
        _vehicles = data
            .map(
              (item) => Vehicle.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _vehicles = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVehicle(Vehicle vehicle) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/vehicles',
        vehicle.toJson(),
      );

      if (response['success'] == true &&
          response['vehicle'] != null) {
        final createdVehicle = Vehicle.fromJson(
          Map<String, dynamic>.from(
            response['vehicle'],
          ),
        );

        _vehicles.insert(0, createdVehicle);
        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to create vehicle';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/vehicles/${vehicle.id}',
        vehicle.toJson(),
      );

      if (response['success'] == true &&
          response['vehicle'] != null) {
        final updatedVehicle = Vehicle.fromJson(
          Map<String, dynamic>.from(
            response['vehicle'],
          ),
        );

        final index = _vehicles.indexWhere(
          (item) => item.id == vehicle.id,
        );

        if (index != -1) {
          _vehicles[index] = updatedVehicle;
        }

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to update vehicle';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete(
        '/vehicles/$vehicleId',
      );

      if (response['success'] == true) {
        _vehicles.removeWhere(
          (vehicle) => vehicle.id == vehicleId,
        );

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to delete vehicle';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVehicles() {
    _vehicles = [];
    notifyListeners();
  }
}