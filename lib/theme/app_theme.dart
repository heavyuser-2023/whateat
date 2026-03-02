import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppColors {
  // 모던하고 트렌디한 Deep Teal & Mint Green 테마
  static const Color primary = Color(0xFF00BFA5); // Teal Accent
  static const Color secondary = Color(0xFF00897B); // Deep Teal
  static const Color tertiary = Color(0xFF64FFDA); // Light Mint
  static const Color error = Color(0xFFE57373);
  
  static const Color background = Color(0xFFF8F9FB); // Very light cool gray
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  
  static const Color textPrimary = Color(0xFF1A1A24); // 부드러운 다크 네이비 블랙
  static const Color textBody = Color(0xFF6E7191); // 고급스러운 블루 그레이
  
  static const Color chipBackground = Color(0xFFE0F2F1); // Light Teal
  static const Color scaffoldBackground = Color(0xFFF8F9FB);
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
      fontFamily: 'Roboto', // 가독성 좋은 기본 폰트 적용
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
        displayMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        displaySmall: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textBody, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textBody, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.secondary, width: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Edge to edge 화면 구성을 위해 투명 설정
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackground,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
    );
  }
}
