import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_button.dart';
import '../../../../injection_container.dart' as di;
import '../../../breathing/domain/entities/breathing_pattern.dart';
import '../../../breathing/presentation/pages/breathing_page.dart';
import '../../../breathing/presentation/widgets/breathing_orb.dart';
import '../../onboarding_storage.dart';

class _OnboardingSlide {
  final String title;
  final String body;

  const _OnboardingSlide({required this.title, required this.body});
}

const _slides = [
  _OnboardingSlide(
    title: 'Ease',
    body: 'A few slow breaths, guided. Calmer in minutes.',
  ),
  _OnboardingSlide(
    title: 'Follow the circle.',
    body:
        "Breathe in as it grows, out as it softens. That's all there is to it.",
  ),
];

/// A slow, even demo rhythm for the onboarding orb (4s in, 4s out).
final _demoPattern = BreathingPattern.classic(
  inhaleMs: 4000,
  holdAfterInhaleMs: 0,
  exhaleMs: 4000,
  holdAfterExhaleMs: 0,
);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _demoPattern.cycleDurationMs),
  );
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show the orb at mid-breath, still.
    if (MediaQuery.disableAnimationsOf(context)) {
      _demo
        ..stop()
        ..value = 0.25;
    } else if (!_demo.isAnimating) {
      _demo.repeat();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _demo.dispose();
    super.dispose();
  }

  void _finish() {
    di.sl<OnboardingStorage>().markSeen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const BreathingPage()));
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.of(context, AppMotion.calm),
        curve: AppMotion.standard,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: AppMotion.of(context, AppMotion.base),
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: EaseButton.quiet(label: 'Skip', onTap: _finish),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => Center(
                  child: ExcludeSemantics(
                    child: BreathingOrb(
                      cycle: _demo,
                      pattern: _demoPattern,
                      mode: OrbMode.follow,
                      size: (c.biggest.shortestSide - 32).clamp(140.0, 280.0),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(168),
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final slide in _slides)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      child: Column(
                        children: [
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.displayLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: theme.bodyLarge?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: 'Page ${_index + 1} of ${_slides.length}',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    return AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.base),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      width: 24,
                      height: 1,
                      color: i == _index ? AppColors.white : AppColors.disabled,
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xl,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: EaseButton.primary(
                label: isLast ? 'Begin' : 'Continue',
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
