import 'package:hive/hive.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 6)
enum Frequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

@HiveType(typeId: 5)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type; // 'Credit' or 'Debit'

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final Frequency frequency;

  @HiveField(6)
  final String? platform;

  @HiveField(7)
  final String accountId;

  @HiveField(8)
  final DateTime? endDate;

  @HiveField(9)
  DateTime? lastGenerated;

  @HiveField(10)
  final String note;

  RecurringTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.startDate,
    required this.frequency,
    this.platform,
    required this.accountId,
    this.endDate,
    this.lastGenerated,
    required this.note,
  });
}
