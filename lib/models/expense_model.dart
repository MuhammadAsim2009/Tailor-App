class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
