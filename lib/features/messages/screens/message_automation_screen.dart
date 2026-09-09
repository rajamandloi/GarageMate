import 'package:flutter/material.dart';
import '../../customers/models/customer.dart';
import '../../services/models/service_record.dart';
import '../services/automation_service.dart';

class MessageAutomationScreen extends StatefulWidget {
  final List<Customer> customers;
  final List<ServiceRecord> services;

  const MessageAutomationScreen({
    super.key,
    required this.customers,
    required this.services,
  });

  @override
  State<MessageAutomationScreen> createState() =>
      _MessageAutomationScreenState();
}

class _MessageAutomationScreenState
    extends State<MessageAutomationScreen> {
  bool _automationEnabled = true;
  bool _serviceReminders = true;
  bool _specialOffers = false;
  bool _paymentReminders = false;

  String _serviceTemplate = 'Service Reminder';
  String _offerTemplate = 'Special Offer';
  String _paymentTemplate = 'Payment Reminder';

  List<Customer> get _serviceRecipients =>
    AutomationService.getServiceReminderRecipients(
      customers: widget.customers,
    );

List<Customer> get _offerRecipients =>
    AutomationService.getSpecialOfferRecipients(
      customers: widget.customers,
    );

List<ServiceRecord> get _paymentRecipients =>
    AutomationService.getPaymentReminderRecipients(
      services: widget.services,
    );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Message Automation',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ),
        children: [
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        'Messages will be prepared automatically '
                        'for eligible customers.',
                        style: TextStyle(
                          color: theme.colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                setState(() {
                  _automationEnabled = value;
                });
              },
              title: const Text(
                'Enable Automation',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
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
                'Automatically remind customers when their service is due.',
            enabled: _serviceReminders,
            recipients: _serviceRecipients.length,
            template: _serviceTemplate,
            templates: const [
              'Service Reminder',
              'Service Due Today',
            ],
            onEnabledChanged: (value) {
              setState(() {
                _serviceReminders = value;
              });
            },
            onTemplateChanged: (value) {
              if (value == null) return;

              setState(() {
                _serviceTemplate = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _AutomationCard(
            icon: Icons.local_offer_rounded,
            title: 'Special Offers',
            subtitle:
                'Send promotional offers automatically to eligible customers.',
            enabled: _specialOffers,
            recipients: _offerRecipients.length,
            template: _offerTemplate,
            templates: const [
              'Special Offer',
              'Festival Offer',
            ],
            onEnabledChanged: (value) {
              setState(() {
                _specialOffers = value;
              });
            },
            onTemplateChanged: (value) {
              if (value == null) return;

              setState(() {
                _offerTemplate = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _AutomationCard(
            icon: Icons.payments_rounded,
            title: 'Payment Reminders',
            subtitle:
                'Remind customers about pending service payments.',
            enabled: _paymentReminders,
            recipients: _paymentRecipients.length,
            template: _paymentTemplate,
            templates: const [
              'Payment Reminder',
              'Payment Due',
            ],
            onEnabledChanged: (value) {
              setState(() {
                _paymentReminders = value;
              });
            },
            onTemplateChanged: (value) {
              if (value == null) return;

              setState(() {
                _paymentTemplate = value;
              });
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Automation Summary',
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
                  value: '${_serviceRecipients.length}',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  title: 'Offer recipients',
                  value: '${_offerRecipients.length}',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  title: 'Payment recipients',
                  value: '${_paymentRecipients.length}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                    'The app will identify eligible customers '
                    'automatically. You will not need to select '
                    'customers one by one.',
                    style: TextStyle(
                      color: theme.colorScheme
                          .onSurfaceVariant,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                        color: theme.colorScheme
                            .onSurfaceVariant,
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
            initialValue: template,
            decoration: const InputDecoration(
              labelText: 'Message Template',
              prefixIcon:
                  Icon(Icons.message_outlined),
            ),
            items: templates
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged:
                enabled ? onTemplateChanged : null,
          ),
        ],
      ),
    );
  }
}

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
              color:
                  theme.colorScheme.onSurfaceVariant,
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