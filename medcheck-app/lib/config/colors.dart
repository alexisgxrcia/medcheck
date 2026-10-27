import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFF3F4F4);
  static const textPrimary = Color(0xFF161613);
  static const textSecondary = Color(0xFF4E4D4B);
  static const primary = Color(0xFFA294F9);
  static const secondary = Color(0xFFCDC1FF);
  static const taken = Color(0xFF84B179);

  static Color adaptiveBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color adaptiveTextPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color adaptiveTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9A9896)
      : AppColors.textSecondary;

  static Color adaptiveTileBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;

  static Color adaptiveTileBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFE8E8E8);

  static Color adaptiveNavBarBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;
}
