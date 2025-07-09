import 'package:flutter/material.dart';
import 'package:food_app/themes/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = AppThemes.baseTheme(Colors.deepPurple);
  ThemeData getTheme() => _themeData;
  void setTheme(Color color) {
    _themeData = AppThemes.baseTheme(color);
    notifyListeners();
  }
}