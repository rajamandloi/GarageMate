import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../scanner/screens/scanner_screen.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../vehicles/screens/vehicle_details_screen.dart';
import '../../vehicles/services/vehicle_lookup_service.dart';

import 'add_customer_screen.dart';
import 'customer_details_screen.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CustomerProvider>().fetchCustomers();
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  // ============================================================
  // OPEN CUSTOMER DETAILS
  // ============================================================

  void _openCustomerDetails(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(
          customer: customer,
          onEdit: () {
            Navigator.pop(context);
            _editCustomer(customer);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteCustomer(customer);
          },
        ),
      ),
    ).then((_) {
      // Refresh after returning
      if (!mounted) return;
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  // ============================================================
  // EDIT CUSTOMER
  // ============================================================

  Future<void> _editCustomer(Customer customer) async {
    final updated = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          customer: customer,
        ),
      ),
    );

    if (!mounted || updated == null) return;

    await context.read<CustomerProvider>().fetchCustomers();
  }

  // ============================================================
  // DELETE CUSTOMER
  // ============================================================

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Customer?'),
          content: Text(
            'Are you sure you want to delete ${customer.name}? '
            'All associated vehicles and services may also be affected.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<CustomerProvider>();
    final success =
        await provider.deleteCustomer(customer.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Customer deleted successfully'
              : provider.error ??
                  'Unable to delete customer',
        ),
      ),
    );
  }

  // ============================================================
  // SCAN + SMART ROUTING
  // ============================================================

  Future<void> _openScanner() async {
    final customerProvider = context.read<CustomerProvider>();
    final vehicleProvider = context.read<VehicleProvider>();

    if (customerProvider.customers.isEmpty) {
      await customerProvider.fetchCustomers();
    }

    if (vehicleProvider.vehicles.isEmpty) {
      await vehicleProvider.fetchVehicles();
    }

    if (!mounted) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(),
      ),
    );

    if (!mounted || result == null) return;

    final scannedNumber = result;

    final existingVehicle =
        VehicleLookupService.findByNumber(
      vehicles: vehicleProvider.vehicles,
      registrationNumber: scannedNumber,
    );

    if (existingVehicle != null) {
      // ✅ पुराना vehicle → Vehicle Details
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleDetailsScreen(
            vehicle: existingVehicle,
            onEdit: () {
              Navigator.pop(context);
            },
            onDelete: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      // ✅ नया vehicle → Add Customer
      if (!mounted) return;

      final created = await Navigator.push<Customer>(
        context,
        MaterialPageRoute(
          builder: (_) => AddCustomerScreen(
            initialRegistrationNumber: scannedNumber,
          ),
        ),
      );

      if (!mounted) return;

      if (created != null) {
        await customerProvider.fetchCustomers();
        await vehicleProvider.fetchVehicles();
      }
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Customer> _filteredCustomers(
    List<Customer> customers,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return customers;

    return customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customers',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Scan Vehicle Number',
            onPressed: _openScanner,
            icon: const Icon(
              Icons.document_scanner_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<CustomerProvider>().fetchCustomers();
              context.read<VehicleProvider>().fetchVehicles();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<Customer>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustomerScreen(),
            ),
          );

          if (!mounted) return;

          if (created != null) {
            await context
                .read<CustomerProvider>()
                .fetchCustomers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Customer'),
      ),

      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          final customers = _filteredCustomers(
            provider.customers,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  16,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search customer',
                    prefixIcon:
                        const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(
                                () => _searchQuery = '',
                              );
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),

              if (provider.isLoading &&
                  provider.customers.isEmpty)
                const LinearProgressIndicator(),

              Expanded(
                child: provider.isLoading &&
                        provider.customers.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : customers.isEmpty
                        ? _EmptyCustomers(
                            hasSearch:
                                _searchQuery.isNotEmpty,
                            onScan: _openScanner,
                            onAdd: () async {
                              final created =
                                  await Navigator.push<Customer>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddCustomerScreen(),
                                ),
                              );

                              if (!mounted) return;

                              if (created != null) {
                                await context
                                    .read<CustomerProvider>()
                                    .fetchCustomers();
                              }
                            },
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              100,
                            ),
                            itemCount: customers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final customer =
                                  customers[index];

                              return _CustomerCard(
                                customer: customer,
                                onTap: () =>
                                    _openCustomerDetails(
                                  customer,
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// CUSTOMER CARD
// ============================================================

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (customer.phone.isNotEmpty)
                      Text(
                        customer.phone,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyCustomers extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onScan;
  final VoidCallback onAdd;

  const _EmptyCustomers({
    required this.hasSearch,
    required this.onScan,
    required this.onAdd,
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
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 70,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              hasSearch
                  ? 'कोई customer नहीं मिला'
                  : 'अभी कोई customer नहीं',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'दूसरा नाम या नंबर try करें'
                  : 'पहला customer add करें या vehicle scan करें',
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onScan,
                      icon: const Icon(
                        Icons.document_scanner_rounded,
                      ),
                      label: const Text('Scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Customer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}