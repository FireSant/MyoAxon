import 'package:hive/hive.dart';

part 'gym_exercise_model.g.dart';

@HiveType(typeId: 1)
class GymExerciseModel extends HiveObject {
  @HiveField(0)
  int orden;

  @HiveField(1)
  String nombreEjercicio;

  @HiveField(2)
  int series;

  @HiveField(3)
  int repeticiones;

  @HiveField(4)
  double pesoKg;

  @HiveField(5)
  int rir;

  @HiveField(6)
  int descansoSegundos;

  @HiveField(7)
  String notas;

  GymExerciseModel({
    required this.orden,
    required this.nombreEjercicio,
    required this.series,
    required this.repeticiones,
    required this.pesoKg,
    required this.rir,
    required this.descansoSegundos,
    this.notas = '',
  });

  Map<String, dynamic> toFirebase() {
    return {
      'orden': orden,
      'nombre_ejercicio': nombreEjercicio,
      'series': series,
      'repeticiones': repeticiones,
      'peso_kg': pesoKg,
      'rir': rir,
      'descanso_segundos': descansoSegundos,
      'notas': notas,
    };
  }

  factory GymExerciseModel.fromFirebase(Map<String, dynamic> data) {
    return GymExerciseModel(
      orden: data['orden'] ?? 0,
      nombreEjercicio: data['nombre_ejercicio'] ?? '',
      series: data['series'] ?? 0,
      repeticiones: data['repeticiones'] ?? 0,
      pesoKg: (data['peso_kg'] ?? 0).toDouble(),
      rir: data['rir'] ?? 0,
      descansoSegundos: data['descanso_segundos'] ?? 0,
      notas: data['notas'] ?? '',
    );
  }
}
