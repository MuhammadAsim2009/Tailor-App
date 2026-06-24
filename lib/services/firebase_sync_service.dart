import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../models/profile_model.dart';
import '../controllers/order_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/profile_controller.dart';
import 'database_service.dart';
import 'dart:async';
import 'dart:developer';

enum SyncStatus { synced, pending, syncing, error }

class FirebaseSyncService extends ChangeNotifier {
  static final FirebaseSyncService instance = FirebaseSyncService._init();
  FirebaseSyncService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SyncStatus _status = SyncStatus.synced;
  int _pendingOps = 0;
  Timer? _syncTimeoutTimer;

  static const _syncTimeout = Duration(seconds: 30);

  SyncStatus get status => _status;
  String get statusLabel {
    switch (_status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  // ── Fire-and-forget individual ops ───────────────────────────────────────
  void _startOp() {
    _pendingOps++;
    if (_status != SyncStatus.syncing) {
      _status = SyncStatus.syncing;
      notifyListeners();
      _syncTimeoutTimer?.cancel();
      _syncTimeoutTimer = Timer(_syncTimeout, () {
        if (_pendingOps > 0) {
          _status = SyncStatus.pending;
          notifyListeners();
        }
      });
    }
  }

  void _finishOp({bool error = false}) {
    _pendingOps = (_pendingOps - 1).clamp(0, 9999);
    if (_pendingOps == 0) {
      _syncTimeoutTimer?.cancel();
      _syncTimeoutTimer = null;
      _status = error ? SyncStatus.error : SyncStatus.synced;
      notifyListeners();
    }
  }

  void syncCustomer(CustomerModel customer) {
    _startOp();
    if (customer.deletedAt != null) {
      _firestore.collection('customers').doc(customer.id).delete().then((_) {
        DatabaseService.instance.purgeCustomer(customer.id);
        _finishOp();
      }).catchError((e) {
        log('Error deleting customer from firestore: $e');
        _finishOp(error: true);
      });
    } else {
      _firestore.collection('customers').doc(customer.id).set(customer.toFirestore()).then((_) {
        _finishOp();
      }).catchError((e) {
        log('Error syncing customer: $e');
        _finishOp(error: true);
      });
    }
  }

  void deleteCustomer(String id) {}

  void syncOrder(OrderModel order) {
    _startOp();
    if (order.deletedAt != null) {
      _firestore.collection('orders').doc(order.id).delete().then((_) {
        DatabaseService.instance.purgeOrder(order.id);
        _finishOp();
      }).catchError((e) {
        log('Error deleting order from firestore: $e');
        _finishOp(error: true);
      });
    } else {
      _firestore.collection('orders').doc(order.id).set(order.toFirestore()).then((_) {
        _finishOp();
      }).catchError((e) {
        log('Error syncing order: $e');
        _finishOp(error: true);
      });
    }
  }

  void deleteOrder(String id) {}

  void syncExpense(ExpenseModel expense) {
    _startOp();
    if (expense.deletedAt != null) {
      _firestore.collection('expenses').doc(expense.id).delete().then((_) {
        DatabaseService.instance.purgeExpense(expense.id);
        _finishOp();
      }).catchError((e) {
        log('Error deleting expense from firestore: $e');
        _finishOp(error: true);
      });
    } else {
      _firestore.collection('expenses').doc(expense.id).set(expense.toFirestore()).then((_) {
        _finishOp();
      }).catchError((e) {
        log('Error syncing expense: $e');
        _finishOp(error: true);
      });
    }
  }

  void deleteExpense(String id) {}

  void syncProfile(Map<String, dynamic> profileMap) {
    _startOp();
    final profile = ProfileModel.fromMap(profileMap);
    _firestore
        .collection('profile')
        .doc(profile.id)
        .set(profile.toFirestore())
        .then((_) {
      _finishOp();
    }).catchError((e) {
      log('Error syncing profile: $e');
      _finishOp(error: true);
    });
  }

  // ── Full two-way sync ─────────────────────────────────────────────────────
  /// Uses a [lastSyncAt] anchor stored in SharedPreferences.
  ///
  /// Conflict resolution rules (per record):
  /// 1. If cloud.updatedAt  > lastSyncAt AND local.updatedAt <= lastSyncAt → pull cloud
  /// 2. If local.updatedAt  > lastSyncAt AND cloud.updatedAt <= lastSyncAt → push local
  /// 3. If both changed since lastSyncAt (true conflict)                   → newer wins
  /// 4. If timestamps are equal but data differs (e.g. Firebase Console edit
  ///    without bumping updatedAt)                                          → pull cloud
  Future<void> performTwoWaySync() async {
    if (_status == SyncStatus.syncing) return;

    try {
      log('Starting two-way sync...');
      _status = SyncStatus.syncing;
      notifyListeners();

      final dbService = DatabaseService.instance;
      final lastSyncAt = await dbService.getLastSyncAt();
      final syncStartedAt = DateTime.now();

      log('Last sync anchor: $lastSyncAt');

      final sqldb = await dbService.database;

      // ── METADATA RICHNESS CHECK ───────────────────────────────────────────
      final metaDoc = await _firestore.collection('metadata').doc('sync_info').get();
      int cloudOrdersCount = 0;
      int cloudCustomersCount = 0;
      int cloudExpensesCount = 0;
      
      if (metaDoc.exists) {
        final data = metaDoc.data()!;
        cloudOrdersCount = data['ordersCount'] ?? 0;
        cloudCustomersCount = data['customersCount'] ?? 0;
        cloudExpensesCount = data['expensesCount'] ?? 0;
      }

      final localCustomersCount = (await dbService.getAllCustomers()).length;
      final localOrdersCount = (await dbService.getAllOrders()).length;
      final localExpensesCount = (await dbService.getExpenses()).length;

      log('--- Richness Check ---');
      log('Local DB  -> Customers: $localCustomersCount | Orders: $localOrdersCount | Expenses: $localExpensesCount');
      log('Firebase  -> Customers: $cloudCustomersCount | Orders: $cloudOrdersCount | Expenses: $cloudExpensesCount');
      
      if (localOrdersCount == 0 && cloudOrdersCount > 0) {
        log('Condition met: SQLite local DB is empty/deleted, Firebase is richer. Pulling all data from Firebase.');
      } else if (cloudOrdersCount == 0 && localOrdersCount > 0) {
        log('Condition met: Firebase is empty, SQLite local DB is richer. Pushing all data to Firebase.');
      } else if (cloudOrdersCount > localOrdersCount) {
        log('Condition met: Firebase data is richer. Missing records will be transferred to SQLite.');
      } else if (localOrdersCount > cloudOrdersCount) {
        log('Condition met: SQLite data is richer. Missing records will be transferred to Firebase.');
      }

      // ── GRANULAR TWO-WAY MERGE ────────────────────────────────────────────
      // This safely implements the transfers checked above without risking data loss
      await _syncProfileCollection(dbService, sqldb, lastSyncAt);
      await _syncCustomersCollection(dbService, sqldb, lastSyncAt);
      await _syncOrdersCollection(dbService, sqldb, lastSyncAt);
      await _syncExpensesCollection(dbService, sqldb, lastSyncAt);

      await dbService.saveLastSyncAt(syncStartedAt);

      // ── UPDATE METADATA ───────────────────────────────────────────────────
      // After sync, both sides are fully matched. Update Firebase metadata.
      await _firestore.collection('metadata').doc('sync_info').set({
        'customersCount': (await dbService.getAllCustomers()).length,
        'ordersCount': (await dbService.getAllOrders()).length,
        'expensesCount': (await dbService.getExpenses()).length,
        'globalLastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Force UI controllers to reload from the freshly updated SQLite database
      await Future.wait([
        OrderController().loadData(),
        ExpenseController().loadExpenses(),
        ProfileController().loadProfile(),
      ]);

      log('Two-way sync completed. New anchor: $syncStartedAt');
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e, st) {
      log('Error during two-way sync: $e\n$st');
      _status = SyncStatus.error;
      notifyListeners();
    }
  }

  /// Completely wipes the local SQLite database and overwrites it with whatever is in Firebase.
  /// Used exclusively for manual pull-to-refresh.
  Future<void> forcePullFromFirebase() async {
    if (_status == SyncStatus.syncing) return;
    try {
      _status = SyncStatus.syncing;
      notifyListeners();

      final dbService = DatabaseService.instance;
      final sqldb = await dbService.database;

      log('--- FORCE PULL: Fetching all Firebase data ---');
      final profileSnap = await _firestore.collection('profile').get();
      final customersSnap = await _firestore.collection('customers').get();
      final ordersSnap = await _firestore.collection('orders').get();
      final expensesSnap = await _firestore.collection('expenses').get();

      log('--- FORCE PULL: Wiping local SQLite tables ---');
      await sqldb.delete('profile');
      await sqldb.delete('customers');
      await sqldb.delete('orders');
      await sqldb.delete('expenses');

      log('--- FORCE PULL: Inserting Firebase data into SQLite ---');
      if (profileSnap.docs.isNotEmpty) {
        final profile = ProfileModel.fromFirestore(profileSnap.docs.first.data());
        await sqldb.insert('profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var doc in customersSnap.docs) {
        final customer = CustomerModel.fromFirestore(doc.data());
        await sqldb.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var doc in ordersSnap.docs) {
        final order = OrderModel.fromFirestore(doc.data());
        await sqldb.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var doc in expensesSnap.docs) {
        final expense = ExpenseModel.fromFirestore(doc.data());
        await sqldb.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await dbService.saveLastSyncAt(DateTime.now());

      // Force UI controllers to reload from the freshly overwritten SQLite database
      await Future.wait([
        OrderController().loadData(),
        ExpenseController().loadExpenses(),
        ProfileController().loadProfile(),
      ]);

      log('Force pull completed. SQLite overwritten successfully.');
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e, st) {
      log('Error during force pull: $e\n$st');
      _status = SyncStatus.error;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true when a cloud record should win over a local one.
  /// Cloud wins when it was updated after lastSyncAt (meaning it changed in
  /// Firebase), OR when timestamps are identical (Firebase Console edits that
  /// don't bump updatedAt) – we trust cloud in that case.
  bool _cloudWins(DateTime cloudUpdatedAt, DateTime localUpdatedAt, DateTime? lastSyncAt) {
    if (cloudUpdatedAt.isAfter(localUpdatedAt)) return true;
    if (localUpdatedAt.isAfter(cloudUpdatedAt)) return false;
    // Timestamps equal: cloud wins unless local was changed since last sync
    if (lastSyncAt == null) return true; // first sync, trust cloud
    return !localUpdatedAt.isAfter(lastSyncAt); // local untouched → pull cloud
  }

  // ── Collection sync methods ───────────────────────────────────────────────

  Future<void> _syncProfileCollection(
      DatabaseService dbService, Database sqldb, DateTime? lastSyncAt) async {
    final cloudSnapshot = await _firestore.collection('profile').get();
    final localProfileMap = await dbService.getProfile();
    final localProfile = ProfileModel.fromMap(localProfileMap);

    if (cloudSnapshot.docs.isNotEmpty) {
      final cloudProfile = ProfileModel.fromFirestore(cloudSnapshot.docs.first.data());
      if (_cloudWins(cloudProfile.updatedAt, localProfile.updatedAt, lastSyncAt)) {
        log('Profile: pulling from cloud');
        await sqldb.update('profile', cloudProfile.toMap(),
            where: 'id = ?', whereArgs: [cloudProfile.id]);
      } else {
        log('Profile: pushing local to cloud');
        await _firestore.collection('profile').doc(localProfile.id).set(localProfile.toFirestore());
      }
    } else {
      log('Profile: no cloud record, pushing local');
      await _firestore.collection('profile').doc(localProfile.id).set(localProfile.toFirestore());
    }
  }

  Future<void> _syncCustomersCollection(
      DatabaseService dbService, Database sqldb, DateTime? lastSyncAt) async {
    final cloudSnapshot = await _firestore.collection('customers').get();
    final localRecords = await dbService.getSyncCustomers();

    final cloudMap = {for (var doc in cloudSnapshot.docs) doc.id: CustomerModel.fromFirestore(doc.data())};
    final localMap = {for (var record in localRecords) record.id: record};

    final allIds = <String>{...cloudMap.keys, ...localMap.keys};

    for (final id in allIds) {
      try {
        final cloud = cloudMap[id];
        final local = localMap[id];

        if (cloud != null && local != null) {
          final takeCloud = _cloudWins(cloud.updatedAt, local.updatedAt, lastSyncAt);
          final winner = takeCloud ? cloud : local;

          if (takeCloud) {
            log('Customer $id: pulling from cloud');
            await sqldb.update('customers', cloud.toMap(), where: 'id = ?', whereArgs: [id]);
          } else {
            log('Customer $id: pushing local to cloud');
            await _firestore.collection('customers').doc(id).set(local.toFirestore());
          }

          if (winner.deletedAt != null) {
            await _firestore.collection('customers').doc(id).delete();
            await dbService.purgeCustomer(id);
          }
        } else if (cloud != null && local == null) {
          if (cloud.deletedAt == null) {
            log('Customer $id: new from cloud, inserting locally');
            await sqldb.insert('customers', cloud.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await _firestore.collection('customers').doc(id).delete();
          }
        } else if (cloud == null && local != null) {
          if (local.deletedAt == null) {
            log('Customer $id: local only, pushing to cloud');
            await _firestore.collection('customers').doc(id).set(local.toFirestore());
          } else {
            await dbService.purgeCustomer(id);
          }
        }
      } catch (e) {
        log('Failed to sync customer $id: $e');
      }
    }
  }

  Future<void> _syncOrdersCollection(
      DatabaseService dbService, Database sqldb, DateTime? lastSyncAt) async {
    final cloudSnapshot = await _firestore.collection('orders').get();
    final localRecords = await dbService.getSyncOrders();

    final cloudMap = {for (var doc in cloudSnapshot.docs) doc.id: OrderModel.fromFirestore(doc.data())};
    final localMap = {for (var record in localRecords) record.id: record};

    final allIds = <String>{...cloudMap.keys, ...localMap.keys};

    for (final id in allIds) {
      try {
        final cloud = cloudMap[id];
        final local = localMap[id];

        if (cloud != null && local != null) {
          final takeCloud = _cloudWins(cloud.updatedAt, local.updatedAt, lastSyncAt);
          final winner = takeCloud ? cloud : local;

          if (takeCloud) {
            log('Order $id: pulling from cloud');
            await sqldb.update('orders', cloud.toMap(), where: 'id = ?', whereArgs: [id]);
          } else {
            log('Order $id: pushing local to cloud');
            await _firestore.collection('orders').doc(id).set(local.toFirestore());
          }

          if (winner.deletedAt != null) {
            await _firestore.collection('orders').doc(id).delete();
            await dbService.purgeOrder(id);
          }
        } else if (cloud != null && local == null) {
          if (cloud.deletedAt == null) {
            log('Order $id: new from cloud, inserting locally');
            await sqldb.insert('orders', cloud.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await _firestore.collection('orders').doc(id).delete();
          }
        } else if (cloud == null && local != null) {
          if (local.deletedAt == null) {
            log('Order $id: local only, pushing to cloud');
            await _firestore.collection('orders').doc(id).set(local.toFirestore());
          } else {
            await dbService.purgeOrder(id);
          }
        }
      } catch (e) {
        log('Failed to sync order $id: $e');
      }
    }
  }

  Future<void> _syncExpensesCollection(
      DatabaseService dbService, Database sqldb, DateTime? lastSyncAt) async {
    final cloudSnapshot = await _firestore.collection('expenses').get();
    final localRecords = await dbService.getSyncExpenses();

    final cloudMap = {for (var doc in cloudSnapshot.docs) doc.id: ExpenseModel.fromFirestore(doc.data())};
    final localMap = {for (var record in localRecords) record.id: record};

    final allIds = <String>{...cloudMap.keys, ...localMap.keys};

    for (final id in allIds) {
      try {
        final cloud = cloudMap[id];
        final local = localMap[id];

        if (cloud != null && local != null) {
          final takeCloud = _cloudWins(cloud.updatedAt, local.updatedAt, lastSyncAt);
          final winner = takeCloud ? cloud : local;

          if (takeCloud) {
            log('Expense $id: pulling from cloud');
            await sqldb.update('expenses', cloud.toMap(), where: 'id = ?', whereArgs: [id]);
          } else {
            log('Expense $id: pushing local to cloud');
            await _firestore.collection('expenses').doc(id).set(local.toFirestore());
          }

          if (winner.deletedAt != null) {
            await _firestore.collection('expenses').doc(id).delete();
            await dbService.purgeExpense(id);
          }
        } else if (cloud != null && local == null) {
          if (cloud.deletedAt == null) {
            log('Expense $id: new from cloud, inserting locally');
            await sqldb.insert('expenses', cloud.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          } else {
            await _firestore.collection('expenses').doc(id).delete();
          }
        } else if (cloud == null && local != null) {
          if (local.deletedAt == null) {
            log('Expense $id: local only, pushing to cloud');
            await _firestore.collection('expenses').doc(id).set(local.toFirestore());
          } else {
            await dbService.purgeExpense(id);
          }
        }
      } catch (e) {
        log('Failed to sync expense $id: $e');
      }
    }
  }
}
