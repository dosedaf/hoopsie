import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF2A52BE),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A52BE),
        primary: const Color(0xFF2A52BE),
      ),
      fontFamily: 'Roboto',
    );
  }
}
