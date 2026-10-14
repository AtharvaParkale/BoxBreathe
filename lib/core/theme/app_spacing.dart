/// 4/8-pt spacing scale. Use these instead of literals so rhythm stays
/// consistent across screens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
  static const double giant = 64;

  /// Left/right page margin on every screen.
  static const double gutter = 24;

  /// Minimum interactive size (iOS HIG 44pt).
  static const double minTarget = 44;
}

/// The only three corner treatments in the app: square (lists, hairlines),
/// [soft] (buttons, sheets, dialogs) and full circles (orb, round controls).
class AppRadius {
  AppRadius._();

  static const double soft = 16;
}
