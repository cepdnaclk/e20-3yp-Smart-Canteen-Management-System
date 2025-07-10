import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _email;
  String? _role;
  String? _name;


  String? get token => _token;
  String? get email => _email;
  String? get role => _role;
  String? get name => _name;
  bool get isAuthenticated => _token != null;

  Future<void> login(String token, String email, String role, String username) async {
    _name = username;
    _token = token; _email = email; _role = role;
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'user_name', value: username);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null; _email = null; _role = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;
    _token = token;
    _email = await _storage.read(key: 'email');
    _role = await _storage.read(key: 'role');
    notifyListeners();
  }
}