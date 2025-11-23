import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  User? _user;

  User? get user => _user;

  Future<void> loadUser() async {
    final name = await _storage.read(key: 'name');
    final username = await _storage.read(key: 'username');
    final mobile = await _storage.read(key: 'mobile');

    if (name != null && username != null && mobile != null) {
      _user = User(name: name, username: username, mobile: mobile);
      notifyListeners();
    }
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: 'name', value: user.name);
    await _storage.write(key: 'username', value: user.username);
    await _storage.write(key: 'mobile', value: user.mobile);
    _user = user;
    notifyListeners();
  }

  Future<bool> isUserLoggedIn() async {
    final name = await _storage.read(key: 'name');
    return name != null;
  }
  
  Future<void> clearUser() async {
    await _storage.deleteAll();
    _user = null;
    notifyListeners();
  }

  // --- Restore State Management ---
  String? _pendingRestorePath;
  String? get pendingRestorePath => _pendingRestorePath;

  void setPendingRestorePath(String? path) {
    _pendingRestorePath = path;
    notifyListeners();
  }
}
