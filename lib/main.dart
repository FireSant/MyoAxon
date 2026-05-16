import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'data/models/session_model.dart';
import 'data/models/gym_exercise_model.dart';
import 'data/models/tech_exercise_model.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/axon_peak_config_model.dart';
import 'data/models/training_block_model.dart';
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

    // Habilitar persistencia offline de Firestore explícitamente
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint(
        '📦 [Main] Configurada persistencia offline de Firestore (Ilimitada)');

    // Ajustar persistencia en Web explícitamente para mayor seguridad
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint(
          '🔥 [Main] Persistencia de Firebase configurada como LOCAL (Web)');
    }

    // Initialize Hive (local database)
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(SessionModelAdapter());
    Hive.registerAdapter(GymExerciseModelAdapter());
    Hive.registerAdapter(TechExerciseModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());
    Hive.registerAdapter(TrainingBlockModelAdapter());
    Hive.registerAdapter(AxonPeakConfigModelAdapter());

    // Open Hive box for sessions
    await Hive.openBox<SessionModel>('sessions_box');
    // Open Hive box for profiles
    await Hive.openBox<UserProfileModel>('user_profiles_box');
    // Nueva caja para persistencia de Auth (separada de sesiones)
    await Hive.openBox('auth_box');
    // Open Hive box for Axon Peak config
    await Hive.openBox<AxonPeakConfigModel>('axon_peak_config_box');

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
    // 1. Obtenemos el UID actual (de Firebase o de la Bandera Hive)
    final userId = ref.watch(currentUserIdProvider);
    // 2. Revisamos el estado crudo para saber si aún estamos "buscando"
    final authState = ref.watch(authStateProvider);

    if (userId != null) {
      debugPrint('🔑 [AuthGate] Sesión activa detectada (UID: $userId)');
      return const _ProfileGate();
    }

    // Si no hay UID, decidimos si mostrar Login o cargar
    return authState.when(
      data: (_) {
        debugPrint('🔓 [AuthGate] Sin sesión confirmada -> LoginScreen');
        return const LoginScreen();
      },
      loading: () {
        debugPrint('⏳ [AuthGate] Buscando rastro de sesión...');
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, st) {
        debugPrint('❌ [AuthGate] Error en AuthState: $e');
        return const LoginScreen();
      },
    );
  }
}

/// Widget jjno para manejar el estado del perfil de forma segura
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);

    return profileState.when(
      data: (profile) => profile == null || !profile.isProfileComplete
          ? const CompleteProfileScreen()
          : const MainScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
