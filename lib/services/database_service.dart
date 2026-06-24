import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import 'firebase_sync_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tailor_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add expenses table introduced in version 2
      await db.execute('''
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  notes TEXT
)
''');
    }
    if (oldVersion < 3) {
      // Add profile table introduced in version 3
      await db.execute('''
CREATE TABLE IF NOT EXISTS profile (
  id TEXT PRIMARY KEY,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL
)
''');
      // Insert default profile (only base columns — updatedAt/createdAt added in later migrations)
      await db.insert('profile', {
        'id': '1',
        'shopName': 'Irfan Tailors',
        'ownerName': 'Muhammad Irfan',
        'phone': '0300-1234567',
        'address': 'Larkana, Sindh',
      });
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE customers ADD COLUMN updatedAt TEXT;');
      await db.execute('ALTER TABLE customers ADD COLUMN deletedAt TEXT;');
      
      await db.execute('ALTER TABLE orders ADD COLUMN updatedAt TEXT;');
      await db.execute('ALTER TABLE orders ADD COLUMN deletedAt TEXT;');
      
      await db.execute('ALTER TABLE expenses ADD COLUMN updatedAt TEXT;');
      await db.execute('ALTER TABLE expenses ADD COLUMN deletedAt TEXT;');
      
      await db.execute('ALTER TABLE profile ADD COLUMN updatedAt TEXT;');
      await db.execute('ALTER TABLE profile ADD COLUMN deletedAt TEXT;');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE customers ADD COLUMN createdAt TEXT;');
      await db.execute('ALTER TABLE profile ADD COLUMN createdAt TEXT;');
    }
    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT,
  measurements TEXT,
  createdAt TEXT,
  updatedAt TEXT,
  deletedAt TEXT
)
''');

    await db.execute('''
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  customerId TEXT NOT NULL,
  isAdult INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  orderDate TEXT NOT NULL,
  deliveryDate TEXT NOT NULL,
  totalAmount REAL NOT NULL,
  advancePaid REAL NOT NULL,
  measurements TEXT NOT NULL,
  status TEXT NOT NULL,
  updatedAt TEXT,
  deletedAt TEXT,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  notes TEXT,
  updatedAt TEXT,
  deletedAt TEXT
)
''');

    await db.execute('''
CREATE TABLE profile (
  id TEXT PRIMARY KEY,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  createdAt TEXT,
  updatedAt TEXT,
  deletedAt TEXT
)
''');
    await db.insert('profile', {
      'id': '1',
      'shopName': 'Irfan Tailors',
      'ownerName': 'Muhammad Irfan',
      'phone': '0300-1234567',
      'address': 'Larkana, Sindh',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await db.execute('''
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
  }

  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await instance.database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    FirebaseSyncService.instance.syncCustomer(customer);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    FirebaseSyncService.instance.syncCustomer(customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    // Soft-delete all child orders
    await db.update('orders', {'deletedAt': now}, where: 'customerId = ?', whereArgs: [customerId]);
    // Soft-delete the customer
    await db.update('customers', {'deletedAt': now}, where: 'id = ?', whereArgs: [customerId]);
    // Sync the soft-deleted customer (triggers Firestore delete → local purge)
    final customerRows = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
    if (customerRows.isNotEmpty) {
      FirebaseSyncService.instance.syncCustomer(CustomerModel.fromMap(customerRows.first));
    }
    // Sync each soft-deleted child order
    final orderRows = await db.query('orders', where: 'customerId = ? AND deletedAt IS NOT NULL', whereArgs: [customerId]);
    for (final row in orderRows) {
      FirebaseSyncService.instance.syncOrder(OrderModel.fromMap(row));
    }
  }

  Future<void> purgeCustomer(String customerId) async {
    final db = await instance.database;
    await db.delete('orders', where: 'customerId = ?', whereArgs: [customerId]);
    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
  }

  Future<void> insertOrder(OrderModel order) async {
    final db = await instance.database;
    await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    FirebaseSyncService.instance.syncOrder(order);
  }

  Future<void> updateOrder(OrderModel order) async {
    final db = await instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    FirebaseSyncService.instance.syncOrder(order);
  }

  Future<void> deleteOrder(String orderId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'orders',
      {'deletedAt': now},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    // Sync the soft-deleted order (triggers Firestore delete → local purge)
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (rows.isNotEmpty) {
      FirebaseSyncService.instance.syncOrder(OrderModel.fromMap(rows.first));
    }
  }

  Future<void> purgeOrder(String orderId) async {
    final db = await instance.database;
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> insertExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    FirebaseSyncService.instance.syncExpense(expense);
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    FirebaseSyncService.instance.syncExpense(expense);
  }

  Future<void> deleteExpense(String expenseId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'expenses',
      {'deletedAt': now},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
    // Sync the soft-deleted expense (triggers Firestore delete → local purge)
    final rows = await db.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
    if (rows.isNotEmpty) {
      FirebaseSyncService.instance.syncExpense(ExpenseModel.fromMap(rows.first));
    }
  }

  Future<void> purgeExpense(String expenseId) async {
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', where: 'deletedAt IS NULL', orderBy: 'date DESC');
    return result.map((json) => ExpenseModel.fromMap(json)).toList();
  }

  Future<List<ExpenseModel>> getSyncExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses');
    return result.map((json) => ExpenseModel.fromMap(json)).toList();
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', where: 'deletedAt IS NULL');
    return result.map((json) => CustomerModel.fromMap(json)).toList();
  }

  Future<List<CustomerModel>> getSyncCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers');
    return result.map((json) => CustomerModel.fromMap(json)).toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders', where: 'deletedAt IS NULL', orderBy: 'orderDate DESC');
    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  Future<List<OrderModel>> getSyncOrders() async {
    final db = await instance.database;
    final result = await db.query('orders');
    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'orders',
      {'status': newStatus, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    final result = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (result.isNotEmpty) {
      FirebaseSyncService.instance.syncOrder(OrderModel.fromMap(result.first));
    }
  }

  Future<void> updateOrderAdvancePaid(String orderId, double amount) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'orders',
      {'advancePaid': amount, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    final result = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (result.isNotEmpty) {
      FirebaseSyncService.instance.syncOrder(OrderModel.fromMap(result.first));
    }
  }

  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      where: 'customerId = ? AND deletedAt IS NULL',
      whereArgs: [customerId],
      orderBy: 'orderDate DESC',
    );
    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  // Profile Methods
  Future<Map<String, dynamic>> getProfile() async {
    final db = await instance.database;
    final maps = await db.query('profile', where: 'id = ?', whereArgs: ['1']);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      final defaultProfile = {
        'id': '1',
        'shopName': 'Irfan Tailors',
        'ownerName': 'Muhammad Irfan',
        'phone': '0300-1234567',
        'address': 'Larkana, Sindh',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await db.insert('profile', defaultProfile);
      FirebaseSyncService.instance.syncProfile(defaultProfile);
      return defaultProfile;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileMap) async {
    final db = await instance.database;
    await db.update(
      'profile',
      profileMap,
      where: 'id = ?',
      whereArgs: ['1'],
    );
    FirebaseSyncService.instance.syncProfile(profileMap);
  }

  // ── Meta Key-Value Store ──────────────────────────────────────────────────
  Future<String?> getMetaValue(String key) async {
    final db = await instance.database;
    final result = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<void> setMetaValue(String key, String value) async {
    final db = await instance.database;
    await db.insert('meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> getLastSyncAt() async {
    final raw = await getMetaValue('last_sync_at');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> saveLastSyncAt(DateTime dt) async {
    await setMetaValue('last_sync_at', dt.toIso8601String());
  }
}
