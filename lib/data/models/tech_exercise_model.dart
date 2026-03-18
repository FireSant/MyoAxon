import 'package:hive/hive.dart';

part 'tech_exercise_model.g.dart';

@HiveType(typeId: 2)
class TechExerciseModel extends HiveObject {
  @HiveField(0)
  int orden;

  @HiveField(1)
  String nombreEjercicio;

  @HiveField(2)
  int series;

  @HiveField(3)
  int repeticiones;

  @HiveField(4)
  double metricaPrincipal;

  @HiveField(5)
  int descansoSegundos;

  @HiveField(6)
  String notasSerie;

  TechExerciseModel({
    required this.orden,
    required this.nombreEjercicio,
    required this.series,
    required this.repeticiones,
    required this.metricaPrincipal,
    required this.descansoSegundos,
    this.notasSerie = '',
  });

  Map<String, dynamic> toFirebase() {
    return {
      'orden': orden,
      'nombre_ejercicio': nombreEjercicio,
      'series': series,
      'repeticiones': repeticiones,
      'metrica_principal': metricaPrincipal,
      'descanso_segundos': descansoSegundos,
      'notas_serie': notasSerie,
    };
  }

  factory TechExerciseModel.fromFirebase(Map<String, dynamic> data) {
    return TechExerciseModel(
      orden: data['orden'] ?? 0,
      nombreEjercicio: data['nombre_ejercicio'] ?? '',
      series: data['series'] ?? 0,
      repeticiones: data['repeticiones'] ?? 0,
      metricaPrincipal: (data['metrica_principal'] ?? 0).toDouble(),
      descansoSegundos: data['descanso_segundos'] ?? 0,
      notasSerie: data['notas_serie'] ?? '',
    );
  }
}
