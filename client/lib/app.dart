import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/auth/auth_wrapper.dart';
import 'state/ai_generation_state.dart';
import 'state/auth_state.dart';
import 'state/classroom_state.dart';
import 'state/profile_state.dart';
import 'state/resource_state.dart';
import 'state/showcase_state.dart';
import 'state/story_orchestrator_state.dart';
import 'theme/glowup_theme.dart';

class GlowUpApp extends StatelessWidget {
  const GlowUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProxyProvider<AuthState, ClassroomState>(
          create: (context) => ClassroomState(context.read<AuthState>()),
          update: (context, auth, state) {
            final classroomState = state ?? ClassroomState(auth);
            classroomState.updateAuth(auth);
            return classroomState;
          },
        ),
        ChangeNotifierProvider(create: (_) => VideoGenerationState()),
        ChangeNotifierProvider(create: (_) => ImageGenerationState()),
        ChangeNotifierProvider(create: (_) => MusicGenerationState()),
        ChangeNotifierProxyProvider<AuthState, ShowcaseState>(
          create: (context) => ShowcaseState(context.read<AuthState>()),
          update: (context, auth, state) {
            final showcaseState = state ?? ShowcaseState(auth);
            showcaseState.updateAuth(auth);
            return showcaseState;
          },
        ),
        ChangeNotifierProxyProvider2<AuthState, ClassroomState, StoryOrchestratorState>(
          create: (context) => StoryOrchestratorState(
            authState: context.read<AuthState>(),
            classroomState: context.read<ClassroomState>(),
            videoState: context.read<VideoGenerationState>(),
            musicState: context.read<MusicGenerationState>(),
          ),
          update: (context, auth, classroom, orchestrator) {
            final storyState = orchestrator ?? StoryOrchestratorState(
              authState: auth,
              classroomState: classroom,
              videoState: context.read<VideoGenerationState>(),
              musicState: context.read<MusicGenerationState>(),
            );
            storyState.attachMediaStates(
              videoState: context.read<VideoGenerationState>(),
              musicState: context.read<MusicGenerationState>(),
            );
            storyState.updateDependencies(auth: auth, classroomState: classroom);
            return storyState;
          },
        ),
        ChangeNotifierProvider(create: (_) => ResourceLibraryState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
      ],
      child: Consumer<ProfileState>(
        builder: (context, profile, _) {
          return MaterialApp(
            title: 'GlowUp',
            debugShowCheckedModeBanner: false,
            theme: GlowUpTheme.lightTheme(highContrast: profile.highContrast),
            locale: profile.locale,
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(profile.textScaleFactor)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
