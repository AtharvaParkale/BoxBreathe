import 'package:hive/hive.dart';

/// First-launch flag only — intentionally not layered like the other
/// features (no repository/usecase split), since there is no domain
/// logic here beyond "has this single flag been set".
class OnboardingStorage {
  final Box box;
  static const String _keyHasSeenOnboarding = 'onboarding_has_seen_v1';

  OnboardingStorage(this.box);

  bool hasSeenOnboarding() =>
      box.get(_keyHasSeenOnboarding, defaultValue: false) as bool;

  Future<void> markSeen() => box.put(_keyHasSeenOnboarding, true);
}
