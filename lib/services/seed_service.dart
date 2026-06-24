import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../models/measurement_model.dart';
import 'database_service.dart';
import 'dart:developer';  

/// DEBUG ONLY — Seeds Firebase Auth and the local SQLite database with sample data.
/// Hard-guarded by [kDebugMode]; does nothing in release mode.
class SeedService {
  static final SeedService instance = SeedService._();
  SeedService._();

  static const _seedEmail    = 'admin@gmail.com';
  static const _seedPassword = 'Admin@123';

  static const _customers = [
    ('c001', 'Ali Hassan',      '0300-1234567', 'House 12, Block A, Larkana'),
    ('c002', 'Usman Khan',      '0311-9876543', 'Street 5, Gulshan Colony'),
    ('c003', 'Bilal Ahmed',     '0333-4567890', 'Near City Hospital, Sukkur'),
    ('c004', 'Farhan Siddiqui', '0321-6543210', 'Main Bazar, Nawabshah'),
    ('c005', 'Zubair Malik',    '0345-1112233', 'Satellite Town, Larkana'),
  ];

  static const _statuses = [
    'Pending',
    'In Progress',
    'Ready',
    'Delivered',
    'Delivered',
  ];

  MeasurementModel _sampleMeasurements(int seed) {
    final lengths = ['42', '44', '46', '40', '43'];
    final arms    = ['23', '24', '22', '25', '23'];
    final chests  = ['40', '42', '38', '44', '41'];
    final waists  = ['36', '38', '34', '40', '37'];
    final i = seed % 5;
    return MeasurementModel(
      lengthMeasure:   lengths[i],
      armMeasure:      arms[i],
      chestMeasure:    chests[i],
      waistMeasure:    waists[i],
      shoulderMeasure: '17',
      collarMeasure:   '15',
      shalwarMeasure:  '40',
      colRegular:      i.isEven,
      colFrench:       i.isOdd,
      cuffType:        i.isEven ? 'Round' : 'Square',
    );
  }

  /// Creates the seed Firebase Auth account (debug only).
  /// Safe to call multiple times — silently skips if the account already exists.
  Future<String?> seedAuthUser() async {
    if (!kDebugMode) return null;
    try {
      log('[SeedService] Creating seed user: $_seedEmail');
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _seedEmail,
        password: _seedPassword,
      );
      log('[SeedService] ✅ Seed user created successfully.');
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        log('[SeedService] ℹ️ Seed user already exists — skipping creation.');
        return null; // Already exists, that's fine
      }
      log('[SeedService] ❌ Failed to create seed user: ${e.message}');
      return e.message ?? 'Unknown error';
    }
  }

  Future<void> seedAll() async {

    if (!kDebugMode) return; // Hard guard — never runs in production

    try {
      log('[SeedService] Starting seed…');
      final db = DatabaseService.instance;
      final now = DateTime.now();

      // ── 1. Customers ─────────────────────────────────────────────────────
      for (final (id, name, phone, address) in _customers) {
        await db.insertCustomer(CustomerModel(
          id: id,
          name: name,
          phone: phone,
          address: address,
          measurements: _sampleMeasurements(_customers.indexWhere((c) => c.$1 == id)),
        ));
      }

      // ── 2. Orders (2 per customer, varied statuses) ───────────────────────
      int orderIdx = 0;
      for (int ci = 0; ci < _customers.length; ci++) {
        final customerId = _customers[ci].$1;
        for (int oi = 0; oi < 2; oi++) {
          final status   = _statuses[orderIdx % _statuses.length];
          final total    = (1200 + orderIdx * 350).toDouble();
          final advance  = status == 'Delivered' ? total : (total * 0.4).roundToDouble();
          final orderDate = now.subtract(Duration(days: 30 - orderIdx * 3));
          final deliveryDate = orderDate.add(Duration(days: 7 + oi * 3));

          await db.insertOrder(OrderModel(
            id: 'o${(orderIdx + 1).toString().padLeft(3, '0')}',
            customerId: customerId,
            isAdult: true,
            quantity: 1 + (orderIdx % 3),
            orderDate: orderDate,
            deliveryDate: deliveryDate,
            totalAmount: total,
            advancePaid: advance,
            measurements: _sampleMeasurements(orderIdx),
            status: status,
          ));
          orderIdx++;
        }
      }

      // ── 3. Expenses ───────────────────────────────────────────────────────
      final expenseData = [
        ('e001', 'Thread & Needles',     'Supplies',   850.0,  30, 'Monthly restocking'),
        ('e002', 'Electricity Bill',     'Utilities', 2400.0,  28, null),
        ('e003', 'Fabric (White Cotton)','Fabric',    5600.0,  25, '10 meters @ 560/m'),
        ('e004', 'Tailor Machine Oil',   'Supplies',   350.0,  20, null),
        ('e005', 'Shop Rent',            'Rent',      8000.0,  15, 'June rent'),
        ('e006', 'Buttons & Zippers',    'Supplies',   600.0,  10, null),
        ('e007', 'Internet Bill',        'Utilities',  900.0,   5, null),
      ];
      for (final (id, title, cat, amount, daysAgo, notes) in expenseData) {
        await db.insertExpense(ExpenseModel(
          id: id,
          title: title,
          category: cat,
          amount: amount,
          date: now.subtract(Duration(days: daysAgo)),
          notes: notes,
        ));
      }

      log('[SeedService] ✅ Seed complete — ${_customers.length} customers, $orderIdx orders, ${expenseData.length} expenses.');
    } catch (e, st) {
      log('[SeedService] ❌ Seed failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    if (!kDebugMode) return;
    try {
      log('[SeedService] Clearing all data…');
      final rawDb = await DatabaseService.instance.database;
      await rawDb.delete('orders');
      await rawDb.delete('customers');
      await rawDb.delete('expenses');
      log('[SeedService] ✅ All data cleared.');
    } catch (e) {
      log('[SeedService] ❌ Clear failed: $e');
      rethrow;
    }
  }
}
