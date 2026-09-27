import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../services/providers/service_provider.dart';

import '../../customers/screens/customer_details_screen.dart';
import '../../vehicles/screens/vehicle_details_screen.dart';
import '../../services/screens/service_details_screen.dart';

import '../models/search_result.dart';
import '../providers/search_provider.dart';
import '../widgets/search_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller =
      TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto focus
      _focusNode.requestFocus();

      // Load recent
      context.read<SearchProvider>().init();

      // Ensure data is loaded
      _ensureDataLoaded();
    });
  }

  // ============================================================
  // ENSURE DATA LOADED
  // ============================================================

  Future<void> _ensureDataLoaded() async {
    final customerProvider = context.read<CustomerProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    if (customerProvider.customers.isEmpty &&
        !customerProvider.isLoading) {
      await customerProvider.fetchCustomers();
    }

    if (vehicleProvider.vehicles.isEmpty &&
        !vehicleProvider.isLoading) {
      await vehicleProvider.fetchVehicles();
    }

    if (serviceProvider.services.isEmpty &&
        !serviceProvider.isLoading) {
      await serviceProvider.fetchServices();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // ON QUERY CHANGED
  // ============================================================

  void _onQueryChanged(String query) {
    final customerProvider = context.read<CustomerProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final searchProvider = context.read<SearchProvider>();

    searchProvider.search(
      query: query,
      customers: customerProvider.customers,
      vehicles: vehicleProvider.vehicles,
      services: serviceProvider.services,
    );
  }

  // ============================================================
  // ON RESULT TAP
  // ============================================================

  Future<void> _onResultTap(SearchResult result) async {
    // Save to recent
    await context
        .read<SearchProvider>()
        .saveRecentSearch(_controller.text);

    if (!mounted) return;

    switch (result.type) {
      case SearchResultType.customer:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(
              customer: result.originalData,
              onEdit: () {
                Navigator.pop(context);
              },
              onDelete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;

      case SearchResultType.vehicle:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailsScreen(
              vehicle: result.originalData,
              onEdit: () {
                Navigator.pop(context);
              },
              onDelete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;

      case SearchResultType.service:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(
              service: result.originalData,
              customerName:
                  result.originalData.customerName ??
                      'Unknown',
              registrationNumber:
                  result.originalData.registrationNumber,
              vehicleBrand:
                  result.originalData.vehicleBrand,
              vehicleModel:
                  result.originalData.vehicleModel,
              onEdit: () {
                Navigator.pop(context);
              },
              onDelete: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        break;
    }
  }

  // ============================================================
  // USE RECENT
  // ============================================================

  void _useRecent(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _onQueryChanged(query);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // ==================================================
          // SEARCH BAR
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                    'Search customer, vehicle or service...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // ==================================================
          // CONTENT
          // ==================================================
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, child) {
                // Empty query → show recent
                if (provider.query.trim().isEmpty) {
                  return _RecentSearchesView(
                    onSearchTap: _useRecent,
                  );
                }

                // Searching
                if (provider.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // No results
                if (!provider.hasResults) {
                  return _NoResultsView(
                    query: provider.query,
                  );
                }

                // Results
                return _ResultsView(
                  groups: provider.groups,
                  onResultTap: _onResultTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT SEARCHES VIEW
// ============================================================

class _RecentSearchesView extends StatelessWidget {
  final Function(String) onSearchTap;

  const _RecentSearchesView({
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final recents = provider.recentSearches;

        if (recents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 72,
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search Anything',
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search by customer name, phone,\nvehicle number, or service type',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    provider.clearRecentSearches();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recents.map(
              (query) => ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(query),
                trailing: IconButton(
                  onPressed: () {
                    provider.removeRecentSearch(query);
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
                onTap: () => onSearchTap(query),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// NO RESULTS VIEW
// ============================================================

class _NoResultsView extends StatelessWidget {
  final String query;

  const _NoResultsView({required this.query});

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
              Icons.search_off_rounded,
              size: 72,
              color: theme.colorScheme.error
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No matches for "$query"\n\n'
              'Try searching by:\n'
              '• Customer name or phone\n'
              '• Vehicle number (e.g. MP09AB1234)\n'
              '• Service type (e.g. Oil Change)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RESULTS VIEW
// ============================================================

class _ResultsView extends StatelessWidget {
  final List<SearchResultGroup> groups;
  final Function(SearchResult) onResultTap;

  const _ResultsView({
    required this.groups,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Total count
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '${groups.fold<int>(0, (sum, g) => sum + g.count)} results',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Groups
        ...groups.map(
          (group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      group.icon,
                      size: 20,
                      color: group.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.label} (${group.count})',
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ...group.results.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SearchResultCard(
                    result: result,
                    onTap: () => onResultTap(result),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}