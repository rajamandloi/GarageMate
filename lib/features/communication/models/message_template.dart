enum MessageTemplateType {
  serviceReminder,
  paymentReminder,
  vehiclePickup,
  insuranceReminder,
  pucReminder,
  specialOffer,
  followUp,
}

class MessageTemplate {
  final String id;
  final MessageTemplateType type;
  final String name;
  String message;
  bool isEnabled;

  MessageTemplate({
    required this.id,
    required this.type,
    required this.name,
    required this.message,
    this.isEnabled = true,
  });
}