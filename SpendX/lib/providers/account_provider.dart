import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/account.dart';

class AccountProvider with ChangeNotifier {
  Box<Account> get _box => Hive.box<Account>('accounts');

  // New method required by transactions_screen.dart
  Account? getAccountById(String? id) {
    if (id == null) return null;
    
    // Iterate through all account values to find a match by the 'id' field
    try {
      return _box.values.firstWhere((account) => account.id == id);
    } catch (e) {
      // Return null if no account is found with the given ID
      return null;
    }
  }

  // --- Existing Methods Below ---

  List<Account> get accounts => _box.values.toList();

  Account? get defaultAccount {
    try {
      return _box.values.firstWhere((element) => element.isDefault);
    } catch (e) {
      if (_box.isNotEmpty) return _box.values.first;
      return null;
    }
  }

  double get totalBalance {
    return _box.values.fold(0, (sum, item) => sum + item.balance);
  }

  Future<void> addAccount(Account account) async {
    if (_box.isEmpty) {
      account.isDefault = true;
    }
    // Note: Assuming you are using an auto-increment key for Hive since you use .add()
    // and relying on the Account.id field for lookup. This is acceptable.
    await _box.add(account); 
    notifyListeners();
  }

  Future<void> updateBalance(String accountId, double amount) async {
    // Corrected to use the new getAccountById method
    final account = getAccountById(accountId); 
    if (account != null) {
      account.balance += amount;
      await account.save();
      notifyListeners();
    }
  }

  Future<void> updateAccount(Account updatedAccount) async {
    // Find the index of the account object using its unique ID
    final index = _box.values.toList().indexWhere((a) => a.id == updatedAccount.id);
    if (index != -1) {
      // Find the actual Hive key associated with that object at the index
      final key = _box.keyAt(index);
      await _box.put(key, updatedAccount); // Use put with the key
      notifyListeners();
    }
  }

  Future<void> setAsDefault(String accountId) async {
    for (var account in _box.values) {
      if (account.id == accountId) {
        account.isDefault = true;
      } else {
        account.isDefault = false;
      }
      await account.save();
    }
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    final accountToDelete = _box.values.firstWhere((a) => a.id == id);
    final wasDefault = accountToDelete.isDefault;

    await accountToDelete.delete(); // Delete the account from the box

    // If we deleted the default account, set the first one as default if available
    if (wasDefault) {
      if (_box.isNotEmpty) {
        // Find the first remaining account and set it as default
        final firstRemainingAccount = _box.values.first;
        firstRemainingAccount.isDefault = true;
        await firstRemainingAccount.save();
      }
    }
    notifyListeners();
  }
}