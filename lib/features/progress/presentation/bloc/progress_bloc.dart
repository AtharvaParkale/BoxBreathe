import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_progress_summary.dart';
import '../../domain/usecases/sync_progress.dart';
import 'progress_event.dart';
import 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final GetProgressSummary getSummary;
  final SyncProgress syncProgress;

  ProgressBloc({required this.getSummary, required this.syncProgress})
    : super(ProgressState()) {
    on<LoadProgress>(_onLoad);
    on<ChangeDisplayedMonth>(_onChangeMonth);
  }

  Future<void> _onLoad(LoadProgress event, Emitter<ProgressState> emit) async {
    // Fast local numbers first — no network dependency, no spinner delay.
    final local = await getSummary(forMonth: state.displayedMonth);
    local.fold((_) => null, (summary) {
      emit(state.copyWith(isLoading: false, summary: summary));
    });

    // Then silently sync from remote and refresh if anything new landed.
    final syncResult = await syncProgress();
    final mergedAny = syncResult.fold((_) => false, (count) => count > 0);
    if (mergedAny) {
      final refreshed = await getSummary(forMonth: state.displayedMonth);
      refreshed.fold((_) => null, (summary) {
        emit(state.copyWith(summary: summary));
      });
    }
  }

  Future<void> _onChangeMonth(
    ChangeDisplayedMonth event,
    Emitter<ProgressState> emit,
  ) async {
    emit(state.copyWith(displayedMonth: event.month));
    final result = await getSummary(forMonth: event.month);
    result.fold((_) => null, (summary) {
      emit(state.copyWith(summary: summary));
    });
  }
}
