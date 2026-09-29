import 'package:flutter/material.dart';

/// Token warna diambil dari index.css di Figma Make.
class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const accent = Color(0xFFF97316); // Safety Orange
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFD1FAE5);
  static const successText = Color(0xFF065F46);

  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningText = Color(0xFF92400E);

  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEE2E2);
  static const dangerText = Color(0xFF991B1B);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
    );
  }
}
