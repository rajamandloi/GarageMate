class Customer {
  final String id;
  String name;
  String phone;
  String email;
  String address;
  int vehicleCount;
  DateTime? lastServiceDate;
  DateTime? nextServiceDate;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.vehicleCount = 0,
    this.lastServiceDate,
    this.nextServiceDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      vehicleCount:
          (json['vehicleCount'] as num?)?.toInt() ?? 0,
      lastServiceDate:
          _parseDate(json['lastServiceDate']),
      nextServiceDate:
          _parseDate(json['nextServiceDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}