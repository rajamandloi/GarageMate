import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/analytics_model.dart';

class AnalyticsExportService {
  // ============================================================
  // EXPORT TO PDF
  // ============================================================

  static Future<void> exportToPdf({
    required AnalyticsData data,
    required String garageName,
  }) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // ================================================
          // HEADER
          // ================================================
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  garageName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Business Analytics Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${dateFormat.format(data.startDate)} - ${dateFormat.format(data.endDate)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ================================================
          // SUMMARY
          // ================================================
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              [
                'Total Revenue (Paid)',
                currencyFormat.format(data.summary.totalRevenue),
              ],
              [
                'Total Billed',
                currencyFormat.format(data.summary.totalBilled),
              ],
              [
                'Pending Amount',
                currencyFormat.format(data.summary.pendingAmount),
              ],
              [
                'Total Invoices',
                data.summary.totalInvoices.toString(),
              ],
              [
                'Average Service Value',
                currencyFormat.format(data.summary.avgServiceValue),
              ],
              [
                'Collection Rate',
                '${data.collection.collectionRate.toStringAsFixed(1)}%',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),

          pw.SizedBox(height: 20),

          // ================================================
          // TOP CUSTOMERS
          // ================================================
          if (data.topCustomers.isNotEmpty) ...[
            pw.Text(
              'Top Customers',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              headers: [
                '#',
                'Customer',
                'Invoices',
                'Revenue',
              ],
              data: data.topCustomers.asMap().entries.map((e) {
                final idx = e.key + 1;
                final c = e.value;
                return [
                  idx.toString(),
                  c.customerName,
                  c.invoiceCount.toString(),
                  currencyFormat.format(c.totalRevenue),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            pw.SizedBox(height: 20),
          ],

          // ================================================
          // SERVICE TYPES
          // ================================================
          if (data.serviceTypes.isNotEmpty) ...[
            pw.Text(
              'Service Type Breakdown',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              headers: [
                'Service Type',
                'Count',
                'Revenue',
              ],
              data: data.serviceTypes.map((s) {
                return [
                  s.serviceType,
                  s.count.toString(),
                  currencyFormat.format(s.revenue),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            pw.SizedBox(height: 20),
          ],

          // ================================================
          // FOOTER
          // ================================================
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by GarageMate on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    // Save & share
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/analytics_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Business Analytics Report',
      text: '$garageName — Analytics Report',
    );
  }

  // ============================================================
  // EXPORT TO CSV
  // ============================================================

  static Future<void> exportToCsv({
    required AnalyticsData data,
    required String garageName,
  }) async {
    final rows = <List<dynamic>>[];

    // Header
    rows.add(['$garageName — Analytics Report']);
    rows.add([
      'Period',
      '${DateFormat('dd MMM yyyy').format(data.startDate)} - ${DateFormat('dd MMM yyyy').format(data.endDate)}',
    ]);
    rows.add([]);

    // Summary
    rows.add(['SUMMARY']);
    rows.add(['Metric', 'Value']);
    rows.add(['Total Revenue', data.summary.totalRevenue]);
    rows.add(['Total Billed', data.summary.totalBilled]);
    rows.add(['Pending Amount', data.summary.pendingAmount]);
    rows.add(['Total Invoices', data.summary.totalInvoices]);
    rows.add(['Average Service Value', data.summary.avgServiceValue]);
    rows.add(['Collection Rate %', data.collection.collectionRate]);
    rows.add([]);

    // Top Customers
    rows.add(['TOP CUSTOMERS']);
    rows.add(['Rank', 'Customer', 'Invoices', 'Revenue']);
    for (var i = 0; i < data.topCustomers.length; i++) {
      final c = data.topCustomers[i];
      rows.add([
        i + 1,
        c.customerName,
        c.invoiceCount,
        c.totalRevenue,
      ]);
    }
    rows.add([]);

    // Service Types
    rows.add(['SERVICE TYPES']);
    rows.add(['Service Type', 'Count', 'Revenue']);
    for (final s in data.serviceTypes) {
      rows.add([s.serviceType, s.count, s.revenue]);
    }
    rows.add([]);

    // Monthly Revenue
    rows.add(['MONTHLY REVENUE']);
    rows.add(['Month', 'Revenue', 'Billed', 'Invoices']);
    for (final m in data.monthlyRevenue) {
      rows.add([m.label, m.revenue, m.billed, m.invoices]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/analytics_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Business Analytics Report',
      text: '$garageName — Analytics (CSV)',
    );
  }
}