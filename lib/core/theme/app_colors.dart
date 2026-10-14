import 'package:flutter/painting.dart';

/// The whole palette. Ease is strictly black and white — hierarchy comes
/// from these opacity tiers, never from hue.
///
/// Text tiers are chosen against pure black: [tertiary] (50%) is the floor
/// for any readable text (~5:1); [disabled] and below are for non-text
/// marks only (rings, hairlines, inactive dots).
class AppColors {
  AppColors._();

  static const black = Color(0xFF000000);

  /// Sheets and dialogs only — the one lifted surface.
  static const raised = Color(0xFF0D0D0D);

  static const white = Color(0xFFFFFFFF);
  static const primary = white;
  static const secondary = Color(0xADFFFFFF); // 68%
  static const tertiary = Color(0x80FFFFFF); // 50%
  static const disabled = Color(0x4DFFFFFF); // 30%
  static const hairline = Color(0x1FFFFFFF); // 12%
  static const faint = Color(0x0FFFFFFF); // 6%
}
