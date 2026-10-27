import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

abstract class AppTheme {
  static TextStyle _rec(double size, {double? letterSpacing}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: letterSpacing,
  );

  static TextTheme get _textTheme {
    final base = GoogleFonts.dmSansTextTheme();

    return base.copyWith(
      displayLarge: _rec(57, letterSpacing: -0.25),
      displayMedium: _rec(45),
      displaySmall: _rec(36),
      headlineLarge: _rec(32),
      headlineMedium: _rec(28),
      headlineSmall: _rec(24),

      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),

      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0.25,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),

      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextStyle _recDark(double size, {double? letterSpacing}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: AppColors.background,
    letterSpacing: letterSpacing,
  );

  static TextTheme get _textThemeDark {
    final base = GoogleFonts.dmSansTextTheme();

    return base.copyWith(
      displayLarge: _recDark(57, letterSpacing: -0.25),
      displayMedium: _recDark(45),
      displaySmall: _recDark(36),
      headlineLarge: _recDark(32),
      headlineMedium: _recDark(28),
      headlineSmall: _recDark(24),

      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.background,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
        letterSpacing: 0.15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
        letterSpacing: 0.1,
      ),

      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.background,
        letterSpacing: 0.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.background,
        letterSpacing: 0.25,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.background,
        letterSpacing: 0.4,
      ),

      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
        letterSpacing: 0.5,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.textPrimary,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: AppColors.background,
      onSurface: AppColors.background,
    ),
    textTheme: _textThemeDark,
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      barBackgroundColor: AppColors.textPrimary,
      scaffoldBackgroundColor: AppColors.textPrimary,
      textTheme: CupertinoTextThemeData(primaryColor: AppColors.primary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.textPrimary,
      foregroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: Color(0xFF2C2C2C),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
      onPrimary: Colors.white,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: _textTheme,
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primary,
      barBackgroundColor: AppColors.background,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: CupertinoTextThemeData(primaryColor: AppColors.primary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: Color(0xFFE0E0E0),
  );
}
