import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../subscription/screens/subscription_screen.dart';
import '../models/staff_model.dart';
import '../providers/staff_provider.dart';
import 'add_staff_screen.dart';
import 'staff_details_screen.dart';
import 'activity_log_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StaffProvider>().fetchStaff();
    });
  }

  // ============================================================
  // ADD STAFF
  // ============================================================

  Future<void> _addStaff() async {
    final provider = context.read<StaffProvider>();

    if (!provider.canAddStaff) {
      await _showUpgradeDialog();
      return;
    }

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddStaffScreen(),
      ),
    );

    if (!mounted || created != true) return;

    await provider.fetchStaff();
  }

  // ============================================================
  // UPGRADE DIALOG
  // ============================================================

  Future<void> _showUpgradeDialog() async {
    final provider = context.read<StaffProvider>();
    final limits = provider.limits;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Staff Limit Reached'),
          content: Text(
            'Aapke current plan (${limits?.plan.toUpperCase() ?? "FREE"}) me '
            'maximum ${limits?.limit ?? 1} staff members allowed hain.\n\n'
            'Zyada staff add karne ke liye apna plan upgrade karein.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              icon: const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
              ),
              label: const Text('Upgrade Plan'),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) return;

    // ✅ Navigate to Subscription Screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );

    if (!mounted) return;

    // Refresh staff list after returning
    await provider.fetchStaff();
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  void _openDetails(StaffModel staff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffDetailsScreen(staff: staff),
      ),
    );
  }

  // ============================================================
  // OPEN ACTIVITY LOG
  // ============================================================

  void _openActivityLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActivityLogScreen(),
      ),
    );
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
          'Staff Management',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Activity Log',
            onPressed: _openActivityLog,
            icon: const Icon(Icons.history_rounded),
          ),
          Consumer<StaffProvider>(
            builder: (context, provider, child) {
              return IconButton(
                tooltip: 'Refresh',
                onPressed: provider.isLoading
                    ? null
                    : provider.fetchStaff,
                icon: const Icon(Icons.refresh_rounded),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Consumer<StaffProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton.extended(
            onPressed:
                provider.isLoading ? null : _addStaff,
            backgroundColor: provider.canAddStaff
                ? null
                : Colors.grey,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Staff'),
          );
        },
      ),
      body: Consumer<StaffProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.staff.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchStaff,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                if (provider.limits != null)
                  _buildLimitsCard(
                    theme,
                    provider.limits!,
                  ),

                const SizedBox(height: 20),

                if (provider.staff.isEmpty)
                  _buildEmptyState(theme)
                else ...[
                  Text(
                    'Team Members (${provider.staff.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.staff.map(
                    (staff) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _StaffCard(
                        staff: staff,
                        onTap: () => _openDetails(staff),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // LIMITS CARD
  // ============================================================

  Widget _buildLimitsCard(
    ThemeData theme,
    StaffLimitsInfo limits,
  ) {
    final progress = limits.limit > 0
        ? limits.used / limits.limit
        : 0.0;

    final isFull = limits.remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${limits.plan.toUpperCase()} Plan',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${limits.used} / ${limits.limit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(
                isFull ? Colors.red : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isFull
                      ? 'Staff limit reached'
                      : '${limits.remaining} slot${limits.remaining == 1 ? "" : "s"} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isFull)
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SubscriptionScreen(),
                      ),
                    );
                    if (!mounted) return;
                    context.read<StaffProvider>().fetchStaff();
                  },
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 16,
                  ),
                  label: const Text('Upgrade'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: theme.colorScheme.primary
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Staff Members Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apne garage ke liye staff add karein — Manager, Mechanic, ya Accountant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _addStaff,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add First Staff'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAFF CARD
// ============================================================

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const _StaffCard({
    required this.staff,
    required this.onTap,
  });

  IconData _roleIcon() {
    switch (staff.staffRole) {
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'mechanic':
        return Icons.build_rounded;
      case 'accountant':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _roleColor() {
    switch (staff.staffRole) {
      case 'manager':
        return Colors.blue;
      case 'mechanic':
        return Colors.orange;
      case 'accountant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor();

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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    staff.initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          _roleIcon(),
                          size: 14,
                          color: roleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          staff.displayRole,
                          style: TextStyle(
                            fontSize: 12,
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      staff.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: staff.isActive
                          ? Colors.green
                              .withValues(alpha: 0.15)
                          : Colors.grey
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      staff.isActive
                          ? 'Active'
                          : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: staff.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}