import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../controllers/profile_controller.dart';

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

  static Future<void> exportToPDF(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tailor_app.db');
      final db = await openDatabase(path);

      final customers = await db.query('customers');
      final orders = await db.query('orders');
      final expenses = await db.query('expenses');

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

      final file = File(join(directory!.path, 'tailor_app_export_${DateTime.now().millisecondsSinceEpoch}.pdf'));
      await file.writeAsBytes(await pdf.save());

      if (!context.mounted) return;
      _showToast(context, 'Export successful! Saved PDF to Downloads.', Colors.green);
    } catch (e) {
      if (!context.mounted) return;
      _showToast(context, 'Failed to export: $e', Colors.red);
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
