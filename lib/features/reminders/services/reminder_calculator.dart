import '../models/reminder.dart';

class ReminderCalculator {
  static const int dueSoonDays = 7;

  static ReminderStatus calculateCombinedStatus({
    DateTime? dueDate,
    double? currentMileage,
    double? dueMileage,
  }) {
    bool mileageDue = false;

    if (currentMileage != null && dueMileage != null) {
      mileageDue = currentMileage >= dueMileage;
    }

    ReminderStatus? dateStatus;

    if (dueDate != null) {
      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final dueDay = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      );

      final difference = dueDay.difference(today).inDays;

      if (difference < 0) {
        dateStatus = ReminderStatus.overdue;
      } else if (difference == 0) {
        dateStatus = ReminderStatus.dueToday;
      } else if (difference <= dueSoonDays) {
        dateStatus = ReminderStatus.dueSoon;
      } else {
        dateStatus = ReminderStatus.upcoming;
      }
    }

    if (mileageDue) {
      return ReminderStatus.overdue;
    }

    return dateStatus ?? ReminderStatus.upcoming;
  }
}