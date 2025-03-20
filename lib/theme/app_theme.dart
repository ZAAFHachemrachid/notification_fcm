import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF8C00); // Deep Orange
  static const Color secondaryColor = Color(0xFFFFA000); // Amber
  static const Color surfaceColor = Color(0xFFFFF3E0); // Light Orange

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
    ),
    scaffoldBackgroundColor: surfaceColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
    ),
  );
}
