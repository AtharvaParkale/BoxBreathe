import 'package:flutter/widgets.dart' show IconData;
import 'package:equatable/equatable.dart';

import 'breathing_pattern.dart';

/// Matches the 5 "What do you need right now?" discovery buckets 1:1.
enum TechniqueCategory { calm, focus, sleep, energize, overwhelmed }

extension TechniqueCategoryLabel on TechniqueCategory {
  String get label {
    switch (this) {
      case TechniqueCategory.calm:
        return 'Calm down';
      case TechniqueCategory.focus:
        return 'Focus';
      case TechniqueCategory.sleep:
        return 'Sleep';
      case TechniqueCategory.energize:
        return 'Feel more awake';
      case TechniqueCategory.overwhelmed:
        return 'Feeling overwhelmed';
    }
  }

  String get emoji {
    switch (this) {
      case TechniqueCategory.calm:
        return '😌';
      case TechniqueCategory.focus:
        return '🧠';
      case TechniqueCategory.sleep:
        return '😴';
      case TechniqueCategory.energize:
        return '⚡';
      case TechniqueCategory.overwhelmed:
        return '❤️';
    }
  }
}

/// Deliberately framed as feel, not skill — a user should never feel like
/// they're "bad" at breathing.
enum TechniqueDifficulty { beginner, gentle, intermediate }

extension TechniqueDifficultyLabel on TechniqueDifficulty {
  String get label {
    switch (this) {
      case TechniqueDifficulty.beginner:
        return 'Beginner-friendly';
      case TechniqueDifficulty.gentle:
        return 'Gentle';
      case TechniqueDifficulty.intermediate:
        return 'A bit more structured';
    }
  }
}

/// Rich content describing a breathing technique for the discovery and
/// detail UI. Deliberately separate from [BreathingPattern] (the pure
/// timing engine) so multiple techniques can share one underlying pattern
/// under different framing — e.g. Focus Breathing and Equal Breathing.
///
/// `isFavorite` is intentionally not a field here: favorites are mutable
/// per-user state, stored in Settings, not part of this static catalog.
class BreathingTechnique extends Equatable {
  /// Stable identifier used for persistence. Independent of [name] so the
  /// display label can change without breaking saved user preferences.
  final String id;
  final String name;
  final String shortDescription;
  final String longDescription;
  final List<TechniqueCategory> categories;
  final List<String> benefits;
  final List<String> useCases;
  final BreathingPattern pattern;

  /// Minutes; -1 means infinite.
  final int recommendedDuration;
  final List<int> availableDurations;
  final TechniqueDifficulty difficulty;
  final List<String> instructions;
  final List<String> tips;
  final List<String> warnings;
  final String whatYouMayNotice;
  final IconData icon;
  final List<String> tags;

  /// Surfaced in "What do you need right now?" category previews.
  final bool isFeatured;

  /// False for hidden variants (e.g. 4-7-8's gentler hold) that are only
  /// reachable via a cross-link, not listed in "Browse all".
  final bool isVisibleInLibrary;
  final int order;
  final String? gentlerVariantId;

  const BreathingTechnique({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.categories,
    required this.benefits,
    required this.useCases,
    required this.pattern,
    required this.recommendedDuration,
    required this.availableDurations,
    required this.difficulty,
    required this.instructions,
    this.tips = const [],
    this.warnings = const [],
    required this.whatYouMayNotice,
    required this.icon,
    this.tags = const [],
    this.isFeatured = false,
    this.isVisibleInLibrary = true,
    required this.order,
    this.gentlerVariantId,
  });

  @override
  List<Object?> get props => [id];
}
