class TodayTasks {
  final List<TaskItem> servicesDueToday;
  final List<TaskItem> paymentsPending;
  final List<TaskItem> remindersDueToday;
  final List<TaskItem> servicesUpcoming;
  final int totalTasksCount;

  TodayTasks({
    required this.servicesDueToday,
    required this.paymentsPending,
    required this.remindersDueToday,
    required this.servicesUpcoming,
    required this.totalTasksCount,
  });

  factory TodayTasks.fromJson(Map<String, dynamic> json) {
    return TodayTasks(
      servicesDueToday: (json['servicesDueToday'] as List?)
              ?.map((e) => TaskItem.fromJson(
                    Map<String, dynamic>.from(e),
                    type: TaskType.serviceDue,
                  ))
              .toList() ??
          [],
      paymentsPending: (json['paymentsPending'] as List?)
              ?.map((e) => TaskItem.fromJson(
                    Map<String, dynamic>.from(e),
                    type: TaskType.paymentPending,
                  ))
              .toList() ??
          [],
      remindersDueToday: (json['remindersDueToday'] as List?)
              ?.map((e) => TaskItem.fromJson(
                    Map<String, dynamic>.from(e),
                    type: TaskType.reminder,
                  ))
              .toList() ??
          [],
      servicesUpcoming: (json['servicesUpcoming'] as List?)
              ?.map((e) => TaskItem.fromJson(
                    Map<String, dynamic>.from(e),
                    type: TaskType.serviceUpcoming,
                  ))
              .toList() ??
          [],
      totalTasksCount: (json['totalTasksCount'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isEmpty =>
      servicesDueToday.isEmpty &&
      paymentsPending.isEmpty &&
      remindersDueToday.isEmpty;
}

// ============================================================
// TASK TYPE
// ============================================================

enum TaskType {
  serviceDue,
  paymentPending,
  reminder,
  serviceUpcoming,
}

// ============================================================
// TASK ITEM
// ============================================================

class TaskItem {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final String title;
  final String subtitle;
  final double? pendingAmount;
  final DateTime? dueDate;
  final TaskType type;

  TaskItem({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.title,
    required this.subtitle,
    this.pendingAmount,
    this.dueDate,
    required this.type,
  });

  factory TaskItem.fromJson(
    Map<String, dynamic> json,
    {required TaskType type}
  ) {
    // Customer info
    final customer = json['customerId'];
    String customerId = '';
    String customerName = '';
    String customerPhone = '';

    if (customer is Map) {
      customerId = customer['_id']?.toString() ?? '';
      customerName = customer['name']?.toString() ?? '';
      customerPhone = customer['phone']?.toString() ?? '';
    }

    // Vehicle info
    final vehicle = json['vehicleId'];
    String vehicleId = '';
    String vehicleNumber = '';
    String vehicleBrand = '';
    String vehicleModel = '';

    if (vehicle is Map) {
      vehicleId = vehicle['_id']?.toString() ?? '';
      vehicleNumber =
          vehicle['registrationNumber']?.toString() ?? '';
      vehicleBrand = vehicle['brand']?.toString() ?? '';
      vehicleModel = vehicle['model']?.toString() ?? '';
    }

    // Pending amount (for payments)
    double? pendingAmount;
    if (json['pendingAmount'] != null) {
      pendingAmount =
          (json['pendingAmount'] as num?)?.toDouble();
    } else if (json['totalAmount'] != null &&
        json['paidAmount'] != null) {
      final total =
          (json['totalAmount'] as num?)?.toDouble() ?? 0;
      final paid =
          (json['paidAmount'] as num?)?.toDouble() ?? 0;
      pendingAmount = (total - paid).clamp(0, total);
    }

    // Due date
    DateTime? dueDate;
    if (json['nextServiceDate'] != null) {
      dueDate =
          DateTime.tryParse(json['nextServiceDate'].toString());
    } else if (json['dueDate'] != null) {
      dueDate = DateTime.tryParse(json['dueDate'].toString());
    } else if (json['serviceDate'] != null) {
      dueDate = DateTime.tryParse(json['serviceDate'].toString());
    }

    // Title based on type
    String title;
    String subtitle;

    switch (type) {
      case TaskType.serviceDue:
        title = json['serviceType']?.toString() ?? 'Service';
        subtitle = _vehicleString(
          vehicleBrand,
          vehicleModel,
          vehicleNumber,
        );
        break;
      case TaskType.paymentPending:
        title = '₹${pendingAmount?.toStringAsFixed(0) ?? 0}';
        subtitle = json['serviceType']?.toString() ?? 'Payment pending';
        break;
      case TaskType.reminder:
        title = json['title']?.toString() ?? 'Reminder';
        subtitle = json['message']?.toString() ?? '';
        break;
      case TaskType.serviceUpcoming:
        title = json['serviceType']?.toString() ?? 'Service';
        subtitle = _vehicleString(
          vehicleBrand,
          vehicleModel,
          vehicleNumber,
        );
        break;
    }

    return TaskItem(
      id: json['_id']?.toString() ?? '',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      title: title,
      subtitle: subtitle,
      pendingAmount: pendingAmount,
      dueDate: dueDate,
      type: type,
    );
  }

  static String _vehicleString(
    String brand,
    String model,
    String number,
  ) {
    final parts = <String>[];
    if (brand.isNotEmpty) parts.add(brand);
    if (model.isNotEmpty) parts.add(model);
    final name = parts.join(' ');
    if (number.isNotEmpty) {
      return name.isNotEmpty ? '$name • $number' : number;
    }
    return name;
  }
}