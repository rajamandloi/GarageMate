enum MessageTemplateType {
  serviceReminder,
  specialOffer,
  paymentReminder,
  general,
}

class MessageTemplate {
  final String id;
  final String name;
  final MessageTemplateType type;
  String message;
  bool isActive;

  MessageTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.message,
    this.isActive = true,
  });
}