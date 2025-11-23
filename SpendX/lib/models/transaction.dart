import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String type; // 'Credit' or 'Debit'

  @HiveField(4)
  final String category;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String note;

  @HiveField(7)
  final String? paymentApp;

  @HiveField(8)
  final String? transactionNumber;

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.note,
    this.paymentApp,
    this.transactionNumber,
    this.transferAccountId,
  });

  @HiveField(9)
  final String? transferAccountId;
}
