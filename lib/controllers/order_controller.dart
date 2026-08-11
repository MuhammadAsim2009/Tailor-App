import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../models/family_model.dart';
import '../models/payment_model.dart';
import '../services/database_service.dart';

class OrderController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;


  List<CustomerModel> customers = [];
  List<OrderModel> orders = [];
  List<FamilyModel> families = [];
  List<PaymentModel> payments = [];

  bool isLoading = false;

  static final OrderController _instance = OrderController._internal();
  
  factory OrderController() => _instance;

  OrderController._internal() {
    loadData();
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      customers = await _dbService.getAllCustomers();
      orders = await _dbService.getAllOrders();
      families = await _dbService.getAllFamilies();
      payments = await _dbService.getAllPayments();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Intentionally left empty to prevent singleton disposal
    super.dispose();
  }

  /// Returns the customer name for a given order's customerId.
  String getCustomerName(String customerId) {
    for (var c in customers) {
      if (c.id == customerId) return c.name;
    }
    return 'Unknown';
  }

  /// Returns the CustomerModel for a given order's customerId, or null if not found.
  CustomerModel? getCustomerById(String customerId) {
    for (var c in customers) {
      if (c.id == customerId) return c;
    }
    return null;
  }

  /// Returns the FamilyModel for a given familyId, or null.
  FamilyModel? getFamilyById(String familyId) {
    for (var f in families) {
      if (f.id == familyId) return f;
    }
    return null;
  }

  /// Returns the family name for a given familyId, or empty string.
  String getFamilyName(String? familyId) {
    if (familyId == null || familyId.isEmpty) return '';
    return getFamilyById(familyId)?.name ?? '';
  }

  /// Returns all customers belonging to a given familyId.
  List<CustomerModel> getCustomersByFamilyId(String familyId) {
    return customers.where((c) => c.familyId == familyId).toList();
  }

  /// Returns all orders for a given customerId.
  List<OrderModel> getOrdersByCustomerId(String customerId) {
    return orders.where((o) => o.customerId == customerId).toList();
  }

  /// Generate a next family ID (numeric like customers/orders).
  String get nextFamilyId => generateNextId(families.map((f) => f.id));

  String generateNextId(Iterable<String> existingIds) {
    int maxId = 100;
    for (var idStr in existingIds) {
      final id = int.tryParse(idStr);
      if (id != null && id > maxId) {
        maxId = id;
      }
    }
    return (maxId + 1).toString();
  }

  String get nextCustomerId => generateNextId(customers.map((c) => c.id));
  String get nextOrderId => generateNextId(orders.map((o) => o.id));
  String get nextPaymentId => generateNextId(payments.map((p) => p.id));

  /// Recalculates the memberCount for the given [familyId] based on the
  /// in-memory customers list and persists the update to SQLite + Firebase.
  Future<void> _refreshFamilyCount(String familyId) async {
    final family = getFamilyById(familyId);
    if (family == null) return;
    final count = customers
        .where((c) => c.familyId == familyId && c.deletedAt == null)
        .length;
    final updated = family.copyWith(memberCount: count, updatedAt: DateTime.now());
    await _dbService.updateFamily(updated);
  }

  Future<String> addOrder({
    required OrderModel order,
    required CustomerModel customer,
  }) async {
    try {
      final customerToSave = customer.id.isEmpty
          ? customer.copyWith(
              id: nextCustomerId,
              measurements: order.measurements,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : customer.copyWith(
              measurements: order.measurements,
              updatedAt: DateTime.now(),
            );

      await _dbService.insertCustomer(customerToSave);

      // ── Update family member count if the customer belongs to one ──────
      if (customer.id.isEmpty && customerToSave.familyId != null) {
        // New customer — load data first so the in-memory list is up to date
        await loadData();
        await _refreshFamilyCount(customerToSave.familyId!);
      }

      final orderToSave = OrderModel(
        id: nextOrderId,
        customerId: customerToSave.id,
        isAdult: order.isAdult,
        quantity: order.quantity,
        orderDate: order.orderDate,
        deliveryDate: order.deliveryDate,
        totalAmount: order.totalAmount,
        advancePaid: order.advancePaid,
        measurements: order.measurements,
        status: order.status,
        updatedAt: DateTime.now(),
        subTotal: order.subTotal,
        pricingItems: order.pricingItems,
      );

      await _dbService.insertOrder(orderToSave);

      // Record a payment entry if advance was paid at order creation
      if (orderToSave.advancePaid > 0) {
        final payment = PaymentModel(
          id: nextPaymentId,
          orderId: orderToSave.id,
          customerId: orderToSave.customerId,
          amount: orderToSave.advancePaid,
          paidAt: DateTime.now(),
        );
        await _dbService.insertPayment(payment);
      }

      if (kDebugMode) {
        print('Order saved: ${orderToSave.id}');
        print('Customer saved: ${customerToSave.id}');
      }

      await loadData();
      return orderToSave.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding order: $e');
      }
      rethrow;
    }
  }

  Future<String> createFamily(String name) async {
    try {
      final family = FamilyModel(id: nextFamilyId, name: name, createdAt: DateTime.now());
      await _dbService.insertFamily(family);
      await loadData();
      return family.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating family: $e');
      }
      rethrow;
    }
  }

  Future<void> updateFamily(FamilyModel family) async {
    try {
      await _dbService.updateFamily(family);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating family: $e');
      }
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _dbService.updateOrderStatus(orderId, newStatus);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      rethrow;
    }
  }

  Future<void> markOrderAsPaid(String orderId, double totalAmount) async {
    try {
      // Get the previous advance so we only record the delta as a new payment
      final existing = orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      final delta = totalAmount - existing.advancePaid;

      await _dbService.updateOrderAdvancePaid(orderId, totalAmount);

      // Record the additional payment amount
      if (delta > 0) {
        final payment = PaymentModel(
          id: nextPaymentId,
          orderId: orderId,
          customerId: existing.customerId,
          amount: delta,
          paidAt: DateTime.now(),
        );
        await _dbService.insertPayment(payment);
      }

      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking order as paid: $e');
      }
      rethrow;
    }
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      final existing = orders.firstWhere(
        (o) => o.id == order.id,
        orElse: () => order,
      );
      final delta = order.advancePaid - existing.advancePaid;
      if (delta != 0) {
        final payment = PaymentModel(
          id: nextPaymentId,
          orderId: order.id,
          customerId: order.customerId,
          amount: delta,
          paidAt: DateTime.now(),
        );
        await _dbService.insertPayment(payment);
      }

      final orderToSave = order.copyWith(updatedAt: DateTime.now());
      await _dbService.updateOrder(orderToSave);

      final customer = getCustomerById(order.customerId);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          measurements: orderToSave.measurements,
          updatedAt: DateTime.now(),
        );
        await _dbService.insertCustomer(updatedCustomer);
      }

      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _dbService.deleteOrder(orderId);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting order: $e');
      }
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      // Capture previous familyId before the update
      final previous = getCustomerById(customer.id);
      final previousFamilyId = previous?.familyId;

      final customerToSave = customer.copyWith(updatedAt: DateTime.now());
      await _dbService.updateCustomer(customerToSave);
      await loadData();

      // Adjust counts for any changed family links
      final newFamilyId = customerToSave.familyId;
      if (previousFamilyId != newFamilyId) {
        if (previousFamilyId != null) await _refreshFamilyCount(previousFamilyId);
        if (newFamilyId != null) await _refreshFamilyCount(newFamilyId);
        await loadData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      // Capture the family before deletion so we can update its count after
      final customer = getCustomerById(customerId);
      final familyId = customer?.familyId;

      await _dbService.deleteCustomer(customerId);
      await loadData();

      if (familyId != null) {
        await _refreshFamilyCount(familyId);
        await loadData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting customer: $e');
      }
      rethrow;
    }
  }
}
