import 'package:flutter/material.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  bool _serviceReminders = true;
  bool _specialOffers = false;
  bool _paymentReminders = false;

  int _daysBeforeService = 3;
  int _daysBeforeOffer = 7;

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                  Icons.auto_awesome_rounded,
                  size: 34,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'GarageMate will identify eligible customers automatically.',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Automation Rules',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          _AutomationCard(
            icon: Icons.build_rounded,
            title: 'Service Reminders',
            subtitle:
                'Automatically remind customers when their service is due.',
            value: _serviceReminders,
            onChanged: (value) {
              setState(() {
                _serviceReminders = value;
              });
            },
          ),

          if (_serviceReminders) ...[
            const SizedBox(height: 8),
            _DaysSelector(
              title: 'Send reminder before service',
              value: _daysBeforeService,
              onChanged: (value) {
                setState(() {
                  _daysBeforeService = value;
                });
              },
            ),
          ],

          const SizedBox(height: 14),

          _AutomationCard(
            icon: Icons.local_offer_outlined,
            title: 'Special Offers',
            subtitle:
                'Automatically send offers to eligible customers.',
            value: _specialOffers,
            onChanged: (value) {
              setState(() {
                _specialOffers = value;
              });
            },
          ),

          if (_specialOffers) ...[
            const SizedBox(height: 8),
            _DaysSelector(
              title: 'Offer campaign interval',
              value: _daysBeforeOffer,
              onChanged: (value) {
                setState(() {
                  _daysBeforeOffer = value;
                });
              },
            ),
          ],

          const SizedBox(height: 14),

          _AutomationCard(
            icon: Icons.payments_outlined,
            title: 'Payment Reminders',
            subtitle:
                'Automatically remind customers about pending payments.',
            value: _paymentReminders,
            onChanged: (value) {
              setState(() {
                _paymentReminders = value;
              });
            },
          ),

          const SizedBox(height: 28),

          const Text(
            'How it works',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          _InfoCard(
            number: '1',
            title: 'Find customers automatically',
            text:
                'GarageMate checks customer vehicles and service records.',
          ),

          const SizedBox(height: 10),

          _InfoCard(
            number: '2',
            title: 'Select the right message',
            text:
                'The appropriate message template is selected according to the reminder type.',
          ),

          const SizedBox(height: 10),

          _InfoCard(
            number: '3',
            title: 'Send automatically',
            text:
                'The connected WhatsApp service sends the message without requiring manual selection of every customer.',
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Automation settings saved.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Automation Settings'),
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
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AutomationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DaysSelector extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  const _DaysSelector({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('1 day'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text('3 days'),
              ),
              DropdownMenuItem(
                value: 5,
                child: Text('5 days'),
              ),
              DropdownMenuItem(
                value: 7,
                child: Text('7 days'),
              ),
              DropdownMenuItem(
                value: 15,
                child: Text('15 days'),
              ),
            ],
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _InfoCard({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  text,
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
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