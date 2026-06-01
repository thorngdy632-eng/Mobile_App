// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1565C0);      // blue-700
  static const Color primaryLight = Color(0xFFE3F2FD); // blue-50
  static const Color primaryMid = Color(0xFF1E88E5);   // blue-600
  static const Color primaryGreen = Color(0xFF2E7D32); // green-700

  static const Color purple = Color(0xFF7B1FA2);
  static const Color purpleLight = Color(0xFFF3E5F5);

  static const Color green = Color(0xFF2E7D32);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color greenAccent = Color(0xFF43A047);
  static const Color greenBg = Color(0xFFE8F5E9);

  static const Color amber = Color(0xFFFFC107);
  static const Color amberBg = Color(0xFFF57C00);
  static const Color orange = Color(0xFFE64A19);
  static const Color badgeHot = Color(0xFFE53935);

  // Neutral
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFBBDEFB);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textBlue = Color(0xFF1565C0);

  // Status
  static const Color statusConfirmed = Color(0xFFE8F5E9);
  static const Color statusConfirmedText = Color(0xFF2E7D32);
  static const Color statusPending = Color(0xFFFFF8E1);
  static const Color statusPendingText = Color(0xFFF57F17);

  // Android system bars
  static const Color androidBar = Color(0xFF000000);
  static const Color androidBarText = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansKhmerTextTheme().copyWith(
        // fallback for non-Khmer chars
        displayLarge: GoogleFonts.notoSansKhmer(fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.notoSansKhmer(fontSize: 20, fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.notoSansKhmer(fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.notoSansKhmer(fontSize: 16),
        bodyMedium: GoogleFonts.notoSansKhmer(fontSize: 14),
        bodySmall: GoogleFonts.notoSansKhmer(fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        shadowColor: Colors.black26,
        titleTextStyle: GoogleFonts.notoSansKhmer(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.notoSansKhmer(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
