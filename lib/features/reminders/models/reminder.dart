enum ReminderType {
  service,
  payment,
  general,
  specialOffer,
}

enum ReminderStatus {
  upcoming,
  dueSoon,
  dueToday,
  overdue,
  completed,
  cancelled,
}

class Reminder {
  final String id;
  final String customerId;
  final String vehicleId;

  // Populated customer information
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;

  // Populated vehicle information
  final String? registrationNumber;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleVariant;
  final double? currentMileage;

  ReminderType type;

  DateTime? dueDate;
  double? dueMileage;

  String title;
  String message;

  ReminderStatus status;

  Reminder({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.registrationNumber,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleVariant,
    this.currentMileage,
    required this.type,
    this.dueDate,
    this.dueMileage,
    required this.title,
    required this.message,
    this.status = ReminderStatus.upcoming,
  });

  // ------------------------------------------------------------
  // FROM JSON
  // ------------------------------------------------------------

  factory Reminder.fromJson(
    Map<String, dynamic> json,
  ) {
    final customer = json['customerId'];
    final vehicle = json['vehicleId'];

    String customerId = '';
    String? customerName;
    String? customerPhone;
    String? customerEmail;
    String? customerAddress;

    String vehicleId = '';
    String? registrationNumber;
    String? vehicleBrand;
    String? vehicleModel;
    String? vehicleVariant;
    double? currentMileage;

    // Customer can either be populated object
    // or simple ObjectId string.

    if (customer is Map) {
      customerId =
          customer['_id']?.toString() ?? '';

      customerName =
          customer['name']?.toString();

      customerPhone =
          customer['phone']?.toString();

      customerEmail =
          customer['email']?.toString();

      customerAddress =
          customer['address']?.toString();
    } else {
      customerId =
          customer?.toString() ?? '';
    }

    // Vehicle can either be populated object
    // or simple ObjectId string.

    if (vehicle is Map) {
      vehicleId =
          vehicle['_id']?.toString() ?? '';

      registrationNumber =
          vehicle['registrationNumber']
              ?.toString();

      vehicleBrand =
          vehicle['brand']?.toString();

      vehicleModel =
          vehicle['model']?.toString();

      vehicleVariant =
          vehicle['variant']?.toString();

      currentMileage =
          (vehicle['currentMileage'] as num?)
              ?.toDouble();
    } else {
      vehicleId =
          vehicle?.toString() ?? '';
    }

    return Reminder(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',

      customerId: customerId,
      vehicleId: vehicleId,

      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,

      registrationNumber:
          registrationNumber,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      vehicleVariant: vehicleVariant,
      currentMileage: currentMileage,

      type: _parseReminderType(
        json['type'],
      ),

      dueDate: _parseDate(
        json['dueDate'],
      ),

      dueMileage:
          (json['dueMileage'] as num?)
              ?.toDouble(),

      title:
          json['title']?.toString() ?? '',

      message:
          json['message']?.toString() ?? '',

      status: _parseReminderStatus(
        json['status'],
      ),
    );
  }

  // ------------------------------------------------------------
  // TO JSON
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'vehicleId': vehicleId,

      'type': _reminderTypeToString(
        type,
      ),

      'dueDate':
          dueDate?.toIso8601String(),

      'dueMileage': dueMileage,

      'title': title,
      'message': message,

