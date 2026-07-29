import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../models/family_model.dart';
import '../services/database_service.dart';

class OrderController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;


  List<CustomerModel> customers = [];
  List<OrderModel> orders = [];
  List<FamilyModel> families = [];

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

  Future<String> addOrder({
    required OrderModel order,
    required CustomerModel customer,
  }) async {
    try {
      final customerToSave = customer.id.isEmpty
          ? CustomerModel(
              id: nextCustomerId,
              name: customer.name,
              phone: customer.phone,
              address: customer.address,
              measurements: order.measurements,
              updatedAt: DateTime.now(),
              familyId: customer.familyId,
            )
          : CustomerModel(
              id: customer.id,
              name: customer.name,
              phone: customer.phone,
              address: customer.address,
              measurements: order.measurements,
              updatedAt: DateTime.now(),
              familyId: customer.familyId,
            );

      await _dbService.insertCustomer(customerToSave);

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
      await _dbService.updateOrderAdvancePaid(orderId, totalAmount);
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
      final orderToSave = order.copyWith(updatedAt: DateTime.now());
      await _dbService.updateOrder(orderToSave);

      final customer = getCustomerById(order.customerId);
      if (customer != null) {
        final updatedCustomer = CustomerModel(
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          address: customer.address,
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
      final customerToSave = customer.copyWith(updatedAt: DateTime.now());
      await _dbService.updateCustomer(customerToSave);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _dbService.deleteCustomer(customerId);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting customer: $e');
      }
      rethrow;
    }
  }
}
