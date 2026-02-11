import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/breathing/presentation/bloc/breathing_bloc.dart';
import 'features/breathing/presentation/bloc/breathing_event.dart';
import 'features/breathing/presentation/pages/breathing_page.dart';
import 'injection_container.dart' as di;

import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const BoxBreatheApp());
}

class BoxBreatheApp extends StatelessWidget {
  const BoxBreatheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<BreathingBloc>()..add(LoadBreathingSettings()),
        ),
        BlocProvider(
          create: (_) => di.sl<SettingsBloc>()..add(LoadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'BoxBreathe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(state.settings.themeMode),
            home: const BreathingPage(),
          );
        },
      ),
    );
  }
}
