import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';

import '../../customers/providers/customer_provider.dart';
//import '../../customers/models/customer.dart';

import '../../services/screens/add_service_screen.dart';
import '../../services/screens/services_screen.dart';

import '../../reminders/screens/reminders_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _addService(BuildContext context) async {
    final customerProvider =
        context.read<CustomerProvider>();

    final vehicleProvider =
        context.read<VehicleProvider>();

    // Make sure latest data is available.
    if (customerProvider.customers.isEmpty) {
      await customerProvider.fetchCustomers();
    }

    if (vehicleProvider.vehicles.isEmpty) {
      await vehicleProvider.fetchVehicles();
    }

    if (!context.mounted) return;

    final customers = customerProvider.customers;
    final vehicles = vehicleProvider.vehicles;

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No customers available. Please add a customer first.',
          ),
        ),
      );
      return;
    }

    final selectedCustomer = customers.firstWhere(
      (customer) => customer.id == vehicle.customerId,
      orElse: () => customers.first,
    );

    final customerVehicles = vehicles
        .where(
          (item) =>
              item.customerId == selectedCustomer.id,
        )
        .toList();

    if (customerVehicles.isEmpty) {
      customerVehicles.add(vehicle);
    } else if (!customerVehicles.any(
      (item) => item.id == vehicle.id,
    )) {
      customerVehicles.add(vehicle);
    }

    final service = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          customers: customers,
          vehicles: customerVehicles,
        ),
      ),
    );

    if (!context.mounted) return;

    if (service != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Service added successfully.',
          ),
        ),
      );
    }
  }

  void _openServiceHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesScreen(),
      ),
    );
  }

  void _openReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RemindersScreen(),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not added';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;

    final today = DateTime.now();

    final expiry = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final current = DateTime(
      today.year,
      today.month,
      today.day,
    );

    return expiry.isBefore(current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final insuranceExpired =
        _isExpired(vehicle.insuranceExpiry);

    final pucExpired =
        _isExpired(vehicle.pucExpiry);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Vehicle',
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Delete Vehicle',
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
          // --------------------------------------------------
          // VEHICLE HEADER
          // --------------------------------------------------

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: 46,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  vehicle.registrationNumber,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (vehicle.variant.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    vehicle.variant,
                    style:
                        theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------
          // QUICK METRICS
          // --------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Mileage',
                  value:
                      '${vehicle.currentMileage.toStringAsFixed(0)} km',
                  icon: Icons.speed_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _MetricCard(
                  title: 'Fuel',
                  value: vehicle.fuelType,
                  icon:
                      Icons.local_gas_station_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------
          // OWNER
          // --------------------------------------------------

          _SectionCard(
            title: 'Owner Information',
            children: [
              if (vehicle.customerName != null &&
                  vehicle.customerName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Customer',
                  value: vehicle.customerName!,
                ),

              if (vehicle.customerPhone != null &&
                  vehicle.customerPhone!.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: vehicle.customerPhone!,
                ),

              if (vehicle.customerEmail != null &&
                  vehicle.customerEmail!.isNotEmpty)
                _InfoRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: vehicle.customerEmail!,
                ),

              if (vehicle.customerAddress != null &&
                  vehicle.customerAddress!.isNotEmpty)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: vehicle.customerAddress!,
                ),

              if (vehicle.customerName == null &&
                  vehicle.customerPhone == null &&
                  vehicle.customerEmail == null &&
                  vehicle.customerAddress == null)
                const _EmptyInfo(
                  message:
                      'Customer information not available.',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // VEHICLE INFORMATION
          // --------------------------------------------------

          _SectionCard(
            title: 'Vehicle Information',
            children: [
              _InfoRow(
                icon:
                    Icons.confirmation_number_outlined,
                title: 'Registration',
                value:
                    vehicle.registrationNumber,
              ),

              _InfoRow(
                icon:
                    Icons.directions_car_outlined,
                title: 'Brand',
                value: vehicle.brand,
              ),

              _InfoRow(
                icon:
                    Icons.car_repair_outlined,
                title: 'Model',
                value: vehicle.model,
              ),

              if (vehicle.variant.isNotEmpty)
                _InfoRow(
                  icon: Icons.tune_rounded,
                  title: 'Variant',
                  value: vehicle.variant,
                ),

              if (vehicle.manufacturingYear
                  .isNotEmpty)
                _InfoRow(
                  icon:
                      Icons.calendar_today_outlined,
                  title: 'Manufacturing Year',
                  value:
                      vehicle.manufacturingYear,
                ),

              _InfoRow(
                icon:
                    Icons.local_gas_station_outlined,
                title: 'Fuel Type',
                value: vehicle.fuelType,
              ),

              _InfoRow(
                icon: Icons.speed_rounded,
                title: 'Current Mileage',
                value:
                    '${vehicle.currentMileage.toStringAsFixed(0)} km',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // IDENTIFICATION
          // --------------------------------------------------

          _SectionCard(
            title: 'Identification',
            children: [
              _InfoRow(
                icon: Icons.qr_code_2_rounded,
                title: 'VIN / Chassis',
                value: vehicle.vin.isEmpty
                    ? 'Not added'
                    : vehicle.vin,
              ),

              _InfoRow(
                icon: Icons.settings_outlined,
                title: 'Engine Number',
                value:
                    vehicle.engineNumber.isEmpty
                        ? 'Not added'
                        : vehicle.engineNumber,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // DOCUMENTS
          // --------------------------------------------------

          _SectionCard(
            title: 'Documents & Expiry',
            children: [
              _ExpiryRow(
                title: 'Insurance',
                date: vehicle.insuranceExpiry,
                expired: insuranceExpired,
              ),

              _ExpiryRow(
                title: 'PUC',
                date: vehicle.pucExpiry,
                expired: pucExpired,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // SERVICE ACTIONS
          // --------------------------------------------------

          _SectionCard(
            title: 'Service',
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openServiceHistory(context),
                  icon: const Icon(
                    Icons.history_rounded,
                  ),
                  label: const Text(
                    'Service History',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _addService(context),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                  ),
                  label: const Text(
                    'Add Service',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // REMINDERS
          // --------------------------------------------------

          _SectionCard(
            title: 'Reminders',
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openReminders(context),
                  icon: const Icon(
                    Icons.notifications_outlined,
                  ),
                  label: const Text(
                    'Manage Reminders',
                  ),
                ),
              ),
            ],
          ),

          // --------------------------------------------------
          // NOTES
          // --------------------------------------------------

          if (vehicle.notes.isNotEmpty) ...[
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Notes',
              children: [
                Text(
                  vehicle.notes,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // --------------------------------------------------
          // BOTTOM ACTIONS
          // --------------------------------------------------

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit Vehicle',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _addService(context),
                  icon: const Icon(
                    Icons.build_outlined,
                  ),
                  label: const Text(
                    'Add Service',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================
// METRIC CARD
// ============================================================

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
          color:
              theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: theme.textTheme.bodySmall
                ?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION CARD
// ============================================================

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
          color:
              theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(
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

// ============================================================
// INFO ROW
// ============================================================

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
      padding:
          const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w600,
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

// ============================================================
// EXPIRY ROW
// ============================================================

class _ExpiryRow extends StatelessWidget {
  final String title;
  final DateTime? date;
  final bool expired;

  const _ExpiryRow({
    required this.title,
    required this.date,
    required this.expired,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not added';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color = expired
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            expired
                ? Icons.warning_amber_rounded
                : Icons.verified_outlined,
            color: color,
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
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _formatDate(date),
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (expired)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.errorContainer,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                'Expired',
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY INFO
// ============================================================

class _EmptyInfo extends StatelessWidget {
  final String message;

  const _EmptyInfo({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style:
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
      ),
    );
  }
}