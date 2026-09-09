import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  int _customerCount = 0;
  int _vehicleCount = 0;
  int _serviceCount = 0;
  int _upcomingReminderCount = 0;
  int _overdueReminderCount = 0;
  int _completedReminderCount = 0;

  double _totalAmount = 0;
  double _paidAmount = 0;
  double _pendingAmount = 0;

  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _recentServices = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get customerCount => _customerCount;
  int get vehicleCount => _vehicleCount;
  int get serviceCount => _serviceCount;

  int get upcomingReminderCount => _upcomingReminderCount;
  int get overdueReminderCount => _overdueReminderCount;
  int get completedReminderCount => _completedReminderCount;

  double get totalAmount => _totalAmount;
  double get paidAmount => _paidAmount;
  double get pendingAmount => _pendingAmount;

  List<Map<String, dynamic>> get reminders =>
      List.unmodifiable(_reminders);

  List<Map<String, dynamic>> get recentServices =>
      List.unmodifiable(_recentServices);

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/dashboard/stats');

      

      final data = Map<String, dynamic>.from(response);

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ??
              'Unable to load dashboard',
        );
      }

      // --------------------------------------------------
      // STATS
      // --------------------------------------------------

      final rawStats = data['stats'];

      if (rawStats is Map) {
        final stats = Map<String, dynamic>.from(rawStats);

        _customerCount =
            _toInt(stats['totalCustomers']);

        _vehicleCount =
            _toInt(stats['totalVehicles']);

        _serviceCount =
            _toInt(stats['totalServices']);

        _upcomingReminderCount =
            _toInt(stats['pendingReminders']);

        _overdueReminderCount =
            _toInt(stats['overdueReminders']);

        _completedReminderCount =
            _toInt(stats['completedReminders']);

        _totalAmount =
            _toDouble(stats['totalAmount']);

        _paidAmount =
            _toDouble(stats['paidAmount']);

        _pendingAmount =
            _toDouble(stats['pendingAmount']);
      } else {
        _resetStats();
      }

      // --------------------------------------------------
      // RECENT SERVICES
      // --------------------------------------------------

      final rawServices = data['recentServices'];

      if (rawServices is List) {
        _recentServices = rawServices
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      } else {
        _recentServices = [];
      }

      // --------------------------------------------------
      // RECENT REMINDERS
      // --------------------------------------------------

      final rawReminders = data['recentReminders'];

      if (rawReminders is List) {
        _reminders = rawReminders
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      } else {
        _reminders = [];
      }
    } catch (error) {
      _error = _cleanError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetStats() {
    _customerCount = 0;
    _vehicleCount = 0;
    _serviceCount = 0;
    _upcomingReminderCount = 0;
    _overdueReminderCount = 0;
    _completedReminderCount = 0;
    _totalAmount = 0;
    _paidAmount = 0;
    _pendingAmount = 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  String _cleanError(dynamic error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}