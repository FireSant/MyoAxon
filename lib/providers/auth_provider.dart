import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../data/models/session_model.dart';
import '../data/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';

// Stream del estado de autenticación
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider centralizado para obtener el UID actual (Doble Persistencia)
/// Combina Firebase Auth con la bandera local de Hive para un arranque instantáneo.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user != null) return user.uid;

  // Si está cargando o es null, intentamos recuperar el UID de la bandera local
  try {
    final authBox = Hive.box('auth_box');
    final savedUid = authBox.get('current_uid');
    if (savedUid != null) {
      debugPrint(
          '🛡️ [currentUserIdProvider] UID rescatado de auth_box: $savedUid');
      return savedUid as String;
    }
  } catch (_) {
    // Si la caja no está abierta o hay error
  }

  return null;
});

// Notifier para acciones de autenticación
class AuthNotifier extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.loading();
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Doble Persistencia: Guardar UID en caja dedicada
      await Hive.box('auth_box').put('current_uid', credential.user!.uid);

      // Limpieza de bandera vieja (solo por migración)
      await Hive.box<SessionModel>('sessions_box')
          .delete('auth_persistent_flag');

      state = AsyncValue.data(credential.user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Doble Persistencia: Guardar UID en caja dedicada
      await Hive.box('auth_box').put('current_uid', credential.user!.uid);

      // Crear perfil de usuario con código de vinculación (solo para atletas por defecto)
      final uid = credential.user!.uid;
      final linkCode = const Uuid().v4().substring(0, 6).toUpperCase();
      final profile = UserProfileModel(
        uid: uid,
        nombreCompleto: '',
        fechaNacimiento: DateTime.now(),
        sexo: '',
        perfilDeportivo: '',
        mejorMarca: '',
        fechaMejorMarca: DateTime.now(),
        competenciaObjetivo: '',
        categoria: '',
        rol: 'atleta',
        coachId: '',
        nombreCoach: '',
        especialidadCoach: '',
        institucionCoach: '',
        redSocialCoach: null,
        linkCode: linkCode,
        isSynced: false,
      );
      // Guardar en Hive usando el repositorio de perfiles
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.saveProfile(profile);

      // Limpieza de bandera vieja
      await Hive.box<SessionModel>('sessions_box')
          .delete('auth_persistent_flag');

      state = AsyncValue.data(credential.user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Borrar persistencia local
    await Hive.box('auth_box').delete('current_uid');
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }

  /// Envía un correo de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 [Auth] Enviando correo de restablecimiento a: $email');
      
      // Firebase envía el correo independientemente de si el email existe o no (por seguridad)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      
      debugPrint('✅ [Auth] Solicitud de restablecimiento procesada para: $email');
    } catch (e) {
      debugPrint('❌ [Auth] Error al enviar correo: $e');
      // No lanzamos error para evitar revelar si el email existe o no
      // Firebase maneja la seguridad por defecto
      throw 'Error al enviar el correo. Verifica tu conexión e intenta nuevamente.';
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<User?>>(() => AuthNotifier());
