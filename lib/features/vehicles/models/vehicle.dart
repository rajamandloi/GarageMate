class Vehicle {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;

  final String registrationNumber;
  final String brand;
  final String model;
  final String variant;
  final String manufacturingYear;
  final String fuelType;
  final double currentMileage;
  final String vin;
  final String engineNumber;
  final String notes;

  final DateTime? insuranceExpiry;
  final DateTime? pucExpiry;

  Vehicle({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    required this.registrationNumber,
    required this.brand,
    required this.model,
    this.variant = '',
    this.manufacturingYear = '',
    this.fuelType = 'Petrol',
    this.currentMileage = 0,
    this.vin = '',
    this.engineNumber = '',
    this.notes = '',
    this.insuranceExpiry,
    this.pucExpiry,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final customer = json['customerId'];

    String customerId = '';
    String? customerName;
    String? customerPhone;
    String? customerEmail;
    String? customerAddress;

    if (customer is Map) {
      customerId = customer['_id']?.toString() ?? '';
      customerName = customer['name']?.toString();
      customerPhone = customer['phone']?.toString();
      customerEmail = customer['email']?.toString();
      customerAddress = customer['address']?.toString();
    } else {
      customerId = customer?.toString() ?? '';
    }

    return Vehicle(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      registrationNumber:
          json['registrationNumber']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      manufacturingYear:
          json['manufacturingYear']?.toString() ?? '',
      fuelType: json['fuelType']?.toString() ?? 'Petrol',
      currentMileage:
          (json['currentMileage'] as num?)?.toDouble() ?? 0,
      vin: json['vin']?.toString() ?? '',
      engineNumber:
          json['engineNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      insuranceExpiry:
          _parseDate(json['insuranceExpiry']),
      pucExpiry:
          _parseDate(json['pucExpiry']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'registrationNumber': registrationNumber,
      'brand': brand,
      'model': model,
      'variant': variant,
      'manufacturingYear': manufacturingYear,
      'fuelType': fuelType,
      'currentMileage': currentMileage,
      'vin': vin,
      'engineNumber': engineNumber,
      'notes': notes,
      'insuranceExpiry':
          insuranceExpiry?.toIso8601String(),
      'pucExpiry':
          pucExpiry?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}