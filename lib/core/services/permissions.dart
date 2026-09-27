import '../../features/auth/screens/login_screen.dart';

class Permissions {
  final String role;
  final String? staffRole;

  Permissions({
    required this.role,
    this.staffRole,
  });

  // ============================================================
  // HELPER
  // ============================================================

  bool get _isOwner => role == 'garage_owner';
  bool get _isManager => staffRole == 'manager';
  bool get _isMechanic => staffRole == 'mechanic';
  bool get _isAccountant => staffRole == 'accountant';

  // ============================================================
  // FEATURES
  // ============================================================

  bool get canViewDashboard =>
      _isOwner || _isManager;

  bool get canViewCustomers =>
      _isOwner || _isManager || _isMechanic || _isAccountant;

  bool get canEditCustomers =>
      _isOwner || _isManager;

  bool get canViewVehicles => true;

  bool get canEditVehicles =>
      _isOwner || _isManager || _isMechanic;

  bool get canViewServices => true;

  bool get canEditServices =>
      _isOwner || _isManager || _isMechanic;

  bool get canViewPayments =>
      _isOwner || _isManager || _isAccountant;

  bool get canEditPayments =>
      _isOwner || _isManager || _isAccountant;

  bool get canViewInvoices => true;

  bool get canSendInvoices =>
      _isOwner || _isManager || _isAccountant;

  bool get canViewAnalytics =>
      _isOwner || _isManager || _isAccountant;

  bool get canViewReminders => true;

  bool get canEditReminders =>
      _isOwner || _isManager;

  bool get canViewWhatsApp =>
      _isOwner || _isManager || _isAccountant;

  bool get canSendWhatsApp =>
      _isOwner || _isManager || _isAccountant;

  bool get canManageStaff =>
      _isOwner || _isManager;

  bool get canViewSettings => true;

  bool get canEditSettings =>
      _isOwner;

  bool get canViewSubscription =>
      _isOwner;

  bool get canViewInvoiceBranding =>
      _isOwner;

  bool get canViewAutomation =>
      _isOwner || _isManager;

  bool get canViewScanner => true;

  bool get canViewSearch => true;
}