import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/session_repository.dart';
import 'auth_provider.dart';

/// Data Transfer Object for Dashboard calculations.
class ExerciseRecord {
  final String id;
  final String exerciseName;
  final double weight;
  final int repetitions;
  final DateTime timestamp;

  ExerciseRecord({
    required this.id,
    required this.exerciseName,
    required this.weight,
    required this.repetitions,
    required this.timestamp,
  });

  double get volume => weight * repetitions;
}

final exerciseRecordsProvider =
    StateNotifierProvider<ExerciseRecordsNotifier, List<ExerciseRecord>>((ref) {
  final user = ref.watch(authStateProvider).value;
  return ExerciseRecordsNotifier(userId: user?.uid ?? 'single_user');
});

class ExerciseRecordsNotifier extends StateNotifier<List<ExerciseRecord>> {
  final SessionRepository _sessionRepository = SessionRepository();
  final String _userId;

  ExerciseRecordsNotifier({required String userId})
      : _userId = userId,
        super([]) {
    _loadRecords();
  }

  void _loadRecords() {
    final sessions = _sessionRepository.getAllSessionsForUser(_userId);
    final records = <ExerciseRecord>[];

    for (final session in sessions) {
      // Convertir ejercicios de gimnasio
      for (final gymExercise in session.ejerciciosGim) {
        records.add(ExerciseRecord(
          id: '${session.idSesion}_${gymExercise.orden}',
          exerciseName: gymExercise.nombreEjercicio,
          weight: gymExercise.pesoKg,
          repetitions: gymExercise.repeticiones,
          timestamp: session.fecha,
        ));
      }

      // Convertir ejercicios de técnica
      for (final techExercise in session.ejerciciosTech) {
        records.add(ExerciseRecord(
          id: '${session.idSesion}_${techExercise.orden}',
          exerciseName: techExercise.nombreEjercicio,
          weight: techExercise.metricaPrincipal,
          repetitions: techExercise.repeticiones,
          timestamp: session.fecha,
        ));
      }
    }

    // Ordenar por fecha, más reciente primero
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = records;
  }

  // Refrescar datos (útil después de guardar una nueva sesión)
  Future<void> refresh() async {
    _loadRecords();
  }
}
