import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/breathing/presentation/bloc/breathing_bloc.dart';
import 'features/breathing/presentation/bloc/breathing_event.dart';
import 'features/breathing/presentation/pages/breathing_page.dart';
import 'features/onboarding/onboarding_storage.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'injection_container.dart' as di;

import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  final showOnboarding = !di.sl<OnboardingStorage>().hasSeenOnboarding();
  runApp(BoxBreatheApp(showOnboarding: showOnboarding));
}

class BoxBreatheApp extends StatelessWidget {
  final bool showOnboarding;

  const BoxBreatheApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<BreathingBloc>()..add(LoadBreathingSettings()),
        ),
        BlocProvider(create: (_) => di.sl<SettingsBloc>()..add(LoadSettings())),
      ],
      child: MaterialApp(
        title: 'Ease',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: showOnboarding ? const OnboardingPage() : const BreathingPage(),
      ),
    );
  }
}
