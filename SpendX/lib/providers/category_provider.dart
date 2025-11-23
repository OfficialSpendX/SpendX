import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  Box<Category> get _box => Hive.box<Category>('categories');

  List<Category> get categories => _box.values.toList();

  List<Category> get incomeCategories => 
      _box.values.where((c) => c.type == 'Credit').toList();

  List<Category> get expenseCategories => 
      _box.values.where((c) => c.type == 'Debit').toList();

  Future<void> init() async {
    if (_box.isEmpty) {
      await _seedDefaults();
    }
  }

  Future<void> _seedDefaults() async {
    final defaults = [
      // Debit
      Category(id: const Uuid().v4(), name: 'Food', type: 'Debit', iconCode: FontAwesomeIcons.utensils.codePoint, colorValue: 0xFFFF5252, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Transport', type: 'Debit', iconCode: FontAwesomeIcons.bus.codePoint, colorValue: 0xFF4EA8DE, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Shopping', type: 'Debit', iconCode: FontAwesomeIcons.bagShopping.codePoint, colorValue: 0xFFFD79A8, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Bills', type: 'Debit', iconCode: FontAwesomeIcons.fileInvoiceDollar.codePoint, colorValue: 0xFFFF7675, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Entertainment', type: 'Debit', iconCode: FontAwesomeIcons.film.codePoint, colorValue: 0xFF6C5CE7, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Health', type: 'Debit', iconCode: FontAwesomeIcons.heartPulse.codePoint, colorValue: 0xFF00CEC9, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Other', type: 'Debit', iconCode: FontAwesomeIcons.circleQuestion.codePoint, colorValue: 0xFFB2BEC3, isCustom: false),
      
      // Credit
      Category(id: const Uuid().v4(), name: 'Salary', type: 'Credit', iconCode: FontAwesomeIcons.moneyBillWave.codePoint, colorValue: 0xFF2ECC71, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Cashback', type: 'Credit', iconCode: FontAwesomeIcons.moneyBillTransfer.codePoint, colorValue: 0xFFFDCB6E, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Refund', type: 'Credit', iconCode: FontAwesomeIcons.rotateLeft.codePoint, colorValue: 0xFF0984E3, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Gift', type: 'Credit', iconCode: FontAwesomeIcons.gift.codePoint, colorValue: 0xFFE84393, isCustom: false),
      Category(id: const Uuid().v4(), name: 'Family', type: 'Credit', iconCode: FontAwesomeIcons.peopleGroup.codePoint, colorValue: 0xFFA29BFE, isCustom: false),
    ];

    for (var c in defaults) {
      await _box.add(c);
    }
  }

  Future<void> addCategory(Category category) async {
    await _box.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    // If we are updating, we usually replace the object or modify fields.
    // Since fields are final, we replace.
    await _box.put(category.key, category);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    try {
      final cat = _box.values.firstWhere((c) => c.id == id);
      await cat.delete();
      notifyListeners();
    } catch (e) {
      // Handle not found
    }
  }
}
