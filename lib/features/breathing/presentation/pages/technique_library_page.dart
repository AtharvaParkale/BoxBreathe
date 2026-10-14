import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ease_page.dart';
import '../../../../core/widgets/ease_sheet.dart';
import '../../../../core/widgets/lists.dart';
import '../../../../core/widgets/text_segmented.dart';
import '../../../../injection_container.dart' as di;
import '../../../progress/domain/entities/progress_session_record.dart';
import '../../../progress/domain/usecases/get_recent_sessions.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../widgets/technique_row.dart';
import 'technique_detail_page.dart';

/// Short labels for the need filter — the full [TechniqueCategoryLabel]
/// phrasing is used in the "Not sure?" sheet where there's room.
extension on TechniqueCategory {
  String get filterLabel => switch (this) {
    TechniqueCategory.calm => 'Calm',
    TechniqueCategory.focus => 'Focus',
    TechniqueCategory.sleep => 'Sleep',
    TechniqueCategory.energize => 'Awake',
    TechniqueCategory.overwhelmed => 'Overwhelmed',
  };
}

/// Pops with `true` when the user chose to begin a session (directly or
/// via a detail page), so the home screen can start immediately.
class TechniqueLibraryPage extends StatefulWidget {
  const TechniqueLibraryPage({super.key});

  @override
  State<TechniqueLibraryPage> createState() => _TechniqueLibraryPageState();
}

class _TechniqueLibraryPageState extends State<TechniqueLibraryPage> {
  /// `null` = all techniques.
  TechniqueCategory? _filter;

  late final Future<List<ProgressSessionRecord>> _recentSessionsFuture = di
      .sl<GetRecentSessions>()(limit: 10)
      .then(
        (result) =>
            result.fold((_) => const <ProgressSessionRecord>[], (s) => s),
      );

  @override
  Widget build(BuildContext context) {
    final hapticsEnabled = context.select(
      (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
    );
    final favoriteIds = context.select(
      (SettingsBloc bloc) => bloc.state.settings.favoriteTechniqueIds,
    );
    final favorites = favoriteIds
        .where(BreathingTechniqueCatalog.exists)
        .map(BreathingTechniqueCatalog.byId)
        .toList();
    final listed = _filter == null
        ? BreathingTechniqueCatalog.visible
        : BreathingTechniqueCatalog.byCategory(_filter!);

    return EasePage(
      title: 'Techniques',
      slivers: [
        GutterSliver(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              ListRow(
                title: 'Not sure what you need?',
                subtitle: "Say how you feel and we'll start the right one.",
                hapticsEnabled: hapticsEnabled,
                onTap: () => _showFeelingPicker(hapticsEnabled),
              ),
              const Divider(),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: TextSegmented<TechniqueCategory?>(
              scrollable: true,
              hapticsEnabled: hapticsEnabled,
              selected: _filter,
              onSelect: (c) => setState(() => _filter = c),
              options: [
                (null, 'All'),
                for (final c in TechniqueCategory.values) (c, c.filterLabel),
              ],
            ),
          ),
        ),
        if (_filter == null && favorites.isNotEmpty)
          GutterSliver(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Favorites'),
                HairlineList(children: _rowsFor(favorites, hapticsEnabled)),
              ],
            ),
          ),
        if (_filter == null)
          GutterSliver(
            child: FutureBuilder<List<ProgressSessionRecord>>(
              future: _recentSessionsFuture,
              builder: (context, snapshot) {
                final recent = _distinctRecent(snapshot.data ?? const []);
                if (recent.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionLabel('Recently'),
                    HairlineList(
                      children: [
                        for (final record in recent)
                          ListRow(
                            title: _displayNameFor(record),
                            value: formatRelativeDay(record.completedAt),
                            hapticsEnabled: hapticsEnabled,
                            onTap:
                                BreathingTechniqueCatalog.exists(
                                  record.techniqueId,
                                )
                                ? () => _openDetail(
                                    BreathingTechniqueCatalog.byId(
                                      record.techniqueId,
                                    ),
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        GutterSliver(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel(_filter == null ? 'All techniques' : _filter!.label),
              HairlineList(
                children: _rowsFor(
                  listed,
                  hapticsEnabled,
                  reason: _filter?.name,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ProgressSessionRecord> _distinctRecent(
    List<ProgressSessionRecord> records,
  ) {
    final seen = <String>{};
    final distinct = <ProgressSessionRecord>[];
    for (final r in records) {
      if (seen.add(r.techniqueId)) distinct.add(r);
      if (distinct.length == 3) break;
    }
    return distinct;
  }

  String _displayNameFor(ProgressSessionRecord record) {
    return BreathingTechniqueCatalog.exists(record.techniqueId)
        ? BreathingTechniqueCatalog.byId(record.techniqueId).name
        : record.techniqueName;
  }

  List<Widget> _rowsFor(
    List<BreathingTechnique> techniques,
    bool hapticsEnabled, {
    String? reason,
  }) {
    return [
      for (final technique in techniques)
        TechniqueRow(
          technique: technique,
          hapticsEnabled: hapticsEnabled,
          onTap: () => _openDetail(technique, reason: reason),
        ),
    ];
  }

  Future<void> _openDetail(
    BreathingTechnique technique, {
    String? reason,
  }) async {
    final start = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TechniqueDetailPage(technique: technique, reason: reason),
      ),
    );
    if (start == true && mounted) Navigator.pop(context, true);
  }

  void _showFeelingPicker(bool hapticsEnabled) {
    showEaseSheet<void>(
      context: context,
      title: 'How are you feeling?',
      builder: (sheetContext) => HairlineList(
        children: [
          for (final category in TechniqueCategory.values)
            ListRow(
              title: category.label,
              hapticsEnabled: hapticsEnabled,
              onTap: () {
                Navigator.pop(sheetContext);
                _startFromCategory(category);
              },
            ),
        ],
      ),
    );
  }

  void _startFromCategory(TechniqueCategory category) {
    final technique = BreathingTechniqueCatalog.featuredByCategory(
      category,
    ).first;
    context.read<BreathingBloc>().add(
      ChangeTechnique(technique.id, reason: category.name),
    );
    context.read<BreathingBloc>().add(
      ChangeSessionDuration(technique.recommendedDuration),
    );
    Navigator.pop(context, true);
  }
}
