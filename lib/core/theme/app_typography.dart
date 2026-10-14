import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Two families, one job each: Newsreader (serif) for the few moments that
/// should feel calm and human — "Breathe.", phase words, titles, numerals —
/// and Inter for everything functional.
///
/// Feature code reads these through `Theme.of(context).textTheme`:
///
/// | role            | slot            | spec                    |
/// |-----------------|-----------------|-------------------------|
/// | Hero line       | displayLarge    | serif 44 / 300          |
/// | Statistic       | displaySmall    | serif 40 / 300, tabular |
/// | Phase word      | displayMedium   | serif 34 / 300          |
/// | Page title      | headlineMedium  | serif 32 / 300          |
/// | Sheet/dialog    | headlineSmall   | serif 24 / 300          |
/// | Row title       | titleMedium     | sans 17 / 500           |
/// | Body            | bodyLarge       | sans 16 / 400           |
/// | Secondary body  | bodyMedium      | sans 14 / 400, 68%      |
/// | Button          | labelLarge      | sans 16 / 500           |
/// | Timer / figures | labelMedium     | sans 16 / 500, tabular  |
/// | Section label   | labelSmall      | sans 12 / 500, caps     |
class AppTypography {
  AppTypography._();

  static const serif = 'Newsreader';
  static const sans = 'Inter';

  static const _tabular = [FontFeature.tabularFigures()];

  /// The single oversized figure on Progress (current streak).
  static const heroNumeral = TextStyle(
    fontFamily: serif,
    fontSize: 72,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: -1.5,
    color: AppColors.primary,
    fontFeatures: _tabular,
  );

  static TextTheme textTheme() {
    const s = TextStyle(fontFamily: serif, color: AppColors.primary);
    const i = TextStyle(fontFamily: sans, color: AppColors.primary);

    return TextTheme(
      displayLarge: s.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w300,
        height: 1.1,
        letterSpacing: -0.6,
      ),
      displayMedium: s.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w300,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      displaySmall: s.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        height: 1.1,
        letterSpacing: -0.4,
        fontFeatures: _tabular,
      ),
      headlineMedium: s.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      headlineSmall: s.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        height: 1.25,
      ),
      titleLarge: i.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      titleMedium: i.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: -0.1,
      ),
      titleSmall: i.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyLarge: i.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: i.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.secondary,
      ),
      bodySmall: i.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.tertiary,
      ),
      labelLarge: i.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: i.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
        color: AppColors.secondary,
      ),
      labelSmall: i.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        height: 1.3,
        color: AppColors.tertiary,
      ),
    );
  }
}
