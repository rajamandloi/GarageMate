import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';

class MessageAutomationScreen extends StatefulWidget {
  const MessageAutomationScreen({super.key});

  @override
  State<MessageAutomationScreen> createState() =>
      _MessageAutomationScreenState();
}

class _MessageAutomationScreenState
    extends State<MessageAutomationScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _automationEnabled = true;
  bool _serviceReminders = true;
  bool _specialOffers = false;
  bool _paymentReminders = false;

  String _serviceTemplate = 'service_reminder';
  String _offerTemplate = 'special_offer';
  String _paymentTemplate = 'payment_reminder';

  int _serviceCount = 0;
  int _offerCount = 0;
  int _paymentCount = 0;

  DateTime? _lastRunAt;
  String _lastRunStatus = 'never';
  String _lastRunMessage = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSending = false;
  String? _errorMessage;

  // ============================================================
  // TEMPLATE OPTIONS
  // ============================================================

  static const List<String> _serviceTemplates = [
    'service_reminder',
    'garage_service_bill',
  ];

  static const List<String> _offerTemplates = [
    'special_offer',
  ];

  static const List<String> _paymentTemplates = [
    'payment_reminder',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ApiService.getAutomationSettings();

      if (!mounted) return;

      final settings =
          response['settings'] as Map<String, dynamic>? ?? {};

      final counts =
          response['counts'] as Map<String, dynamic>? ?? {};

      setState(() {
        _automationEnabled =
            settings['automationEnabled'] ?? true;
        _serviceReminders =
            settings['serviceRemindersEnabled'] ?? true;
        _specialOffers =
            settings['specialOffersEnabled'] ?? false;
        _paymentReminders =
            settings['paymentRemindersEnabled'] ?? false;

        _serviceTemplate = settings['serviceTemplate']
                ?.toString() ??
            'service_reminder';
        _offerTemplate =
            settings['offerTemplate']?.toString() ??
                'special_offer';
        _paymentTemplate =
            settings['paymentTemplate']?.toString() ??
                'payment_reminder';

        _serviceCount =
            (counts['serviceReminders'] as num?)?.toInt() ?? 0;
        _paymentCount =
            (counts['paymentReminders'] as num?)?.toInt() ?? 0;
        _offerCount =
            (counts['specialOffers'] as num?)?.toInt() ?? 0;

        _lastRunAt = settings['lastRunAt'] != null
            ? DateTime.tryParse(
                settings['lastRunAt'].toString(),
              )
            : null;
        _lastRunStatus =
            settings['lastRunStatus']?.toString() ?? 'never';
        _lastRunMessage =
            settings['lastRunMessage']?.toString() ?? '';

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await ApiService.updateAutomationSettings(
        automationEnabled: _automationEnabled,
        serviceRemindersEnabled: _serviceReminders,
        specialOffersEnabled: _specialOffers,
        paymentRemindersEnabled: _paymentReminders,
        serviceTemplate: _serviceTemplate,
        offerTemplate: _offerTemplate,
        paymentTemplate: _paymentTemplate,
      );

      if (!mounted) return;

      _showSnack('Settings saved successfully');
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Unable to save: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============================================================
  // SEND NOW
  // ============================================================

  Future<void> _sendNow(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send Now?'),
          content: Text(
            category == 'all'
                ? 'This will send all eligible messages right now.'
                : 'This will send all eligible "$category" messages right now.',
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
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSending = true);

    try {
      final response =
          await ApiService.sendAutomationNow(
        category: category,
      );

      if (!mounted) return;

      final sent = response['totalSent'] ?? 0;
      final failed = response['totalFailed'] ?? 0;

      _showSnack(
        failed == 0
            ? 'Sent $sent message(s) successfully'
            : 'Sent $sent, failed $failed',
        isError: failed > 0,
      );

      await _loadSettings();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Send failed: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
          'Message Automation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(theme),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // HERO
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.smart_toy_rounded,
                size: 42,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Automatic Messaging',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Messages are sent automatically daily. '
                      'You can also send them right now.',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // MASTER SWITCH
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: SwitchListTile(
            value: _automationEnabled,
            onChanged: (value) {
              setState(() => _automationEnabled = value);
            },
            title: const Text(
              'Enable Automation',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              _automationEnabled
                  ? 'Automatic messaging is enabled'
                  : 'Automatic messaging is disabled',
            ),
            secondary: Icon(
              _automationEnabled
                  ? Icons.autorenew_rounded
                  : Icons.pause_circle_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Automatic Messages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        _AutomationCard(
          icon: Icons.build_rounded,
          title: 'Service Reminders',
          subtitle:
              'Automatically remind customers when service is due.',
          enabled: _serviceReminders,
          recipients: _serviceCount,
          template: _serviceTemplate,
          templates: _serviceTemplates,
          onEnabledChanged: (value) {
            setState(() => _serviceReminders = value);
          },
          onTemplateChanged: (value) {
            if (value == null) return;
            setState(() => _serviceTemplate = value);
          },
          onSendNow: () => _sendNow('service'),
          isSending: _isSending,
        ),

        const SizedBox(height: 12),

        _AutomationCard(
          icon: Icons.local_offer_rounded,
          title: 'Special Offers',
          subtitle:
              'Send promotional offers to all customers.',
          enabled: _specialOffers,
          recipients: _offerCount,
          template: _offerTemplate,
          templates: _offerTemplates,
          onEnabledChanged: (value) {
            setState(() => _specialOffers = value);
          },
          onTemplateChanged: (value) {
            if (value == null) return;
            setState(() => _offerTemplate = value);
          },
          onSendNow: () => _sendNow('offer'),
          isSending: _isSending,
        ),

        const SizedBox(height: 12),

        _AutomationCard(
          icon: Icons.payments_rounded,
          title: 'Payment Reminders',
          subtitle:
              'Remind customers about pending payments.',
          enabled: _paymentReminders,
          recipients: _paymentCount,
          template: _paymentTemplate,
          templates: _paymentTemplates,
          onEnabledChanged: (value) {
            setState(() => _paymentReminders = value);
          },
          onTemplateChanged: (value) {
            if (value == null) return;
            setState(() => _paymentTemplate = value);
          },
          onSendNow: () => _sendNow('payment'),
          isSending: _isSending,
        ),

        const SizedBox(height: 24),

        // LAST RUN INFO
        if (_lastRunAt != null) ...[
          Text(
            'Last Automation Run',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                      _lastRunStatus == 'success'
                          ? Icons.check_circle_rounded
                          : _lastRunStatus == 'partial'
                              ? Icons.warning_amber_rounded
                              : Icons.error_rounded,
                      color: _lastRunStatus == 'success'
                          ? Colors.green
                          : _lastRunStatus == 'partial'
                              ? Colors.orange
                              : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDateTime(_lastRunAt!),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _lastRunStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _lastRunStatus == 'success'
                            ? Colors.green
                            : _lastRunStatus == 'partial'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (_lastRunMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _lastRunMessage,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // SUMMARY
        Text(
          'Eligible Recipients',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              _SummaryRow(
                title: 'Service recipients',
                value: '$_serviceCount',
              ),
              const Divider(height: 24),
              _SummaryRow(
                title: 'Offer recipients',
                value: '$_offerCount',
              ),
              const Divider(height: 24),
              _SummaryRow(
                title: 'Payment recipients',
                value: '$_paymentCount',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // SEND ALL NOW
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed:
                _isSending ? null : () => _sendNow('all'),
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _isSending
                  ? 'Sending...'
                  : 'Send All Eligible Now',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // SAVE SETTINGS
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Settings',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // INFO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Automatic messages run daily in the background. '
                  'Use "Send Now" to trigger them immediately.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }
}

// ============================================================
// AUTOMATION CARD
// ============================================================

class _AutomationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final int recipients;
  final String template;
  final List<String> templates;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String?> onTemplateChanged;
  final VoidCallback onSendNow;
  final bool isSending;

  const _AutomationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.recipients,
    required this.template,
    required this.templates,
    required this.onEnabledChanged,
    required this.onTemplateChanged,
    required this.onSendNow,
    required this.isSending,
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
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
                        fontSize: 16,
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
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$recipients customers eligible',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: templates.contains(template)
                ? template
                : templates.first,
            decoration: const InputDecoration(
              labelText: 'Message Template',
              prefixIcon: Icon(Icons.message_outlined),
            ),
            items: templates
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: enabled ? onTemplateChanged : null,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (enabled && !isSending)
                  ? onSendNow
                  : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFF25D366),
                side: const BorderSide(
                  color: Color(0xFF25D366),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY ROW
// ============================================================

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}