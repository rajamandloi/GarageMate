import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';

import '../../vehicles/providers/vehicle_provider.dart';
import '../../vehicles/models/vehicle.dart';
import '../../scanner/screens/scanner_screen.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() =>
      _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  /// Customer ID -> actual vehicle count
  final Map<String, int> _vehicleCounts = {};

  bool _loadingVehicleCounts = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  // ============================================================
  // LOAD CUSTOMERS
  // ============================================================

  Future<void> _loadCustomers() async {
    final customerProvider =
        context.read<CustomerProvider>();

    await customerProvider.fetchCustomers();

    if (!mounted) return;

    await _loadVehicleCounts();
  }

  // ============================================================
  // LOAD VEHICLE COUNTS
  // ============================================================

  Future<void> _loadVehicleCounts() async {
    if (!mounted) return;

    final customers =
        context.read<CustomerProvider>().customers;

    if (customers.isEmpty) {
      setState(() {
        _vehicleCounts.clear();
      });
      return;
    }

    setState(() {
      _loadingVehicleCounts = true;
    });

    final vehicleProvider =
        context.read<VehicleProvider>();

    final Map<String, int> counts = {};

    for (final customer in customers) {
      try {
        await vehicleProvider.fetchCustomerVehicles(
          customer.id,
        );

        if (!mounted) return;

        counts[customer.id] =
            vehicleProvider.vehicles.length;
      } catch (_) {
        counts[customer.id] =
            customer.vehicleCount;
      }
    }

    if (!mounted) return;

    setState(() {
      _vehicleCounts
        ..clear()
        ..addAll(counts);

      _loadingVehicleCounts = false;
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<Customer> _filteredCustomers(
    List<Customer> customers,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name
              .toLowerCase()
              .contains(query) ||
          customer.phone.contains(query) ||
          customer.email
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  // ============================================================
  // ADD CUSTOMER
  // ============================================================

Future<void> _scanVehicle() async {
  final plate = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => const ScannerScreen(),
    ),
  );

  if (!mounted || plate == null || plate.trim().isEmpty) {
    return;
  }

  final scannedPlate = plate
      .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
      .toUpperCase();

  final vehicleProvider =
      context.read<VehicleProvider>();

  try {
    if (vehicleProvider.vehicles.isEmpty &&
        !vehicleProvider.isLoading) {
      await vehicleProvider.fetchVehicles();
    }

    if (!mounted) return;

    Vehicle? matchedVehicle;

    for (final vehicle in vehicleProvider.vehicles) {
      final registration = vehicle.registrationNumber
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
          .toUpperCase();

      if (registration == scannedPlate) {
        matchedVehicle = vehicle;
        break;
      }
    }

    if (matchedVehicle != null) {
      final customerProvider =
          context.read<CustomerProvider>();

      Customer? matchedCustomer;

      for (final customer
          in customerProvider.customers) {
        if (customer.id == matchedVehicle!.customerId) {
          matchedCustomer = customer;
          break;
        }
      }

      if (matchedCustomer != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(
              customer: matchedCustomer!,
              onEdit: () {
                Navigator.pop(context);
                _editCustomer(matchedCustomer!);
              },
              onDelete: () {
                Navigator.pop(context);
                _deleteCustomer(matchedCustomer!);
              },
            ),
          ),
        );

        return;
      }
    }

    // Vehicle/customer nahi mila
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle $scannedPlate nahi mila. New customer add karein.',
        ),
      ),
    );

    await _addCustomer();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle search failed: $e',
        ),
      ),
    );
  }
}

  Future<void> _addCustomer() async {
    final customer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomerScreen(),
      ),
    );

    if (!mounted) return;

    if (customer != null) {
      await _loadCustomers();
    }
  }

  // ============================================================
  // EDIT CUSTOMER
  // ============================================================

  Future<void> _editCustomer(
    Customer customer,
  ) async {
    final updated =
        await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          customer: customer,
        ),
      ),
    );

    if (!mounted) return;

    if (updated != null) {
      await _loadCustomers();
    }
  }

  // ============================================================
  // DELETE CUSTOMER
  // ============================================================

  Future<void> _deleteCustomer(
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Customer?',
          ),
          content: Text(
            'Are you sure you want to delete ${customer.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .error,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider =
        context.read<CustomerProvider>();

    final success =
        await provider.deleteCustomer(
      customer.id,
    );

    if (!mounted) return;

    if (success) {
      _vehicleCounts.remove(customer.id);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Customer deleted successfully',
          ),
        ),
      );

      await _loadCustomers();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                'Unable to delete customer',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CUSTOMER DETAILS
  // ============================================================

  Future<void> _openCustomerDetails(
    Customer customer,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CustomerDetailsScreen(
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
    );

    if (!mounted) return;

    // Refresh when coming back from details.
    await _loadCustomers();
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
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadCustomers,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
  tooltip: 'Scan Vehicle',
  onPressed: _scanVehicle,
  icon: const Icon(
    Icons.document_scanner_rounded,
  ),
),
          IconButton(
            tooltip: 'Add Customer',
            onPressed: _addCustomer,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.add),
        label: const Text('Customer'),
      ),

      body: Consumer<CustomerProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          if (provider.isLoading &&
              provider.customers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (provider.error != null &&
              provider.customers.isEmpty) {
            return _ErrorState(
              message: provider.error!,
              onRetry: _loadCustomers,
            );
          }

          final customers =
              _filteredCustomers(
            provider.customers,
          );

          // ------------------------------------------------------
          // MAIN CONTENT
          // ------------------------------------------------------

          return Column(
            children: [
              // SEARCH
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  12,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Search name, mobile or email',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery =
                                        '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                ),
                              )
                            : null,
                  ),
                ),
              ),

              // VEHICLE COUNT LOADING
              if (_loadingVehicleCounts)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child:
                      LinearProgressIndicator(),
                ),

              // CUSTOMER LIST
              Expanded(
                child: customers.isEmpty
                    ? _EmptyState(
                        searchActive:
                            _searchQuery
                                .isNotEmpty,
                        onAdd: _addCustomer,
                      )
                    : RefreshIndicator(
                        onRefresh:
                            _loadCustomers,
                        child:
                            ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            100,
                          ),
                          itemCount:
                              customers.length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            height: 12,
                          ),
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final customer =
                                customers[
                                    index];

                            final vehicleCount =
                                _vehicleCounts[
                                        customer
                                            .id] ??
                                    customer
                                        .vehicleCount;

                            return _CustomerCard(
                              customer:
                                  customer,
                              vehicleCount:
                                  vehicleCount,
                              onTap: () {
                                _openCustomerDetails(
                                  customer,
                                );
                              },
                            );
                          },
                        ),
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

