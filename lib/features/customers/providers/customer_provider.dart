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

      _error =
          response['message']?.toString() ??
          'Unable to create customer';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

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

      _error =
          response['message']?.toString() ??
          'Unable to update customer';

      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

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

      _error =
          response['message']?.toString() ??
          'Unable to delete customer';

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

  void clearCustomers() {
    _customers = [];
    notifyListeners();
  }
}