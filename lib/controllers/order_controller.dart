import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';

class OrderController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;


  List<CustomerModel> customers = [];
  List<OrderModel> orders = [];

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
    // Intentionally left empty. This is a singleton and should never be disposed.
    // This completely prevents the "A OrderController was used after being disposed" error.
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

  Future<void> addOrder({
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
            )
          : CustomerModel(
              id: customer.id,
              name: customer.name,
              phone: customer.phone,
              address: customer.address,
              measurements: order.measurements,
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
      );

      await _dbService.insertOrder(orderToSave);

      if (kDebugMode) {
        print('Order saved: ${orderToSave.id}');
        print('Customer saved: ${customerToSave.id}');
      }

      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding order: $e');
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
      await _dbService.updateOrder(order);

      final customer = getCustomerById(order.customerId);
      if (customer != null) {
        final updatedCustomer = CustomerModel(
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          address: customer.address,
          measurements: order.measurements,
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
      await _dbService.updateCustomer(customer);
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
