import 'entities/streak_info.dart';

/// Pure streak math — no I/O, safe to unit test in isolation. Dates are
/// always compared as UTC calendar dates (constructed fresh from the
/// 'yyyy-MM-dd' key) purely to get exact whole-day arithmetic without local
/// DST transitions distorting a midnight-to-midnight difference — this is
/// calendar-day counting, not elapsed real-world time.
DateTime _parseKeyAsUtc(String key) {
  final parts = key.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

int daysBetweenKeys(String earlierKey, String laterKey) {
  return _parseKeyAsUtc(laterKey).difference(_parseKeyAsUtc(earlierKey)).inDays;
}

bool _isNextCalendarDay(String earlierKey, String laterKey) {
  return daysBetweenKeys(earlierKey, laterKey) == 1;
}

/// [practicedDateKeys] is a set of 'yyyy-MM-dd' local dates on which at
/// least one session was completed — using a Set (not a session count)
/// means multiple sessions on the same day collapse to a single practiced
/// day for free. [todayKey] is the caller's current local date.
StreakInfo computeStreak(Set<String> practicedDateKeys, String todayKey) {
  if (practicedDateKeys.isEmpty) {
    return StreakInfo.empty;
  }

  final sorted = practicedDateKeys.toList()..sort();
  final lastKey = sorted.last;

  // Longest ever: a pure scan of the full (immutable, only-grows) history.
  // Because it's always recomputed fresh rather than stored, it cannot
  // regress when a streak later breaks.
  var longest = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    run = _isNextCalendarDay(sorted[i - 1], sorted[i]) ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  // Current streak, anchored at "today," with a 1-day grace period: having
  // practiced yesterday (but not yet today) keeps the streak alive rather
  // than resetting it the instant midnight passes.
  final gap = daysBetweenKeys(lastKey, todayKey);
  if (gap >= 2) {
    return StreakInfo(
      current: 0,
      longest: longest,
      lastPracticedDateKey: lastKey,
      isActiveToday: false,
    );
  }

  var current = 1;
  var cursor = lastKey;
  for (var i = sorted.length - 2; i >= 0; i--) {
    if (_isNextCalendarDay(sorted[i], cursor)) {
      current += 1;
      cursor = sorted[i];
    } else {
      break;
    }
  }

  return StreakInfo(
    current: current,
    longest: longest,
    lastPracticedDateKey: lastKey,
    isActiveToday: gap == 0,
  );
}
