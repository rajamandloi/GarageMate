import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';

import '../models/service_record.dart';
import '../providers/service_provider.dart';
import 'add_service_screen.dart';
import 'service_details_screen.dart';

class ServicesScreen extends StatefulWidget {
  final String? customerId;

  const ServicesScreen({
    super.key,
    this.customerId,
  });

  @override
  State<ServicesScreen> createState() =>
      _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ServiceProvider>().fetchServices();

      final customerProvider =
          context.read<CustomerProvider>();

      if (customerProvider.customers.isEmpty &&
          !customerProvider.isLoading) {
        customerProvider.fetchCustomers();
      }

      final vehicleProvider =
          context.read<VehicleProvider>();

      if (vehicleProvider.vehicles.isEmpty &&
          !vehicleProvider.isLoading) {
        vehicleProvider.fetchVehicles();
      }
    });
  }

  List<ServiceRecord> _filteredServices(
    List<ServiceRecord> services,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return services;
    }

    return services.where((service) {
      final customerName =
          service.customerName?.toLowerCase() ?? '';

      final customerPhone =
          service.customerPhone?.toLowerCase() ?? '';

      final registration =
          service.registrationNumber?.toLowerCase() ?? '';

      final brand =
          service.vehicleBrand?.toLowerCase() ?? '';

      final model =
          service.vehicleModel?.toLowerCase() ?? '';

      final serviceType =
          service.serviceType.toLowerCase();

      return customerName.contains(query) ||
          customerPhone.contains(query) ||
          registration.contains(query) ||
          brand.contains(query) ||
          model.contains(query) ||
          serviceType.contains(query);
    }).toList();
  }

  Future<void> _addService() async {
  final customerProvider =
      context.read<CustomerProvider>();

  final vehicleProvider =
      context.read<VehicleProvider>();

  final serviceProvider =
      context.read<ServiceProvider>();

  // Load customers
  if (customerProvider.customers.isEmpty &&
      !customerProvider.isLoading) {
    await customerProvider.fetchCustomers();
  }

  // Load vehicles
  if (vehicleProvider.vehicles.isEmpty &&
      !vehicleProvider.isLoading) {
    await vehicleProvider.fetchVehicles();
  }

  if (!mounted) return;

  // Open Add Service Form
  final service =
      await Navigator.push<ServiceRecord>(
    context,
    MaterialPageRoute(
      builder: (_) => AddServiceScreen(
        customers: customerProvider.customers,
        vehicles: vehicleProvider.vehicles,
      ),
    ),
  );

  if (!mounted || service == null) {
    return;
  }

  // ============================================================
  // SAVE SERVICE TO BACKEND
  // ============================================================

  final success =
      await serviceProvider.createService(service);

  if (!mounted) return;

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Service saved successfully',
        ),
      ),
    );

    // Refresh latest backend data
    await serviceProvider.fetchServices();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          serviceProvider.error ??
              'Unable to save service',
        ),
      ),
    );
  }
}

