// File: ./providers/budget_provider.dart (Refined)

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';

class BudgetProvider with ChangeNotifier {
  Box<Budget> get _box => Hive.box<Budget>('budgets');

  List<Budget> get budgets => _box.values.toList();

  List<Budget> getBudgetsForMonth(DateTime month) {
    // Note: It's better to store the 'month' in the model as the first day (e.g., 2025-11-01) 
    // to simplify comparison, but the current implementation works fine.
    return _box.values.where((b) => 
      b.month.year == month.year && b.month.month == month.month
    ).toList();
  }

  Budget? getBudgetForCategory(String category, DateTime month) {
    try {
      // Find the existing budget object
      return _box.values.firstWhere((b) => 
        b.category == category && 
        b.month.year == month.year && 
        b.month.month == month.month
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> setBudget(Budget newBudget) async {
    // 1. Check if budget exists using the helper
    final existingBudget = getBudgetForCategory(newBudget.category, newBudget.month);

    if (existingBudget != null) {
      // 2. If it exists, overwrite it using its Hive key.
      // We must use the key from the existing HiveObject instance to update it.
      // This is a more direct way than putAt(index).
      // Since newBudget was created by reusing the existing ID, it's essentially an updated object.
      await _box.put(existingBudget.key, newBudget);
    } else {
      // 3. If it's new, add it.
      await _box.add(newBudget);
    }
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    try {
        final budgetToDelete = _box.values.firstWhere((b) => b.id == id);
        // Delete using the HiveObject instance's delete() method.
        await budgetToDelete.delete();
        notifyListeners();
    } catch (e) {
        // Handle case where budget with ID is not found.
    }
  }
}