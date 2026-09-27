import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../services/analytics_export_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _garageName = 'Garage';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<AnalyticsProvider>()
          .fetchDashboard(range: 'month');

      _loadGarageName();
    });
  }

  Future<void> _loadGarageName() async {
    try {
      final response = await ApiService.get('/auth/me');

      if (!mounted) return;

      final user = response['user'];
      final garage = user?['garage'];

      if (garage?['name'] != null) {
        setState(() {
          _garageName = garage['name'].toString();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Analytics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (context, provider, child) {
              if (provider.data == null) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.download_rounded),
                onSelected: (value) {
                  if (value == 'pdf') {
                    AnalyticsExportService.exportToPdf(
                      data: provider.data!,
                      garageName: _garageName,
                    );
                  } else if (value == 'csv') {
                    AnalyticsExportService.exportToCsv(
                      data: provider.data!,
                      garageName: _garageName,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded),
                        SizedBox(width: 10),
                        Text('Export PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_rounded),
                        SizedBox(width: 10),
                        Text('Export CSV'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.data == null) {
            return _buildError(provider);
          }

          if (provider.data == null) {
            return const Center(
              child: Text('No data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchDashboard(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildRangeFilter(provider),
                const SizedBox(height: 16),
                _buildSummaryCards(provider.data!),
                const SizedBox(height: 20),
                _buildMonthlyRevenueChart(provider.data!),
                const SizedBox(height: 20),
                _buildCollectionCard(provider.data!),
                const SizedBox(height: 20),
                _buildTopCustomers(provider.data!),
                const SizedBox(height: 20),
                _buildServiceTypes(provider.data!),
                const SizedBox(height: 20),
                _buildBusyDays(provider.data!),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RANGE FILTER
  // ============================================================

  Widget _buildRangeFilter(AnalyticsProvider provider) {
    final ranges = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': 'This Week'},
      {'key': 'month', 'label': 'This Month'},
      {'key': 'year', 'label': 'This Year'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...ranges.map((r) {
            final isSelected =
                provider.range == r['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(r['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    provider.changeRange(r['key']!);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(AnalyticsData data) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Revenue',
                value: currency.format(data.summary.totalRevenue),
                icon: Icons.trending_up_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Billed',
                value: currency.format(data.summary.totalBilled),
                icon: Icons.receipt_long_rounded,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pending',
                value: currency.format(data.summary.pendingAmount),
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Avg Service',
                value: currency.format(data.summary.avgServiceValue),
                icon: Icons.analytics_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MONTHLY REVENUE CHART
  // ============================================================

  Widget _buildMonthlyRevenueChart(AnalyticsData data) {
    final monthly = data.monthlyRevenue;

    if (monthly.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue = monthly
        .map((m) => m.revenue)
        .reduce((a, b) => a > b ? a : b);

    final maxY = maxRevenue > 0 ? maxRevenue * 1.2 : 100.0;

    return _ChartCard(
      title: 'Monthly Revenue (Last 12 Months)',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '₹${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= monthly.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        monthly[idx].monthName,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (monthly.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: monthly.asMap().entries.map((e) {
                  return FlSpot(
                    e.key.toDouble(),
                    e.value.revenue,
                  );
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COLLECTION CARD
  // ============================================================

  Widget _buildCollectionCard(AnalyticsData data) {
    final collection = data.collection;
    final rate = collection.collectionRate;
    final progress = (rate / 100).clamp(0.0, 1.0);

    return _ChartCard(
      title: 'Payment Collection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${collection.fullyPaidCount} / ${collection.totalCount} invoices fully paid',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                rate >= 80
                    ? Colors.green
                    : rate >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(
                color: Colors.green,
                label:
                    'Paid: ${collection.fullyPaidCount}',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: Colors.orange,
                label:
                    'Pending: ${collection.pendingCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP CUSTOMERS
  // ============================================================

  Widget _buildTopCustomers(AnalyticsData data) {
    if (data.topCustomers.isEmpty) {
      return const SizedBox.shrink();
    }

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return _ChartCard(
      title: 'Top 10 Customers',
      child: Column(
        children: data.topCustomers.asMap().entries.map((e) {
          final idx = e.key + 1;
          final c = e.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: idx <= 3
                        ? Colors.amber.shade100
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: idx <= 3
                            ? Colors.amber.shade900
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (c.customerPhone != null)
                        Text(
                          c.customerPhone!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(c.totalRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${c.invoiceCount} invoices',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SERVICE TYPES
  // ============================================================

  Widget _buildServiceTypes(AnalyticsData data) {
    if (data.serviceTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = data.serviceTypes
        .fold<int>(0, (sum, s) => sum + s.count);

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return _ChartCard(
      title: 'Service Type Breakdown',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.serviceTypes
                    .take(8)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final idx = e.key;
                  final s = e.value;
                  final percent = total > 0
                      ? (s.count / total) * 100
                      : 0;

                  return PieChartSectionData(
                    value: s.count.toDouble(),
                    color: colors[idx % colors.length],
                    radius: 55,
                    title: percent >= 10
                        ? '${percent.toStringAsFixed(0)}%'
                        : '',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: data.serviceTypes
                .take(8)
                .toList()
                .asMap()
                .entries
                .map((e) {
              final idx = e.key;
              final s = e.value;

              return _LegendDot(
                color: colors[idx % colors.length],
                label: '${s.serviceType} (${s.count})',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSY DAYS
  // ============================================================

  Widget _buildBusyDays(AnalyticsData data) {
    if (data.busyDays.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = data.busyDays
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b);

    final maxY = maxCount > 0 ? maxCount * 1.3 : 10.0;

    return _ChartCard(
      title: 'Busy Days (by Service Count)',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 ||
                        idx >= data.busyDays.length) {
                      return const SizedBox.shrink();
                    }
                    final day = data.busyDays[idx].day;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        day.substring(0, 3),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: data.busyDays
                .asMap()
                .entries
                .map((e) {
              final isMax = e.value.count == maxCount;

              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    color: isMax
                        ? Colors.blue.shade700
                        : Colors.blue.shade300,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildError(AnalyticsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Unable to load analytics',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => provider.fetchDashboard(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    );
  }
}

// ============================================================
// CHART CARD
// ============================================================

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// LEGEND DOT
// ============================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}