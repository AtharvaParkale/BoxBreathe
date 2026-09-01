import 'package:equatable/equatable.dart';

import '../../domain/entities/progress_summary.dart';

class ProgressState extends Equatable {
  final bool isLoading;
  final ProgressSummary? summary;
  final DateTime displayedMonth;

  ProgressState({this.isLoading = true, this.summary, DateTime? displayedMonth})
    : displayedMonth = displayedMonth ?? DateTime.now();

  ProgressState copyWith({
    bool? isLoading,
    ProgressSummary? summary,
    DateTime? displayedMonth,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      displayedMonth: displayedMonth ?? this.displayedMonth,
    );
  }

  @override
  List<Object?> get props => [isLoading, summary, displayedMonth];
}
