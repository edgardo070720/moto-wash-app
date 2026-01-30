import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors from Labo Bar logo
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color lightOrange = Color(0xFFFFA500);
  static const Color secondaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF60A5FA);

  // Neutral colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: secondaryBlue, // Changed to Blue
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: ColorScheme.light(
      primary: secondaryBlue, // Changed to Blue
      secondary: primaryOrange, // Changed to Orange
      surface: cardColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: secondaryBlue, // Changed to Blue
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryBlue, // Changed to Blue
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: secondaryBlue,
          width: 2,
        ), // Changed to Blue
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryBlue, // Changed to Blue
      foregroundColor: Colors.white,
    ),
  );

  // Gradient for cards and backgrounds
  static LinearGradient primaryGradient = LinearGradient(
    colors: [darkBlue, secondaryBlue], // Changed to Blue gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient orangeGradient = LinearGradient(
    // Renamed from blueGradient
    colors: [primaryOrange, lightOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
