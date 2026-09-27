import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';

class UsageBanner extends StatelessWidget {
  const UsageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final usage = provider.usage;

        // Don't show until loaded
        if (usage == null) {
          return const SizedBox.shrink();
        }

        // Don't show if plenty remaining
        if (!usage.hasReachedLimit &&
            !usage.isNearLimit) {
          return const SizedBox.shrink();
        }

        return _buildBanner(context, usage);
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    dynamic usage,
  ) {
    final theme = Theme.of(context);

    final isLimitReached = usage.hasReachedLimit as bool;

    final bgColor = isLimitReached
        ? theme.colorScheme.errorContainer
        : Colors.orange.shade100;

    final fgColor = isLimitReached
        ? theme.colorScheme.error
        : Colors.orange.shade900;

    final icon = isLimitReached
        ? Icons.error_rounded
        : Icons.warning_amber_rounded;

    final title = isLimitReached
        ? 'WhatsApp limit reached'
        : 'Almost out of WhatsApp messages';

    final subtitle = isLimitReached
        ? 'You have used ${usage.whatsappUsed}/${usage.whatsappLimit} messages. Upgrade to send more.'
        : 'Only ${usage.whatsappRemaining} messages left this month.';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: fgColor.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SubscriptionScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: fgColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}