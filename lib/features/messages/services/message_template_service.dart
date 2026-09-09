import '../models/message_template.dart';

class MessageTemplateService {
  static final List<MessageTemplate> templates = [
    MessageTemplate(
      id: 'service_reminder',
      name: 'Service Reminder',
      type: MessageTemplateType.serviceReminder,
      message:
          'Hello {customerName}, your vehicle {vehicleNumber} is due for service. Please contact us to book your service.',
    ),
    MessageTemplate(
      id: 'special_offer',
      name: 'Special Offer',
      type: MessageTemplateType.specialOffer,
      message:
          'Hello {customerName}, we have a special offer available for you. Visit our garage to avail the offer.',
    ),
    MessageTemplate(
      id: 'payment_reminder',
      name: 'Payment Reminder',
      type: MessageTemplateType.paymentReminder,
      message:
          'Hello {customerName}, this is a reminder regarding the pending payment for your vehicle {vehicleNumber}.',
    ),
    MessageTemplate(
      id: 'general',
      name: 'General Message',
      type: MessageTemplateType.general,
      message:
          'Hello {customerName}, thank you for choosing our garage.',
    ),
  ];
}