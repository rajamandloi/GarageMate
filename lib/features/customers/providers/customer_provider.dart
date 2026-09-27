import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];

  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  // FETCH ALL CUSTOMERS
  // ============================================================

  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/customers');

      final data = response['customers'];

      if (data is List) {
        _customers = data
            .map(
              (item) => Customer.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _customers = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CREATE CUSTOMER ONLY
  // ============================================================

  Future<bool> createCustomer(Customer customer) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/customers',
        customer.toJson(),
      );

      if (response['success'] == true &&
          response['customer'] != null) {
        final createdCustomer = Customer.fromJson(
          Map<String, dynamic>.from(
            response['customer'],
          ),
        );

        _customers.insert(0, createdCustomer);
        notifyListeners();

        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to create customer';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // ✅ CREATE CUSTOMER + VEHICLE (LINKED)
  // ============================================================

  /// Returns the created [Customer] on success, or `null` on failure.
  /// Sets [error] on failure.
  Future<Customer?> createCustomerWithVehicle({
    required Customer customer,
    required String vehicleRegistrationNumber,
    String vehicleBrand = '',
    String vehicleModel = '',
    String vehicleFuelType = 'Petrol',
    String vehicleManufacturingYear = '',
    double vehicleMileage = 0,
  }) async {
    _error = null;
    notifyListeners();

    try {
      // --------------------------------------------------------
      // STEP 1: Create Customer
      // --------------------------------------------------------
      final customerResponse = await ApiService.post(
        '/customers',
        customer.toJson(),
      );

      if (customerResponse['success'] != true ||
          customerResponse['customer'] == null) {
        _error = customerResponse['message']?.toString() ??
            'Unable to create customer';
        notifyListeners();
        return null;
      }

      final createdCustomer = Customer.fromJson(
        Map<String, dynamic>.from(
          customerResponse['customer'],
        ),
      );

      // --------------------------------------------------------
      // STEP 2: Create Vehicle linked to customer
      // --------------------------------------------------------
      final vehicleBody = {
        'customerId': createdCustomer.id,
        'registrationNumber':
            vehicleRegistrationNumber.trim().toUpperCase(),
        'brand': vehicleBrand.trim(),
        'model': vehicleModel.trim(),
        'fuelType': vehicleFuelType,
        'manufacturingYear': vehicleManufacturingYear.trim(),
        'currentMileage': vehicleMileage,
        'variant': '',
        'vin': '',
        'engineNumber': '',
        'notes': '',
      };

      final vehicleResponse = await ApiService.post(
        '/vehicles',
        vehicleBody,
      );

      if (vehicleResponse['success'] != true) {
        // Customer बन गया, लेकिन vehicle नहीं बना
        // Error message में साफ बताएं
        _error =
            'Customer बना लेकिन Vehicle नहीं बना: ${vehicleResponse['message'] ?? 'Unknown error'}';

        // Still insert customer into list
        _customers.insert(0, createdCustomer);
        notifyListeners();

        return createdCustomer;
      }

      // --------------------------------------------------------
      // SUCCESS — both created
      // --------------------------------------------------------
      _customers.insert(0, createdCustomer);
      notifyListeners();

      return createdCustomer;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // UPDATE CUSTOMER
  // ============================================================

  Future<bool> updateCustomer(Customer customer) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/customers/${customer.id}',
        customer.toJson(),
      );

      if (response['success'] == true &&
          response['customer'] != null) {
        final updatedCustomer = Customer.fromJson(
          Map<String, dynamic>.from(
            response['customer'],
          ),
        );

        final index = _customers.indexWhere(
          (item) => item.id == customer.id,
        );

        if (index != -1) {
          _customers[index] = updatedCustomer;
        }

        notifyListeners();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to update customer';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // DELETE CUSTOMER
  // ============================================================

  Future<bool> deleteCustomer(String customerId) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete(
        '/customers/$customerId',
      );

      if (response['success'] == true) {
        _customers.removeWhere(
          (customer) => customer.id == customerId,
        );

        notifyListeners();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to delete customer';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCustomers() {
    _customers = [];
    notifyListeners();
  }
}