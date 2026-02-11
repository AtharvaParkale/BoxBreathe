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
          background: const Color(0xFF000000),
          surface: const Color(0xFF1C1C1E),
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
          background: const Color(0xFF051109),
          surface: const Color(0xFF0F2618),
          primary: const Color(0xFFE6F4EA),
          secondary: const Color(0xFF1C3A29),
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
          background: const Color(0xFFFFFFFF),
          surface: const Color(0xFFF7F7F7),
          primary: const Color(0xFF000000),
          secondary: const Color(0xFFEEEEEE),
          text: const Color(0xFF000000),
          subtext: const Color(0xFF757575),
        );
      case AppThemeMode.sunset:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF100C18),
          surface: const Color(0xFF241E36),
          primary: const Color(0xFFFF9E80), // Soft Coral
          secondary: const Color(0xFF4527A0),
          text: const Color(0xFFFFE0B2),
          subtext: const Color(0xFFB39DDB),
        );
      case AppThemeMode.bamboo:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFF1F8E9),
          surface: const Color(0xFFDCEDC8),
          primary: const Color(0xFF33691E), // Deep Green
          secondary: const Color(0xFFAED581),
          text: const Color(0xFF1B5E20),
          subtext: const Color(0xFF558B2F),
        );
      case AppThemeMode.cedar:
        return _buildTheme(
          brightness: Brightness.dark,
          background: const Color(0xFF1D1612),
          surface: const Color(0xFF3E2723),
          primary: const Color(0xFFFFCCBC), // Peach
          secondary: const Color(0xFF5D4037),
          text: const Color(0xFFD7CCC8),
          subtext: const Color(0xFFA1887F),
        );
      case AppThemeMode.glacier:
        return _buildTheme(
          brightness: Brightness.light,
          background: const Color(0xFFE0F7FA),
          surface: const Color(0xFFB2EBF2),
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
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w200, // Very thin timer
          letterSpacing: 2.0,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: subtext,
        ),
      ),

      iconTheme: IconThemeData(
        color: text.withValues(alpha: 0.8),
        size: 24,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
          highlightColor: primary.withValues(alpha: 0.1),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: text,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      // Clean List Tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return  secondary;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
      ),
    );
  }
}
