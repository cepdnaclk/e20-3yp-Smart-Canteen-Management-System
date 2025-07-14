// import 'package:flutter/material.dart';
// import 'package:food_app/themes/app_themes.dart';
//
// class ThemeProvider with ChangeNotifier {
//   ThemeData _themeData = AppThemes.baseTheme(Colors.deepPurple);
//   ThemeData getTheme() => _themeData;
//   void setTheme(Color color) {
//     _themeData = AppThemes.baseTheme(color);
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/themes/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _themeColorKey = 'theme_color';

  late ThemeData _themeData;

  // ✨ Use a standard getter for easier access
  ThemeData get themeData => _themeData;

  ThemeProvider() {
    // ✨ Load the saved theme when the app starts
    _loadTheme();
  }

  void _loadTheme() async {
    // Read the saved color value from storage
    final colorString = await _storage.read(key: _themeColorKey);

    // If a color was saved, use it. Otherwise, default to deepPurple.
    final color = colorString != null
        ? Color(int.parse(colorString))
        : Colors.deepPurple;

    _themeData = AppThemes.baseTheme(color);
    notifyListeners();
  }

  void setTheme(Color color) async { // ✨ Make the method async
    _themeData = AppThemes.baseTheme(color);

    // ✨ Save the new color's integer value as a string
    await _storage.write(key: _themeColorKey, value: color.value.toString());

    notifyListeners();
  }
}