class ActivityLogModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String action;
  final String entity;
  final String description;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.entity,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Unknown',
      userRole: json['userRole']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}