class _CustomerCard
    extends StatelessWidget {
  final Customer customer;
  final int vehicleCount;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.vehicleCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: theme
                  .colorScheme
                  .outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // AVATAR
              CircleAvatar(
                radius: 27,
                backgroundColor:
                    theme.colorScheme
                        .primaryContainer,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0]
                          .toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .primary,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // CUSTOMER INFO
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      customer.phone,
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // VEHICLE COUNT
                    Row(
                      children: [
                        Icon(
                          Icons
                              .directions_car_outlined,
                          size: 16,
                          color: theme
                              .colorScheme
                              .primary,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          '$vehicleCount vehicle${vehicleCount == 1 ? '' : 's'}',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState
    extends StatelessWidget {
  final bool searchActive;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.searchActive,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              searchActive
                  ? Icons.search_off_rounded
                  : Icons
                      .people_outline_rounded,
              size: 70,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 18),

            Text(
              searchActive
                  ? 'No customers found'
                  : 'No customers yet',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              searchActive
                  ? 'Try another name, mobile number or email.'
                  : 'Add your first customer to start managing vehicles and service reminders.',
              textAlign:
                  TextAlign.center,
            ),

            if (!searchActive) ...[
              const SizedBox(
                height: 22,
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon:
                    const Icon(Icons.add),
                label: const Text(
                  'Add Customer',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 60,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Could not load customers',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}