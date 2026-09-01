import 'package:flutter/material.dart';

import 'breathing_pattern.dart';
import 'breathing_technique.dart';

/// The curated technique library. Adding a technique means adding one entry
/// here — no engine or BLoC changes required, as long as its timing fits
/// [BreathingPattern] (which itself supports arbitrary phase sequences, not
/// just the classic inhale/hold/exhale/hold shape).
///
/// Several entries deliberately share one [BreathingPattern] instance under
/// different content/framing (e.g. Focus Breathing reuses Equal Breathing's
/// timing) — that's the point: the pattern is the physiology, the technique
/// is how it's framed for a specific moment.
class BreathingTechniqueCatalog {
  BreathingTechniqueCatalog._();

  /// Persisted id of the technique shown by default and used as a fallback
  /// whenever a stored/legacy id no longer resolves.
  static const String defaultId = 'box';

  // Shared pattern instances — reused across techniques with identical
  // timing but different framing, so adding a technique doesn't always
  // mean adding a new physiological pattern.
  static final _coherencePattern = BreathingPattern.classic(
    inhaleMs: 5500,
    holdAfterInhaleMs: 0,
    exhaleMs: 5500,
    holdAfterExhaleMs: 0,
  );
  static final _equalBreathingPattern = BreathingPattern.classic(
    inhaleMs: 4000,
    holdAfterInhaleMs: 0,
    exhaleMs: 4000,
    holdAfterExhaleMs: 0,
  );
  static final _extendedExhalePattern = BreathingPattern.classic(
    inhaleMs: 4000,
    holdAfterInhaleMs: 0,
    exhaleMs: 7000,
    holdAfterExhaleMs: 0,
  );

  static final box = BreathingTechnique(
    id: 'box',
    name: 'Box Breathing',
    shortDescription:
        'A steady four-count rhythm that helps you regain control when '
        'stress takes over.',
    longDescription:
        'Box breathing uses four equal phases — inhale, hold, exhale, hold '
        '— to give your mind something steady to follow when everything '
        'else feels chaotic. Simple enough to do anywhere, structured '
        'enough to actually anchor a racing mind.',
    categories: const [TechniqueCategory.calm, TechniqueCategory.focus],
    benefits: const ['Stress', 'Anxiety', 'Focus', 'Overthinking'],
    useCases: const [
      'Before a stressful meeting',
      'When work feels overwhelming',
      'Before an exam',
      'When your thoughts feel scattered',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 4000,
      holdAfterInhaleMs: 4000,
      exhaleMs: 4000,
      holdAfterExhaleMs: 4000,
    ),
    recommendedDuration: 3,
    availableDurations: const [1, 3, 5, 10],
    difficulty: TechniqueDifficulty.intermediate,
    instructions: const [
      'Inhale slowly through your nose for 4 seconds',
      'Hold gently for 4 seconds',
      'Exhale slowly through your mouth for 4 seconds',
      'Hold again for 4 seconds',
      'Repeat at your own pace',
    ],
    tips: const [
      "If a hold feels uncomfortable, shorten it or skip it — you're "
          'always in control',
      'Try counting in your head rather than watching a clock',
    ],
    whatYouMayNotice:
        'Your breathing may begin to feel slower and more controlled. '
        'Your attention may shift away from racing thoughts and toward '
        'your breath.',
    icon: Icons.crop_square_rounded,
    isFeatured: true,
    order: 1,
  );

