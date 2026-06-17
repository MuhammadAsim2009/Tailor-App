import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';

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
      version: 3,
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
      // Insert default profile
      await db.insert('profile', {
        'id': '1',
        'shopName': 'Irfan Tailors',
        'ownerName': 'Muhammad Irfan',
        'phone': '0300-1234567',
        'address': 'Larkana, Sindh'
      });
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT,
  measurements TEXT
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
  notes TEXT
)
''');

    await db.execute('''
CREATE TABLE profile (
  id TEXT PRIMARY KEY,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL
)
''');
    await db.insert('profile', {
      'id': '1',
      'shopName': 'Irfan Tailors',
      'ownerName': 'Muhammad Irfan',
      'phone': '0300-1234567',
      'address': 'Larkana, Sindh'
    });
  }

  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await instance.database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String customerId) async {
    final db = await instance.database;
    await db.delete('orders', where: 'customerId = ?', whereArgs: [customerId]);
    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
  }

  Future<void> insertOrder(OrderModel order) async {
    final db = await instance.database;
    await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOrder(OrderModel order) async {
    final db = await instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteOrder(String orderId) async {
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
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => ExpenseModel.fromMap(json)).toList();
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers');
    return result.map((json) => CustomerModel.fromMap(json)).toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'orderDate DESC');
    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final db = await instance.database;
    await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateOrderAdvancePaid(String orderId, double amount) async {
    final db = await instance.database;
    await db.update(
      'orders',
      {'advancePaid': amount},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      where: 'customerId = ?',
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
        'address': 'Larkana, Sindh'
      };
      await db.insert('profile', defaultProfile);
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
  }
}
