import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/features/breathing/domain/entities/breathing_technique.dart';
import 'package:box_breathe/features/breathing/domain/entities/breathing_technique_catalog.dart';

void main() {
  group('BreathingTechniqueCatalog', () {
    test('every technique has a unique id', () {
      final ids = BreathingTechniqueCatalog.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every technique has a positive cycle duration', () {
      for (final technique in BreathingTechniqueCatalog.all) {
        expect(
          technique.pattern.cycleDurationMs,
          greaterThan(0),
          reason: '${technique.id} has a zero-length cycle',
        );
      }
    });

    test('recommendedDuration is always one of availableDurations', () {
      for (final technique in BreathingTechniqueCatalog.all) {
        expect(
          technique.availableDurations.contains(technique.recommendedDuration),
          isTrue,
          reason:
              '${technique.id}: recommendedDuration '
              '${technique.recommendedDuration} not in '
              '${technique.availableDurations}',
        );
      }
    });

    test('the 5 pre-existing ids are preserved (persistence compatibility)', () {
      for (final id in ['box', 'calm478', 'sleep', 'coherence', 'quickReset']) {
        expect(BreathingTechniqueCatalog.exists(id), isTrue, reason: id);
      }
    });

    test('gentlerVariantId always points at a real technique', () {
      for (final technique in BreathingTechniqueCatalog.all) {
        final variantId = technique.gentlerVariantId;
        if (variantId != null) {
          expect(
            BreathingTechniqueCatalog.exists(variantId),
            isTrue,
            reason: '${technique.id} -> missing variant $variantId',
          );
        }
      }
    });

    test('byId falls back to the default technique for an unknown id', () {
      final result = BreathingTechniqueCatalog.byId('does-not-exist');
      expect(result.id, BreathingTechniqueCatalog.defaultId);
    });

    test('visible excludes hidden variants (e.g. the 4-7-8 gentler hold)', () {
      final visibleIds = BreathingTechniqueCatalog.visible.map((t) => t.id);
      expect(visibleIds, isNot(contains('calm478Gentle')));
      expect(BreathingTechniqueCatalog.exists('calm478Gentle'), isTrue);
    });

    test('every category has at least one technique', () {
      for (final category in TechniqueCategory.values) {
        expect(
          BreathingTechniqueCatalog.byCategory(category),
          isNotEmpty,
          reason: category.name,
        );
      }
    });

    test('featuredByCategory never returns an empty list', () {
      for (final category in TechniqueCategory.values) {
        expect(
          BreathingTechniqueCatalog.featuredByCategory(category),
          isNotEmpty,
          reason: category.name,
        );
      }
    });
  });
}