  static final calm478 = BreathingTechnique(
    id: 'calm478',
    name: '4-7-8 Breathing',
    shortDescription:
        'A longer exhale designed to help your body settle before rest.',
    longDescription:
        'The 4-7-8 pattern stretches the exhale well past the inhale, '
        'which tends to feel naturally calming. A popular choice for '
        'winding down at night or easing racing thoughts before bed.',
    categories: const [TechniqueCategory.sleep, TechniqueCategory.calm],
    benefits: const ['Relaxation', 'Racing thoughts', 'Bedtime wind-down'],
    useCases: const [
      'Lying in bed, unable to switch off',
      'Winding down after a long day',
      'Before a nap',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 4000,
      holdAfterInhaleMs: 7000,
      exhaleMs: 8000,
      holdAfterExhaleMs: 0,
    ),
    recommendedDuration: 5,
    availableDurations: const [3, 5, 10],
    difficulty: TechniqueDifficulty.intermediate,
    instructions: const [
      'Inhale quietly through your nose for 4 seconds',
      'Hold for 7 seconds',
      'Exhale slowly through your mouth for 8 seconds',
      'Repeat',
    ],
    tips: const [
      'The 7-second hold is the hardest part for most people — if it '
          'feels tight or uncomfortable, try the gentler version instead',
      'Keep your shoulders relaxed throughout',
    ],
    warnings: const [
      'If holding your breath ever feels dizzying or uncomfortable, stop '
          'and breathe normally',
    ],
    whatYouMayNotice:
        'Some people notice a heavy, settled feeling as the exhale '
        'lengthens. It may take a few rounds before it feels natural.',
    icon: Icons.bedtime_rounded,
    isFeatured: true,
    order: 2,
    gentlerVariantId: 'calm478Gentle',
  );

  static final calm478Gentle = BreathingTechnique(
    id: 'calm478Gentle',
    name: '4-7-8 · Gentler Hold',
    shortDescription:
        'The same wind-down pattern, with a shorter, easier hold.',
    longDescription:
        'Same idea as 4-7-8 — a stretched exhale to help you settle — but '
        'with a 4-second hold instead of 7, for anyone who finds the '
        'longer hold uncomfortable.',
    categories: const [TechniqueCategory.sleep, TechniqueCategory.calm],
    benefits: const ['Relaxation', 'Racing thoughts'],
    useCases: const [
      'When the standard 4-7-8 hold feels like too much',
      'Winding down at night',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 4000,
      holdAfterInhaleMs: 4000,
      exhaleMs: 8000,
      holdAfterExhaleMs: 0,
    ),
    recommendedDuration: 5,
    availableDurations: const [3, 5, 10],
    difficulty: TechniqueDifficulty.gentle,
    instructions: const [
      'Inhale through your nose for 4 seconds',
      'Hold gently for 4 seconds',
      'Exhale slowly through your mouth for 8 seconds',
      'Repeat',
    ],
    tips: const [
      "Once this feels easy, you're welcome to try the full 4-7-8 hold",
    ],
    whatYouMayNotice:
        'A slower, heavier feeling as your exhale lengthens, without the '
        'strain of a longer hold.',
    icon: Icons.bedtime_outlined,
    isFeatured: false,
    isVisibleInLibrary: false,
    order: 90,
  );

