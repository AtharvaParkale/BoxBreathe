import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// Shared layout for every secondary screen: a back control, a large
/// left-aligned serif title that hands off to a small centred title (and a
/// hairline) once it scrolls away, gutter-padded content, and an optional
/// pinned bottom action.
class EasePage extends StatefulWidget {
  final String title;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Widget? bottomBar;

  const EasePage({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.bottomBar,
  });

  @override
  State<EasePage> createState() => _EasePageState();
}

class _EasePageState extends State<EasePage> {
  final _controller = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final collapsed = _controller.offset > 40;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.base);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: AnimatedOpacity(
          opacity: _collapsed ? 1 : 0,
          duration: duration,
          child: ExcludeSemantics(child: Text(widget.title)),
        ),
        actions: [
          ...widget.actions,
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: AnimatedOpacity(
            opacity: _collapsed ? 1 : 0,
            duration: duration,
            child: const ColoredBox(
              color: AppColors.hairline,
              child: SizedBox(height: 1, width: double.infinity),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomBar,
      body: CustomScrollView(
        controller: _controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ),
          ...widget.slivers,
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps box content in gutter padding as a sliver.
class GutterSliver extends StatelessWidget {
  final Widget child;

  const GutterSliver({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}

/// Pinned bottom action area (above the home indicator) with a hairline.
class BottomActionBar extends StatelessWidget {
  final Widget child;

  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}
