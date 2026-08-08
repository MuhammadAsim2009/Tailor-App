/// A single payment transaction record.
/// Created whenever money is collected: advance on order creation, or balance payment.
class PaymentModel {
  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final DateTime paidAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.paidAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
      };

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id: map['id'] ?? '',
        orderId: map['orderId'] ?? '',
        customerId: map['customerId'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        paidAt: DateTime.parse(map['paidAt']),
      );
}
