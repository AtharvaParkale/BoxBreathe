import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/id_generator.dart';
import 'core/services/notification_helper.dart';
import 'core/services/sound_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/delete_account.dart';
import 'features/auth/domain/usecases/link_anonymous_with_google.dart';
import 'features/auth/domain/usecases/sign_in_anonymously.dart';
import 'features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email_password.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/settings/data/datasources/settings_local_data_source.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/save_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/breathing/data/datasources/breathing_local_data_source.dart';
import 'features/breathing/data/repositories/breathing_repository_impl.dart';
import 'features/breathing/domain/repositories/breathing_repository.dart';
import 'features/breathing/domain/usecases/get_breathing_settings.dart';
import 'features/breathing/domain/usecases/save_breathing_settings.dart';
import 'features/breathing/presentation/bloc/breathing_bloc.dart';
import 'features/history/data/datasources/history_local_data_source.dart';
import 'features/history/data/datasources/history_remote_data_source.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/domain/repositories/history_repository.dart';
import 'features/history/domain/usecases/get_history.dart';
import 'features/history/domain/usecases/get_sessions_since.dart';
import 'features/history/domain/usecases/log_completed_session.dart';
import 'features/history/domain/usecases/log_remote_session.dart';
import 'features/onboarding/onboarding_storage.dart';
import 'features/progress/data/datasources/progress_local_data_source.dart';
import 'features/progress/data/repositories/progress_repository_impl.dart';
import 'features/progress/domain/repositories/progress_repository.dart';
import 'features/progress/domain/usecases/get_post_session_reward.dart';
import 'features/progress/domain/usecases/get_progress_summary.dart';
import 'features/progress/domain/usecases/get_recent_sessions.dart';
import 'features/progress/domain/usecases/log_progress_session.dart';
import 'features/progress/domain/usecases/sync_progress.dart';
import 'features/progress/presentation/bloc/progress_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External - Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Core
  sl.registerLazySingleton<IdGenerator>(() => FirestoreIdGenerator(sl()));

  // Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      authRepository: sl(),
      signInAnonymously: sl(),
      signInWithGoogle: sl(),
      signInWithEmailPassword: sl(),
      signUpWithEmailPassword: sl(),
      linkAnonymousWithGoogle: sl(),
      signOut: sl(),
      deleteAccount: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithEmailPassword(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailPassword(sl()));
  sl.registerLazySingleton(() => LinkAnonymousWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: sl(),
      userProfileRemoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileFirestoreDataSourceImpl(firestore: sl()),
  );

  // Features - Breathing
  // Bloc
  sl.registerFactory(
    () => BreathingBloc(
      getSettings: sl(),
      saveSettings: sl(),
      logCompletedSession: sl(),
      logRemoteSession: sl(),
      logProgressSession: sl(),
      getPostSessionReward: sl(),
      idGenerator: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetBreathingSettings(sl()));
  sl.registerLazySingleton(() => SaveBreathingSettings(sl()));

  // Repository
  sl.registerLazySingleton<BreathingRepository>(
    () => BreathingRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<BreathingLocalDataSource>(
    () => BreathingLocalDataSourceImpl(sl()),
  );

  // Features - Settings
  // Bloc
  sl.registerFactory(() => SettingsBloc(getSettings: sl(), saveSettings: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => SaveSettings(sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sl()),
  );

  // Core
  await NotificationHelper.init();
  // Eagerly register and kick off audio pre-loading immediately at app start
  final soundService = SoundService();
  sl.registerSingleton<SoundService>(soundService);

  // External
  await Hive.initFlutter();
  final box = await Hive.openBox('breathing_settings');
  sl.registerLazySingleton(() => box);

  // Features - Onboarding (first-launch flag only, reuses the shared box)
  sl.registerLazySingleton(() => OnboardingStorage(box));

  // Features - History
  // Use cases
  sl.registerLazySingleton(() => GetHistory(sl()));
  sl.registerLazySingleton(() => LogCompletedSession(sl()));
  sl.registerLazySingleton(() => LogRemoteSession(sl()));

  // Repository
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      authRepository: sl(),
    ),
  );

  // Data sources (own box — an accumulating log/counter, not a settings
  // record, so it doesn't share the settings box)
  final historyBox = await Hive.openBox('session_history');
  sl.registerLazySingleton<HistoryLocalDataSource>(
    () => HistoryLocalDataSourceImpl(historyBox),
  );
  sl.registerLazySingleton<HistoryRemoteDataSource>(
    () => FirestoreHistoryRemoteDataSourceImpl(firestore: sl()),
  );

  // Cross-feature: reads this user's remote session history for Progress
  // sync (write path already registered above via LogRemoteSession).
  sl.registerLazySingleton(() => GetSessionsSince(sl()));

  // Features - Progress
  // Bloc (page-scoped in practice — ProgressPage creates its own instance
  // via sl(), it is not added to main.dart's app-lifetime MultiBlocProvider)
  sl.registerFactory(
    () => ProgressBloc(getSummary: sl(), syncProgress: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LogProgressSession(sl()));
  sl.registerLazySingleton(() => GetProgressSummary(sl()));
  sl.registerLazySingleton(() => SyncProgress(sl()));
  sl.registerLazySingleton(() => GetPostSessionReward(sl()));
  sl.registerLazySingleton(() => GetRecentSessions(sl()));

  // Repository
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      localDataSource: sl(),
      getSessionsSince: sl(),
      authRepository: sl(),
    ),
  );

  // Data sources (own boxes — see progress_local_data_source.dart for why
  // sessions are one-key-per-record rather than a single mega-list key)
  final progressSessionsBox = await Hive.openBox('progress_sessions');
  final progressAchievementsBox = await Hive.openBox('progress_achievements');
  final progressMetaBox = await Hive.openBox('progress_meta');
  sl.registerLazySingleton<ProgressLocalDataSource>(
    () => ProgressLocalDataSourceImpl(
      sessionsBox: progressSessionsBox,
      achievementsBox: progressAchievementsBox,
      metaBox: progressMetaBox,
    ),
  );
}
