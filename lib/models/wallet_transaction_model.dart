import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  final String id;
  final double amount;
  final String type; // 'credit' (add money) or 'debit' (remove/expense)
  final DateTime date;
  final String? notes;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    DateTime? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: map['id'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      type: map['type'] ?? 'credit',
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.tryParse(map['deletedAt']) : null,
    );
  }

  WalletTransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    DateTime? date,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return WalletTransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  factory WalletTransactionModel.fromFirestore(Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: map['id'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      type: map['type'] ?? 'credit',
      date: map['date'] is Timestamp ? (map['date'] as Timestamp).toDate() : DateTime.parse(map['date'].toString()),
      notes: map['notes'],
      updatedAt: map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : null,
      deletedAt: map['deletedAt'] is Timestamp ? (map['deletedAt'] as Timestamp).toDate() : null,
    );
  }
}
