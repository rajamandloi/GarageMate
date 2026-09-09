import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/service_record.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceRecord> _services = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<ServiceRecord> get services =>
      List.unmodifiable(_services);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // ============================================================
  // FETCH ALL SERVICES
  // ============================================================

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/services');

      final data = response['services'];

      if (data is List) {
        _services = data
            .map(
              (item) => ServiceRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _services = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FETCH SINGLE SERVICE
  // ============================================================

  Future<ServiceRecord?> fetchServiceById(
    String serviceId,
  ) async {
    _error = null;

    try {
      final response = await ApiService.get(
        '/services/$serviceId',
      );

      if (response['success'] == true &&
          response['service'] != null) {
        return ServiceRecord.fromJson(
          Map<String, dynamic>.from(
            response['service'],
          ),
        );
      }

      _error =
          response['message']?.toString() ??
          'Unable to fetch service';

      notifyListeners();
      return null;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // FETCH CUSTOMER SERVICE HISTORY
  // ============================================================

  Future<List<ServiceRecord>> fetchCustomerServices(
    String customerId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/services/customer/$customerId',
      );

      final data = response['services'];

      if (data is List) {
        final services = data
            .map(
              (item) => ServiceRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        return services;
      }

      return [];
    } catch (error) {
      _error = error.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FETCH VEHICLE SERVICE HISTORY
  // ============================================================

  Future<List<ServiceRecord>> fetchVehicleServices(
    String vehicleId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/services/vehicle/$vehicleId',
      );

      final data = response['services'];

      if (data is List) {
        final services = data
            .map(
              (item) => ServiceRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        return services;
      }

      return [];
    } catch (error) {
      _error = error.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CREATE SERVICE
  // ============================================================

  Future<bool> createService(
    ServiceRecord service,
  ) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/services',
        service.toJson(),
      );

      if (response['success'] == true &&
          response['service'] != null) {
        final createdService =
            ServiceRecord.fromJson(
          Map<String, dynamic>.from(
            response['service'],
          ),
        );

        _services.insert(0, createdService);

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to create service';

      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE SERVICE
  // ============================================================

  Future<bool> updateService(
    ServiceRecord service,
  ) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/services/${service.id}',
        service.toJson(),
      );

      if (response['success'] == true &&
          response['service'] != null) {
        final updatedService =
            ServiceRecord.fromJson(
          Map<String, dynamic>.from(
            response['service'],
          ),
        );

        final index = _services.indexWhere(
          (item) => item.id == service.id,
        );

        if (index != -1) {
          _services[index] = updatedService;
        } else {
          _services.insert(0, updatedService);
        }

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to update service';

      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<bool> deleteService(
    String serviceId,
  ) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete(
        '/services/$serviceId',
      );

      if (response['success'] == true) {
        _services.removeWhere(
          (service) => service.id == serviceId,
        );

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to delete service';

      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOCAL FILTERING
  // ============================================================

  List<ServiceRecord> servicesForCustomer(
    String customerId,
  ) {
    return _services
        .where(
          (service) =>
              service.customerId == customerId,
        )
        .toList();
  }

  List<ServiceRecord> servicesForVehicle(
    String vehicleId,
  ) {
    return _services
        .where(
          (service) =>
              service.vehicleId == vehicleId,
        )
        .toList();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<ServiceRecord> searchServices(
    String query,
  ) {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      return _services;
    }

    return _services.where((service) {
      return service.serviceType
              .toLowerCase()
              .contains(search) ||
          (service.customerName ?? '')
              .toLowerCase()
              .contains(search) ||
          (service.registrationNumber ?? '')
              .toLowerCase()
              .contains(search) ||
          (service.vehicleBrand ?? '')
              .toLowerCase()
              .contains(search) ||
          (service.vehicleModel ?? '')
              .toLowerCase()
              .contains(search) ||
          service.mechanic
              .toLowerCase()
              .contains(search);
    }).toList();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  double get totalRevenue {
    return _services.fold(
      0,
      (sum, service) =>
          sum + service.paidAmount,
    );
  }

  double get totalAmount {
    return _services.fold(
      0,
      (sum, service) =>
          sum + service.totalAmount,
    );
  }

  double get pendingPayments {
    return _services.fold(
      0,
      (sum, service) =>
          sum + service.pendingAmount,
    );
  }

  int get totalServices => _services.length;

  int get paidServices {
    return _services
        .where(
          (service) =>
              service.paymentStatus ==
              PaymentStatus.paid,
        )
        .length;
  }

  int get pendingServicePayments {
    return _services
        .where(
          (service) =>
              service.paymentStatus !=
              PaymentStatus.paid,
        )
        .length;
  }

  // ============================================================
  // ERROR MANAGEMENT
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearServices() {
    _services = [];
    _error = null;
    notifyListeners();
  }
}