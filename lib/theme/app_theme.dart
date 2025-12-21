import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF34A853);
  static const Color secondary = Color(0xFF4285F4);
  static const Color tertiary = Color(0xFFFFA726);
  static const Color error = Color(0xFFEA4335);
  static const Color background = Color(0xFFF4F9F4);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  
  static const Color textPrimary = Color(0xFF202124);
  static const Color textBody = Color(0xFF5F6368);
  
  static const Color chipBackground = Color(0xFFE8F5E9); // Light Green
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        background: AppColors.background,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textBody),
        bodyMedium: TextStyle(color: AppColors.textBody),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackground,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
    );
  }
}
