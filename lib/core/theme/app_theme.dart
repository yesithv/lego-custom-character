import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFFFFD700); // Brix yellow
  static const _secondaryColor = Color(0xFF0055A5); // Brix blue
  static const _backgroundColor = Color(0xFFF5F5F5);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          secondary: _secondaryColor,
          surface: _backgroundColor,
        ),
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primaryColor,
          secondary: _secondaryColor,
        ),
        fontFamily: 'Nunito',
      );
}
