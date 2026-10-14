import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The single Ease theme: pure black, white, and white-at-opacity. Every
/// Material component that could otherwise pull a tinted/generated colour
/// (M3 containers, time picker, switches, dialogs) is pinned to grayscale
/// here so feature code never has to.
class AppTheme {
  AppTheme._();

  static final ThemeData darkTheme = _build();

  static ThemeData _build() {
    final text = AppTypography.textTheme();
    const softShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.soft)),
    );

    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.white,
      onPrimary: AppColors.black,
      primaryContainer: AppColors.hairline,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.white,
      onSecondary: AppColors.black,
      secondaryContainer: AppColors.hairline,
      onSecondaryContainer: AppColors.white,
      tertiary: AppColors.white,
      onTertiary: AppColors.black,
      tertiaryContainer: AppColors.hairline,
      onTertiaryContainer: AppColors.white,
      // Errors are carried by wording, not hue.
      error: AppColors.white,
      onError: AppColors.black,
      errorContainer: AppColors.hairline,
      onErrorContainer: AppColors.white,
      surface: AppColors.black,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.secondary,
      surfaceDim: AppColors.black,
      surfaceBright: AppColors.raised,
      surfaceContainerLowest: AppColors.black,
      surfaceContainerLow: AppColors.raised,
      surfaceContainer: AppColors.raised,
      surfaceContainerHigh: AppColors.raised,
      surfaceContainerHighest: AppColors.raised,
      outline: AppColors.disabled,
      outlineVariant: AppColors.hairline,
      shadow: AppColors.black,
      scrim: Color(0xB3000000),
      inverseSurface: AppColors.white,
      onInverseSurface: AppColors.black,
      inversePrimary: AppColors.black,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      fontFamily: AppTypography.sans,
      textTheme: text,
      dividerColor: AppColors.hairline,
      disabledColor: AppColors.disabled,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.faint,
      hoverColor: AppColors.faint,
      focusColor: AppColors.hairline,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.black,
          ),
        },
      ),
      iconTheme: const IconThemeData(color: AppColors.white, size: 22),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.white,
          minimumSize: const Size.square(AppSpacing.minTarget),
          splashFactory: NoSplash.splashFactory,
          highlightColor: AppColors.faint,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          textStyle: text.labelLarge,
          minimumSize: const Size(AppSpacing.minTarget, AppSpacing.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: softShape,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          textStyle: text.labelLarge,
          minimumSize: const Size(AppSpacing.minTarget, 48),
          side: const BorderSide(color: AppColors.disabled),
          shape: softShape,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.tertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : Colors.transparent,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.disabled,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.white,
        linearTrackColor: AppColors.hairline,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.white,
        selectionColor: AppColors.disabled,
        selectionHandleColor: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.tertiary),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.white),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.raised,
        modalBackgroundColor: AppColors.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.soft),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.soft)),
          side: BorderSide(color: AppColors.hairline),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge?.copyWith(color: AppColors.secondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.white,
        contentTextStyle: text.bodyLarge?.copyWith(color: AppColors.black),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: softShape,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.raised,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.soft)),
          side: BorderSide(color: AppColors.hairline),
        ),
        dialBackgroundColor: AppColors.faint,
        dialHandColor: AppColors.white,
        dialTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.white,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.hairline
              : AppColors.faint,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.secondary,
        ),
        hourMinuteShape: softShape,
        dayPeriodColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.secondary,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.disabled),
        entryModeIconColor: AppColors.tertiary,
        helpTextStyle: text.labelSmall,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.white,
        ),
      ),
    );
  }
}
