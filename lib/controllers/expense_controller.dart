import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class ExpenseController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<ExpenseModel> expenses = [];
  bool isLoading = false;

  static final ExpenseController _instance = ExpenseController._internal();
  
  factory ExpenseController() => _instance;

  ExpenseController._internal() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    isLoading = true;
    notifyListeners();

    try {
      expenses = await _dbService.getExpenses();
    } catch (e) {
      debugPrint("Error loading expenses: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    String id = _generateExpenseId();
    final expense = ExpenseModel(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
    );

    await _dbService.insertExpense(expense);
    await loadExpenses();
  }

  @override
  void dispose() {
    // Intentionally left empty to prevent singleton disposal
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _dbService.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _dbService.deleteExpense(expenseId);
    await loadExpenses();
  }

  String _generateExpenseId() {
    int maxId = 100;
    for (var expense in expenses) {
      if (expense.id.startsWith('EXP-')) {
        int? currentId = int.tryParse(expense.id.substring(4));
        if (currentId != null && currentId > maxId) {
          maxId = currentId;
        }
      }
    }
    return 'EXP-${maxId + 1}';
  }
}