  static final physiologicalSigh = BreathingTechnique(
    id: 'physiologicalSigh',
    name: 'Physiological Sigh',
    shortDescription:
        'A double inhale and one long exhale — the fastest way to take '
        'the edge off.',
    longDescription:
        "Two inhales back to back, followed by one long, slow exhale. "
        "One of the quickest ways to bring your body down from a stress "
        'spike — usually just one to three rounds is enough.',
    categories: const [
      TechniqueCategory.overwhelmed,
      TechniqueCategory.calm,
    ],
    benefits: const ['Sudden stress', 'Feeling overwhelmed', 'Anxiety spikes'],
    useCases: const [
      'Right after something stressful happens',
      'Before a difficult conversation',
      'When you feel a wave of stress hit',
    ],
    pattern: BreathingPattern([
      const PhaseSegment(
        kind: BreathingPhaseKind.inhale,
        durationMs: 2000,
        scaleStart: 0.6,
        scaleEnd: 0.85,
      ),
      const PhaseSegment(
        kind: BreathingPhaseKind.inhale,
        durationMs: 1000,
        scaleStart: 0.85,
        scaleEnd: 1.0,
        labelOverride: 'AND AGAIN',
      ),
      const PhaseSegment(
        kind: BreathingPhaseKind.exhale,
        durationMs: 6000,
        scaleStart: 1.0,
        scaleEnd: 0.6,
      ),
    ]),
    recommendedDuration: 1,
    availableDurations: const [1],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Take a deep inhale through your nose',
      'Without exhaling, take one more short, sharp inhale to top off '
          'your lungs',
      'Let out a long, slow exhale through your mouth',
      "That's one round — a few rounds is usually enough",
    ],
    tips: const [
      'No need to force the second inhale — a small extra breath is '
          'enough',
    ],
    whatYouMayNotice:
        'A quick release of tension, often within a single round.',
    icon: Icons.bolt_rounded,
    isFeatured: true,
    order: 3,
  );

  static final coherence = BreathingTechnique(
    id: 'coherence',
    name: 'Coherent Breathing',
    shortDescription:
        'Even, steady breathing with no holds — a simple way to feel more '
        'settled.',
    longDescription:
        'Equal-length inhales and exhales, with nothing to hold or count '
        'beyond the breath itself. An easy pattern to return to '
        'throughout the day whenever you want to feel a bit more even.',
    categories: const [TechniqueCategory.calm],
    benefits: const ['General stress', 'Emotional steadiness', 'Daily reset'],
    useCases: const [
      'Resetting between tasks',
      'General daily stress',
      'Anytime you want a moment of calm',
    ],
    pattern: _coherencePattern,
    recommendedDuration: 5,
    availableDurations: const [3, 5, 10],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Inhale slowly through your nose for about 5 seconds',
      'Exhale slowly for about 5 seconds',
      'No holds — just a smooth, even rhythm',
    ],
    tips: const [
      'Let the numbers be approximate — smoothness matters more than '
          'precision',
    ],
    whatYouMayNotice:
        'A steadier, more even feeling as the rhythm continues.',
    icon: Icons.graphic_eq_rounded,
    isFeatured: true,
    order: 4,
  );

  static final extendedExhale = BreathingTechnique(
    id: 'extendedExhale',
    name: 'Extended Exhale',
    shortDescription:
        'A longer exhale than inhale, designed to help you settle.',
    longDescription:
        'Keeping the exhale noticeably longer than the inhale is one of '
        'the simplest ways to encourage your body to relax. No holds, '
        'nothing to remember beyond breathing out longer than you '
        'breathed in.',
    categories: const [
      TechniqueCategory.calm,
      TechniqueCategory.overwhelmed,
      TechniqueCategory.sleep,
    ],
    benefits: const ['Tension', 'Restlessness', 'Anxiety'],
    useCases: const [
      'After a stressful day',
      'When you feel tense or wound up',
      'Before sleep',
    ],
    pattern: _extendedExhalePattern,
    recommendedDuration: 5,
    availableDurations: const [3, 5, 10],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Inhale through your nose for 4 seconds',
      'Exhale slowly through your mouth for 7 seconds',
      'No holds — just let the exhale stretch out',
    ],
    tips: const [
      'If 7 seconds feels like a stretch at first, aim for "longer than '
          'the inhale" rather than an exact count',
    ],
    whatYouMayNotice:
        'A gradual settling feeling as the longer exhales continue.',
    icon: Icons.south_rounded,
    isFeatured: true,
    order: 5,
  );

  static final equalBreathing = BreathingTechnique(
    id: 'equalBreathing',
    name: 'Equal Breathing',
    shortDescription: 'Simple, balanced breathing to help you concentrate.',
    longDescription:
        "Equal-length inhales and exhales create a steady rhythm that's "
        'easy to hold in the background of your mind — useful for '
        'settling in before focused work.',
    categories: const [TechniqueCategory.focus],
    benefits: const ['Focus', 'Concentration', 'Task transitions'],
    useCases: const [
      'Before studying',
      'Settling in before work',
      'Switching between tasks',
    ],
    pattern: _equalBreathingPattern,
    recommendedDuration: 3,
    availableDurations: const [1, 3, 5],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Inhale through your nose for 4 seconds',
      'Exhale through your nose or mouth for 4 seconds',
      'Keep the rhythm even and steady',
    ],
    whatYouMayNotice:
        'A quieter, more settled mind as the rhythm continues.',
    icon: Icons.balance_rounded,
    isFeatured: true,
    order: 6,
  );

  static final diaphragmatic = BreathingTechnique(
    id: 'diaphragmatic',
    name: 'Deep Diaphragmatic Breathing',
    shortDescription: 'Slow, full breaths that let your belly do the work.',
    longDescription:
        'Rather than counting exact seconds, this technique is about '
        'where you breathe from — letting your abdomen expand on the '
        'inhale instead of raising your shoulders. A good starting point '
        'if breathing exercises are new to you.',
    categories: const [TechniqueCategory.calm],
    benefits: const ['General relaxation', 'Body awareness'],
    useCases: const [
      'Learning the basics of slow breathing',
      'General everyday stress',
      'Whenever you want a simple reset',
    ],
    pattern: _coherencePattern,
    recommendedDuration: 5,
    availableDurations: const [3, 5, 10],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Place a hand on your belly if it helps',
      'Inhale slowly through your nose, letting your belly rise',
      'Exhale slowly, letting your belly fall',
      'Keep your shoulders relaxed throughout',
    ],
    tips: const ["There's no need to force a deep breath — let it expand naturally"],
    whatYouMayNotice:
        'A looser, heavier feeling in your shoulders and chest as your '
        'breathing settles lower.',
    icon: Icons.circle_outlined,
    isFeatured: false,
    order: 7,
  );

  static final morningEnergize = BreathingTechnique(
    id: 'morningEnergize',
    name: 'Morning Energizing Breath',
    shortDescription: 'A gentle, upbeat rhythm to help you feel more awake.',
    longDescription:
        'Slightly quicker and lighter than the other techniques here, '
        'this pattern is designed to help you feel more alert without '
        'any holds or intensity — energizing, not intense.',
    categories: const [TechniqueCategory.energize],
    benefits: const ['Alertness', 'Waking up', 'Starting the day'],
    useCases: const [
      'First thing in the morning',
      'Before you need to feel more awake',
      'A slow start to the day',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 2000,
      holdAfterInhaleMs: 0,
      exhaleMs: 2000,
      holdAfterExhaleMs: 0,
    ),
    recommendedDuration: 1,
    availableDurations: const [1, 3],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Inhale through your nose for 2 seconds',
      'Exhale through your mouth for 2 seconds',
      'Keep the pace light and easy — no need to force it',
    ],
    tips: const [
      'Stop any time the pace feels like too much — a slower rhythm '
          'works just as well',
    ],
    warnings: const [
      'Designed to feel gentle, not intense — slow down if you feel '
          'lightheaded',
    ],
    whatYouMayNotice: 'A brighter, more awake feeling by the end of the session.',
    icon: Icons.wb_sunny_rounded,
    isFeatured: true,
    order: 8,
  );

  static final focusBreathing = BreathingTechnique(
    id: 'focusBreathing',
    name: 'Focus Breathing',
    shortDescription:
        'A short, structured session to quiet mental noise before deep work.',
    longDescription:
        'The same balanced rhythm as Equal Breathing, framed as a quick '
        'warm-up before something that needs your full attention — '
        'studying, coding, reading, or anything that requires a clear '
        'head.',
    categories: const [TechniqueCategory.focus],
    benefits: const ['Mental noise', 'Concentration', 'Preparing for deep work'],
    useCases: const [
      'Before a study session',
      'Before coding or writing',
      'Before reading something dense',
    ],
    pattern: _equalBreathingPattern,
    recommendedDuration: 3,
    availableDurations: const [1, 3, 5],
    difficulty: TechniqueDifficulty.beginner,
    instructions: const [
      'Inhale through your nose for 4 seconds',
      'Exhale for 4 seconds',
      'Let your mind settle into the rhythm before you begin your task',
    ],
    whatYouMayNotice:
        'Fewer stray thoughts pulling at your attention once the session '
        'ends.',
    icon: Icons.center_focus_strong_rounded,
    isFeatured: true,
    order: 9,
  );

  static final sleep = BreathingTechnique(
    id: 'sleep',
    name: 'Sleep Breathing',
    shortDescription: 'A slow, unhurried pattern to help you wind down.',
    longDescription:
        'Slower inhales, a brief hold, and a longer exhale — designed to '
        'help quiet a racing mind as you transition toward sleep.',
    categories: const [TechniqueCategory.sleep],
    benefits: const ['Winding down', 'Racing thoughts at night'],
    useCases: const [
      'Lying in bed',
      "Your thoughts won't slow down",
      'Transitioning toward rest',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 5000,
      holdAfterInhaleMs: 5000,
      exhaleMs: 7000,
      holdAfterExhaleMs: 0,
    ),
    recommendedDuration: 10,
    availableDurations: const [5, 10, -1],
    difficulty: TechniqueDifficulty.gentle,
    instructions: const [
      'Inhale slowly through your nose for 5 seconds',
      'Hold gently for 5 seconds',
      'Exhale slowly for 7 seconds',
      'Let your eyes stay closed throughout',
    ],
    tips: const ["It's fine to drift off mid-session — that's the point"],
    whatYouMayNotice: 'A heavier, sleepier feeling as the session continues.',
    icon: Icons.nightlight_round,
    isFeatured: true,
    order: 10,
  );

  static final preMeetingReset = BreathingTechnique(
    id: 'quickReset',
    name: 'Pre-Meeting Reset',
    shortDescription:
        'A short structured session to settle your nerves right before it '
        'matters.',
    longDescription:
        'The same box-like structure as Box Breathing, sized down to '
        "something you can finish in under a minute — right outside the "
        'room, right before you go on.',
    categories: const [TechniqueCategory.overwhelmed, TechniqueCategory.focus],
    benefits: const ['Nerves', 'Pre-event stress', 'Regaining composure quickly'],
    useCases: const [
      'Right before a meeting',
      'Before a presentation',
      'Before an interview',
      'Before public speaking',
    ],
    pattern: BreathingPattern.classic(
      inhaleMs: 3000,
      holdAfterInhaleMs: 3000,
      exhaleMs: 3000,
      holdAfterExhaleMs: 3000,
    ),
    recommendedDuration: 1,
    availableDurations: const [1, 3],
    difficulty: TechniqueDifficulty.intermediate,
    instructions: const [
      'Inhale for 3 seconds',
      'Hold for 3 seconds',
      'Exhale for 3 seconds',
      'Hold for 3 seconds',
      'A minute is usually enough',
    ],
    tips: const [
      "If a hold feels uncomfortable, shorten it or skip it — you're "
          'always in control',
    ],
    whatYouMayNotice:
        'A calmer, more composed feeling heading into the moment.',
    icon: Icons.record_voice_over_rounded,
    isFeatured: true,
    order: 11,
  );

  static final panicReset = BreathingTechnique(
    id: 'panicReset',
    name: 'Panic & Anxiety Reset',
    shortDescription: 'A gentle breathing reset for overwhelming moments.',
    longDescription:
        'No holds, no complicated counting — just slow inhales and long, '
        'comfortable exhales. Designed to be usable the moment you need '
        'it, with nothing to remember beyond breathing out slowly.',
    categories: const [TechniqueCategory.overwhelmed],
    benefits: const ['Overwhelm', 'Sudden anxiety', 'Feeling out of control'],
    useCases: const [
      'When everything feels like too much',
      'In the middle of a stressful moment',
      'When you need something simple, right now',
    ],
    pattern: _extendedExhalePattern,
    recommendedDuration: 3,
    availableDurations: const [1, 3, 5],
    difficulty: TechniqueDifficulty.gentle,
    instructions: const [
      'Inhale gently through your nose',
      'Exhale slowly, taking longer than the inhale',
      "There's no count to get right — just breathe out slower than you "
          'breathe in',
    ],
    tips: const [
      "You're always in control — stop any time and breathe however "
          'feels natural',
    ],
    whatYouMayNotice: 'A gradual easing, even if it takes a few minutes to notice.',
    icon: Icons.favorite_rounded,
    isFeatured: true,
    order: 12,
  );

  static final List<BreathingTechnique> all = [
    box,
    calm478,
    calm478Gentle,
    physiologicalSigh,
    coherence,
    extendedExhale,
    equalBreathing,
    diaphragmatic,
    morningEnergize,
    focusBreathing,
    sleep,
    preMeetingReset,
    panicReset,
  ];

  static List<BreathingTechnique> get visible =>
      all.where((t) => t.isVisibleInLibrary).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  static BreathingTechnique get defaultTechnique => byId(defaultId);

  static bool exists(String id) => all.any((t) => t.id == id);

  static BreathingTechnique byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => box);

  static List<BreathingTechnique> byCategory(TechniqueCategory category) =>
      visible.where((t) => t.categories.contains(category)).toList();

  /// Techniques to show in a category preview — featured ones, falling
  /// back to the full category list if none happen to be featured.
  static List<BreathingTechnique> featuredByCategory(
    TechniqueCategory category,
  ) {
    final featured =
        byCategory(category).where((t) => t.isFeatured).toList();
    return featured.isNotEmpty ? featured : byCategory(category);
  }
}
