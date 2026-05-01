import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  static const _bioKey = 'biometric_user_ids';

  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;

  void login(User user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }

  Future<List<String>> getBiometricUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bioKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveBiometricUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getBiometricUserIds();
    if(!ids.contains(userId)) {
      ids.add(userId);
      await prefs.setString(_bioKey, jsonEncode(ids));
    }
  }


  Future<void> removeBiometricUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getBiometricUserIds();
    ids.remove(userId);
    await prefs.setString(_bioKey, jsonEncode(ids));
    }

  Future<bool> isBiometricEnabled(String userId) async {
    final ids = await getBiometricUserIds();
    return ids.contains(userId);
  }

    
}
