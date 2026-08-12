import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Use Inter for that clean, premium look
  static final _textFont = GoogleFonts.interTextTheme();

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    background: const Color(0xFF000000),
    surface: const Color(0xFF0C0C0C),
    primary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF111111),
    text: const Color(0xFFFFFFFF),
    subtext: const Color(0xFFFFFFFF),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color text,
    required Color subtext,
  }) {
    final baseTextTheme = _textFont.apply(bodyColor: text, displayColor: text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      dividerColor: Colors.transparent, // No dividers for clean look
      splashFactory: NoSplash.splashFactory, // Remove default ripple

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: secondary,
        onSecondary: text,
        error: const Color(0xFFCF6679),
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        outline: subtext,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w200,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
          height: 1.3,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 56,
          fontWeight: FontWeight.w100, // Very thin timer
          letterSpacing: 1.0,
          height: 1.1,
          fontFeatures: [
            const FontFeature.tabularFigures(),
          ], // Monospace numbers
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
          color: text.withValues(alpha: 0.60),
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: text.withValues(alpha: 0.35),
        ),
      ),

      iconTheme: IconThemeData(color: text.withValues(alpha: 0.9), size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
          color: text,
        ),
        iconTheme: IconThemeData(color: text),
      ),

      // Minimalist Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: text,
          highlightColor: primary.withValues(alpha: 0.05),
          splashFactory: NoSplash.splashFactory,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: text,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),

      // Clean List Tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.transparent,
        textColor: text,
        iconColor: text.withValues(alpha: 0.35),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return subtext;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.2);
          }
          return Colors.white.withValues(alpha: 0.12);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
}
