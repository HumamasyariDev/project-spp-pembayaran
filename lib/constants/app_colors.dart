import 'package:flutter/material.dart';

/// App Colors dari Figma Design
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary01 = Color(0xFF1CAD95);
  static const Color primary02 = Color(0xFF10B881);
  static const Color primary03 = Color(0xFF0FA574);
  static const Color primary04 = Color(0xFF17907C);
  static const Color primary05 = Color(0xFF1CAD95);
  static const Color primary06 = Color(0xFF26D3AF);
  static const Color primary07 = Color(0xFF74E3CC);
  static const Color primary08 = Color(0xFFB0EFE1);
  static const Color primary09 = Color(0xFFD2EAE8);
  static const Color primary10 = Color(0xFFD2EFE9);

  // Secondary Colors
  static const Color dark = Color(0xFF282F2E); // #282F2E
  static const Color secondary = Color(0xFFFFCC71); // Yellow/Orange

  // Black & White
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Neutral Colors
  static const Color neutral01 = Color(0xFFF6F6F6);
  static const Color neutral02 = Color(0xFFEDEDED);
  static const Color neutral03 = Color(0xFFDEDEDE);
  static const Color neutral04 = Color(0xFFC9C9C9);
  static const Color neutral05 = Color(0xFFB4B4B4);
  static const Color neutral06 = Color(0xFF9F9F9F);
  static const Color neutral07 = Color(0xFF8A8A8A);
  static const Color neutral08 = Color(0xFF757575);
  static const Color neutral09 = Color(0xFF606060);
  static const Color neutral10 = Color(0xFF4B4B4B);

  // Warning Colors
  static const Color warning01 = Color(0xFFFFF4E5);
  static const Color warning02 = Color(0xFFFFA800);

  // Destructive Colors
  static const Color destructive01 = Color(0xFFFFE5E5);
  static const Color destructive02 = Color(0xFFFF4747);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary04, primary06],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

