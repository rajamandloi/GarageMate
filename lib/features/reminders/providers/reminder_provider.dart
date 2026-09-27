import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/reminder.dart';
import '../services/reminder_calculator.dart';

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];

  bool _isLoading = false;
  String? _error;

  List<Reminder> get reminders =>
      List.unmodifiable(_reminders);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ------------------------------------------------------------
  // FETCH ALL REMINDERS
  // ------------------------------------------------------------

  Future<void> fetchReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.get('/reminders');

      final data = response['reminders'];

      if (data is List) {
        _reminders = data
            .map(
              (item) => Reminder.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _reminders = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // FETCH CUSTOMER REMINDERS
  // ------------------------------------------------------------

  Future<void> fetchCustomerReminders(
    String customerId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/reminders/customer/$customerId',
      );

      final data = response['reminders'];

      if (data is List) {
        _reminders = data
            .map(
              (item) => Reminder.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _reminders = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // FETCH VEHICLE REMINDERS
  // ------------------------------------------------------------

  Future<void> fetchVehicleReminders(
    String vehicleId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/reminders/vehicle/$vehicleId',
      );

      final data = response['reminders'];

      if (data is List) {
        _reminders = data
            .map(
              (item) => Reminder.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        _reminders = [];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // CREATE REMINDER
  // ------------------------------------------------------------

  Future<bool> createReminder(
    Reminder reminder,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/reminders',
        reminder.toJson(),
      );

      if (response['success'] == true &&
          response['reminder'] != null) {
        final createdReminder =
            Reminder.fromJson(
          Map<String, dynamic>.from(
            response['reminder'],
          ),
        );

        _reminders.insert(
          0,
          createdReminder,
        );

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to create reminder';

      notifyListeners();

      return false;
    } catch (error) {
      _error = error.toString();

      notifyListeners();

      return false;
    }
  }

  // ------------------------------------------------------------
  // UPDATE REMINDER
  // ------------------------------------------------------------

  Future<bool> updateReminder(
    Reminder reminder,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/reminders/${reminder.id}',
        reminder.toJson(),
      );

      if (response['success'] == true &&
          response['reminder'] != null) {
        final updatedReminder =
            Reminder.fromJson(
          Map<String, dynamic>.from(
            response['reminder'],
          ),
        );

        final index =
            _reminders.indexWhere(
          (item) => item.id == reminder.id,
        );

        if (index != -1) {
          _reminders[index] =
              updatedReminder;
        }

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to update reminder';

      notifyListeners();

      return false;
    } catch (error) {
      _error = error.toString();

      notifyListeners();

      return false;
    }
  }

  // ------------------------------------------------------------
  // COMPLETE REMINDER
  // ------------------------------------------------------------

  Future<bool> completeReminder(String reminderId) async {
  _error = null;

  try {
    final response = await ApiService.patch(
      '/reminders/$reminderId/complete',
      {},
    );

    if (response['success'] == true) {
      final index = _reminders.indexWhere(
        (r) => r.id == reminderId,
      );

      if (index != -1) {
        _reminders[index].status = ReminderStatus.completed;
        notifyListeners();
      }

      return true;
    }

    _error = response['message']?.toString() ??
        'Unable to complete reminder';
    return false;
  } catch (error) {
    _error = error.toString();
    return false;
  }
}

  // ------------------------------------------------------------
  // CANCEL REMINDER
  // ------------------------------------------------------------

  Future<bool> cancelReminder(
    String reminderId,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.patch(
        '/reminders/$reminderId/cancel',
        {},
      );

      if (response['success'] == true &&
          response['reminder'] != null) {
        final updatedReminder =
            Reminder.fromJson(
          Map<String, dynamic>.from(
            response['reminder'],
          ),
        );

        final index =
            _reminders.indexWhere(
          (item) => item.id == reminderId,
        );

        if (index != -1) {
          _reminders[index] =
              updatedReminder;
        }

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to cancel reminder';

      notifyListeners();

      return false;
    } catch (error) {
      _error = error.toString();

      notifyListeners();

      return false;
    }
  }

  // ------------------------------------------------------------
  // DELETE REMINDER
  // ------------------------------------------------------------

  Future<bool> deleteReminder(
    String reminderId,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.delete(
        '/reminders/$reminderId',
      );

      if (response['success'] == true) {
        _reminders.removeWhere(
          (reminder) =>
              reminder.id == reminderId,
        );

        notifyListeners();

        return true;
      }

      _error =
          response['message']?.toString() ??
          'Unable to delete reminder';

      notifyListeners();

      return false;
    } catch (error) {
      _error = error.toString();

      notifyListeners();

      return false;
    }
  }

ReminderStatus effectiveStatus(
  Reminder reminder,
) {
  if (reminder.status == ReminderStatus.completed ||
      reminder.status == ReminderStatus.cancelled) {
    return reminder.status;
  }

  return ReminderCalculator.calculateCombinedStatus(
    dueDate: reminder.dueDate,
    currentMileage: reminder.currentMileage,
    dueMileage: reminder.dueMileage,
  );
}

  // ------------------------------------------------------------
  // FILTER HELPERS
  // ------------------------------------------------------------

  List<Reminder> remindersForCustomer(
    String customerId,
  ) {
    return _reminders
        .where(
          (reminder) =>
              reminder.customerId ==
              customerId,
        )
        .toList();
  }

  List<Reminder> remindersForVehicle(
    String vehicleId,
  ) {
    return _reminders
        .where(
          (reminder) =>
              reminder.vehicleId ==
              vehicleId,
        )
        .toList();
  }

  List<Reminder> remindersByStatus(
    ReminderStatus status,
  ) {
    return _reminders
        .where(
          (reminder) =>
              reminder.status == status,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // COUNTS
  // ------------------------------------------------------------

  int get upcomingCount =>
      remindersByStatus(
        ReminderStatus.upcoming,
      ).length;

  int get dueSoonCount =>
      remindersByStatus(
        ReminderStatus.dueSoon,
      ).length;

  int get dueTodayCount =>
      remindersByStatus(
        ReminderStatus.dueToday,
      ).length;

  int get overdueCount =>
      remindersByStatus(
        ReminderStatus.overdue,
      ).length;

  int get completedCount =>
      remindersByStatus(
        ReminderStatus.completed,
      ).length;

  // ------------------------------------------------------------
  // CLEAR
  // ------------------------------------------------------------

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearReminders() {
    _reminders = [];
    notifyListeners();
  }
}