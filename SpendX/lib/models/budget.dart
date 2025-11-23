// File: lib/models/budget.dart

import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final double amount;

  // We store the full DateTime, but use the month/year for logic.
  @HiveField(3)
  final DateTime month;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  // Helper to get a consistent key for filtering by month and category
  String get budgetKey => '${category}_${month.year}-${month.month.toString().padLeft(2, '0')}';
}