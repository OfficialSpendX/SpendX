class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'Credit' or 'Debit'
  final String category;
  final DateTime date;
  final String? note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });
}
