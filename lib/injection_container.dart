import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'core/services/notification_helper.dart';
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

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Breathing
  // Bloc
  sl.registerFactory(
    () => BreathingBloc(
      getSettings: sl(),
      saveSettings: sl(),
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
  sl.registerFactory(
    () => SettingsBloc(
      getSettings: sl(),
      saveSettings: sl(),
    ),
  );

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

  // External
  await Hive.initFlutter();
  final box = await Hive.openBox('breathing_settings');
  sl.registerLazySingleton(() => box);
}