      'status':
          _reminderStatusToString(
        status,
      ),
    };
  }

  // ------------------------------------------------------------
  // ENUM PARSERS
  // ------------------------------------------------------------

  static ReminderType _parseReminderType(
    dynamic value,
  ) {
    switch (value?.toString()) {
      case 'service':
        return ReminderType.service;

      case 'payment':
        return ReminderType.payment;

      case 'general':
        return ReminderType.general;

      case 'specialOffer':
      case 'special_offer':
        return ReminderType.specialOffer;

      default:
        return ReminderType.general;
    }
  }

  static ReminderStatus _parseReminderStatus(
    dynamic value,
  ) {
    switch (value?.toString()) {
      case 'upcoming':
        return ReminderStatus.upcoming;

      case 'dueSoon':
      case 'due_soon':
        return ReminderStatus.dueSoon;

      case 'dueToday':
      case 'due_today':
        return ReminderStatus.dueToday;

      case 'overdue':
        return ReminderStatus.overdue;

      case 'completed':
        return ReminderStatus.completed;

      case 'cancelled':
      case 'canceled':
        return ReminderStatus.cancelled;

      default:
        return ReminderStatus.upcoming;
    }
  }

  static String _reminderTypeToString(
    ReminderType type,
  ) {
    switch (type) {
      case ReminderType.service:
        return 'service';

      case ReminderType.payment:
        return 'payment';

      case ReminderType.general:
        return 'general';

      case ReminderType.specialOffer:
        return 'specialOffer';
    }
  }

  static String _reminderStatusToString(
    ReminderStatus status,
  ) {
    switch (status) {
      case ReminderStatus.upcoming:
        return 'upcoming';

      case ReminderStatus.dueSoon:
        return 'dueSoon';

      case ReminderStatus.dueToday:
        return 'dueToday';

      case ReminderStatus.overdue:
        return 'overdue';

      case ReminderStatus.completed:
        return 'completed';

      case ReminderStatus.cancelled:
        return 'cancelled';
    }
  }

  // ------------------------------------------------------------
  // DATE PARSER
  // ------------------------------------------------------------

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null ||
        value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ------------------------------------------------------------
  // DISPLAY HELPERS
  // ------------------------------------------------------------

  String get customerDisplayName {
    if (customerName != null &&
        customerName!.trim().isNotEmpty) {
      return customerName!;
    }

    return 'Unknown Customer';
  }

  String get vehicleDisplayName {
    final parts = <String>[];

    if (vehicleBrand != null &&
        vehicleBrand!.trim().isNotEmpty) {
      parts.add(vehicleBrand!);
    }

    if (vehicleModel != null &&
        vehicleModel!.trim().isNotEmpty) {
      parts.add(vehicleModel!);
    }

    if (parts.isEmpty) {
      return registrationNumber ??
          'Unknown Vehicle';
    }

    return parts.join(' ');
  }

  String get formattedDueDate {
    if (dueDate == null) {
      return 'No date set';
    }

    final date = dueDate!;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String get typeLabel {
    switch (type) {
      case ReminderType.service:
        return 'Service';

      case ReminderType.payment:
        return 'Payment';

      case ReminderType.general:
        return 'General';

      case ReminderType.specialOffer:
        return 'Special Offer';
    }
  }

  String get statusLabel {
    switch (status) {
      case ReminderStatus.upcoming:
        return 'Upcoming';

      case ReminderStatus.dueSoon:
        return 'Due Soon';

      case ReminderStatus.dueToday:
        return 'Due Today';

      case ReminderStatus.overdue:
        return 'Overdue';

      case ReminderStatus.completed:
        return 'Completed';

      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Reminder copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? registrationNumber,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleVariant,
    double? currentMileage,
    ReminderType? type,
    DateTime? dueDate,
    double? dueMileage,
    String? title,
    String? message,
    ReminderStatus? status,
  }) {
    return Reminder(
      id: id ?? this.id,
      customerId:
          customerId ?? this.customerId,
      vehicleId:
          vehicleId ?? this.vehicleId,

      customerName:
          customerName ?? this.customerName,
      customerPhone:
          customerPhone ?? this.customerPhone,
      customerEmail:
          customerEmail ?? this.customerEmail,
      customerAddress:
          customerAddress ?? this.customerAddress,

      registrationNumber:
          registrationNumber ??
              this.registrationNumber,

      vehicleBrand:
          vehicleBrand ?? this.vehicleBrand,

      vehicleModel:
          vehicleModel ?? this.vehicleModel,

      vehicleVariant:
          vehicleVariant ?? this.vehicleVariant,

      currentMileage:
          currentMileage ?? this.currentMileage,

      type: type ?? this.type,

      dueDate:
          dueDate ?? this.dueDate,

      dueMileage:
          dueMileage ?? this.dueMileage,

      title:
          title ?? this.title,

      message:
          message ?? this.message,

      status:
          status ?? this.status,
    );
  }
}