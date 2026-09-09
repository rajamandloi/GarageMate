import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import 'vehicle_details_screen.dart';
import 'add_vehicle_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  List<Vehicle> _filterVehicles(List<Vehicle> vehicles) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return vehicles;
    }

    return vehicles.where((vehicle) {
      return vehicle.registrationNumber
              .toLowerCase()
              .contains(query) ||
          vehicle.brand.toLowerCase().contains(query) ||
          vehicle.model.toLowerCase().contains(query) ||
          vehicle.customerName
                  ?.toLowerCase()
                  .contains(query) ==
              true ||
          vehicle.customerPhone
                  ?.toLowerCase()
                  .contains(query) ==
              true;
    }).toList();
  }

  Future<void> _refreshVehicles() async {
    await context.read<VehicleProvider>().fetchVehicles();
  }

  Future<void> _editVehicle(Vehicle vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(
          customerId: vehicle.customerId,
          vehicle: vehicle,
        ),
      ),
    );

    if (!mounted) return;

    // AddVehicleScreen provider ko update karega.
    // Safety ke liye list refresh kar dete hain.
    if (result != null) {
      await _refreshVehicles();
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Vehicle?'),
          content: Text(
            'Are you sure you want to delete '
            '${vehicle.registrationNumber}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<VehicleProvider>();

    final success = await provider.deleteVehicle(vehicle.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Vehicle deleted successfully'
              : provider.error ?? 'Unable to delete vehicle',
        ),
      ),
    );
  }

  void _openVehicleDetails(Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleDetailsScreen(
          vehicle: vehicle,
          onEdit: () {
            Navigator.pop(context);
            _editVehicle(vehicle);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteVehicle(vehicle);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, provider, child) {
        final vehicles = _filterVehicles(provider.vehicles);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Vehicles',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed:
                    provider.isLoading ? null : _refreshVehicles,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
            ],
          ),

          body: RefreshIndicator(
            onRefresh: _refreshVehicles,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    16,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search vehicle, owner or mobile',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                  ),
                                )
                              : null,
                    ),
                  ),
                ),

                if (provider.isLoading &&
                    provider.vehicles.isNotEmpty)
                  const LinearProgressIndicator(),

                Expanded(
                  child: _buildContent(
                    context,
                    provider,
                    vehicles,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    VehicleProvider provider,
    List<Vehicle> vehicles,
  ) {
    if (provider.isLoading && provider.vehicles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null &&
        provider.vehicles.isEmpty) {
      return _ErrorVehicles(
        message: provider.error!,
        onRetry: _refreshVehicles,
      );
    }

    if (vehicles.isEmpty) {
      return _EmptyVehicles(
        isSearching: _searchQuery.isNotEmpty,
        onClearSearch: () {
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        30,
      ),
      itemCount: vehicles.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];

        return _VehicleCard(
          vehicle: vehicle,
          onTap: () {
            _openVehicleDetails(vehicle);
          },
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasOwner = vehicle.customerName != null &&
        vehicle.customerName!.trim().isNotEmpty;

    final hasPhone = vehicle.customerPhone != null &&
        vehicle.customerPhone!.trim().isNotEmpty;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  size: 29,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.registrationNumber,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${vehicle.brand} ${vehicle.model}'
                      '${vehicle.variant.isNotEmpty ? ' • ${vehicle.variant}' : ''}',
                      style:
                          theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 8),

                    if (hasOwner)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              vehicle.customerName!,
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    if (hasPhone)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              vehicle.customerPhone!,
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

                    const SizedBox(height: 6),

                    Text(
                      '${vehicle.fuelType} • '
                      '${vehicle.currentMileage.toStringAsFixed(0)} km',
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

class _EmptyVehicles extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onClearSearch;

  const _EmptyVehicles({
    required this.isSearching,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.directions_car_outlined,
              size: 70,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 18),

            Text(
              isSearching
                  ? 'No vehicles found'
                  : 'No vehicles yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSearching
                  ? 'Try another registration number, owner name or mobile number.'
                  : 'Vehicles are added from the customer details page.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (isSearching) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(
                  Icons.clear_rounded,
                ),
                label: const Text(
                  'Clear Search',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorVehicles extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorVehicles({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load vehicles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}