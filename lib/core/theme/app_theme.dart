import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  midnight,
  ocean,
  forest,
  lavender,
  sand,
  minimalLight,
  sunset,
  bamboo,
  cedar,
  glacier,
}

class AppTheme {
  // Use Inter for that clean, premium look
  static final _textFont = GoogleFonts.interTextTheme();

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.midnight:
        return _buildTheme(
          brightness: Brightness.dark,
          // Premium Charcoal
          background: const Color(0xFF141416),
          surface: const Color(0xFF232326),
          primary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF2C2C2E),
          text: const Color(0xFFFFFFFF),
          subtext: const Color(0xFF8E8E93),
        );
      case AppThemeMode.ocean:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF0F172A),
          surface: const Color(0xFF1E293B),
          primary: const Color(0xFFE2E8F0),
          secondary: const Color(0xFF334155),
          text: const Color(0xFFF8FAFC),
          subtext: const Color(0xFF94A3B8),
        );
      case AppThemeMode.forest:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF0D1811),
          surface: const Color(0xFF1A2F23),
          primary: const Color(0xFFE6F4EA),
          secondary: const Color(0xFF2D4F3B),
          text: const Color(0xFFF1F8E9),
          subtext: const Color(0xFF81C784),
        );
      case AppThemeMode.lavender:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFFDFBFD),
          surface: const Color(0xFFF3E5F5), // Very light purple
          primary: const Color(0xFF4A148C),
          secondary: const Color(0xFFE1BEE7),
          text: const Color(0xFF2D1F35),
          subtext: const Color(0xFF7B6685),
        );
      case AppThemeMode.sand:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFFDFCF8),
          surface: const Color(0xFFF4F1EA),
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFFE6DCCD),
          text: const Color(0xFF4E342E),
          subtext: const Color(0xFF8D6E63),
        );
      case AppThemeMode.minimalLight:
        return _buildTheme(
          brightness: Brightness.light,
          // Premium Off-White
          background: const Color(0xFFF9FAFB),
          surface: const Color(0xFFFFFFFF),
          primary: const Color(0xFF111827),
          secondary: const Color(0xFFF3F4F6),
          text: const Color(0xFF111827),
          subtext: const Color(0xFF6B7280),
        );
      case AppThemeMode.sunset:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF18151E),
          surface: const Color(0xFF2A2438),
          primary: const Color(0xFFFF9E80), // Soft Coral
          secondary: const Color(0xFF4527A0),
          text: const Color(0xFFFFE0B2),
          subtext: const Color(0xFFB39DDB),
        );
      case AppThemeMode.bamboo:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFF4F9F1),
          surface: const Color(0xFFE5F0DB),
          primary: const Color(0xFF33691E), // Deep Green
          secondary: const Color(0xFFAED581),
          text: const Color(0xFF1B5E20),
          subtext: const Color(0xFF558B2F),
        );
      case AppThemeMode.cedar:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF1D1816),
          surface: const Color(0xFF3E2D27),
          primary: const Color(0xFFFFCCBC), // Peach
          secondary: const Color(0xFF5D4037),
          text: const Color(0xFFD7CCC8),
          subtext: const Color(0xFFA1887F),
        );
      case AppThemeMode.glacier:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFF0F9FA),
          surface: const Color(0xFFD3EEF3),
          primary: const Color(0xFF006064), // Cyan
          secondary: const Color(0xFF4DD0E1),
          text: const Color(0xFF004D40),
          subtext: const Color(0xFF0097A7),
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color text,
    required Color subtext,
  }) {
    final baseTextTheme = _textFont.apply(
      bodyColor: text,
      displayColor: text,
    );

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
          fontFeatures: [const FontFeature.tabularFigures()], // Monospace numbers
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
          color: text.withValues(alpha: 0.8),
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: subtext,
        ),
      ),

      iconTheme: IconThemeData(
        color: text.withValues(alpha: 0.9),
        size: 24,
      ),

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
        iconColor: subtext,
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return subtext;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.2);
          return  secondary;
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

