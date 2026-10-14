/// Human-readable formatting shared across screens.
library;

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "18 min", "1h", "2h 5m".
String formatMinutes(int totalMinutes) {
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

/// "October 2026".
String formatMonthYear(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

/// "today", "yesterday", "3 days ago", then "12 Sep" after a week.
String formatRelativeDay(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return '${d.day} ${_shortMonthNames[d.month - 1]}';
}

/// "9:00 AM".
String formatTimeOfDay(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')} $period';
}

/// "4", "5.5" — seconds for a phase duration given in ms.
String formatPhaseSeconds(int ms) {
  final seconds = ms / 1000;
  return seconds == seconds.roundToDouble()
      ? '${seconds.round()}'
      : seconds.toStringAsFixed(1);
}
