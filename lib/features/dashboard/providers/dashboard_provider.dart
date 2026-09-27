import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/today_tasks.dart';

class DashboardProvider extends ChangeNotifier {
  // ============================================================
  // STATE — MAIN DASHBOARD
  // ============================================================

  int _customerCount = 0;
  int _vehicleCount = 0;
  int _serviceCount = 0;
  double _pendingAmount = 0;

  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _recentServices = [];

  bool _isLoading = false;
  String? _error;

  // ============================================================
  // STATE — TODAY'S TASKS
  // ============================================================

  TodayTasks? _todayTasks;
  bool _isLoadingTasks = false;

  // ============================================================
  // GETTERS
  // ============================================================

  int get customerCount => _customerCount;
  int get vehicleCount => _vehicleCount;
  int get serviceCount => _serviceCount;
  double get pendingAmount => _pendingAmount;

  List<Map<String, dynamic>> get reminders => _reminders;
  List<Map<String, dynamic>> get recentServices =>
      _recentServices;

  bool get isLoading => _isLoading;
  String? get error => _error;

  TodayTasks? get todayTasks => _todayTasks;
  bool get isLoadingTasks => _isLoadingTasks;

  // ============================================================
  // FETCH DASHBOARD
  // ============================================================

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/dashboard');

      if (response['success'] == true) {
        final stats =
            response['stats'] as Map<String, dynamic>? ?? {};

        _customerCount =
            (stats['totalCustomers'] as num?)?.toInt() ?? 0;
        _vehicleCount =
            (stats['totalVehicles'] as num?)?.toInt() ?? 0;
        _serviceCount =
            (stats['totalServices'] as num?)?.toInt() ?? 0;
        _pendingAmount =
            (stats['pendingAmount'] as num?)?.toDouble() ?? 0;

        final remindersData = response['recentReminders'];
        if (remindersData is List) {
          _reminders = remindersData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _reminders = [];
        }

        final servicesData = response['recentServices'];
        if (servicesData is List) {
          _recentServices = servicesData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _recentServices = [];
        }
      } else {
        _error = response['message']?.toString() ??
            'Unable to load dashboard';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FETCH TODAY'S TASKS
  // ============================================================

  Future<void> fetchTodayTasks() async {
    _isLoadingTasks = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/dashboard/today-tasks',
      );

      if (response['success'] == true &&
          response['tasks'] != null) {
        _todayTasks = TodayTasks.fromJson(
          Map<String, dynamic>.from(response['tasks']),
        );
      }
    } catch (e) {
      // Silent fail — tasks optional hain
      debugPrint('Fetch today tasks error: $e');
    } finally {
      _isLoadingTasks = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH ALL
  // ============================================================

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDashboard(),
      fetchTodayTasks(),
    ]);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _customerCount = 0;
    _vehicleCount = 0;
    _serviceCount = 0;
    _pendingAmount = 0;
    _reminders = [];
    _recentServices = [];
    _todayTasks = null;
    _error = null;
    _isLoading = false;
    _isLoadingTasks = false;
    notifyListeners();
  }
}