import 'measurement_model.dart';

class OrderModel {
  final String id;
  final String customerId;
  final bool isAdult;
  final int quantity;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final double totalAmount;
  final double advancePaid;
  final MeasurementModel measurements;
  final String status;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.isAdult,
    required this.quantity,
    required this.orderDate,
    required this.deliveryDate,
    required this.totalAmount,
    required this.advancePaid,
    required this.measurements,
    this.status = 'Pending',
  });

  OrderModel copyWith({
    String? id,
    String? customerId,
    bool? isAdult,
    int? quantity,
    DateTime? orderDate,
    DateTime? deliveryDate,
    double? totalAmount,
    double? advancePaid,
    MeasurementModel? measurements,
    String? status,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      isAdult: isAdult ?? this.isAdult,
      quantity: quantity ?? this.quantity,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      totalAmount: totalAmount ?? this.totalAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      measurements: measurements ?? this.measurements,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'isAdult': isAdult ? 1 : 0, // SQLite doesn't have booleans
      'quantity': quantity,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate.toIso8601String(),
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'measurements': measurements.toJson(), // Store as JSON string
      'status': status,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      isAdult: map['isAdult'] == 1,
      quantity: map['quantity']?.toInt() ?? 1,
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: DateTime.parse(map['deliveryDate']),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      advancePaid: map['advancePaid']?.toDouble() ?? 0.0,
      measurements: MeasurementModel.fromJson(map['measurements']),
      status: map['status'] ?? 'Pending',
    );
  }
}
