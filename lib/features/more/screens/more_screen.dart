import 'package:flutter/material.dart';

//import '../../reminders/screens/automation_screen.dart';
import '../../messages/screens/message_templates_screen.dart';
import '../../messages/screens/message_automation_screen.dart';


class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _MoreCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Message Automation',
            subtitle:
                'Automatically manage service reminders and special offers.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessageAutomationScreen(
                    customers: [],
                    services: [],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

_MoreCard(
  icon: Icons.message_outlined,
  title: 'Message Templates',
  subtitle:
      'Create and manage WhatsApp reminder and offer messages.',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MessageTemplatesScreen(),
      ),
    );
  },
),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreCard({
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
    );
  }
}