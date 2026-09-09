enum PaymentMethod {
  cash,
  upi,
  card,
  bankTransfer,
  other,
}

enum PaymentStatus {
  paid,
  partiallyPaid,
  pending,
}

class Payment {
  final String id;
  final String serviceId;
  final String customerId;
  final String vehicleId;

  double amount;
  PaymentMethod method;
  DateTime paymentDate;
  PaymentStatus status;
  String notes;

  Payment({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.vehicleId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.status,
    this.notes = '',
  });
}