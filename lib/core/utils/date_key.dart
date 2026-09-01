/// Local-calendar-date key ('yyyy-MM-dd') for a [DateTime], used to attach
/// a stable, timezone-safe practice day to a session at the moment it's
/// logged. Once written, a dateKey is treated as an opaque string forever —
/// never re-derived later from a raw timestamp using a possibly different
/// device timezone.
String dateKeyFor(DateTime local) {
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
