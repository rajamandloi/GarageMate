import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../models/subscription_usage.dart';
import '../providers/subscription_provider.dart';
import '../../../core/utils/phone_helper.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends State<SubscriptionScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoadingPlans = true;
  String? _plansError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      context.read<SubscriptionProvider>().fetchUsage(),
      _loadPlans(),
    ]);
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final response = await ApiService.getSubscriptionPlans();

      final list = response['plans'] as List? ?? [];

      setState(() {
        _plans = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _plansError =
            e.toString().replaceAll('Exception: ', '');
        _isLoadingPlans = false;
      });
    }
  }

  // ============================================================
  // START TRIAL
  // ============================================================

  Future<void> _startTrial() async {
    final provider = context.read<SubscriptionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start Free Trial?'),
          content: const Text(
            'Get 14 days of Pro features + 100 WhatsApp messages. '
            'After trial ends, you will return to Free plan.',
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
              child: const Text('Start Trial'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await provider.startTrial();

    if (!mounted) return;

    if (success) {
      _showSnack(
        '🎉 Trial started! Enjoy Pro features for 14 days.',
      );
    } else {
      _showSnack(
        provider.error ?? 'Unable to start trial',
        isError: true,
      );
    }
  }

    // ============================================================
  // REQUEST UPGRADE (manual + WhatsApp)
  // ============================================================

  Future<void> _requestUpgrade(String planName) async {
    final provider = context.read<SubscriptionProvider>();

    // ----------------------------------------------------------
    // 1. Log request to backend
    // ----------------------------------------------------------
    final success = await provider.requestUpgrade(
      plan: planName,
    );

    if (!mounted) return;

    if (!success) {
      _showSnack(
        provider.error ?? 'Unable to submit request',
        isError: true,
      );
      return;
    }

    _showSnack(
      '✅ Request submitted! Opening WhatsApp...',
    );

    // ----------------------------------------------------------
    // 2. Open WhatsApp chat
    // ----------------------------------------------------------
    await _contactOnWhatsApp(planName);
  }

    // ============================================================
  // CONTACT ON WHATSAPP (using helper)
  // ============================================================

  Future<void> _contactOnWhatsApp(String planName) async {
    // Admin number — sirf 10 digit (helper 91 laga dega)
    const adminPhone = '8889353432';

    final planLabel = planName == 'pro'
        ? 'Pro (₹199/month)'
        : planName == 'business'
            ? 'Business (₹499/month)'
            : planName == 'founder'
                ? "Founder's Plan (₹149/month)"
                : planName;

    final usage =
        context.read<SubscriptionProvider>().usage;

    final message = '''
Hello GarageMate Team,

I want to upgrade my subscription.

📦 Plan: $planLabel
🏢 Current Plan: ${usage?.planDisplayName ?? 'Free'}

Please guide me on the next steps for payment.
''';

    // ✅ Use helper
    final url = PhoneHelper.buildWhatsAppUrl(
      phone: adminPhone,
      message: message,
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showSnack(
          'Unable to open WhatsApp. Please install WhatsApp.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Unable to open WhatsApp: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _planDisplayName(String plan) {
    switch (plan) {
      case 'pro':
        return 'Pro';
      case 'business':
        return 'Business';
      case 'founder':
        return "Founder's Plan";
      default:
        return 'Free';
    }
  }

  String _planPriceText(String plan) {
    switch (plan) {
      case 'pro':
        return '₹199 / month';
      case 'business':
        return '₹499 / month';
      case 'founder':
        return '₹149 / month (locked forever)';
      default:
        return 'Free forever';
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscription',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: _init,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ),
              children: [
                // CURRENT PLAN
                if (provider.usage != null)
                  _buildCurrentPlan(provider.usage!),

                const SizedBox(height: 24),

                // TRIAL BANNER (if eligible)
                if (provider.usage != null &&
                    provider.usage!.canStartTrial)
                  _buildTrialBanner(),

                const SizedBox(height: 24),

                // PLANS
                Text(
                  'Choose Your Plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 12),

                if (_isLoadingPlans)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_plansError != null)
                  _buildPlansError()
                else
                  ..._plans.map(_buildPlanCard).toList(),

                const SizedBox(height: 24),

                // INFO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payment is manual for now. '
                          'After paying, submit the upgrade request — '
                          'our team will activate within 24 hours.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
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
        },
      ),
    );
  }

  // ============================================================
  // CURRENT PLAN CARD
  // ============================================================

  Widget _buildCurrentPlan(SubscriptionUsage usage) {
    final theme = Theme.of(context);

    final progressValue = usage.whatsappLimit > 0
        ? (usage.whatsappUsed / usage.whatsappLimit)
            .clamp(0.0, 1.0)
        : 0.0;

    final progressColor = usage.whatsappPercentage >= 100
        ? theme.colorScheme.error
        : usage.whatsappPercentage >= 80
            ? Colors.orange
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(
              alpha: 0.5,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  usage.isTrial
                      ? 'PRO TRIAL'
                      : usage.planDisplayName.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (usage.planPrice > 0)
                Text(
                  '₹${usage.planPrice}/mo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            usage.isTrial
                ? 'Pro Trial Active'
                : '${usage.planDisplayName} Plan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          if (usage.isTrial && usage.trialEndsAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ends on ${_formatDate(usage.trialEndsAt!)}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (usage.isFounderPlan) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  'Founder — price locked forever',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // WhatsApp usage
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'WhatsApp Messages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${usage.whatsappUsed} / ${usage.whatsappLimit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(
                progressColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            usage.hasReachedLimit
                ? '⚠️ Limit reached! Upgrade to send more.'
                : '${usage.whatsappRemaining} messages remaining this month',
            style: TextStyle(
              fontSize: 12,
              color: usage.hasReachedLimit
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRIAL BANNER
  // ============================================================

  Widget _buildTrialBanner() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Try Pro Free for 14 Days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '100 WhatsApp messages + all Pro features',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _startTrial,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF128C7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Start Free Trial',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PLAN CARD
  // ============================================================

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);

    final planName = plan['name']?.toString() ?? '';
    final displayName =
        plan['displayName']?.toString() ?? 'Plan';
    final price = (plan['priceInr'] as num?)?.toInt() ?? 0;
    final popular = plan['popular'] == true;
    final features = (plan['features'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final currentUsage = context.watch<SubscriptionProvider>().usage;
    final isCurrentPlan = currentUsage != null &&
        currentUsage.plan == planName &&
        !currentUsage.isTrial;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: popular
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: popular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (popular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Price
          Text(
            price == 0 ? 'Free' : '₹$price',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),

          if (price > 0)
            Text(
              'per month',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 14),

          // Features
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action button
          if (isCurrentPlan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Current Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else if (price > 0)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => _requestUpgrade(planName),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Upgrade to $displayName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PLANS ERROR
  // ============================================================

  Widget _buildPlansError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          Text(
            _plansError!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadPlans,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}