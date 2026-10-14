import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:box_breathe/core/services/breathing_audio_handler.dart';
import 'package:box_breathe/core/services/sound_service.dart';
import 'package:box_breathe/core/theme/app_theme.dart';
import 'package:box_breathe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:box_breathe/features/auth/presentation/bloc/auth_event.dart';
import 'package:box_breathe/features/auth/presentation/bloc/auth_state.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_bloc.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_event.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/progress/domain/entities/progress_session_record.dart';
import 'package:box_breathe/features/progress/domain/usecases/get_recent_sessions.dart';
import 'package:box_breathe/features/progress/presentation/bloc/progress_bloc.dart';
import 'package:box_breathe/features/progress/presentation/bloc/progress_event.dart';
import 'package:box_breathe/features/progress/presentation/bloc/progress_state.dart';
import 'package:box_breathe/features/settings/domain/entities/settings.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_event_state.dart';
import 'package:box_breathe/injection_container.dart' as di;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBreathingBloc extends MockBloc<BreathingEvent, BreathingState>
    implements BreathingBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProgressBloc extends MockBloc<ProgressEvent, ProgressState>
    implements ProgressBloc {}

class MockAudioHandler extends Mock implements BreathingAudioHandler {}

class MockSoundService extends Mock implements SoundService {}

class MockGetRecentSessions extends Mock implements GetRecentSessions {}

class _FakeBreathingEvent extends Fake implements BreathingEvent {}

class _FakeSettingsEvent extends Fake implements SettingsEvent {}

/// Settings with cues/haptics off so tests don't reach platform services.
const quietSettings = Settings(isSoundEnabled: false, isHapticEnabled: false);

void registerUiFallbacks() {
  registerFallbackValue(_FakeBreathingEvent());
  registerFallbackValue(_FakeSettingsEvent());
}

/// Swaps the service locator for fakes and stubs the wakelock channel.
Future<void> installFakeServices({
  List<ProgressSessionRecord> recent = const [],
  ProgressBloc Function()? progressBloc,
}) async {
  await di.sl.reset();
  final audio = MockAudioHandler();
  when(() => audio.onInterruption).thenAnswer((_) => const Stream.empty());
  when(() => audio.endSession()).thenAnswer((_) async {});
  di.sl.registerSingleton<BreathingAudioHandler>(audio);

  final sound = MockSoundService();
  when(() => sound.playPhaseSound(any())).thenAnswer((_) async {});
  di.sl.registerSingleton<SoundService>(sound);

  final getRecent = MockGetRecentSessions();
  when(
    () => getRecent(limit: any(named: 'limit')),
  ).thenAnswer((_) async => Right(recent));
  di.sl.registerSingleton<GetRecentSessions>(getRecent);

  if (progressBloc != null) di.sl.registerFactory<ProgressBloc>(progressBloc);

  TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
      .setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
}

/// Wraps [child] in the app theme and the three app-level blocs.
Widget wrapWithApp(
  Widget child, {
  required BreathingBloc breathing,
  required SettingsBloc settings,
  AuthBloc? auth,
}) {
  final authBloc =
      auth ??
      (MockAuthBloc()
        ..stubState(const AuthState(status: AuthStatus.anonymous)));
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<BreathingBloc>.value(value: breathing),
      BlocProvider<SettingsBloc>.value(value: settings),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

extension StubState<E, S> on MockBloc<E, S> {
  /// Fixes the bloc at [state] with no further emissions.
  void stubState(S state) =>
      whenListen<S>(this, Stream<S>.empty(), initialState: state);

  /// Starts at [initial] and lets the test push later states.
  StreamController<S> stubStream(S initial) {
    final controller = StreamController<S>.broadcast();
    whenListen<S>(this, controller.stream, initialState: initial);
    return controller;
  }
}
