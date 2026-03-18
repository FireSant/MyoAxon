import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_model.dart';

class LocalTrainingRepository {
  static const String _boxName = 'sessions_box';

  /// Returns the open Hive box for sessions.
  Box<SessionModel> get _box => Hive.box<SessionModel>(_boxName);

  /// Opens the Hive box. Call this once during app startup in main().
  static Future<void> init() async {
    await Hive.openBox<SessionModel>(_boxName);
  }

  /// Saves (or overwrites) a session using its [idSesion] as the key.
  Future<void> saveSession(SessionModel session) async {
    await _box.put(session.idSesion, session);
  }

  /// Returns all sessions ordered by date, newest first.
  List<SessionModel> getAllSessions() {
    final sessions = _box.values.toList();
    sessions.sort((a, b) => b.fecha.compareTo(a.fecha));
    return sessions;
  }
}
