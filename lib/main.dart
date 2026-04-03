import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'data/models/session_model.dart';
import 'data/models/gym_exercise_model.dart';
import 'data/models/tech_exercise_model.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/axon_analysis_model.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/complete_profile_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/theme_provider.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Hive (local database)
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(SessionModelAdapter());
    Hive.registerAdapter(GymExerciseModelAdapter());
    Hive.registerAdapter(TechExerciseModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());
    Hive.registerAdapter(AxonAnalysisModelAdapter());

    // Open Hive box for sessions
    await Hive.openBox<SessionModel>('sessions_box');
    // Open Hive box for profiles
    await Hive.openBox<UserProfileModel>('user_profiles_box');
    // Open Hive box for Laboratorio Axon
    await Hive.openBox<AxonAnalysisModel>('axon_analysis_box');

    // Configuración de UI del sistema (Barra transparente y orientación)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent, // Barra transparente para look "Clean"
    ));
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    initError = e.toString();
    debugPrint('INITIALIZATION ERROR: $e');
  }

  runApp(
    ProviderScope(
      child: TrainingApp(error: initError),
    ),
  );
}

class TrainingApp extends ConsumerWidget {
  final String? error;
  const TrainingApp({super.key, this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    if (error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Critical Init Error:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'MyoAxon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

/// Gate de autenticación: muestra LoginScreen, CompleteProfileScreen o MainScreen según el estado
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (User? user) {
        if (user != null) {
          // Usuario logueado: delegamos a un widget hijo para verificar perfil
          return const _ProfileGate();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}

/// Widget interno para manejar el estado del perfil de forma segura
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ahora ref.watch está en el nivel superior del build, como debe ser
    final profileState = ref.watch(userProfileProvider);

    return profileState.when(
      data: (UserProfileModel? profile) {
        if (profile == null) {
          return const CompleteProfileScreen();
        }
        return const MainScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}
