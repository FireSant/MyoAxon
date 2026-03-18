import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/session_model.dart';
import '../data/repositories/session_repository.dart';
import 'auth_provider.dart';

// Provide the repository instance
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// State: the list of sessions specific to the current user
final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, List<SessionModel>>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  final auth = ref.watch(authStateProvider).value;
  return SessionListNotifier(repo, auth?.uid);
});

class SessionListNotifier extends StateNotifier<List<SessionModel>> {
  final SessionRepository _repository;
  final String? _userId;

  SessionListNotifier(this._repository, this._userId) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllSessionsForUser(_userId);
  }

  Future<void> addSession(SessionModel session) async {
    await _repository.saveSession(session); // 1. Hive (always)
    _load();
    // 2. Try Firebase immediately (fire-and-forget)
    unawaited(_repository.syncSessionToFirebase(session));
  }

  Future<void> updateSession(SessionModel session) async {
    await _repository.updateSession(session);
    _load();
  }

  Future<void> deleteSession(String idSesion) async {
    await _repository.deleteSession(idSesion);
    _load();
  }

  Future<void> markSynced(String idSesion) async {
    await _repository.markSynced(idSesion);
    _load();
  }

  // Refresh the session list from Hive
  Future<void> refresh() async {
    _load();
  }

  // Get all unsynced sessions for user
  List<SessionModel> get unsyncedSessions =>
      _userId != null ? _repository.getUnsyncedSessionsForUser(_userId) : [];

  /// Retries uploading every session that was saved offline.
  /// Call on app start or when connectivity returns.
  Future<void> syncPending() async {
    if (_userId == null) return;
    await _repository.syncAllPendingToFirebase(_userId);
    _load(); // refresh isSynced flags in UI
  }
}
