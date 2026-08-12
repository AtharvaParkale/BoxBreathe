import 'package:equatable/equatable.dart';

class SessionHistory extends Equatable {
  final int totalSessions;
  final int totalSeconds;

  const SessionHistory({
    required this.totalSessions,
    required this.totalSeconds,
  });

  static const empty = SessionHistory(totalSessions: 0, totalSeconds: 0);

  @override
  List<Object?> get props => [totalSessions, totalSeconds];
}
