import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('current_user');
    _isAuthenticated = _userId != null;
    notifyListeners();
  }

  Future<void> login(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', userId);
    _isAuthenticated = true;
    _userId = userId;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _isAuthenticated = false;
    _userId = null;
    notifyListeners();
  }
}