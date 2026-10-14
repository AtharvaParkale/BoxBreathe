import 'package:flutter/widgets.dart';

/// Motion tokens. Entrances ease out, exits ease in and run shorter;
/// everything collapses to zero when the OS asks for reduced motion.
class AppMotion {
  AppMotion._();

  static const quick = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const calm = Duration(milliseconds: 450);
  static const phaseFade = Duration(milliseconds: 600);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;

  /// [duration], or zero when animations are disabled system-wide.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
