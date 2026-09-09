import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../vehicles/screens/add_vehicle_screen.dart';

import '../../services/models/service_record.dart';
import '../../services/providers/service_provider.dart';
import '../../services/screens/add_service_screen.dart';
import '../../services/screens/services_screen.dart';

import '../../reminders/screens/reminders_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState
    extends State<CustomerDetailsScreen> {
  bool _isLoading = true;

  List<Vehicle> _vehicles = [];
  List<ServiceRecord> _services = [];

  String? _error;

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _loadCustomerData();
  });
}

  // ============================================================
  // LOAD CUSTOMER DATA
  // ============================================================

  Future<void> _loadCustomerData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vehicleProvider =
          context.read<VehicleProvider>();

      final serviceProvider =
          context.read<ServiceProvider>();

      final vehicles =
          await vehicleProvider.fetchCustomerVehicles(
        widget.customer.id,
      );

      final services =
          await serviceProvider.fetchCustomerServices(
        widget.customer.id,
      );

      if (!mounted) return;

      setState(() {
        _vehicles = vehicleProvider.vehicles;
        _services = services;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // ADD VEHICLE
  // ============================================================

  Future<void> _addVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(
          customerId: widget.customer.id,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadCustomerData();
    }
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<void> _addService() async {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a vehicle before creating a service.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          customers: [widget.customer],
          vehicles: _vehicles,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadCustomerData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service added successfully.'),
        ),
      );
    }
  }

  // ============================================================
  // SERVICE HISTORY
  // ============================================================

  Future<void> _openServiceHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServicesScreen(
          customerId: widget.customer.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadCustomerData();
  }

  // ============================================================
  // REMINDERS
  // ============================================================

  Future<void> _openReminders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemindersScreen(
          customerId: widget.customer.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadCustomerData();
  }

  // ============================================================
  // CALL
  // ============================================================

  void _callCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Call: ${widget.customer.phone}',
        ),
      ),
    );
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  void _whatsappCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WhatsApp: ${widget.customer.phone}',
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadCustomerData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Edit Customer',
            onPressed: widget.onEdit,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Delete Customer',
            onPressed: widget.onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadCustomerData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ==================================================
            // CUSTOMER HEADER
            // ==================================================

            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor:
                    theme.colorScheme.primaryContainer,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                customer.name,
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Text(
                customer.phone,
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ==================================================
            // CALL / WHATSAPP
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_outlined,
                    title: 'Call',
                    onTap: _callCustomer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    onTap: _whatsappCustomer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // ==================================================
            // LOADING
            // ==================================================

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: LinearProgressIndicator(),
              ),

            // ==================================================
            // ERROR
            // ==================================================

            if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadCustomerData,
              ),

            // ==================================================
            // PERSONAL INFORMATION
            // ==================================================

            _SectionCard(
              title: 'Personal Information',
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Name',
                  value: customer.name,
                ),

                _InfoRow(
                  icon: Icons.phone_outlined,
                  title: 'Mobile',
                  value: customer.phone,
                ),

                if (customer.email.isNotEmpty)
                  _InfoRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: customer.email,
                  ),

                if (customer.address.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    value: customer.address,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // VEHICLES
            // ==================================================

            _SectionCard(
              title: 'Vehicles',
              children: [
                _InfoRow(
                  icon:
                      Icons.directions_car_outlined,
                  title: 'Total Vehicles',
                  value: _vehicles.length.toString(),
                ),

                const SizedBox(height: 8),

                if (_vehicles.isNotEmpty)
                  ..._vehicles.map(
                    (vehicle) => _VehicleRow(
                      vehicle: vehicle,
                      onTap: () {
                        // Vehicle details can be opened
                        // from the vehicle list later.
                      },
                    ),
                  ),

                if (_vehicles.isEmpty && !_isLoading)
                  const _EmptyInfo(
                    message:
                        'No vehicles added for this customer.',
                  ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading ? null : _addVehicle,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SERVICE HISTORY
            // ==================================================

            _SectionCard(
              title: 'Service History',
              children: [
                _InfoRow(
                  icon: Icons.build_outlined,
                  title: 'Total Services',
                  value: _services.length.toString(),
                ),

                if (_services.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  _InfoRow(
                    icon: Icons.history_rounded,
                    title: 'Last Service',
                    value: _formatDate(
                      _services.first.serviceDate,
                    ),
                  ),

                  _InfoRow(
                    icon:
                        Icons.event_available_outlined,
                    title: 'Next Service',
                    value: _services.first
                                .nextServiceDate !=
                            null
                        ? _formatDate(
                            _services
                                .first
                                .nextServiceDate,
                          )
                        : 'Not scheduled',
                  ),
                ],

                if (_services.isEmpty && !_isLoading)
                  const _EmptyInfo(
                    message:
                        'No service history available.',
                  ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _openServiceHistory,
                    icon: const Icon(
                      Icons.history_rounded,
                    ),
                    label: const Text(
                      'View Service History',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            _SectionCard(
              title: 'Quick Actions',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _isLoading ? null : _addService,
                    icon: const Icon(
                      Icons.build_outlined,
                    ),
                    label: const Text(
                      'Add Service',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _openReminders,
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VEHICLE ROW
// ============================================================

class _VehicleRow extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleRow({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_filled_rounded,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.registrationNumber,
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style:
                        theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR CARD
// ============================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load customer data',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
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
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

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
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme
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

// ============================================================
// ACTION BUTTON
// ============================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}