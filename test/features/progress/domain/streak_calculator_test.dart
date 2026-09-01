import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/features/progress/domain/streak_calculator.dart';

void main() {
  group('computeStreak', () {
    test('empty history yields a zeroed streak', () {
      final result = computeStreak({}, '2026-09-02');
      expect(result.current, 0);
      expect(result.longest, 0);
      expect(result.lastPracticedDateKey, isNull);
      expect(result.isActiveToday, isFalse);
    });

    test('a single day practiced today is a 1-day active streak', () {
      final result = computeStreak({'2026-09-02'}, '2026-09-02');
      expect(result.current, 1);
      expect(result.longest, 1);
      expect(result.isActiveToday, isTrue);
    });

    test('consecutive days accumulate the current streak', () {
      final days = {
        '2026-08-30',
        '2026-08-31',
        '2026-09-01',
        '2026-09-02',
      };
      final result = computeStreak(days, '2026-09-02');
      expect(result.current, 4);
      expect(result.longest, 4);
      expect(result.isActiveToday, isTrue);
    });

    test(
      'a 1-day gap (practiced yesterday, not yet today) keeps the streak '
      'alive but not yet active today',
      () {
        final days = {'2026-08-31', '2026-09-01'};
        final result = computeStreak(days, '2026-09-02');
        expect(result.current, 2);
        expect(result.isActiveToday, isFalse);
      },
    );

    test('a 2+ day gap resets the current streak to zero without erasing '
        'the longest streak on record', () {
      final days = {'2026-08-25', '2026-08-26', '2026-08-27'};
      final result = computeStreak(days, '2026-09-02');
      expect(result.current, 0);
      expect(result.longest, 3);
      expect(result.isActiveToday, isFalse);
    });

    test('multiple sessions collapsing to the same day count once', () {
      // Caller is expected to pass a Set of dateKeys — duplicate dateKeys
      // for the same calendar day are impossible by construction, but this
      // documents the invariant the Set-based API relies on.
      final days = {'2026-09-01', '2026-09-02'};
      final result = computeStreak(days, '2026-09-02');
      expect(result.current, 2);
    });

    test('longest never regresses across a broken streak', () {
      final days = {
        '2026-08-01',
        '2026-08-02',
        '2026-08-03',
        '2026-08-04',
        '2026-08-05', // 5-day run, then a long gap
        '2026-09-02', // isolated day, breaks current streak
      };
      final result = computeStreak(days, '2026-09-02');
      expect(result.longest, 5);
      expect(result.current, 1);
    });

    test('stable across a simulated timezone change: dateKeys are treated '
        'as opaque calendar dates, not re-derived from timestamps', () {
      // Even though these keys were hypothetically written from devices in
      // different timezones, they are compared purely as calendar dates.
      final days = {'2026-09-01', '2026-09-02'};
      final result = computeStreak(days, '2026-09-02');
      expect(result.current, 2);
      expect(result.longest, 2);
    });

    test('daysBetweenKeys is exact across a DST-affected local date range', () {
      // Regression guard: UTC-based key parsing must not be thrown off by
      // a local DST transition landing between two calendar days.
      expect(daysBetweenKeys('2026-03-07', '2026-03-08'), 1);
      expect(daysBetweenKeys('2026-11-01', '2026-11-02'), 1);
    });
  });
}
