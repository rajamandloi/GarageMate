import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../../../l10n/app_localizations.dart';

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
import '../../subscription/widgets/usage_banner.dart';
import '../../../core/utils/phone_helper.dart';
import '../../search/screens/search_screen.dart';

import '../models/today_tasks.dart';
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
    final t = AppLocalizations.of(context);

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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon:
                const Icon(Icons.dashboard_rounded),
            label: t.dashboard,
          ),
          NavigationDestination(
            icon:
                const Icon(Icons.people_outline_rounded),
            selectedIcon:
                const Icon(Icons.people_rounded),
            label: t.customers,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.directions_car_outlined,
            ),
            selectedIcon: const Icon(
              Icons.directions_car_rounded,
            ),
            label: t.vehicles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.build_outlined),
            selectedIcon: const Icon(Icons.build_rounded),
            label: t.services,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            selectedIcon:
                const Icon(Icons.more_horiz_rounded),
            label: t.more,
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

class _DashboardHomeState extends State<_DashboardHome> {
  String _ownerName = 'Owner';
  bool _loadingOwner = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final dashboard = context.read<DashboardProvider>();

      if (!dashboard.isLoading) {
        dashboard.fetchDashboard();
      }

      if (dashboard.todayTasks == null) {
        dashboard.fetchTodayTasks();
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
      final response = await ApiService.get('/auth/me');

      if (!mounted) return;

      final name = _extractOwnerName(response);

      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _ownerName = name.trim();
        });
      }
    } catch (_) {
      // Safe fallback.
    } finally {
      _loadingOwner = false;
    }
  }

  String? _extractOwnerName(dynamic response) {
    if (response is! Map) return null;

    final map = Map<String, dynamic>.from(response);

    if (map['name'] != null) return map['name'].toString();

    final user = map['user'];
    if (user is Map && user['name'] != null) {
      return user['name'].toString();
    }

    final data = map['data'];
    if (data is Map && data['name'] != null) {
      return data['name'].toString();
    }

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
      context.read<DashboardProvider>().refreshAll(),
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
        builder: (_) => const CustomersScreen(),
      ),
    );
  }

  void _openVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VehiclesScreen(),
      ),
    );
  }

  void _openServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesScreen(),
      ),
    );
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RemindersScreen(),
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

    final service = await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          customers: customerProvider.customers,
          vehicles: vehicleProvider.vehicles,
        ),
      ),
    );

    if (!mounted || service == null) return;

    final success =
        await serviceProvider.createService(service);

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    if (success) {
      await context.read<DashboardProvider>().refreshAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.serviceSavedWhatsApp),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceProvider.error ?? t.somethingWentWrong,
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

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddReminderScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await context.read<DashboardProvider>().refreshAll();
    }
  }

  // ==========================================================
  // REMINDER DETAILS
  // ==========================================================

  void _openReminderDetails(
    Map<String, dynamic> reminder,
  ) {
    final customer = _extractName(reminder['customerId']);
    final vehicle = _extractVehicle(reminder['vehicleId']);
    final title = _extractServiceName(reminder);

    final message =
        reminder['message']?.toString().trim().isNotEmpty ==
                true
            ? reminder['message'].toString()
            : 'No additional message';

    final status = _normalizeStatus(reminder['status']);

    final isCompleted = status == 'completed';
    final isCancelled =
        status == 'cancelled' || status == 'canceled';
    final isDone = isCompleted || isCancelled;

    final dueDate = _formatDate(reminder['dueDate']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        final urgent = !isDone &&
            (status == 'overdue' || status == 'duetoday');

        Color headerBg;
        Color headerFg;
        IconData headerIcon;

        if (isCompleted) {
          headerBg = theme.colorScheme.primaryContainer;
          headerFg = theme.colorScheme.primary;
          headerIcon = Icons.check_circle_rounded;
        } else if (isCancelled) {
          headerBg =
              theme.colorScheme.surfaceContainerHighest;
          headerFg = theme.colorScheme.onSurfaceVariant;
          headerIcon = Icons.cancel_rounded;
        } else if (urgent) {
          headerBg = theme.colorScheme.errorContainer;
          headerFg = theme.colorScheme.error;
          headerIcon = Icons.notifications_active_rounded;
        } else {
          headerBg = theme.colorScheme.primaryContainer;
          headerFg = theme.colorScheme.primary;
          headerIcon = Icons.notifications_active_rounded;
        }

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child:
                          Icon(headerIcon, color: headerFg),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme
                                .textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatStatus(status),
                            style: TextStyle(
                              color: headerFg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: customer,
                ),

                _DetailRow(
                  icon: Icons.directions_car_outlined,
                  label: 'Vehicle',
                  value: vehicle,
                ),

                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: dueDate,
                ),

                const SizedBox(height: 12),

                Text(
                  'Message',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(message),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
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
  // RECENT SERVICE — OPEN DETAILS
  // ==========================================================

  void _openRecentService(
    Map<String, dynamic> rawService,
  ) {
    ServiceRecord service;

    try {
      service = ServiceRecord.fromJson(
        Map<String, dynamic>.from(rawService),
      );
    } catch (_) {
      _openServices();
      return;
    }

    if (service.id.isEmpty) {
      _openServices();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(
          service: service,
          customerName:
              service.customerName ?? 'Unknown Customer',
          registrationNumber: service.registrationNumber,
          vehicleBrand: service.vehicleBrand,
          vehicleModel: service.vehicleModel,
          onEdit: () {
            Navigator.pop(context);
            _editRecentService(service);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteRecentService(service);
          },
        ),
      ),
    );
  }

  // ==========================================================
  // EDIT RECENT SERVICE
  // ==========================================================

  Future<void> _editRecentService(
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

    final updated = await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          customers: customerProvider.customers,
          vehicles: vehicleProvider.vehicles,
          service: service,
        ),
      ),
    );

    if (!mounted || updated == null) return;

    final success =
        await serviceProvider.updateService(updated);

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.serviceUpdated)),
      );

      await context.read<DashboardProvider>().refreshAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceProvider.error ?? t.somethingWentWrong,
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DELETE RECENT SERVICE
  // ==========================================================

  Future<void> _deleteRecentService(
    ServiceRecord service,
  ) async {
    final confirmed = await showDialog<bool>(
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

    final serviceProvider =
        context.read<ServiceProvider>();

    final success =
        await serviceProvider.deleteService(service.id);

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.serviceDeleted)),
      );

      await context.read<DashboardProvider>().refreshAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceProvider.error ?? t.somethingWentWrong,
          ),
        ),
      );
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final activeReminders =
            dashboard.reminders.where((r) {
          final status = _normalizeStatus(r['status']);
          return status != 'completed' &&
              status != 'cancelled' &&
              status != 'canceled';
        }).toList();

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              slivers: [
                // HEADER
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                ),

                // USAGE BANNER
                const SliverToBoxAdapter(
                  child: UsageBanner(),
                ),

                // ==================================================
                // TODAY'S TASKS
                // ==================================================
                const SliverToBoxAdapter(
                  child: _TodayTasksSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                if (dashboard.isLoading &&
                    dashboard.customerCount == 0 &&
                    dashboard.vehicleCount == 0)
                  const SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: LinearProgressIndicator(),
                    ),
                  ),

                if (dashboard.error != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ErrorCard(
                        message: dashboard.error!,
                        onRetry: dashboard.fetchDashboard,
                      ),
                    ),
                  ),

                // ==================================================
                // STATS
                // ==================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate(
                      [
                        _StatCard(
                          title: t.customers,
                          value: dashboard.customerCount
                              .toString(),
                          icon: Icons.people_alt_rounded,
                          onTap: _openCustomers,
                        ),
                        _StatCard(
                          title: t.vehicles,
                          value: dashboard.vehicleCount
                              .toString(),
                          icon: Icons
                              .directions_car_filled_rounded,
                          onTap: _openVehicles,
                        ),
                        _StatCard(
                          title: t.services,
                          value: dashboard.serviceCount
                              .toString(),
                          icon: Icons.build_circle_rounded,
                          onTap: _openServices,
                        ),
                        _StatCard(
                          title:
                              t.paymentsPending,
                          value: _formatCurrency(
                            dashboard.pendingAmount,
                          ),
                          icon: Icons
                              .account_balance_wallet_rounded,
                          onTap: _openServices,
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
                  child: SizedBox(height: 28),
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      t.quickActions,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 14),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons
                                .person_add_alt_1_rounded,
                            title: t.customer,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddCustomerScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons
                                .directions_car_filled_rounded,
                            title: t.vehicle,
                            onTap: _openVehicles,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.build_circle_rounded,
                            title: t.service,
                            onTap: _addService,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_alert_rounded,
                            title: t.reminder,
                            onTap: _addReminder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),

                // ==================================================
                // UPCOMING REMINDERS HEADER
                // ==================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.upcomingReminders,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openReminders,
                          child: Text(t.viewAll),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 8),
                ),

                if (activeReminders.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyCard(
                        icon: Icons
                            .notifications_none_rounded,
                        message: t.noUpcomingReminders,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder =
                              activeReminders[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _ReminderCard(
                              reminder: reminder,
                              onTap: () {
                                _openReminderDetails(
                                  reminder,
                                );
                              },
                            ),
                          );
                        },
                        childCount: activeReminders.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 18),
                ),

                // ==================================================
                // RECENT SERVICES
                // ==================================================
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.recentServices,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openServices,
                          child: Text(t.viewAll),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                if (dashboard.recentServices.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      30,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyCard(
                        icon: Icons.build_outlined,
                        message: t.noRecentServices,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      30,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (context, index) {
                          final service = dashboard
                              .recentServices[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _RecentServiceCard(
                              service: service,
                              onTap: () {
                                _openRecentService(
                                  service,
                                );
                              },
                            ),
                          );
                        },
                        childCount:
                            dashboard.recentServices.length,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final hour = DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = t.goodMorning;
    } else if (hour < 17) {
      greeting = t.goodAfternoon;
    } else {
      greeting = t.goodEvening;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        // Search Icon
        IconButton(
          tooltip: 'Search',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.search_rounded),
        ),
        
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
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Stack(
          children: [
            IconButton(
              tooltip: 'Reminders',
              onPressed: _openReminders,
              icon: const Icon(
                Icons.notifications_none_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// TODAY'S TASKS SECTION
// ============================================================

class _TodayTasksSection extends StatelessWidget {
  const _TodayTasksSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final tasks = provider.todayTasks;
        final isLoading = provider.isLoadingTasks;
        final t = AppLocalizations.of(context);

        if (isLoading && tasks == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (tasks == null || tasks.isEmpty) {
          return Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color:
                        Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.allCaughtUp,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.noTasksToday,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                10,
              ),
              child: Row(
                children: [
                  Text(
                    t.todayTasksTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.totalTasksCount}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (tasks.servicesDueToday.isNotEmpty)
              _TaskGroup(
                title: t.servicesDueToday,
                icon: Icons.build_circle_rounded,
                color: Colors.blue,
                items: tasks.servicesDueToday,
              ),

            if (tasks.paymentsPending.isNotEmpty)
              _TaskGroup(
                title: t.paymentsPending,
                icon: Icons.payments_rounded,
                color: Colors.orange,
                items: tasks.paymentsPending,
              ),

            if (tasks.remindersDueToday.isNotEmpty)
              _TaskGroup(
                title: t.remindersDueToday,
                icon:
                    Icons.notifications_active_rounded,
                color: Colors.red,
                items: tasks.remindersDueToday,
              ),
          ],
        );
      },
    );
  }
}

// ============================================================
// TASK GROUP
// ============================================================

class _TaskGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<TaskItem> items;

  const _TaskGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${items.length})',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _TaskCard(item: item, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TASK CARD
// ============================================================

class _TaskCard extends StatelessWidget {
  final TaskItem item;
  final Color color;

  const _TaskCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openWhatsApp(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName.isNotEmpty
                          ? item.customerName
                          : 'Customer',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.customerPhone.isNotEmpty)
                IconButton(
                  onPressed: () => _openWhatsApp(context),
                  icon: const Icon(Icons.chat_rounded),
                  color: const Color(0xFF25D366),
                  iconSize: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(TaskType type) {
    switch (type) {
      case TaskType.serviceDue:
        return Icons.build_rounded;
      case TaskType.paymentPending:
        return Icons.payments_rounded;
      case TaskType.reminder:
        return Icons.notifications_active_rounded;
      case TaskType.serviceUpcoming:
        return Icons.schedule_rounded;
    }
  }

    Future<void> _openWhatsApp(BuildContext context) async {
    if (item.customerPhone.isEmpty) return;

    // ✅ Use helper — 91 automatically lagega
    final url = PhoneHelper.buildWhatsAppUrl(
      phone: item.customerPhone,
    );

    try {
      await launchUrl(url,
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open WhatsApp'),
        ),
      );
    }
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 25,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final customer = _extractName(reminder['customerId']);
    final vehicle = _extractVehicle(reminder['vehicleId']);
    final service = _extractServiceName(reminder);

    final status = _normalizeStatus(reminder['status']);

    final isCompleted = status == 'completed';
    final isCancelled =
        status == 'cancelled' || status == 'canceled';
    final isDone = isCompleted || isCancelled;

    final due = isDone
        ? _formatStatus(status)
        : _formatReminderDue(reminder['dueDate'], status);

    final urgent = !isDone &&
        (status == 'duetoday' || status == 'overdue');

    Color iconBg;
    Color iconColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    if (isCompleted) {
      iconBg = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.primary;
      iconData = Icons.check_circle_rounded;
    } else if (isCancelled) {
      iconBg = theme.colorScheme.surfaceContainerHighest;
      iconColor = theme.colorScheme.onSurfaceVariant;
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.onSurfaceVariant;
      iconData = Icons.cancel_rounded;
    } else if (urgent) {
      iconBg = theme.colorScheme.errorContainer;
      iconColor = theme.colorScheme.error;
      borderColor =
          theme.colorScheme.error.withValues(alpha: 0.35);
      textColor = theme.colorScheme.error;
      iconData = Icons.notifications_active_rounded;
    } else {
      iconBg = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.primary;
      iconData = Icons.notifications_active_rounded;
    }

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
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? theme
                                .colorScheme
                                .onSurfaceVariant
                            : null,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: isDone
                            ? theme
                                .colorScheme
                                .onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    due,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
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

class _RecentServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const _RecentServiceCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final customer = _extractName(service['customerId']);
    final vehicle = _extractVehicle(service['vehicleId']);
    final serviceName = _extractServiceName(service);

    final amount = _formatCurrency(
      _toDouble(service['totalAmount']),
    );

    final date = _formatDate(
      service['serviceDate'] ?? service['createdAt'],
    );

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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.build_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY CARD
// ============================================================

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

String _extractName(dynamic customer) {
  if (customer is Map) {
    final name = customer['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
  }
  return 'Unknown Customer';
}

String _extractVehicle(dynamic vehicle) {
  if (vehicle is Map) {
    final registration =
        vehicle['registrationNumber']?.toString().trim();

    final brand = vehicle['brand']?.toString().trim();
    final model = vehicle['model']?.toString().trim();

    final parts = <String>[];

    if (brand != null && brand.isNotEmpty) parts.add(brand);
    if (model != null && model.isNotEmpty) parts.add(model);

    final vehicleName = parts.join(' ');

    if (registration != null &&
        registration.isNotEmpty &&
        vehicleName.isNotEmpty) {
      return '$vehicleName • $registration';
    }

    if (registration != null && registration.isNotEmpty) {
      return registration;
    }

    if (vehicleName.isNotEmpty) return vehicleName;
  }

  return 'Vehicle details unavailable';
}

String _extractServiceName(Map<String, dynamic> data) {
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
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return 'Service';
}

String _normalizeStatus(dynamic value) {
  return value
          ?.toString()
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll('-', '') ??
      '';
}

String _formatStatus(String status) {
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

String _formatReminderDue(dynamic rawDate, String status) {
  if (status == 'completed') return 'Completed';
  if (status == 'cancelled' || status == 'canceled') {
    return 'Cancelled';
  }
  if (status == 'overdue') return 'Overdue';
  if (status == 'duetoday') return 'Due Today';

  if (rawDate == null) {
    if (status == 'duesoon') return 'Due Soon';
    return 'Upcoming';
  }

  final date = DateTime.tryParse(rawDate.toString());
  if (date == null) {
    return status == 'duesoon' ? 'Due Soon' : 'Upcoming';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDate = DateTime(
    date.toLocal().year,
    date.toLocal().month,
    date.toLocal().day,
  );

  final difference = dueDate.difference(today).inDays;

  if (difference < 0) return 'Overdue';
  if (difference == 0) return 'Due Today';
  if (difference == 1) return 'Tomorrow';
  return '$difference days';
}

String _formatDate(dynamic value) {
  if (value == null) return '-';

  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();

  final local = date.toLocal();

  return '${local.day.toString().padLeft(2, '0')} '
      '${_monthName(local.month)} '
      '${local.year}';
}

String _monthName(int month) {
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

  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _formatCurrency(double value) {
  final rounded = value.round();
  final formatted = rounded.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < formatted.length; i++) {
    final position = formatted.length - i;
    buffer.write(formatted[i]);

    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }

  return '₹${buffer.toString()}';
}