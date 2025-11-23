import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'Bank' or 'Cash'

  @HiveField(3)
  double balance;

  @HiveField(4)
  final String imagePath;

  @HiveField(5)
  bool isDefault;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.imagePath,
    this.isDefault = false,
  });
}
