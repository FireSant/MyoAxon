import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/session_model.dart';
import 'data/models/gym_exercise_model.dart';
import 'data/models/tech_exercise_model.dart';
import 'data/models/user_profile_model.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/complete_profile_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive (local database)
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SessionModelAdapter());
  Hive.registerAdapter(GymExerciseModelAdapter());
  Hive.registerAdapter(TechExerciseModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());

  // Open Hive box for sessions
  await Hive.openBox<SessionModel>('sessions_box');
  // Open Hive box for profiles
  await Hive.openBox<UserProfileModel>('user_profiles_box');

  runApp(
    const ProviderScope(
      child: TrainingApp(),
    ),
  );
}

class TrainingApp extends ConsumerWidget {
  const TrainingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MyoAxon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
          // Si el usuario está logueado, verificamos su perfil
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
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}
