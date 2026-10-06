import 'package:flutter/foundation.dart';
import '../models/wallet_transaction_model.dart';
import '../services/database_service.dart';

class WalletController extends ChangeNotifier {
  static final WalletController instance = WalletController._();
  WalletController._();

  List<WalletTransactionModel> _transactions = [];
  List<WalletTransactionModel> get transactions => _transactions;

  /// Total wallet balance: sum of credits minus sum of debits.
  double get balance => _transactions.fold(0.0, (sum, t) {
        if (t.deletedAt != null) return sum;
        return sum + (t.type == 'credit' ? t.amount : -t.amount);
      });

  /// Generate the next sequential wallet transaction ID.
  String get _nextId {
    final nums = _transactions
        .map((t) => int.tryParse(t.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'wt${(max + 1).toString().padLeft(4, '0')}';
  }

  Future<void> loadTransactions() async {
    try {
      _transactions = await DatabaseService.instance.getAllWalletTransactions();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('WalletController.loadTransactions error: $e');
    }
  }

  /// Add money to the other wallet (credit entry).
  Future<void> addMoney(double amount, {String? notes, DateTime? date}) async {
    final txn = WalletTransactionModel(
      id: _nextId,
      amount: amount,
      type: 'credit',
      date: date ?? DateTime.now(),
      notes: notes,
    );
    await DatabaseService.instance.insertWalletTransaction(txn);
    await loadTransactions();
  }

  /// Debit the wallet when an expense is paid from it.
  Future<void> debitForExpense(double amount, {String? notes}) async {
    final txn = WalletTransactionModel(
      id: _nextId,
      amount: amount,
      type: 'debit',
      date: DateTime.now(),
      notes: notes,
    );
    await DatabaseService.instance.insertWalletTransaction(txn);
    await loadTransactions();
  }

  Future<void> updateTransaction(WalletTransactionModel txn) async {
    final updatedTxn = txn.copyWith(updatedAt: DateTime.now());
    await DatabaseService.instance.updateWalletTransaction(updatedTxn);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseService.instance.deleteWalletTransaction(id);
    await loadTransactions();
  }
}
