import '../../customers/models/customer.dart';
import '../../services/models/service_record.dart';

class AutomationService {
  /// Customers whose next service date is due
  /// within the next 7 days or is already overdue.
  static List<Customer> getServiceReminderRecipients({
    required List<Customer> customers,
  }) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final limit = today.add(
      const Duration(days: 7),
    );

    return customers.where((customer) {
      final nextServiceDate = customer.nextServiceDate;

      if (nextServiceDate == null) {
        return false;
      }

      final serviceDate = DateTime(
        nextServiceDate.year,
        nextServiceDate.month,
        nextServiceDate.day,
      );

      return !serviceDate.isAfter(limit);
    }).toList();
  }

  /// Customers who have pending or partially paid services.
  static List<ServiceRecord> getPaymentReminderRecipients({
    required List<ServiceRecord> services,
  }) {
    return services.where((service) {
      return service.pendingAmount > 0;
    }).toList();
  }

  /// Customers who have valid phone numbers and can receive
  /// a special offer.
  static List<Customer> getSpecialOfferRecipients({
    required List<Customer> customers,
  }) {
    return customers.where((customer) {
      return customer.phone.trim().length >= 10;
    }).toList();
  }

  /// Generates a service reminder message.
  static String serviceReminderMessage(
    Customer customer,
  ) {
    final name = customer.name.trim();

    return 'Hello $name, your vehicle service is due soon. '
        'Please contact us to schedule your service.';
  }

  /// Generates a special offer message.
  static String specialOfferMessage(
    Customer customer,
  ) {
    final name = customer.name.trim();

    return 'Hello $name, we have a special offer available '
        'for you. Contact us to know more.';
  }

  /// Generates a payment reminder message.
  static String paymentReminderMessage(
    Customer customer,
    ServiceRecord service,
  ) {
    final name = customer.name.trim();

    return 'Hello $name, your previous service has a '
        'pending payment of ₹${service.pendingAmount.toStringAsFixed(0)}. '
        'Please contact us for payment details.';
  }
}