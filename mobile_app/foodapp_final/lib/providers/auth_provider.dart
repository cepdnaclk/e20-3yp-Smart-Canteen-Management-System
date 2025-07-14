// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// class AuthProvider with ChangeNotifier {
//   final _storage = const FlutterSecureStorage();
//   String? _token;
//   String? _email;
//   String? _role;
//   String? _name;
//
//
//   String? get token => _token;
//   String? get email => _email;
//   String? get role => _role;
//   String? get name => _name;
//   bool get isAuthenticated => _token != null;
//
//   Future<void> login(String token, String email, String role, String username) async {
//     _name = username;
//     _token = token; _email = email; _role = role;
//     await _storage.write(key: 'jwt_token', value: token);
//     await _storage.write(key: 'email', value: email);
//     await _storage.write(key: 'role', value: role);
//     await _storage.write(key: 'user_name', value: username);
//     notifyListeners();
//   }
//
//   Future<void> logout() async {
//     _token = null; _email = null; _role = null;
//     await _storage.deleteAll();
//     notifyListeners();
//   }
//
//   Future<void> tryAutoLogin() async {
//     final token = await _storage.read(key: 'jwt_token');
//     if (token == null) return;
//     _token = token;
//     _email = await _storage.read(key: 'email');
//     _role = await _storage.read(key: 'role');
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // For API calls
import 'dart:convert'; // For JSON decoding

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _email;
  String? _role;
  String? _name;
  String? _fullName;
  String? _canteenName;

  String? get token => _token;
  String? get email => _email;
  String? get role => _role;
  String? get name => _name;
  String? get fullName => _fullName;
  String? get canteenName => _canteenName;
  bool get isAuthenticated => _token != null;

  Future<void> login(String token, String email, String role, String username, {String? fullName, String? canteenName}) async {
    _name = username;
    _token = token;
    _email = email;
    _role = role;
    _fullName = fullName;
    _canteenName = canteenName;
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'user_name', value: username);
    await _storage.write(key: 'full_name', value: fullName);
    await _storage.write(key: 'canteen_name', value: canteenName);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
    _role = null;
    _name = null;
    _fullName = null;
    _canteenName = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;
    _token = token;
    _email = await _storage.read(key: 'email');
    _role = await _storage.read(key: 'role');
    _name = await _storage.read(key: 'user_name');
    _fullName = await _storage.read(key: 'full_name');
    _canteenName = await _storage.read(key: 'canteen_name');
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) {
      throw Exception('No token available');
    }
    try {
      // Replace with your actual API endpoint and logic
      final response = await http.get(
        Uri.parse('http://192.168.237.203:8081/api/auth/login'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _fullName = data['fullName'] ?? _fullName;
        _canteenName = data['canteenName'] ?? _canteenName;
        _email = data['email'] ?? _email;
        // Store updated values in secure storage
        await _storage.write(key: 'full_name', value: _fullName);
        await _storage.write(key: 'canteen_name', value: _canteenName);
        await _storage.write(key: 'email', value: _email);
        notifyListeners();
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to stored values if API call fails
      _fullName = await _storage.read(key: 'full_name');
      _canteenName = await _storage.read(key: 'canteen_name');
      notifyListeners();
      rethrow;
    }
  }
}