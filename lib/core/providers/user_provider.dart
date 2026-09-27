import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================

  Map<String, dynamic>? _user;

  // ============================================================
  // GETTERS
  // ============================================================

  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _user != null;

  String get role => (_user?['role'] ?? 'garage_owner').toString();

  String? get staffRole {
    final value = _user?['staffRole'];
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  String get name => (_user?['name'] ?? 'User').toString();
  String get phone => (_user?['phone'] ?? '').toString();
  String get email => (_user?['email'] ?? '').toString();
  String? get garageId => _user?['garageId']?.toString();

  // ============================================================
  // SET USER (login ke baad call karo)
  // ============================================================

  void setUser(Map<String, dynamic> userData) {
    _user = Map<String, dynamic>.from(userData);
    debugPrint('✅ UserProvider setUser: ${_user?['role']} / ${_user?['staffRole']}');
    notifyListeners();
  }

  // ============================================================
  // CLEAR (logout ke baad call karo)
  // ============================================================

  void clear() {
    _user = null;
    notifyListeners();
  }
}