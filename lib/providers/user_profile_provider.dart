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
    try {
      // Intentar cargar localmente
      var profile = repository.getProfile(uid);

      // Si no existe localmente, intentar descargar de Firebase
      profile ??= await repository.fetchProfileFromFirebase(uid);

      state = AsyncValue.data(profile);
    } catch (e, st) {
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

  Future<void> clearProfile() async {
    await repository.clearProfile();
    state = const AsyncValue.data(null);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfileModel?>>(
        (ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final notifier = UserProfileNotifier(repository);

  // Escuchar cambios en auth
  ref.listen(
    authStateProvider,
    (previous, next) {
      // next is AsyncValue<User?>
      final user = next.value;
      if (user != null) {
        notifier.loadProfile(user.uid);
        // Retry syncing any sessions that were saved offline
        Future.microtask(
            () => ref.read(sessionListProvider.notifier).syncPending());
      } else {
        notifier.clearProfile();
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
