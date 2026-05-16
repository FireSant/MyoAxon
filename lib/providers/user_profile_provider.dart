import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/user_profile_repository.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel?>> {
  final UserProfileRepository repository;

  UserProfileNotifier(this.repository) : super(const AsyncValue.loading());

  Future<void> loadProfile(String uid) async {
    state = const AsyncValue.loading();
    debugPrint('🔍 [UserProfileNotifier] Intentando cargar perfil para: $uid');
    try {
      // Intentar cargar localmente
      var profile = repository.getProfile(uid);
      if (profile != null) {
        debugPrint(
            '📦 [UserProfileNotifier] Perfil encontrado en Hive: ${profile.nombreCompleto}');
      } else {
        debugPrint(
            '☁️ [UserProfileNotifier] Perfil NO en Hive. Intentando Firebase...');
        profile = await repository.fetchProfileFromFirebase(uid);
        if (profile != null) {
          debugPrint(
              '☁️ [UserProfileNotifier] Perfil recuperado de Firebase con éxito.');
        } else {
          debugPrint(
              '⚠️ [UserProfileNotifier] No se encontró perfil ni en Hive ni en Firebase.');
        }
      }

      state = AsyncValue.data(profile);
    } catch (e, st) {
      debugPrint('❌ [UserProfileNotifier] Error fatal cargando perfil: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveAndSyncProfile(UserProfileModel profile) async {
    // Guardar localmente primero (actualiza la UI rápido)
    await repository.saveProfile(profile);
    state = AsyncValue.data(profile);

    // Intentar subir a Firebase
    try {
      await repository.syncProfileToFirebase(profile);
    } catch (e) {
      // Si falla, se queda guardado localmente (isSynced = false) pero la UI ya lo muestra
    }
  }

  Future<void> clearProfile({String? uid}) async {
    await repository.clearProfile(uid: uid);
    state = const AsyncValue.data(null);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfileModel?>>(
        (ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final notifier = UserProfileNotifier(repository);

  // Escuchar cambios en el UID (Doble Persistencia)
  ref.listen(
    currentUserIdProvider,
    (previous, userId) {
      if (userId != null) {
        debugPrint('👤 [UserProfileProvider] UID detectado: $userId');
        notifier.loadProfile(userId);
        // Sincronización en segundo plano
        Future.microtask(
            () => ref.read(sessionListProvider.notifier).syncPending());
        Future.microtask(
            () => ref.read(sessionListProvider.notifier).pullFromFirebase());
      } else {
        debugPrint(
            '🚪 [UserProfileProvider] UID es null -> Limpiando perfil local');
        notifier.clearProfile(uid: previous);
      }
    },
    fireImmediately: true,
  );

  return notifier;
});

// Provider para obtener los atletas de un entrenador
final coachAthletesProvider =
    FutureProvider<List<UserProfileModel>>((ref) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  final profile = ref.watch(userProfileProvider).value;

  if (profile != null && profile.rol == 'entrenador') {
    return await repo.getAthletesForCoach(profile.uid);
  }
  return [];
});
