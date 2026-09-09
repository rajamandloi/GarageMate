enum CampaignStatus {
  draft,
  scheduled,
  processing,
  completed,
  failed,
  cancelled,
}

class Campaign {
  final String id;
  final String name;
  final String templateId;

  String? offerTitle;
  String? offerDescription;
  DateTime? scheduledAt;

  int totalRecipients;
  int sentCount;
  int deliveredCount;
  int failedCount;

  CampaignStatus status;

  Campaign({
    required this.id,
    required this.name,
    required this.templateId,
    this.offerTitle,
    this.offerDescription,
    this.scheduledAt,
    this.totalRecipients = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = CampaignStatus.draft,
  });
}