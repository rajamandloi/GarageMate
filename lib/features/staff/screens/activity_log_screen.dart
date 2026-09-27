import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity_log_model.dart';
import '../providers/staff_provider.dart';

class ActivityLogScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ActivityLogScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<ActivityLogScreen> createState() =>
      _ActivityLogScreenState();
}

class _ActivityLogScreenState
    extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<StaffProvider>()
          .fetchActivityLog(userId: widget.userId);
    });
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // ACTION ICON
  // ============================================================

  IconData _actionIcon(String action) {
    if (action.contains('create')) {
      return Icons.add_circle_rounded;
    }
    if (action.contains('delete') ||
        action.contains('remove')) {
      return Icons.delete_rounded;
    }
    if (action.contains('update') ||
        action.contains('change')) {
      return Icons.edit_rounded;
    }
    if (action.contains('activate')) {
      return Icons.check_circle_rounded;
    }
    if (action.contains('deactivate')) {
      return Icons.block_rounded;
    }
    return Icons.history_rounded;
  }

  Color _actionColor(String action) {
    if (action.contains('create')) return Colors.green;
    if (action.contains('delete') ||
        action.contains('remove')) {
      return Colors.red;
    }
    if (action.contains('update') ||
        action.contains('change')) {
      return Colors.orange;
    }
    if (action.contains('activate')) return Colors.blue;
    if (action.contains('deactivate')) return Colors.grey;
    return Colors.purple;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName != null
              ? '${widget.userName}\'s Activity'
              : 'Activity Log',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Consumer<StaffProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.fetchActivityLog(
                          userId: widget.userId,
                        ),
                icon: const Icon(Icons.refresh_rounded),
              );
            },
          ),
        ],
      ),
      body: Consumer<StaffProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading &&
              provider.activityLog.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.activityLog.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 72,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Activity Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activity log yahan dikhega.',
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchActivityLog(
              userId: widget.userId,
            ),
            child: ListView.separated(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 40),
              itemCount: provider.activityLog.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = provider.activityLog[index];

                return _ActivityCard(
                  log: log,
                  timeText: _formatTime(log.createdAt),
                  icon: _actionIcon(log.action),
                  color: _actionColor(log.action),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ACTIVITY CARD
// ============================================================

class _ActivityCard extends StatelessWidget {
  final ActivityLogModel log;
  final String timeText;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.log,
    required this.timeText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.description.isNotEmpty
                      ? log.description
                      : log.action,
                  style: const TextStyle(fontSize: 13),
                ),
                if (log.entity.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.entity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}