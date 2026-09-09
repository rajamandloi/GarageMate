import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../services/reminder_calculator.dart';

class RemindersScreen extends StatefulWidget {
  final String? customerId;

  const RemindersScreen({
    super.key,
    this.customerId,
  });

  @override
  State<RemindersScreen> createState() =>
      _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadReminders();
    });
  }

  Future<void> _loadReminders() async {
    final provider = context.read<ReminderProvider>();

    if (widget.customerId != null &&
        widget.customerId!.isNotEmpty) {
      await provider.fetchCustomerReminders(
        widget.customerId!,
      );
    } else {
      await provider.fetchReminders();
    }
  }

  Future<void> _refresh() async {
    await _loadReminders();
  }

  void _updateReminderStatuses(
    List<Reminder> reminders,
  ) {
    for (final reminder in reminders) {
      if (reminder.status == ReminderStatus.completed ||
          reminder.status == ReminderStatus.cancelled) {
        continue;
      }

      reminder.status =
          ReminderCalculator.calculateCombinedStatus(
        dueDate: reminder.dueDate,
        currentMileage: reminder.currentMileage,
        dueMileage: reminder.dueMileage,
      );
    }
  }

  String _statusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.upcoming:
        return 'Upcoming';

      case ReminderStatus.dueSoon:
        return 'Due Soon';

      case ReminderStatus.dueToday:
        return 'Due Today';

      case ReminderStatus.overdue:
        return 'Overdue';

      case ReminderStatus.completed:
        return 'Completed';

      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(
    BuildContext context,
    ReminderStatus status,
  ) {
    final colors = Theme.of(context).colorScheme;

    switch (status) {
      case ReminderStatus.upcoming:
        return colors.primary;

      case ReminderStatus.dueSoon:
        return Colors.orange;

      case ReminderStatus.dueToday:
        return Colors.deepOrange;

      case ReminderStatus.overdue:
        return colors.error;

      case ReminderStatus.completed:
        return Colors.green;

      case ReminderStatus.cancelled:
        return colors.outline;
    }
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.service:
        return Icons.build_rounded;

      case ReminderType.payment:
        return Icons.payments_outlined;

      case ReminderType.general:
        return Icons.notifications_outlined;

      case ReminderType.specialOffer:
        return Icons.local_offer_outlined;
    }
  }

  String _dueText(Reminder reminder) {
    if (reminder.dueDate != null) {
      return reminder.formattedDueDate;
    }

    if (reminder.dueMileage != null) {
      return '${reminder.dueMileage!.toStringAsFixed(0)} km';
    }

    return 'No due date';
  }

  Future<void> _markCompleted(
    Reminder reminder,
  ) async {
    final provider = context.read<ReminderProvider>();

    final success =
        await provider.completeReminder(reminder.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder marked as completed.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                'Unable to complete reminder.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerId != null
              ? 'Customer Reminders'
              : 'Reminders',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Consumer<ReminderProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          if (provider.isLoading &&
              provider.reminders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null &&
              provider.reminders.isEmpty) {
            return _ErrorReminders(
              message: provider.error!,
              onRetry: _loadReminders,
            );
          }

          final reminders =
              provider.reminders;

          _updateReminderStatuses(reminders);

          if (reminders.isEmpty) {
            return const _EmptyReminders();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ),
              itemCount: reminders.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: 14),
              itemBuilder: (
                context,
                index,
              ) {
                final reminder =
                    reminders[index];

                return _ReminderCard(
                  reminder: reminder,
                  statusLabel:
                      _statusLabel(
                    reminder.status,
                  ),
                  statusColor:
                      _statusColor(
                    context,
                    reminder.status,
                  ),
                  icon: _typeIcon(
                    reminder.type,
                  ),
                  dueText:
                      _dueText(reminder),
                  onComplete:
                      reminder.status ==
                                  ReminderStatus
                                      .completed ||
                              reminder.status ==
                                  ReminderStatus
                                      .cancelled
                          ? null
                          : () =>
                              _markCompleted(
                                reminder,
                              ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final String dueText;
  final VoidCallback? onComplete;

  const _ReminderCard({
    required this.reminder,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.dueText,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      reminder.message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (reminder.customerName != null)
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 17,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    reminder
                        .customerDisplayName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          if (reminder.customerName != null)
            const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons
                    .calendar_today_outlined,
                size: 17,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),

              const SizedBox(width: 7),

              Text(
                dueText,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: statusColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (reminder
                      .registrationNumber !=
                  null &&
              reminder
                  .registrationNumber!
                  .isNotEmpty) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons
                      .directions_car_outlined,
                  size: 17,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),

                const SizedBox(width: 7),

                Text(
                  reminder
                      .registrationNumber!,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          if (onComplete != null) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: onComplete,
                icon: const Icon(
                  Icons
                      .check_circle_outline,
                ),
                label: const Text(
                  'Mark as Completed',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyReminders
    extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .notifications_none_rounded,
              size: 72,
              color: theme
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 18),

            const Text(
              'No reminders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Upcoming vehicle services and document reminders will appear here.',
              textAlign:
                  TextAlign.center,
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
}

class _ErrorReminders
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorReminders({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 64,
              color:
                  theme.colorScheme.error,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load reminders',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}