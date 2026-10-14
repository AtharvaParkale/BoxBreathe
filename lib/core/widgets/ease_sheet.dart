import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The single bottom-sheet presentation: handle, serif title, gutter
/// padding, scrollable body, safe-area aware.
Future<T?> showEaseSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.md,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(child: builder(sheetContext)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Trailing tick for the selected option in a sheet list.
class SelectedMark extends StatelessWidget {
  final bool selected;

  const SelectedMark({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: selected
          ? const Icon(Icons.check_rounded, size: 20, color: AppColors.white)
          : null,
    );
  }
}
