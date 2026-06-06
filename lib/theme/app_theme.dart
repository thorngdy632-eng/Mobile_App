import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGold = Color(0xFFF9A825);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color bgLight = Color(0xFFF1F8E9);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color adminBlue = Color(0xFF1565C0);
  static const Color farmerGreen = Color(0xFF2E7D32);
  static const Color providerOrange = Color(0xFFE65100);

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        background: bgLight,
        surface: bgCard,
        error: errorRed,
      ),
      useMaterial3: true,
      fontFamily: 'KhmerOSBattambang',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'KhmerOSBattambang',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'KhmerOSBattambang',
          color: Color(0xFFBDBDBD),
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'KhmerOSBattambang',
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF9E9E9E),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 14,
        ),
      ),
    );
  }
}