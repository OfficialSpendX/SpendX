import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/goal.dart';

class GoalProvider with ChangeNotifier {
  Box<Goal> get _box => Hive.box<Goal>('goals');

  List<Goal> get goals => _box.values.toList();

  Future<void> addGoal(Goal goal) async {
    await _box.add(goal);
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    await _box.put(goal.key, goal);
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    try {
      final goal = _box.values.firstWhere((g) => g.id == id);
      await goal.delete();
      notifyListeners();
    } catch (e) {
      // Handle not found
    }
  }

  Future<void> addSavedAmount(String id, double amount) async {
    try {
      final goal = _box.values.firstWhere((g) => g.id == id);
      final updatedGoal = Goal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        savedAmount: goal.savedAmount + amount,
        deadline: goal.deadline,
        colorValue: goal.colorValue,
        iconCode: goal.iconCode,
      );
      await _box.put(goal.key, updatedGoal);
      notifyListeners();
    } catch (e) {
      // Handle not found
    }
  }
}
