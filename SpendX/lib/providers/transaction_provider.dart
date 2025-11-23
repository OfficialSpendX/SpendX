import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  Box<Transaction> get _box => Hive.box<Transaction>('transactions');

  List<Transaction> get transactions {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return list;
  }

  List<Transaction> get recentTransactions {
    return transactions.take(5).toList();
  }

  double get monthlyIncome {
    final now = DateTime.now();
    final m = now.month;
    final y = now.year;

    return transactions
        .where((t) =>
            t.type == 'Credit' &&
            t.date.month == m &&
            t.date.year == y)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    final m = now.month;
    final y = now.year;

    return transactions
        .where((t) =>
            t.type == 'Debit' &&
            t.date.month == m &&
            t.date.year == y)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _box.add(transaction);
    notifyListeners();
  }

  Future<void> deleteTransaction(int index) async {
    await _box.deleteAt(index);
    notifyListeners();
  }
}
