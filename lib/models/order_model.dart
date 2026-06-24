import 'package:cloud_firestore/cloud_firestore.dart';
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
  final DateTime updatedAt;
  final DateTime? deletedAt;

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
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? orderDate;

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
    DateTime? updatedAt,
    DateTime? deletedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
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
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.tryParse(map['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'customerId': customerId,
      'isAdult': isAdult,
      'quantity': quantity,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'measurements': measurements.toJson(),
      'status': status,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  factory OrderModel.fromFirestore(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      isAdult: map['isAdult'] is bool ? map['isAdult'] as bool : (map['isAdult'] == 1),
      quantity: map['quantity']?.toInt() ?? 1,
      orderDate: map['orderDate'] is Timestamp ? (map['orderDate'] as Timestamp).toDate() : DateTime.parse(map['orderDate'].toString()),
      deliveryDate: map['deliveryDate'] is Timestamp ? (map['deliveryDate'] as Timestamp).toDate() : DateTime.parse(map['deliveryDate'].toString()),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      advancePaid: map['advancePaid']?.toDouble() ?? 0.0,
      measurements: MeasurementModel.fromJson(map['measurements']),
      status: map['status'] ?? 'Pending',
      updatedAt: map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : null,
      deletedAt: map['deletedAt'] is Timestamp ? (map['deletedAt'] as Timestamp).toDate() : null,
    );
  }
}
