import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/phone_helper.dart';
import '../models/staff_model.dart';
import '../providers/staff_provider.dart';
import 'activity_log_screen.dart';

class StaffDetailsScreen extends StatelessWidget {
  final StaffModel staff;

  const StaffDetailsScreen({
    super.key,
    required this.staff,
  });

  // ============================================================
  // CHANGE ROLE
  // ============================================================

  Future<void> _changeRole(BuildContext context) async {
    final provider = context.read<StaffProvider>();

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.manage_accounts_rounded,
                ),
                title: const Text('Manager'),
                subtitle: const Text('Full access'),
                trailing: staff.staffRole == 'manager'
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.pop(sheetContext, 'manager'),
              ),
              ListTile(
                leading: const Icon(Icons.build_rounded),
                title: const Text('Mechanic'),
                subtitle: const Text('Services & vehicles'),
                trailing: staff.staffRole == 'mechanic'
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.pop(sheetContext, 'mechanic'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_rounded,
                ),
                title: const Text('Accountant'),
                subtitle: const Text('Payments & invoices'),
                trailing: staff.staffRole == 'accountant'
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () =>
                    Navigator.pop(sheetContext, 'accountant'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == staff.staffRole) {
      return;
    }

    if (!context.mounted) return;

    final success = await provider.changeRole(
      staffId: staff.id,
      newRole: selected,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Unable to update'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<void> _toggleActive(BuildContext context) async {
    final provider = context.read<StaffProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            staff.isActive
                ? 'Deactivate Staff?'
                : 'Activate Staff?',
          ),
          content: Text(
            staff.isActive
                ? '${staff.name} ke saare sessions revoke ho jayenge.'
                : '${staff.name} phir se login kar payenge.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                staff.isActive ? 'Deactivate' : 'Activate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final success = await provider.toggleActive(staff.id);

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Unable'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Minimum 6 characters',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Minimum 6 characters';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<StaffProvider>();

    final success = await provider.resetPassword(
      staffId: staff.id,
      newPassword: controller.text.trim(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password reset successfully'
              : provider.error ?? 'Unable',
        ),
        backgroundColor:
            success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // DELETE STAFF
  // ============================================================

  Future<void> _deleteStaff(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Staff?'),
          content: Text(
            '${staff.name} ko permanently remove kar diya jayega. Ye action undo nahi ho sakta.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<StaffProvider>();

    final success = await provider.deleteStaff(staff.id);

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Unable'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CALL STAFF
  // ============================================================

  Future<void> _callStaff(BuildContext context) async {
    final url = PhoneHelper.buildWhatsAppUrl(
      phone: staff.phone,
    );

    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open WhatsApp'),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      theme.colorScheme.surface,
                  child: Text(
                    staff.initials,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  staff.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.displayRole,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: staff.isActive
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: staff.isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // INFO
          _SectionCard(
            title: 'Contact',
            icon: Icons.contact_phone_rounded,
            children: [
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: staff.phone,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ACTIONS
          _SectionCard(
            title: 'Actions',
            icon: Icons.settings_rounded,
            children: [
              _ActionTile(
                icon: Icons.manage_accounts_rounded,
                title: 'Change Role',
                subtitle: staff.displayRole,
                onTap: () => _changeRole(context),
              ),
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                title: 'Reset Password',
                subtitle: 'Set new password',
                onTap: () => _resetPassword(context),
              ),
              _ActionTile(
                icon: staff.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded,
                title: staff.isActive
                    ? 'Deactivate'
                    : 'Activate',
                subtitle: staff.isActive
                    ? 'Revoke sessions'
                    : 'Allow login',
                onTap: () => _toggleActive(context),
              ),
              _ActionTile(
                icon: Icons.history_rounded,
                title: 'View Activity',
                subtitle: 'See what they did',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityLogScreen(
                        userId: staff.id,
                        userName: staff.name,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                icon: Icons.chat_rounded,
                title: 'Send WhatsApp',
                subtitle: 'Message on WhatsApp',
                onTap: () => _callStaff(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // DELETE
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _deleteStaff(context),
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              label: const Text(
                'Remove Staff Member',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION TILE
// ============================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}