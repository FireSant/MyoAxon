import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/session_provider.dart';
import '../../data/models/session_model.dart';
import '../../data/models/gym_exercise_model.dart';
import '../../data/models/tech_exercise_model.dart';
import '../../providers/user_profile_provider.dart';
import '../../data/models/user_profile_model.dart';
import 'nuevo_registro_screen.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;

    if (profile?.rol == 'entrenador') {
      return const _CoachAthletesView();
    } else {
      return const _AthleteHistoryView(null); // null means own history
    }
  }
}

class _CoachAthletesView extends ConsumerWidget {
  const _CoachAthletesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletesAsync = ref.watch(coachAthletesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Atletas'),
      ),
      body: athletesAsync.when(
        data: (athletes) {
          if (athletes.isEmpty) {
            return const Center(child: Text('No tienes atletas asignados.'));
          }
          return ListView.builder(
            itemCount: athletes.length,
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(athlete.nombreCompleto),
                subtitle:
                    Text('${athlete.categoria} - ${athlete.perfilDeportivo}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _AthleteSpecificHistoryScreen(athlete),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AthleteSpecificHistoryScreen extends StatelessWidget {
  final UserProfileModel athlete;
  const _AthleteSpecificHistoryScreen(this.athlete);

  @override
  Widget build(BuildContext context) {
    return _AthleteHistoryView(athlete, isSubScreen: true);
  }
}

class _AthleteHistoryView extends ConsumerWidget {
  final UserProfileModel? specificAthlete;
  final bool isSubScreen;

  const _AthleteHistoryView(this.specificAthlete, {this.isSubScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);
    final displayedSessions = specificAthlete != null
        ? sessions.where((s) => s.userId == specificAthlete!.uid).toList()
        : sessions;

    Widget body;
    if (displayedSessions.isEmpty) {
      body = const Center(
        child: Text(
          'No hay sesiones registradas aún.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      final groupedSessions = _groupSessionsByDateAndShift(displayedSessions);
      body = ListView.builder(
        itemCount: groupedSessions.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final entry = groupedSessions.entries.toList()[index];
          return _DateGroupWidget.fromMapEntry(entry);
        },
      );
    }

    if (isSubScreen) {
      return Scaffold(
        appBar: AppBar(
            title: Text('Historial: ${specificAthlete?.nombreCompleto}')),
        body: body,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Entrenamiento'),
        ),
        body: body,
      );
    }
  }

  /// Agrupa las sesiones por fecha (día) y luego por jornada
  Map<DateTime, Map<String, List<SessionModel>>> _groupSessionsByDateAndShift(
      List<SessionModel> sessions) {
    final Map<DateTime, Map<String, List<SessionModel>>> grouped = {};

    for (final session in sessions) {
      final dateKey = DateTime(
        session.fecha.year,
        session.fecha.month,
        session.fecha.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = {};
      }

      if (!grouped[dateKey]!.containsKey(session.jornada)) {
        grouped[dateKey]![session.jornada] = [];
      }

      grouped[dateKey]![session.jornada]!.add(session);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedGrouped = <DateTime, Map<String, List<SessionModel>>>{};
    for (final date in sortedDates) {
      sortedGrouped[date] = grouped[date]!;
    }

    return sortedGrouped;
  }
}

class _DateGroupWidget extends StatelessWidget {
  final DateTime date;
  final Map<String, List<SessionModel>> shifts;

  const _DateGroupWidget({
    required this.date,
    required this.shifts,
  });

  factory _DateGroupWidget.fromMapEntry(
      MapEntry<DateTime, Map<String, List<SessionModel>>> entry) {
    return _DateGroupWidget(
      date: entry.key,
      shifts: entry.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final formattedDate = dateFormat.format(date);

    // Obtener todas las sesiones ordenadas por jornada
    final sortedShifts = shifts.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // Matutina antes que Vespertina

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la fecha
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            formattedDate,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        const SizedBox(height: 8),
        // Cards de sesiones por jornada
        ...sortedShifts.map((jornada) {
          final sessionList = shifts[jornada]!;
          // Ordenar sesiones por tipo de sesión (Gimnasio antes que Técnica)
          sessionList.sort((a, b) => a.tipoSesion.compareTo(b.tipoSesion));
          return _ShiftSessionCard(
            jornada: jornada,
            sessions: sessionList,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ShiftSessionCard extends StatelessWidget {
  final String jornada;
  final List<SessionModel> sessions;

  const _ShiftSessionCard({
    required this.jornada,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar una card por cada sesión
    return Column(
      children: sessions.map((session) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getJornadaColor(jornada, context),
              child: Icon(
                _getJornadaIcon(jornada),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '$jornada - ${session.tipoSesion}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Icono de sincronización
                if (session.isSynced)
                  const Icon(
                    Icons.cloud_done,
                    size: 20,
                    color: Colors.green,
                  ),
              ],
            ),
            subtitle: Text(
              'RPE: ${session.intensidadPercibida}/10 | Fatiga: ${session.fatiguaPreentrenamiento}/5',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NuevoRegistroScreen(editingSession: session),
                  ),
                );
              },
            ),
            children: [
              ...session.ejerciciosGim.map((ej) => _buildGymExerciseItem(ej)),
              ...session.ejerciciosTech.map((ej) => _buildTechExerciseItem(ej)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getJornadaColor(String jornada, BuildContext context) {
    final theme = Theme.of(context);
    switch (jornada) {
      case 'Matutina':
        return theme.colorScheme.tertiary;
      case 'Vespertina':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getJornadaIcon(String jornada) {
    switch (jornada) {
      case 'Matutina':
        return Icons.wb_sunny;
      case 'Vespertina':
        return Icons.nights_stay;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildGymExerciseItem(GymExerciseModel exercise) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.fitness_center, size: 20),
      title: Text(exercise.nombreEjercicio),
      subtitle: Text(
        '${exercise.series} series x ${exercise.repeticiones} reps | ${exercise.pesoKg} kg | RIR: ${exercise.rir}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        'Vol: ${(exercise.pesoKg * exercise.repeticiones * exercise.series).toStringAsFixed(1)} kg',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTechExerciseItem(TechExerciseModel exercise) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.directions_run, size: 20),
      title: Text(exercise.nombreEjercicio),
      subtitle: Text(
        'Series: ${exercise.series} | ${exercise.repeticiones} reps | ${exercise.metricaPrincipal}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        'Descanso: ${exercise.descansoSegundos}s',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
