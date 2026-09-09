import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';

import '../../customers/screens/customers_screen.dart';
import '../../customers/screens/add_customer_screen.dart';
import '../../vehicles/screens/vehicles_screen.dart';
import '../../reminders/screens/reminders_screen.dart';
import '../../reminders/screens/add_reminder_screen.dart';
import '../../services/screens/services_screen.dart';
import '../../services/screens/add_service_screen.dart';
import '../../services/screens/service_details_screen.dart';
import '../../services/providers/service_provider.dart';
import '../../services/models/service_record.dart';
import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../more/screens/more_screen.dart';
import '../../profile/screens/garage_profile_screen.dart';

import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _DashboardHome(),
    CustomersScreen(),
    VehiclesScreen(),
    ServicesScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(
              Icons.directions_car_rounded,
            ),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(
              Icons.build_rounded,
            ),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(
              Icons.more_horiz_rounded,
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD HOME
// ============================================================

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() =>
      _DashboardHomeState();
}

class _DashboardHomeState
    extends State<_DashboardHome> {
  String _ownerName = 'Raja';
  bool _loadingOwner = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final dashboard =
          context.read<DashboardProvider>();

      if (!dashboard.isLoading) {
        dashboard.fetchDashboard();
      }

      _loadOwnerName();
    });
  }

  // ==========================================================
  // LOAD OWNER NAME
  // ==========================================================

  Future<void> _loadOwnerName() async {
    if (_loadingOwner) return;

    _loadingOwner = true;

    try {
      final response =
          await ApiService.get('/auth/me');

      if (!mounted) return;

      final name = _extractOwnerName(response);

      if (name != null &&
          name.trim().isNotEmpty) {
        setState(() {
          _ownerName = name.trim();
        });
      }
    } catch (_) {
      // Safe fallback.
      // Dashboard should never fail because
      // owner name could not be loaded.
    } finally {
      _loadingOwner = false;
    }
  }

  String? _extractOwnerName(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final map =
        Map<String, dynamic>.from(response);

    // Direct name
    if (map['name'] != null) {
      return map['name'].toString();
    }

    // response.user.name
    final user = map['user'];

    if (user is Map &&
        user['name'] != null) {
      return user['name'].toString();
    }

    // response.data.name
    final data = map['data'];

    if (data is Map &&
        data['name'] != null) {
      return data['name'].toString();
    }

    // response.data.user.name
    if (data is Map &&
        data['user'] is Map &&
        data['user']['name'] != null) {
      return data['user']['name'].toString();
    }

    return null;
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshDashboard() async {
    await Future.wait([
      context
          .read<DashboardProvider>()
          .fetchDashboard(),
      _loadOwnerName(),
    ]);
  }

  // ==========================================================
  // NAVIGATION HELPERS
  // ==========================================================

  void _openCustomers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CustomersScreen(),
      ),
    );
  }

  void _openVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const VehiclesScreen(),
      ),
    );
  }

  void _openServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ServicesScreen(),
      ),
    );
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RemindersScreen(),
      ),
    );
  }

  // ==========================================================
  // QUICK ADD SERVICE
  // ==========================================================

  Future<void> _addService() async {
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

    final service =
        await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          customers:
              customerProvider.customers,
          vehicles:
              vehicleProvider.vehicles,
        ),
      ),
    );

    if (!mounted || service == null) {
      return;
    }

    final success =
        await serviceProvider
            .createService(service);

    if (!mounted) return;

    if (success) {
      await context
          .read<DashboardProvider>()
          .fetchDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Service saved successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            serviceProvider.error ??
                'Unable to save service',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // QUICK ADD REMINDER
  // ==========================================================

  Future<void> _addReminder() async {
    final customerProvider =
        context.read<CustomerProvider>();

    final vehicleProvider =
        context.read<VehicleProvider>();

    if (customerProvider.customers.isEmpty &&
        !customerProvider.isLoading) {
      await customerProvider.fetchCustomers();
    }

    if (vehicleProvider.vehicles.isEmpty &&
        !vehicleProvider.isLoading) {
      await vehicleProvider.fetchVehicles();
    }

    if (!mounted) return;

    final created =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddReminderScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await context
          .read<DashboardProvider>()
          .fetchDashboard();
    }
  }

  // ==========================================================
  // REMINDER DETAILS
  // ==========================================================

  void _openReminderDetails(
    Map<String, dynamic> reminder,
  ) {
    final customer =
        _extractName(
      reminder['customerId'],
    );

    final vehicle =
        _extractVehicle(
      reminder['vehicleId'],
    );

    final title =
        _extractServiceName(reminder);

    final message =
        reminder['message']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? reminder['message']
            .toString()
        : 'No additional message';

    final status =
        _normalizeStatus(
      reminder['status'],
    );

    final dueDate =
        _formatDate(
      reminder['dueDate'],
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme =
            Theme.of(sheetContext);

        final urgent =
            status == 'overdue' ||
            status == 'duetoday';

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color: urgent
                            ? theme
                                .colorScheme
                                .errorContainer
                            : theme
                                .colorScheme
                                .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .notifications_active_rounded,
                        color: urgent
                            ? theme
                                .colorScheme
                                .error
                            : theme
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
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            title,
                            style: theme
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            _formatStatus(
                              status,
                            ),
                            style: TextStyle(
                              color: urgent
                                  ? theme
                                      .colorScheme
                                      .error
                                  : theme
                                      .colorScheme
                                      .primary,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                _DetailRow(
                  icon:
                      Icons.person_outline_rounded,
                  label: 'Customer',
                  value: customer,
                ),

                _DetailRow(
                  icon:
                      Icons.directions_car_outlined,
                  label: 'Vehicle',
                  value: vehicle,
                ),

                _DetailRow(
                  icon:
                      Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: dueDate,
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  'Message',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(message),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    child:
                        const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // RECENT SERVICE DETAILS
  // ==========================================================

  void _openRecentService(
    Map<String, dynamic> rawService,
  ) {
    try {
      final service =
          ServiceRecord.fromJson(
        Map<String, dynamic>.from(
          rawService,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ServiceDetailsScreen(
            service: service,
            customerName:
                service.customerName ??
                    'Unknown Customer',
            registrationNumber:
                service.registrationNumber,
            vehicleBrand:
                service.vehicleBrand,
            vehicleModel:
                service.vehicleModel,
            onEdit: () {
              Navigator.pop(context);
              _openServices();
            },
            onDelete: () {
              Navigator.pop(context);
              _openServices();
            },
          ),
        ),
      );
    } catch (_) {
      // If dashboard response doesn't contain
      // enough data for ServiceRecord, safely
      // open complete Services screen.
      _openServices();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (
        context,
        dashboard,
        child,
      ) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh:
                _refreshDashboard,
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ==================================================
                // HEADER
                // ==================================================

                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    0,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child:
                        _buildHeader(context),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 24),
                ),

                if (dashboard.isLoading &&
                    dashboard.customerCount ==
                        0 &&
                    dashboard.vehicleCount ==
                        0)
                  const SliverPadding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child:
                          LinearProgressIndicator(),
                    ),
                  ),

                if (dashboard.error != null)
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: _ErrorCard(
                        message:
                            dashboard.error!,
                        onRetry:
                            dashboard
                                .fetchDashboard,
                      ),
                    ),
                  ),

                // ==================================================
                // STATS
                // ==================================================

                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverGrid(
                    delegate:
                        SliverChildListDelegate(
                      [
                        _StatCard(
                          title: 'Customers',
                          value:
                              dashboard
                                  .customerCount
                                  .toString(),
                          icon: Icons
                              .people_alt_rounded,
                          onTap:
                              _openCustomers,
                        ),
                        _StatCard(
                          title: 'Vehicles',
                          value:
                              dashboard
                                  .vehicleCount
                                  .toString(),
                          icon: Icons
                              .directions_car_filled_rounded,
                          onTap:
                              _openVehicles,
                        ),
                        _StatCard(
                          title: 'Services',
                          value:
                              dashboard
                                  .serviceCount
                                  .toString(),
                          icon: Icons
                              .build_circle_rounded,
                          onTap:
                              _openServices,
                        ),
                        _StatCard(
                          title: 'Pending',
                          value:
                              _formatCurrency(
                            dashboard
                                .pendingAmount,
                          ),
                          icon: Icons
                              .account_balance_wallet_rounded,
                          onTap:
                              _openServices,
                        ),
                      ],
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 28),
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 14),
                ),

                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _QuickAction(
                            icon: Icons
                                .person_add_alt_1_rounded,
                            title: 'Customer',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const AddCustomerScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              _QuickAction(
                            icon: Icons
                                .directions_car_filled_rounded,
                            title: 'Vehicle',
                            onTap:
                                _openVehicles,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              _QuickAction(
                            icon: Icons
                                .build_circle_rounded,
                            title: 'Service',
                            onTap:
                                _addService,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              _QuickAction(
                            icon: Icons
                                .add_alert_rounded,
                            title: 'Reminder',
                            onTap:
                                _addReminder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 30),
                ),

                // ==================================================
                // UPCOMING REMINDERS
                // ==================================================

                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Reminders',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _openReminders,
                          child:
                              const Text(
                            'View All',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 8),
                ),

                if (dashboard.reminders.isEmpty)
                  const SliverPadding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: _EmptyCard(
                        icon: Icons
                            .notifications_none_rounded,
                        message:
                            'No upcoming reminders',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver:
                        SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (
                          context,
                          index,
                        ) {
                          final reminder =
                              dashboard
                                  .reminders[index];

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _ReminderCard(
                              reminder:
                                  reminder,
                              onTap: () {
                                _openReminderDetails(
                                  reminder,
                                );
                              },
                            ),
                          );
                        },
                        childCount:
                            dashboard
                                .reminders
                                .length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 18),
                ),

                // ==================================================
                // RECENT SERVICES
                // ==================================================

                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Services',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _openServices,
                          child:
                              const Text(
                            'View All',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 12),
                ),

                if (dashboard
                    .recentServices
                    .isEmpty)
                  const SliverPadding(
                    padding:
                        EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      30,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: _EmptyCard(
                        icon:
                            Icons.build_outlined,
                        message:
                            'No recent services',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      30,
                    ),
                    sliver:
                        SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (
                          context,
                          index,
                        ) {
                          final service =
                              dashboard
                                  .recentServices[
                                      index];

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _RecentServiceCard(
                              service:
                                  service,
                              onTap: () {
                                _openRecentService(
                                  service,
                                );
                              },
                            ),
                          );
                        },
                        childCount:
                            dashboard
                                .recentServices
                                .length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final hour =
        DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                _ownerName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: theme
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),

        // PROFILE
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const GarageProfileScreen(),
              ),
            );
          },
          child: Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color: theme
                  .colorScheme
                  .primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .person_outline_rounded,
              color: theme
                  .colorScheme
                  .primary,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // REMINDER ICON
        Stack(
          children: [
            IconButton(
              tooltip:
                  'Reminders',
              onPressed:
                  _openReminders,
              icon: const Icon(
                Icons
                    .notifications_none_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Material(
      color:
          theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: theme
                  .colorScheme
                  .outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme
                        .colorScheme
                        .primary,
                    size: 24,
                  ),
                  const Spacer(),
                  Icon(
                    Icons
                        .arrow_outward_rounded,
                    size: 16,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: theme
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                title,
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
      ),
    );
  }
}

// ============================================================
// QUICK ACTION
// ============================================================

class _QuickAction
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Material(
      color:
          theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 5,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: theme
                  .colorScheme
                  .outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: theme
                    .colorScheme
                    .primary,
                size: 25,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: theme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REMINDER CARD
// ============================================================

class _ReminderCard
    extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final customer =
        _extractName(
      reminder['customerId'],
    );

    final vehicle =
        _extractVehicle(
      reminder['vehicleId'],
    );

    final service =
        _extractServiceName(
      reminder,
    );

    final status =
        _normalizeStatus(
      reminder['status'],
    );

    final due =
        _formatReminderDue(
      reminder['dueDate'],
      status,
    );

    final urgent =
        status == 'duetoday' ||
        status == 'overdue';

    return Material(
      color:
          theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: urgent
                  ? theme
                      .colorScheme
                      .error
                      .withValues(
                        alpha: 0.35,
                      )
                  : theme
                      .colorScheme
                      .outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: urgent
                      ? theme
                          .colorScheme
                          .errorContainer
                      : theme
                          .colorScheme
                          .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons
                      .notifications_active_rounded,
                  color: urgent
                      ? theme
                          .colorScheme
                          .error
                      : theme
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
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      customer,
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
                      height: 3,
                    ),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      service,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
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

              const SizedBox(
                width: 8,
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    due,
                    textAlign:
                        TextAlign.end,
                    style: theme
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: urgent
                              ? theme
                                  .colorScheme
                                  .error
                              : theme
                                  .colorScheme
                                  .primary,
                          fontWeight:
                              FontWeight.w700,
                        ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECENT SERVICE CARD
// ============================================================

class _RecentServiceCard
    extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const _RecentServiceCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final customer =
        _extractName(
      service['customerId'],
    );

    final vehicle =
        _extractVehicle(
      service['vehicleId'],
    );

    final serviceName =
        _extractServiceName(
      service,
    );

    final amount =
        _formatCurrency(
      _toDouble(
        service['totalAmount'],
      ),
    );

    final date =
        _formatDate(
      service['serviceDate'] ??
          service['createdAt'],
    );

    return Material(
      color:
          theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
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
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: theme
                      .colorScheme
                      .secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.build_rounded,
                  color: theme
                      .colorScheme
                      .secondary,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      customer,
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
                      height: 3,
                    ),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodySmall,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
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

              const SizedBox(
                width: 8,
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    date,
                    style: theme
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme
                .colorScheme
                .primary,
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR CARD
// ============================================================

class _ErrorCard
    extends StatelessWidget {
  final String message;
  final Future<void> Function()
      onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: theme
            .colorScheme
            .errorContainer,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme
                .colorScheme
                .error,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onErrorContainer,
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          TextButton(
            onPressed: onRetry,
            child:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY CARD
// ============================================================

class _EmptyCard
    extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
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
          Icon(
            icon,
            size: 38,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _extractName(
  dynamic customer,
) {
  if (customer is Map) {
    final name =
        customer['name'];

    if (name != null &&
        name.toString()
            .trim()
            .isNotEmpty) {
      return name.toString();
    }
  }

  return 'Unknown Customer';
}

String _extractVehicle(
  dynamic vehicle,
) {
  if (vehicle is Map) {
    final registration =
        vehicle['registrationNumber']
            ?.toString()
            .trim();

    final brand =
        vehicle['brand']
            ?.toString()
            .trim();

    final model =
        vehicle['model']
            ?.toString()
            .trim();

    final parts = <String>[];

    if (brand != null &&
        brand.isNotEmpty) {
      parts.add(brand);
    }

    if (model != null &&
        model.isNotEmpty) {
      parts.add(model);
    }

    final vehicleName =
        parts.join(' ');

    if (registration != null &&
        registration.isNotEmpty &&
        vehicleName.isNotEmpty) {
      return '$vehicleName • $registration';
    }

    if (registration != null &&
        registration.isNotEmpty) {
      return registration;
    }

    if (vehicleName.isNotEmpty) {
      return vehicleName;
    }
  }

  return 'Vehicle details unavailable';
}

String _extractServiceName(
  Map<String, dynamic> data,
) {
  const possibleKeys = [
    'serviceName',
    'name',
    'service',
    'serviceType',
    'title',
    'description',
  ];

  for (final key in possibleKeys) {
    final value = data[key];

    if (value != null &&
        value.toString()
            .trim()
            .isNotEmpty) {
      return value.toString();
    }
  }

  return 'Service';
}

String _normalizeStatus(
  dynamic value,
) {
  return value
      ?.toString()
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('-', '') ??
      '';
}

String _formatStatus(
  String status,
) {
  switch (status) {
    case 'overdue':
      return 'Overdue';

    case 'duetoday':
      return 'Due Today';

    case 'duesoon':
      return 'Due Soon';

    case 'completed':
      return 'Completed';

    case 'cancelled':
    case 'canceled':
      return 'Cancelled';

    default:
      return 'Upcoming';
  }
}

String _formatReminderDue(
  dynamic rawDate,
  String status,
) {
  if (status == 'overdue') {
    return 'Overdue';
  }

  if (status == 'duetoday') {
    return 'Due Today';
  }

  if (rawDate == null) {
    if (status == 'duesoon') {
      return 'Due Soon';
    }

    return 'Upcoming';
  }

  final date =
      DateTime.tryParse(
    rawDate.toString(),
  );

  if (date == null) {
    return status == 'duesoon'
        ? 'Due Soon'
        : 'Upcoming';
  }

  final now =
      DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final dueDate = DateTime(
    date.toLocal().year,
    date.toLocal().month,
    date.toLocal().day,
  );

  final difference =
      dueDate
          .difference(today)
          .inDays;

  if (difference < 0) {
    return 'Overdue';
  }

  if (difference == 0) {
    return 'Due Today';
  }

  if (difference == 1) {
    return 'Tomorrow';
  }

  return '$difference days';
}

String _formatDate(
  dynamic value,
) {
  if (value == null) {
    return '-';
  }

  final date =
      DateTime.tryParse(
    value.toString(),
  );

  if (date == null) {
    return value.toString();
  }

  final local =
      date.toLocal();

  return '${local.day.toString().padLeft(2, '0')} '
      '${_monthName(local.month)} '
      '${local.year}';
}

String _monthName(
  int month,
) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  if (month < 1 ||
      month > 12) {
    return '';
  }

  return months[month - 1];
}

double _toDouble(
  dynamic value,
) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value.toString(),
      ) ??
      0;
}

String _formatCurrency(
  double value,
) {
  final rounded =
      value.round();

  final formatted =
      rounded.toString();

  final buffer =
      StringBuffer();

  for (
    int i = 0;
    i < formatted.length;
    i++
  ) {
    final position =
        formatted.length - i;

    buffer.write(
      formatted[i],
    );

    if (position > 1 &&
        position % 3 == 1) {
      buffer.write(',');
    }
  }

  return '₹${buffer.toString()}';
}