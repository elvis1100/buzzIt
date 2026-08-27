import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF075A91);
  static const primaryDark = Color(0xFF063F66);
  static const primaryLight = Color(0xFFDCECF6);
  static const secondary = Color(0xFFF1A606);
  static const secondaryDark = Color(0xFF9B6700);
  static const secondaryLight = Color(0xFFFFF0C7);
  static const ink = Color(0xFF102A3A);
  static const inkMuted = Color(0xFF617583);
  static const background = Color(0xFFF4F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE9EFF3);
  static const success = Color(0xFF2E7D5B);
  static const error = Color(0xFFB53A45);
  static const warning = Color(0xFF9B6700);
  static const overlay = Color(0xB3122B3A);
}

abstract final class AppSizes {
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;
  static const space2Xl = 48.0;
  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;
  static const radiusPill = 999.0;
  static const controlHeight = 48.0;
  static const desktopMaxWidth = 1440.0;
}

abstract final class AppDurations {
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 240);
  static const celebratory = Duration(milliseconds: 700);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
          borderSide: BorderSide(color: AppColors.surfaceMuted),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.spaceMd,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.primaryLight,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceMuted,
        space: 1,
      ),
    );
  }
}
