import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/profile_controller.dart';
import '../models/expense_model.dart';

class BackupExportService {
  static Future<void> createBackup(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tailor_app.db');
      
      final dbFile = File(path);
      if (!await dbFile.exists()) {
        if (!context.mounted) return;
        _showToast(context, 'No database found to backup.', Colors.red);
        return;
      }

      // We'll save it to the public downloads directory (Android) or Documents (iOS)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final backupPath = join(directory!.path, 'tailor_app_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupPath);
      
      if (!context.mounted) return;
      _showToast(context, 'Backup successful! Saved to Downloads.', Colors.green);
    } catch (e) {
      if (!context.mounted) return;
      _showToast(context, 'Failed to backup: $e', Colors.red);
    }
  }

  static Future<void> exportToPDF(
    BuildContext context, {
    String filterType = 'All',
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tailor_app.db');
      final db = await openDatabase(path);

      var customers = await db.query('customers');
      var orders = await db.query('orders');
      var expenses = await db.query('expenses');

      bool isDateInRange(String? dateStr) {
        if (filterType == 'All' || dateStr == null) return true;
        
        DateTime? date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          return true; // If we can't parse, include it just in case
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        if (filterType == 'Daily') {
          return date.isAfter(today) || date.isAtSameMomentAs(today);
        } else if (filterType == 'Weekly') {
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          return date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek);
        } else if (filterType == 'Monthly') {
          final startOfMonth = DateTime(today.year, today.month, 1);
          return date.isAfter(startOfMonth) || date.isAtSameMomentAs(startOfMonth);
        } else if (filterType == 'Custom') {
          if (customStartDate != null && customEndDate != null) {
            final start = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
            final end = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59);
            return date.isAfter(start) && date.isBefore(end);
          }
        }
        return true;
      }

      customers = customers.where((c) => isDateInRange(c['createdAt']?.toString())).toList();
      orders = orders.where((o) => isDateInRange(o['orderDate']?.toString())).toList();
      expenses = expenses.where((e) => isDateInRange(e['date']?.toString())).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10.0),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
              ),
              padding: const pw.EdgeInsets.only(top: 10.0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Powered by TryUnity Solutios', style: pw.TextStyle(color: PdfColors.grey, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('+92 302 3476605', style: pw.TextStyle(color: PdfColors.grey, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text('${ProfileController().profile?.shopName ?? 'Tailor App'} - Data Export', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              
              pw.Header(level: 1, child: pw.Text('Customers (${customers.length})')),
              if (customers.isEmpty) pw.Text('No customers found.') else
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Name', 'Phone', 'Address'],
                    ...customers.map((c) => [c['name'].toString(), c['phone'].toString(), c['address'].toString()]),
                  ],
                ),
              pw.SizedBox(height: 20),

              pw.Header(level: 1, child: pw.Text('Orders (${orders.length})')),
              if (orders.isEmpty) pw.Text('No orders found.') else
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Date', 'Amount', 'Status'],
                    ...orders.map((o) => [o['orderDate'].toString(), 'PKR ${o['totalAmount']}', o['status'].toString()]),
                  ],
                ),
              pw.SizedBox(height: 20),

              pw.Header(level: 1, child: pw.Text('Expenses (${expenses.length})')),
              if (expenses.isEmpty) pw.Text('No expenses found.') else
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Date', 'Title', 'Category', 'Amount'],
                    ...expenses.map((e) => [e['date'].toString(), e['title'].toString(), e['category'].toString(), 'PKR ${e['amount']}']),
                  ],
                ),
            ];
          },
        ),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File(join(directory!.path, 'irfan_tailor_export_${DateTime.now().millisecondsSinceEpoch}.pdf'));
      await file.writeAsBytes(await pdf.save());

      if (!context.mounted) return;
      _showToast(context, 'Export successful! Saved PDF to Downloads.', Colors.green);
    } catch (e) {
      if (!context.mounted) return;
      _showToast(context, 'Failed to export: $e', Colors.red);
    }
  }

  static Future<void> exportExpensesToPDF(
    BuildContext context, {
    required List<ExpenseModel> expenses,
    required String periodTitle,
    String? categoryFilter,
    String? walletSourceFilter,
  }) async {
    try {
      final shopName = ProfileController().profile?.shopName ?? 'Tailor App';
      final totalAmount = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      final shopAmount = expenses
          .where((e) => e.walletSource != 'other')
          .fold<double>(0.0, (sum, e) => sum + e.amount);
      final otherAmount = expenses
          .where((e) => e.walletSource == 'other')
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (pw.Context ctx) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10.0),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
              ),
              padding: const pw.EdgeInsets.only(top: 10.0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Powered by TryUnity Solutions',
                    style: pw.TextStyle(
                      color: PdfColors.grey,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '+92 302 3476605',
                    style: pw.TextStyle(
                      color: PdfColors.grey,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1E3A5F'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Expenses Report',
                          style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Generated: ${DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Period: $periodTitle',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // KPI / Summary Row
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Expenses', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
                          pw.SizedBox(height: 4),
                          pw.Text('${expenses.length} records', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Amount', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
                          pw.SizedBox(height: 4),
                          pw.Text('PKR ${NumberFormat('#,##0').format(totalAmount.toInt())}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#EF4444'))),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Shop / Other Wallet', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
                          pw.SizedBox(height: 4),
                          pw.Text('PKR ${NumberFormat('#,##0').format(shopAmount.toInt())} / ${NumberFormat('#,##0').format(otherAmount.toInt())}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A5F'))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Filter tags if applied
              if (categoryFilter != null || walletSourceFilter != null) ...[
                pw.Row(
                  children: [
                    if (categoryFilter != null) ...[
                      pw.Text('Category: $categoryFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(width: 12),
                    ],
                    if (walletSourceFilter != null) ...[
                      pw.Text('Source: $walletSourceFilter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ],
                ),
                pw.SizedBox(height: 8),
              ],

              // Table
              if (expenses.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  alignment: pw.Alignment.center,
                  child: pw.Text('No expense records found for the selected criteria.',
                      style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11)),
                )
              else
                pw.TableHelper.fromTextArray(
                  context: ctx,
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A5F')),
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  headers: <String>['#', 'Date', 'Expense Title', 'Category', 'Source', 'Amount'],
                  data: List<List<String>>.generate(expenses.length, (index) {
                    final e = expenses[index];
                    return [
                      '${index + 1}',
                      DateFormat('dd MMM yyyy').format(e.date),
                      e.title + (e.notes != null && e.notes!.isNotEmpty ? ' (${e.notes})' : ''),
                      e.category.isNotEmpty ? e.category : 'General',
                      e.walletSource == 'other' ? 'Other Wallet' : 'Shop Profit',
                      'PKR ${NumberFormat('#,##0').format(e.amount.toInt())}',
                    ];
                  }),
                ),

              pw.SizedBox(height: 12),
              // Grand Total Row
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: PKR ${NumberFormat('#,##0').format(totalAmount.toInt())}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F172A'),
                  ),
                ),
              ),
            ];
          },
        ),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'expenses_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(join(directory!.path, fileName));
      await file.writeAsBytes(await pdf.save());

      if (!context.mounted) return;
      _showToast(context, 'PDF saved to Downloads!', Colors.green);

      try {
        await Share.shareXFiles([XFile(file.path)], subject: 'Expenses Report - $shopName');
      } catch (_) {}
    } catch (e) {
      if (!context.mounted) return;
      _showToast(context, 'Failed to export expenses: $e', Colors.red);
    }
  }

  static void _showToast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
