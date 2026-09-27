import 'package:flutter/material.dart';

// ============================================================
// WHATSAPP MESSAGE TYPE
// ============================================================

enum WhatsAppMessageType {
  invoice('bill', 'Send Invoice', Icons.receipt_long),
  offer('offer', 'Send Offer', Icons.local_offer),
  paymentPending(
      'payment_reminder', 'Payment Pending', Icons.pending_actions),
  reminder('service_reminder', 'Send Reminder',
      Icons.notifications_active);

  final String apiValue;
  final String label;
  final IconData icon;

  const WhatsAppMessageType(this.apiValue, this.label, this.icon);
}

// ============================================================
// RECIPIENT MODE
// ============================================================

enum RecipientMode {
  allCustomers('send_to_all', 'Send to All Customers'),
  selectedCustomer('selected', 'Select Customers');

  final String apiValue;
  final String label;

  const RecipientMode(this.apiValue, this.label);
}

// ============================================================
// CUSTOMER MODEL
// ============================================================

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }
}

// ============================================================
// WHATSAPP TEMPLATE MODEL
// ============================================================

class WhatsAppTemplateModel {
  final String id;
  final String name;
  final String displayName;
  final String language;
  final String category;
  final List<String> bodyParameters;

  WhatsAppTemplateModel({
    required this.id,
    required this.name,
    required this.displayName,
    // ✅ DEFAULT LANGUAGE = "en" (NOT "en_US")
    this.language = 'en',
    this.category = 'UTILITY',
    this.bodyParameters = const [],
  });

  static List<WhatsAppTemplateModel> get defaults => [
        WhatsAppTemplateModel(
          id: 'garage_service_bill',
          name: 'garage_service_bill',
          displayName: 'Service Bill',
          category: 'UTILITY',
          bodyParameters: [
            'Customer Name',
            'Vehicle Model',
            'Date',
          ],
        ),
        WhatsAppTemplateModel(
          id: 'payment_reminder',
          name: 'payment_reminder',
          displayName: 'Payment Reminder',
          category: 'UTILITY',
          bodyParameters: [
            'Customer Name',
            'Pending Amount',
            'Due Date',
            'Garage Name',        // ✅ 4th param for payment_reminder
          ],
        ),
        WhatsAppTemplateModel(
          id: 'service_reminder',
          name: 'service_reminder',
          displayName: 'Service Reminder',
          category: 'UTILITY',
          bodyParameters: [
            'Customer Name',
            'Vehicle Number',
            'Service Type',
          ],
        ),
        WhatsAppTemplateModel(
          id: 'special_offer',
          name: 'special_offer',
          displayName: 'Special Offer',
          category: 'MARKETING',
          bodyParameters: [
            'Customer Name',
            'Offer Title',
            'Offer Details',
          ],
        ),
      ];
}