Future<void> _editService(
  ServiceRecord service,
) async {
  final customerProvider =
      context.read<CustomerProvider>();

  final vehicleProvider =
      context.read<VehicleProvider>();

  final serviceProvider =
      context.read<ServiceProvider>();

  if (customerProvider.customers.isEmpty &&
      !customerProvider.isLoading) {
    await customerProvider.fetchCustomers();
  }

  if (vehicleProvider.vehicles.isEmpty &&
      !vehicleProvider.isLoading) {
    await vehicleProvider.fetchVehicles();
  }

  if (!mounted) return;

  final updated =
      await Navigator.push<ServiceRecord>(
    context,
    MaterialPageRoute(
      builder: (_) => AddServiceScreen(
        customers: customerProvider.customers,
        vehicles: vehicleProvider.vehicles,
        service: service,
      ),
    ),
  );

  if (!mounted || updated == null) {
    return;
  }

  // ============================================================
  // UPDATE SERVICE IN BACKEND
  // ============================================================

  final success =
      await serviceProvider.updateService(updated);

  if (!mounted) return;

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Service updated successfully',
        ),
      ),
    );

    await serviceProvider.fetchServices();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          serviceProvider.error ??
              'Unable to update service',
        ),
      ),
    );
  }
}


  Future<void> _deleteService(
    ServiceRecord service,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text(
            'Are you sure you want to delete '
            '${service.serviceType} service?',
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
        context.read<ServiceProvider>();

    final success =
        await provider.deleteService(
      service.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Service deleted successfully'
              : provider.error ??
                  'Unable to delete service',
        ),
      ),
    );
  }

  void _openDetails(
  ServiceRecord service,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ServiceDetailsScreen(
        service: service,
        customerName:
            service.customerName ?? 'Unknown Customer',
        registrationNumber:
            service.registrationNumber,
        vehicleBrand:
            service.vehicleBrand,
        vehicleModel:
            service.vehicleModel,
        onEdit: () {
          Navigator.pop(context);
          _editService(service);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteService(service);
        },
      ),
    ),
  );
}
  String _statusText(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';

      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';

      case PaymentStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(
    BuildContext context,
    PaymentStatus status,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    switch (status) {
      case PaymentStatus.paid:
        return colors.primary;

      case PaymentStatus.partiallyPaid:
        return colors.tertiary;

      case PaymentStatus.pending:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        final services =
            _filteredServices(
          provider.services,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Services',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: provider.isLoading
                    ? null
                    : provider.fetchServices,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
            ],
          ),

          floatingActionButton:
              FloatingActionButton.extended(
            onPressed:
                provider.isLoading
                    ? null
                    : _addService,
            icon: const Icon(Icons.add),
            label:
                const Text('Service'),
          ),

          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  16,
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
                        'Search service, customer or vehicle',
                    prefixIcon:
                        const Icon(
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
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                              )
                            : null,
                  ),
                ),
              ),

              if (provider.isLoading &&
                  provider.services.isNotEmpty)
                const LinearProgressIndicator(),

              Expanded(
                child:
                    provider.isLoading &&
                            provider.services
                                .isEmpty
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : provider.error != null &&
                                provider.services
                                    .isEmpty
                            ? _ErrorServices(
                                message:
                                    provider.error!,
                                onRetry:
                                    provider
                                        .fetchServices,
                              )
                            : services.isEmpty
                                ? _EmptyServices(
                                    hasSearch:
                                        _searchQuery
                                            .isNotEmpty,
                                    onAdd:
                                        _addService,
                                  )
                                : ListView
                                    .separated(
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      20,
                                      0,
                                      20,
                                      100,
                                    ),
                                    itemCount:
                                        services
                                            .length,
                                    separatorBuilder:
                                        (
                                      _,
                                      _,
                                    ) =>
                                            const SizedBox(
                                      height: 12,
                                    ),
                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      final service =
                                          services[
                                              index];

                                      return _ServiceCard(
                                        service:
                                            service,
                                        statusText:
                                            _statusText(
                                          service
                                              .paymentStatus,
                                        ),
                                        statusColor:
                                            _statusColor(
                                          context,
                                          service
                                              .paymentStatus,
                                        ),
                                        onTap:
                                            () {
                                          _openDetails(
                                            service,
                                          );
                                        },
                                        onEdit:
                                            () {
                                          _editService(
                                            service,
                                          );
                                        },
                                        onDelete:
                                            () {
                                          _deleteService(
                                            service,
                                          );
                                        },
                                      );
                                    },
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCard
    extends StatelessWidget {
  final ServiceRecord service;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration:
            BoxDecoration(
          color:
              theme.colorScheme.surface,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: theme
                .colorScheme
                .outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .primaryContainer,
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    Icons.build_rounded,
                    color: theme
                        .colorScheme
                        .primary,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceType,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      if (service
                                  .registrationNumber !=
                              null &&
                          service
                              .registrationNumber!
                              .isNotEmpty)
                        Text(
                          service
                              .registrationNumber!,
                          style: theme
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                      if (service
                                  .customerName !=
                              null &&
                          service
                              .customerName!
                              .isNotEmpty)
                        Text(
                          service.customerName!,
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                PopupMenuButton<
                    String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      onEdit();
                    } else if (value ==
                        'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child: _SmallInfo(
                    icon:
                        Icons.speed_rounded,
                    text:
                        '${service.mileage.toStringAsFixed(0)} km',
                  ),
                ),

                Expanded(
                  child: _SmallInfo(
                    icon:
                        Icons.calendar_today_rounded,
                    text:
                        _formatDate(
                      service.serviceDate,
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${service.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: statusColor
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  width: 4,
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallInfo
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        const SizedBox(
          width: 6,
        ),
        Flexible(
          child: Text(
            text,
            overflow:
                TextOverflow.ellipsis,
            style: theme
                .textTheme
                .bodySmall,
          ),
        ),
      ],
    );
  }
}

class _EmptyServices
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyServices({
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons
                      .search_off_rounded
                  : Icons
                      .build_circle_outlined,
              size: 70,
              color: theme
                  .colorScheme
                  .primary,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              hasSearch
                  ? 'No services found'
                  : 'No services yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              hasSearch
                  ? 'Try another customer, vehicle or service name.'
                  : 'Add your first service record to start tracking garage work.',
              textAlign:
                  TextAlign.center,
            ),

            if (!hasSearch) ...[
              const SizedBox(
                height: 22,
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon:
                    const Icon(Icons.add),
                label: const Text(
                  'Add Service',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorServices
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorServices({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              size: 60,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Unable to load services',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

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
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}