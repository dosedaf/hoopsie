import '../models/user.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;

  void login(User user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }
}
