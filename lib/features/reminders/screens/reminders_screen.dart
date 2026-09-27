import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';

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
  // ==========================================================
  // MULTI-SELECT MODE
  // ==========================================================

  bool _selectionMode = false;
  final Set<String> _selectedReminderIds = {};

  List<Reminder> _visibleReminders = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadReminders();
    });
  }

  // ==========================================================
  // LOAD REMINDERS
  // ==========================================================

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

  // ==========================================================
  // STATUS UPDATE
  // ==========================================================

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

  // ==========================================================
  // HELPERS
  // ==========================================================

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

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // MARK COMPLETED
  // ==========================================================

  Future<void> _markCompleted(
    Reminder reminder,
  ) async {
    final provider = context.read<ReminderProvider>();

    final success =
        await provider.completeReminder(reminder.id);

    if (!mounted) return;

    if (success) {
      _showSnack('Reminder marked as completed.');
    } else {
      _showSnack(
        provider.error ?? 'Unable to complete reminder.',
        isError: true,
      );
    }
  }

  // ==========================================================
  // SINGLE DELETE
  // ==========================================================

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await _confirmDelete(
      title: 'Delete Reminder?',
      message:
          'Are you sure you want to delete "${reminder.title}"? '
          'This action cannot be undone.',
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.delete('/reminders/${reminder.id}');

      if (!mounted) return;

      _showSnack('Reminder deleted successfully');

      _selectedReminderIds.remove(reminder.id);
      if (_selectedReminderIds.isEmpty) {
        _selectionMode = false;
      }

      await _loadReminders();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Unable to delete reminder: '
        '${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // ==========================================================
  // BULK DELETE
  // ==========================================================

  Future<void> _bulkDeleteSelected() async {
    if (_selectedReminderIds.isEmpty) {
      _showSnack('No reminders selected', isError: true);
      return;
    }

    final count = _selectedReminderIds.length;

    final confirmed = await _confirmDelete(
      title: 'Delete $count Reminder${count == 1 ? '' : 's'}?',
      message:
          'Are you sure you want to delete $count reminder${count == 1 ? '' : 's'}? '
          'This action cannot be undone.',
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await ApiService.post(
        '/reminders/bulk-delete',
        {
          'ids': _selectedReminderIds.toList(),
        },
      );

      if (!mounted) return;

      final deleted = response['deletedCount'] ?? count;

      _showSnack('$deleted reminder(s) deleted');

      setState(() {
        _selectedReminderIds.clear();
        _selectionMode = false;
      });

      await _loadReminders();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Unable to delete: '
        '${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // ==========================================================
  // DELETE ALL COMPLETED
  // ==========================================================

  Future<void> _deleteCompletedReminders() async {
    final confirmed = await _confirmDelete(
      title: 'Delete Completed Reminders?',
      message:
          'This will permanently delete all completed and cancelled reminders.',
    );

    if (confirmed != true || !mounted) return;

    try {
      final response =
          await ApiService.delete('/reminders/completed');

      if (!mounted) return;

      final deleted = response['deletedCount'] ?? 0;

      _showSnack('$deleted completed reminder(s) deleted');

      await _loadReminders();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Unable to delete: '
        '${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // ==========================================================
  // CONFIRM DELETE DIALOG
  // ==========================================================

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SELECTION MODE
  // ==========================================================

  void _enterSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedReminderIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedReminderIds.clear();
    });
  }

  void _toggleReminderSelection(String id) {
    if (id.isEmpty) return;

    setState(() {
      if (_selectedReminderIds.contains(id)) {
        _selectedReminderIds.remove(id);
      } else {
        _selectedReminderIds.add(id);
      }
    });
  }

  void _selectAllVisible() {
    setState(() {
      for (final r in _visibleReminders) {
        if (r.id.isNotEmpty) {
          _selectedReminderIds.add(r.id);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedReminderIds.clear();
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_selectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _selectionMode
              ? Text(
                  '${_selectedReminderIds.length} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Text(
                  widget.customerId != null
                      ? 'Customer Reminders'
                      : 'Reminders',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          leading: _selectionMode
              ? IconButton(
                  onPressed: _exitSelectionMode,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cancel',
                )
              : null,
          actions: [
            if (_selectionMode) ...[
              // Select All / Clear
              IconButton(
                onPressed: _selectedReminderIds.length ==
                        _visibleReminders.length
                    ? _clearSelection
                    : _selectAllVisible,
                icon: Icon(
                  _selectedReminderIds.length ==
                          _visibleReminders.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                tooltip:
                    _selectedReminderIds.length ==
                            _visibleReminders.length
                        ? 'Clear'
                        : 'Select All',
              ),
            ] else ...[
              // Refresh
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
              ),

              // 3-dot menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'bulk') {
                    _enterSelectionMode();
                  } else if (value == 'clean') {
                    _deleteCompletedReminders();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'bulk',
                    child: Row(
                      children: [
                        Icon(Icons.checklist_rounded),
                        SizedBox(width: 10),
                        Text('Select Multiple'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clean',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded),
                        SizedBox(width: 10),
                        Text('Delete Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
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

            final reminders = provider.reminders;

            _updateReminderStatuses(reminders);

            // Store for Select All
            _visibleReminders = reminders;

            if (reminders.isEmpty) {
              return const _EmptyReminders();
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  _selectionMode ? 140 : 100,
                ),
                itemCount: reminders.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];

                  final isSelected =
                      _selectedReminderIds.contains(
                    reminder.id,
                  );

                  return _ReminderCard(
                    reminder: reminder,
                    statusLabel: _statusLabel(
                      reminder.status,
                    ),
                    statusColor: _statusColor(
                      context,
                      reminder.status,
                    ),
                    icon: _typeIcon(reminder.type),
                    dueText: _dueText(reminder),
                    selectionMode: _selectionMode,
                    isSelected: isSelected,
                    onSelectToggle: () {
                      _toggleReminderSelection(reminder.id);
                    },
                    onTap: () {
                      if (_selectionMode) {
                        _toggleReminderSelection(
                          reminder.id,
                        );
                      }
                    },
                    onLongPress: () {
                      if (!_selectionMode) {
                        _showReminderActions(
                          context,
                          reminder,
                        );
                      }
                    },
                    onComplete: reminder.status ==
                                ReminderStatus.completed ||
                            reminder.status ==
                                ReminderStatus.cancelled
                        ? null
                        : () => _markCompleted(reminder),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: _selectionMode
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    12,
                  ),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _selectedReminderIds.isEmpty
                          ? null
                          : _bulkDeleteSelected,
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                      ),
                      label: Text(
                        _selectedReminderIds.isEmpty
                            ? 'Select reminders to delete'
                            : 'Delete ${_selectedReminderIds.length} Reminder${_selectedReminderIds.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                        foregroundColor:
                            Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ==========================================================
  // LONG PRESS ACTION MENU
  // ==========================================================

  void _showReminderActions(
    BuildContext context,
    Reminder reminder,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReminderDetails(reminder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Mark as Completed'),
                enabled:
                    reminder.status != ReminderStatus.completed &&
                        reminder.status !=
                            ReminderStatus.cancelled,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _markCompleted(reminder);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete Reminder',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteReminder(reminder);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // REMINDER DETAILS SHEET
  // ==========================================================

  void _showReminderDetails(Reminder reminder) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final statusColor =
            _statusColor(sheetContext, reminder.status);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _typeIcon(reminder.type),
                        color: statusColor,
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
                            style: theme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(reminder.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (reminder.message.isNotEmpty) ...[
                  Text(
                    'Message',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme
                          .colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(reminder.message),
                  ),
                  const SizedBox(height: 16),
                ],

                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: _dueText(reminder),
                ),

                if (reminder.customerName != null)
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Customer',
                    value: reminder.customerDisplayName,
                  ),

                if (reminder.registrationNumber != null &&
                    reminder.registrationNumber!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value: reminder.registrationNumber!,
                  ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _deleteReminder(reminder);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                        ),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REMINDER CARD
// ============================================================

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final String dueText;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const _ReminderCard({
    required this.reminder,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.dueText,
    required this.onComplete,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor =
        selectionMode && isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: selectionMode && isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectionMode) ...[
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) =>
                            onSelectToggle?.call(),
                        activeColor:
                            theme.colorScheme.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

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
                      color: theme.colorScheme.primary,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          reminder.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                        reminder.customerDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              if (reminder.customerName != null)
                const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    dueText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              if (reminder.registrationNumber != null &&
                  reminder.registrationNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 17,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      reminder.registrationNumber!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              if (!selectionMode && onComplete != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(
                      Icons.check_circle_outline,
                    ),
                    label:
                        const Text('Mark as Completed'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY REMINDERS
// ============================================================

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'No reminders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upcoming vehicle services and document reminders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR REMINDERS
// ============================================================

class _ErrorReminders extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorReminders({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load reminders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}