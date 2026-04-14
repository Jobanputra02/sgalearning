import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Colors.white;
  static const Color navy = Color(0xFF0A1628);
  static const Color navyLight = Color(0xFF1A2F4A);
  static const Color accent = Color(0xFF1A5FA8);
  static const Color accentLight = Color(0xFF4A90D9);
  static const Color accentOverlay10 = Color(0x1A1A5FA8);
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF4A6080);
  static const Color borderColor = Color(0xFFD0DCF0);
  static const Color cardBackground = Color(0xFFF5F8FF);
  static const Color white = Colors.white;
  static const Color navyOverlay10 = Color(0x1A0A1628);  // navy 10%
  static const Color navyOverlay6  = Color(0x0F0A1628);  // navy 6%
  static const Color navyOverlay4 = Color(0x0A0A1628);  // navy 4%
  static const Color borderColorLight = Color(0xFFE8EEF8); // slightly lighter border

  static const List<Color> pitchGradient = [
    Color(0xFF6FB3F5),
    Color(0xFF4A90D9),
  ];
  static const List<Color> noteGradient = [
    Color(0xFF4A90D9),
    Color(0xFF1A5FA8),
  ];
  static const List<Color> intervalCompGradient = [
    Color(0xFF0A3060),
    Color(0xFF1A5FA8),
  ];
  static const List<Color> intervalIdGradient = [
    Color(0xFF1A5FA8),
    Color(0xFF0A1628),
  ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: accent,
        surface: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        iconTheme: IconThemeData(color: navy),
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
      ),
    );
  }
}