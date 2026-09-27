// ============================================================
// ANALYTICS SUMMARY
// ============================================================

class AnalyticsSummary {
  final double totalRevenue;
  final double totalBilled;
  final double pendingAmount;
  final int totalInvoices;
  final double avgServiceValue;

  AnalyticsSummary({
    required this.totalRevenue,
    required this.totalBilled,
    required this.pendingAmount,
    required this.totalInvoices,
    required this.avgServiceValue,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      avgServiceValue: (json['avgServiceValue'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// MONTHLY REVENUE
// ============================================================

class MonthlyRevenue {
  final int year;
  final int month;
  final String monthName;
  final String label;
  final double revenue;
  final double billed;
  final int invoices;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.monthName,
    required this.label,
    required this.revenue,
    required this.billed,
    required this.invoices,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      monthName: json['monthName']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      billed: (json['billed'] as num?)?.toDouble() ?? 0,
      invoices: (json['invoices'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// TOP CUSTOMER
// ============================================================

class TopCustomer {
  final String id;
  final String customerName;
  final String? customerPhone;
  final double totalRevenue;
  final double totalBilled;
  final double pendingAmount;
  final int invoiceCount;

  TopCustomer({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.totalRevenue,
    required this.totalBilled,
    required this.pendingAmount,
    required this.invoiceCount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Unknown',
      customerPhone: json['customerPhone']?.toString(),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// SERVICE TYPE
// ============================================================

class ServiceTypeStat {
  final String serviceType;
  final int count;
  final double revenue;
  final double totalBilled;

  ServiceTypeStat({
    required this.serviceType,
    required this.count,
    required this.revenue,
    required this.totalBilled,
  });

  factory ServiceTypeStat.fromJson(Map<String, dynamic> json) {
    return ServiceTypeStat(
      serviceType: json['serviceType']?.toString() ?? 'Other',
      count: (json['count'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// COLLECTION DATA
// ============================================================

class CollectionData {
  final double totalBilled;
  final double totalPaid;
  final double collectionRate;
  final int fullyPaidCount;
  final int pendingCount;
  final int totalCount;

  CollectionData({
    required this.totalBilled,
    required this.totalPaid,
    required this.collectionRate,
    required this.fullyPaidCount,
    required this.pendingCount,
    required this.totalCount,
  });

  factory CollectionData.fromJson(Map<String, dynamic> json) {
    return CollectionData(
      totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      collectionRate: (json['collectionRate'] as num?)?.toDouble() ?? 0,
      fullyPaidCount: (json['fullyPaidCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// BUSY DAY
// ============================================================

class BusyDay {
  final String day;
  final int dayIndex;
  final int count;
  final double revenue;

  BusyDay({
    required this.day,
    required this.dayIndex,
    required this.count,
    required this.revenue,
  });

  factory BusyDay.fromJson(Map<String, dynamic> json) {
    return BusyDay(
      day: json['day']?.toString() ?? '',
      dayIndex: (json['dayIndex'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// FULL ANALYTICS DATA
// ============================================================

class AnalyticsData {
  final String rangeType;
  final DateTime startDate;
  final DateTime endDate;

  final AnalyticsSummary summary;
  final List<MonthlyRevenue> monthlyRevenue;
  final List<TopCustomer> topCustomers;
  final List<ServiceTypeStat> serviceTypes;
  final CollectionData collection;
  final List<BusyDay> busyDays;
  final List<Map<String, dynamic>> recentInvoices;

  AnalyticsData({
    required this.rangeType,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.monthlyRevenue,
    required this.topCustomers,
    required this.serviceTypes,
    required this.collection,
    required this.busyDays,
    required this.recentInvoices,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>? ?? {};

    return AnalyticsData(
      rangeType: range['type']?.toString() ?? 'month',
      startDate: range['startDate'] != null
          ? DateTime.parse(range['startDate'].toString())
          : DateTime.now(),
      endDate: range['endDate'] != null
          ? DateTime.parse(range['endDate'].toString())
          : DateTime.now(),
      summary: AnalyticsSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] ?? {}),
      ),
      monthlyRevenue: (json['monthlyRevenue'] as List?)
              ?.map((e) => MonthlyRevenue.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          [],
      topCustomers: (json['topCustomers'] as List?)
              ?.map((e) => TopCustomer.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          [],
      serviceTypes: (json['serviceTypes'] as List?)
              ?.map((e) => ServiceTypeStat.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          [],
      collection: CollectionData.fromJson(
        Map<String, dynamic>.from(json['collection'] ?? {}),
      ),
      busyDays: (json['busyDays'] as List?)
              ?.map((e) => BusyDay.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          [],
      recentInvoices: (json['recentInvoices'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}