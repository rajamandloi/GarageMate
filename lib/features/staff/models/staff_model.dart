class StaffModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String? staffRole;
  final bool isActive;
  final DateTime? lastActiveAt;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final String? invitedByName;

  StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.staffRole,
    required this.isActive,
    this.lastActiveAt,
    this.lastLogin,
    required this.createdAt,
    this.invitedByName,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    String? invitedByName;

    if (json['invitedBy'] is Map) {
      invitedByName = json['invitedBy']['name']?.toString();
    }

    return StaffModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'staff',
      staffRole: json['staffRole']?.toString(),
      isActive: json['isActive'] == true,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      invitedByName: invitedByName,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String get displayRole {
    if (staffRole == null) return 'Staff';

    switch (staffRole) {
      case 'manager':
        return 'Manager';
      case 'mechanic':
        return 'Mechanic';
      case 'accountant':
        return 'Accountant';
      default:
        return 'Staff';
    }
  }

  String get initials {
    if (name.isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }
}

// ============================================================
// STAFF LIMITS INFO
// ============================================================

class StaffLimitsInfo {
  final String plan;
  final int limit;
  final int used;
  final int remaining;

  StaffLimitsInfo({
    required this.plan,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  factory StaffLimitsInfo.fromJson(Map<String, dynamic> json) {
    return StaffLimitsInfo(
      plan: json['plan']?.toString() ?? 'free',
      limit: (json['limit'] as num?)?.toInt() ?? 1,
      used: (json['used'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    );
  }
}