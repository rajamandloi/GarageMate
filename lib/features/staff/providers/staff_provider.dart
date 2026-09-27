import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/staff_model.dart';
import '../models/activity_log_model.dart';

class StaffProvider extends ChangeNotifier {
  List<StaffModel> _staff = [];
  List<ActivityLogModel> _activityLog = [];
  StaffLimitsInfo? _limits;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<StaffModel> get staff => List.unmodifiable(_staff);
  List<ActivityLogModel> get activityLog =>
      List.unmodifiable(_activityLog);
  StaffLimitsInfo? get limits => _limits;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  bool get canAddStaff =>
      _limits != null && _limits!.remaining > 0;

  // ============================================================
  // FETCH STAFF
  // ============================================================

  Future<void> fetchStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getStaffList();

      if (response['success'] == true) {
        final list = response['staff'] as List? ?? [];

        _staff = list
            .map((e) => StaffModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();

        final limitsData = response['limits'];
        if (limitsData is Map) {
          _limits = StaffLimitsInfo.fromJson(
            Map<String, dynamic>.from(limitsData),
          );
        }
      } else {
        _error = response['message']?.toString() ??
            'Unable to load staff';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADD STAFF
  // ============================================================

  Future<Map<String, dynamic>?> addStaff({
    required String name,
    required String phone,
    required String staffRole,
    String? password,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.addStaff(
        name: name,
        phone: phone,
        staffRole: staffRole,
        password: password,
      );

      if (response['success'] == true) {
        await fetchStaff();
        return response;
      }

      _error = response['message']?.toString() ??
          'Unable to add staff';
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE ROLE
  // ============================================================

  Future<bool> changeRole({
    required String staffId,
    required String newRole,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateStaffRole(
        staffId: staffId,
        staffRole: newRole,
      );

      if (response['success'] == true) {
        await fetchStaff();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to change role';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<bool> toggleActive(String staffId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.toggleStaffActive(staffId);

      if (response['success'] == true) {
        await fetchStaff();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to update staff';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPassword({
    required String staffId,
    required String newPassword,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.resetStaffPassword(
        staffId: staffId,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to reset password';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE STAFF
  // ============================================================

  Future<bool> deleteStaff(String staffId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.deleteStaff(staffId);

      if (response['success'] == true) {
        await fetchStaff();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to delete staff';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // FETCH ACTIVITY LOG
  // ============================================================

  Future<void> fetchActivityLog({
    int limit = 50,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getActivityLog(
        limit: limit,
        userId: userId,
      );

      if (response['success'] == true) {
        final list = response['logs'] as List? ?? [];

        _activityLog = list
            .map((e) => ActivityLogModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      } else {
        _error = response['message']?.toString() ??
            'Unable to load activity log';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _staff = [];
    _activityLog = [];
    _limits = null;
    _error = null;
    notifyListeners();
  }
}