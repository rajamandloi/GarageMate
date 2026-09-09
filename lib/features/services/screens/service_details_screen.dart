import 'package:flutter/material.dart';

import '../models/service_record.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceRecord service;
  final String customerName;

  final String? registrationNumber;
  final String? vehicleBrand;
  final String? vehicleModel;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceDetailsScreen({
    super.key,
    required this.service,
    required this.customerName,
    this.registrationNumber,
    this.vehicleBrand,
    this.vehicleModel,
    required this.onEdit,
    required this.onDelete,
  });

  String _statusText() {
    switch (service.paymentStatus) {
      case PaymentStatus.paid:
        return 'Paid';

      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';

      case PaymentStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(BuildContext context) {
    switch (service.paymentStatus) {
      case PaymentStatus.paid:
        return Theme.of(context).colorScheme.primary;

      case PaymentStatus.partiallyPaid:
        return Colors.orange;

      case PaymentStatus.pending:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _vehicleText() {
    final parts = <String>[];

    if (registrationNumber != null &&
        registrationNumber!.trim().isNotEmpty) {
      parts.add(registrationNumber!.trim());
    }

    final vehicleName = [
      if (vehicleBrand != null &&
          vehicleBrand!.trim().isNotEmpty)
        vehicleBrand!.trim(),
      if (vehicleModel != null &&
          vehicleModel!.trim().isNotEmpty)
        vehicleModel!.trim(),
    ].join(' ');

    if (vehicleName.isNotEmpty) {
      parts.add(vehicleName);
    }

    if (parts.isEmpty) {
      return 'Vehicle information not available';
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.build_circle_rounded,
                  size: 58,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  service.serviceType,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(service.serviceDate),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _statusText(),
                    style: TextStyle(
                      color: _statusColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total',
                  value:
                      '₹${service.totalAmount.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Pending',
                  value:
                      '₹${service.pendingAmount.toStringAsFixed(0)}',
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'Customer & Vehicle',
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                title: 'Customer',
                value: customerName,
              ),
              _InfoRow(
                icon: Icons.directions_car_outlined,
                title: 'Vehicle',
                value: _vehicleText(),
              ),
              _InfoRow(
                icon: Icons.speed_rounded,
                title: 'Mileage',
                value:
                    '${service.mileage.toStringAsFixed(0)} km',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Service Information',
            children: [
              _InfoRow(
                icon: Icons.build_outlined,
                title: 'Service Type',
                value: service.serviceType,
              ),
              if (service.description.isNotEmpty)
                _InfoRow(
                  icon: Icons.description_outlined,
                  title: 'Description',
                  value: service.description,
                ),
              if (service.partsUsed.isNotEmpty)
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Parts Used',
                  value: service.partsUsed,
                ),
              if (service.mechanic.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Mechanic',
                  value: service.mechanic,
                ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Cost Breakdown',
            children: [
              _AmountRow(
                title: 'Labor Cost',
                amount: service.laborCost,
              ),
              _AmountRow(
                title: 'Parts Cost',
                amount: service.partsCost,
              ),
              _AmountRow(
                title: 'Discount',
                amount: -service.discount,
              ),
              _AmountRow(
                title: 'Tax',
                amount: service.tax,
              ),
              const Divider(height: 24),
              _AmountRow(
                title: 'Grand Total',
                amount: service.totalAmount,
                bold: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Payment',
            children: [
              _InfoRow(
                icon: Icons.payments_outlined,
                title: 'Paid Amount',
                value:
                    '₹${service.paidAmount.toStringAsFixed(0)}',
              ),
              _InfoRow(
                icon:
                    Icons.account_balance_wallet_outlined,
                title: 'Pending Amount',
                value:
                    '₹${service.pendingAmount.toStringAsFixed(0)}',
              ),
              _InfoRow(
                icon: Icons.payment_outlined,
                title: 'Payment Method',
                value: service.paymentMethod,
              ),
              _InfoRow(
                icon: Icons.verified_outlined,
                title: 'Payment Status',
                value: _statusText(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Next Service',
            children: [
              _InfoRow(
                icon: Icons.event_available_outlined,
                title: 'Next Service Date',
                value:
                    _formatDate(service.nextServiceDate),
              ),
              if (service.nextServiceMileage != null)
                _InfoRow(
                  icon: Icons.speed_rounded,
                  title: 'Next Service Mileage',
                  value:
                      '${service.nextServiceMileage!.toStringAsFixed(0)} km',
                ),
            ],
          ),

          if (service.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Notes',
              children: [
                Text(
                  service.notes,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
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
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

class _AmountRow extends StatelessWidget {
  final String title;
  final double amount;
  final bool bold;

  const _AmountRow({
    required this.title,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.w800 : null,
              fontSize: bold ? 17 : null,
            ),
          ),
        ],
      ),
    );
  }
}