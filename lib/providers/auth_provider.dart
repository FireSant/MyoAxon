import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/models/session_model.dart';

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
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<User?>>(() => AuthNotifier());
