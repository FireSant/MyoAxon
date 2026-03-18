import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_model.dart';

class SessionRepository {
  static const String _boxName = 'sessions_box';

  Box<SessionModel> get _box => Hive.box<SessionModel>(_boxName);

  // Save a new session to local database
  Future<void> saveSession(SessionModel session) async {
    await _box.put(session.idSesion, session);
  }

  // Get all sessions for a specific user (multi-user isolation)
  List<SessionModel> getAllSessionsForUser(String? userId) {
    if (userId == null) {
      return [];
    }
    final sessions = _box.values.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return sessions;
  }

  // Get only sessions pending Firebase sync for a specific user
  List<SessionModel> getUnsyncedSessionsForUser(String userId) {
    return _box.values.where((s) => !s.isSynced && s.userId == userId).toList();
  }

  // Get only sessions pending Firebase sync (all users - for admin/debug)
  List<SessionModel> getUnsyncedSessions() {
    return _box.values.where((s) => !s.isSynced).toList();
  }

  // Mark a session as synced after Firebase upload
  Future<void> markSynced(String idSesion) async {
    final session = _box.get(idSesion);
    if (session != null) {
      session.isSynced = true;
      await session.save();
    }
  }

  // Delete a session by id
  Future<void> deleteSession(String idSesion) async {
    await _box.delete(idSesion);
  }

  // Update an existing session
  Future<void> updateSession(SessionModel session) async {
    await _box.put(session.idSesion, session);
  }

  // Get all sessions (single-user mode - no filtering)
  List<SessionModel> getAllSessions() {
    final sessions = _box.values.toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return sessions;
  }

  // ── Firebase sync ────────────────────────────────────────────────────────────

  /// Uploads a single session to Firestore and marks it synced in Hive.
  /// Returns true if successful, false if offline/error.
  Future<bool> syncSessionToFirebase(SessionModel session) async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.idSesion)
          .set(session.toFirebase());
      await markSynced(session.idSesion);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to upload every locally-stored session that has not yet synced.
  /// Call this on app startup or when connectivity is restored.
  Future<void> syncAllPendingToFirebase(String userId) async {
    final pending = getUnsyncedSessionsForUser(userId);
    for (final session in pending) {
      await syncSessionToFirebase(session);
    }
  }
}
