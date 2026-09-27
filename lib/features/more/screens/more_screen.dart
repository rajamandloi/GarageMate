import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/permissions.dart';
import '../../../l10n/app_localizations.dart';

import '../../analytics/screens/analytics_screen.dart';
import '../../invoice_settings/screens/invoice_settings_screen.dart';
import '../../messages/screens/message_automation_screen.dart';
import '../../screens/whatsapp/whatsapp_send_screen.dart';
import '../../settings/screens/business_profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../staff/screens/staff_screen.dart';
import '../../subscription/screens/subscription_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // ============================================================
    // CURRENT USER + PERMISSIONS
    // ============================================================
    final userProvider = context.watch<UserProvider>();

    final permissions = Permissions(
      role: userProvider.role,
      staffRole: userProvider.staffRole,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.moreTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // ============================================================
          // PROFILE HEADER
          // ============================================================
          _ProfileHeader(
            name: userProvider.name,
            phone: userProvider.phone,
            roleLabel: _roleLabel(
              userProvider.role,
              userProvider.staffRole,
            ),
          ),

          const SizedBox(height: 24),

          // ============================================================
          // BUSINESS SECTION
          // ============================================================
          _SectionHeader(title: 'BUSINESS'),

          // Analytics — owner + manager + accountant
          if (permissions.canViewAnalytics)
            _MoreCard(
              icon: Icons.insights_rounded,
              iconColor: Colors.purple,
              title: 'Data Analytics',
              subtitle: 'Revenue, expenses aur profit dekhein',
              onTap: () => _push(context, const AnalyticsScreen()),
            ),

          // Invoice Settings — owner only
          if (permissions.canViewInvoiceBranding)
            _MoreCard(
              icon: Icons.palette_rounded,
              iconColor: Colors.deepOrange,
              title: 'Branded Invoices',
              subtitle: 'Logo, signature aur invoice design',
              onTap: () => _push(context, const InvoiceSettingsScreen()),
            ),

          // Message Automation — owner + manager
          if (permissions.canViewAutomation)
            _MoreCard(
              icon: Icons.auto_awesome_rounded,
              iconColor: Colors.amber.shade700,
              title: t.messageAutomation,
              subtitle: t.messageAutomationSubtitle,
              onTap: () => _push(context, const MessageAutomationScreen()),
            ),

          const SizedBox(height: 20),

          // ============================================================
          // TEAM SECTION — owner + manager only
          // ============================================================
          if (permissions.canManageStaff) ...[
            _SectionHeader(title: 'TEAM'),

            _MoreCard(
              icon: Icons.people_alt_rounded,
              iconColor: Colors.blue,
              title: 'Staff Management',
              subtitle: 'Manager, Mechanic aur Accountant manage karein',
              onTap: () => _push(context, const StaffScreen()),
            ),

            const SizedBox(height: 20),
          ],

          // ============================================================
          // COMMUNICATION SECTION
          // ============================================================
          if (permissions.canSendWhatsApp) ...[
            _SectionHeader(title: 'COMMUNICATION'),

            _MoreCard(
              icon: Icons.send_rounded,
              iconColor: Colors.green,
              title: t.sendOnWhatsApp,
              subtitle: t.sendOnWhatsAppSubtitle,
              onTap: () => _push(context, const WhatsAppSendScreen()),
            ),

            const SizedBox(height: 20),
          ],

          // ============================================================
          // ACCOUNT SECTION
          // ============================================================
          _SectionHeader(title: 'ACCOUNT'),

          // Business Profile — owner + manager
          if (permissions.canEditSettings)
            _MoreCard(
              icon: Icons.store_rounded,
              iconColor: Colors.teal,
              title: 'Business Profile',
              subtitle: 'Garage ki details update karein',
              onTap: () => _push(context, const BusinessProfileScreen()),
            ),

          // Subscription — owner only
          if (permissions.canViewSubscription)
            _MoreCard(
              icon: Icons.workspace_premium_rounded,
              iconColor: Colors.amber.shade800,
              title: t.subscription,
              subtitle: t.subscriptionSubtitle,
              onTap: () => _push(context, const SubscriptionScreen()),
            ),

          // Settings — everyone
          _MoreCard(
            icon: Icons.settings_rounded,
            iconColor: Colors.grey.shade700,
            title: 'settings',
            subtitle: 'App settings aur preferences',
            onTap: () => _push(context, const SettingsScreen()),
          ),

          const SizedBox(height: 20),

          // ============================================================
          // PREFERENCES SECTION
          // ============================================================
          _SectionHeader(title: 'PREFERENCES'),

          // Theme toggle card
          _ThemeCard(),

          // Language card
          _LanguageCard(),

          const SizedBox(height: 30),

          // ============================================================
          // APP VERSION
          // ============================================================
          Center(
            child: Column(
              children: [
                Text(
                  'Garage Mate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  String _roleLabel(String? role, String? staffRole) {
    if (role == 'garage_owner') return 'Garage Owner';
    if (role == 'super_admin') return 'Super Admin';
    if (role == 'staff') {
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
    return 'User';
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE HEADER
// ============================================================

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String roleLabel;

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// THEME CARD
// ============================================================

class _ThemeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isDark ? 'On' : 'Off',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LANGUAGE CARD
// ============================================================

class _LanguageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LanguageProvider>();
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: () => _showLanguagePicker(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.language_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.language,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    provider.currentLanguageName,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final provider = context.read<LanguageProvider>();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧',
                    style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                trailing: provider.isEnglish
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  provider.changeLanguage('en');
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Text('🇮🇳',
                    style: TextStyle(fontSize: 24)),
                title: const Text('हिंदी'),
                trailing: provider.isHindi
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  provider.changeLanguage('hi');
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// MORE CARD WIDGET
// ============================================================

class _MoreCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}