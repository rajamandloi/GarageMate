enum PaymentStatus {
  paid,
  partiallyPaid,
  pending,
}

class ServiceRecord {
  final String id;
  final String customerId;
  final String vehicleId;

  // Populated customer information
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  // Populated vehicle information
  final String? registrationNumber;
  final String? vehicleBrand;
  final String? vehicleModel;

  final DateTime serviceDate;
  final String serviceType;
  final double mileage;

  final String description;
  final String partsUsed;

  final double laborCost;
  final double partsCost;
  final double discount;
  final double tax;

  final double totalAmount;
  final double paidAmount;

  final PaymentStatus paymentStatus;
  final String paymentMethod;

  final DateTime? nextServiceDate;
  final double? nextServiceMileage;

  final String mechanic;
  final String notes;

  ServiceRecord({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.registrationNumber,
    this.vehicleBrand,
    this.vehicleModel,
    required this.serviceDate,
    required this.serviceType,
    required this.mileage,
    this.description = '',
    this.partsUsed = '',
    this.laborCost = 0,
    this.partsCost = 0,
    this.discount = 0,
    this.tax = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = 'Cash',
    this.nextServiceDate,
    this.nextServiceMileage,
    this.mechanic = '',
    this.notes = '',
  });

  double get pendingAmount {
    final pending = totalAmount - paidAmount;
    return pending < 0 ? 0 : pending;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ServiceRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final customer = json['customerId'];
    final vehicle = json['vehicleId'];

    String customerId = '';
    String? customerName;
    String? customerPhone;
    String? customerEmail;

    if (customer is Map) {
      customerId = customer['_id']?.toString() ?? '';
      customerName = customer['name']?.toString();
      customerPhone = customer['phone']?.toString();
      customerEmail = customer['email']?.toString();
    } else {
      customerId = customer?.toString() ?? '';
    }

    String vehicleId = '';
    String? registrationNumber;
    String? vehicleBrand;
    String? vehicleModel;

    if (vehicle is Map) {
      vehicleId = vehicle['_id']?.toString() ?? '';
      registrationNumber =
          vehicle['registrationNumber']?.toString();
      vehicleBrand = vehicle['brand']?.toString();
      vehicleModel = vehicle['model']?.toString();
    } else {
      vehicleId = vehicle?.toString() ?? '';
    }

    return ServiceRecord(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',

      customerId: customerId,
      vehicleId: vehicleId,

      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,

      registrationNumber: registrationNumber,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,

      serviceDate:
          _parseDate(json['serviceDate']) ??
          DateTime.now(),

      serviceType:
          json['serviceType']?.toString() ?? '',

      mileage:
          (json['mileage'] as num?)?.toDouble() ?? 0,

      description:
          json['description']?.toString() ?? '',

      partsUsed:
          json['partsUsed']?.toString() ?? '',

      laborCost:
          (json['laborCost'] as num?)?.toDouble() ?? 0,

      partsCost:
          (json['partsCost'] as num?)?.toDouble() ?? 0,

      discount:
          (json['discount'] as num?)?.toDouble() ?? 0,

      tax:
          (json['tax'] as num?)?.toDouble() ?? 0,

      totalAmount:
          (json['totalAmount'] as num?)?.toDouble() ?? 0,

      paidAmount:
          (json['paidAmount'] as num?)?.toDouble() ?? 0,

      paymentStatus:
          _parsePaymentStatus(
            json['paymentStatus'],
          ),

      paymentMethod:
          json['paymentMethod']?.toString() ?? 'Cash',

      nextServiceDate:
          _parseDate(json['nextServiceDate']),

      nextServiceMileage:
          (json['nextServiceMileage'] as num?)
              ?.toDouble(),

      mechanic:
          json['mechanic']?.toString() ?? '',

      notes:
          json['notes']?.toString() ?? '',
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'vehicleId': vehicleId,

      'serviceDate':
          serviceDate.toIso8601String(),

      'serviceType': serviceType,
      'mileage': mileage,

      'description': description,
      'partsUsed': partsUsed,

      'laborCost': laborCost,
      'partsCost': partsCost,
      'discount': discount,
      'tax': tax,

      'totalAmount': totalAmount,
      'paidAmount': paidAmount,

      'paymentStatus':
          _paymentStatusToString(paymentStatus),

      'paymentMethod': paymentMethod,

      'nextServiceDate':
          nextServiceDate?.toIso8601String(),

      'nextServiceMileage':
          nextServiceMileage,

      'mechanic': mechanic,
      'notes': notes,
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static DateTime? _parseDate(dynamic value) {
    if (value == null ||
        value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static PaymentStatus _parsePaymentStatus(
    dynamic value,
  ) {
    switch (value?.toString()) {
      case 'paid':
        return PaymentStatus.paid;

      case 'partiallyPaid':
        return PaymentStatus.partiallyPaid;

      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  static String _paymentStatusToString(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.paid:
        return 'paid';

      case PaymentStatus.partiallyPaid:
        return 'partiallyPaid';

      case PaymentStatus.pending:
        return 'pending';
    }
  }
}