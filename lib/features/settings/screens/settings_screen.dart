import 'package:flutter/material.dart';
import 'business_profile_screen.dart';
import '../../screens/whatsapp/whatsapp_send_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _whatsappEnabled = true;
  bool _autoRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // ==========================================================
          // GENERAL
          // ==========================================================
          _SectionTitle(title: 'General'),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Receive app notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.dark_mode_outlined,
            title: 'Appearance',
            subtitle: 'Manage app appearance',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showAppearanceDialog();
            },
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // WHATSAPP
          // ==========================================================
          _SectionTitle(title: 'WhatsApp'),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp Messaging',
            subtitle: 'Enable WhatsApp customer messaging',
            trailing: Switch(
              value: _whatsappEnabled,
              onChanged: (value) {
                setState(() {
                  _whatsappEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // ⭐ NAYA CARD — SEND ON WHATSAPP
          _SettingsCard(
            icon: Icons.send_rounded,
            title: 'Send on WhatsApp',
            subtitle: 'Send invoices, offers & reminders',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WhatsAppSendScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Automatic Reminders',
            subtitle: 'Send eligible reminders automatically',
            trailing: Switch(
              value: _autoRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _autoRemindersEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // BUSINESS
          // ==========================================================
          _SectionTitle(title: 'Business'),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.store_outlined,
            title: 'Business Profile',
            subtitle: 'Manage garage information',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusinessProfileScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.message_outlined,
            title: 'Message Templates',
            subtitle: 'Manage customer message templates',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showComingSoon('Message Templates');
            },
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // DATA
          // ==========================================================
          _SectionTitle(title: 'Data'),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Backup & Sync',
            subtitle: 'Manage your garage data',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showComingSoon('Backup & Sync');
            },
          ),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Local Data',
            subtitle: 'Remove locally stored application data',
            iconColor: theme.colorScheme.error,
            onTap: () {
              _showClearDataDialog();
            },
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // ABOUT
          // ==========================================================
          _SectionTitle(title: 'About'),

          const SizedBox(height: 10),

          _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: 'About GarageMate',
            subtitle: 'Version 1.0.0',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showAboutDialog();
            },
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'GarageMate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Center(
            child: Text(
              'Garage Management System',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  void _showAppearanceDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appearance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'system',
                groupValue: 'system',
                title: const Text('System Default'),
                onChanged: (_) {
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                value: 'light',
                groupValue: 'system',
                title: const Text('Light'),
                onChanged: (_) {
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                value: 'dark',
                groupValue: 'system',
                title: const Text('Dark'),
                onChanged: (_) {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Local Data?'),
          content: const Text(
            'This will remove locally stored application data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Local data cleared.'),
                  ),
                );
              },
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GarageMate',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Garage management made simple.',
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================
// SETTINGS CARD
// ============================================================

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (iconColor ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}