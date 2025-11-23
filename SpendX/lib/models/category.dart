import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'category.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'Credit' or 'Debit'

  @HiveField(3)
  final int iconCode;

  @HiveField(4)
  final int colorValue;
  
  @HiveField(5)
  final bool isCustom;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
    this.isCustom = true,
  });
}
