import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF333333);

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: white,
      background: white,
      onPrimary: white,
      onSecondary: black,
      onSurface: black,
      onBackground: black,
    ),
    scaffoldBackgroundColor: white,
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: black,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: white,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 4,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: black,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkGray,
      ),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: darkGray),
    ),
  );
}