import 'package:flutter_test/flutter_test.dart';
import 'package:myoaxon/data/models/tech_exercise_model.dart';

void main() {
  group('TechExerciseModel', () {
    test('Debe crear ejercicio técnico con todos los campos', () {
      final exercise = TechExerciseModel(
        orden: 1,
        nombreEjercicio: '100m planos',
        series: 3,
        repeticiones: 1,
        metricaPrincipal: 100.0,
        descansoSegundos: 180,
        notasSerie: 'Viento +1.2',
      );

      expect(exercise.orden, 1);
      expect(exercise.nombreEjercicio, '100m planos');
      expect(exercise.series, 3);
      expect(exercise.repeticiones, 1);
      expect(exercise.metricaPrincipal, 100.0);
      expect(exercise.descansoSegundos, 180);
      expect(exercise.notasSerie, 'Viento +1.2');
    });

    test('Debe permitir notas vacías por defecto', () {
      final exercise = TechExerciseModel(
        orden: 1,
        nombreEjercicio: 'Salto de altura',
        series: 5,
        repeticiones: 1,
        metricaPrincipal: 1.85,
        descansoSegundos: 120,
      );

      expect(exercise.notasSerie, '');
    });

    test('Debe serializar correctamente para Firebase', () {
      final exercise = TechExerciseModel(
        orden: 2,
        nombreEjercicio: '400m',
        series: 6,
        repeticiones: 1,
        metricaPrincipal: 52.5,
        descansoSegundos: 120,
        notasSerie: 'Parciales: 13.2, 13.5, 13.1',
      );

      final firebaseMap = exercise.toFirebase();

      expect(firebaseMap['orden'], 2);
      expect(firebaseMap['nombre_ejercicio'], '400m');
      expect(firebaseMap['series'], 6);
      expect(firebaseMap['repeticiones'], 1);
      expect(firebaseMap['metrica_principal'], 52.5);
      expect(firebaseMap['descanso_segundos'], 120);
      expect(firebaseMap['notas_serie'], 'Parciales: 13.2, 13.5, 13.1');
    });

    test('Debe deserializar correctamente desde Firebase', () {
      final data = {
        'orden': 3,
        'nombre_ejercicio': '3000m',
        'series': 1,
        'repeticiones': 1,
        'metrica_principal': 540.0,
        'descanso_segundos': 0,
        'notas_serie': 'Ritmo constante',
      };

      final exercise = TechExerciseModel.fromFirebase(data);

      expect(exercise.orden, 3);
      expect(exercise.nombreEjercicio, '3000m');
      expect(exercise.series, 1);
      expect(exercise.repeticiones, 1);
      expect(exercise.metricaPrincipal, 540.0);
      expect(exercise.descansoSegundos, 0);
      expect(exercise.notasSerie, 'Ritmo constante');
    });

    test('Debe manejar valores nulos en fromFirebase', () {
      final data = {
        'orden': 1,
        'nombre_ejercicio': 'Ejercicio técnico',
      };

      final exercise = TechExerciseModel.fromFirebase(data);

      expect(exercise.orden, 1);
      expect(exercise.nombreEjercicio, 'Ejercicio técnico');
      expect(exercise.series, 0);
      expect(exercise.repeticiones, 0);
      expect(exercise.metricaPrincipal, 0.0);
      expect(exercise.descansoSegundos, 0);
      expect(exercise.notasSerie, '');
    });

    test('Debe manejar ejercicios con múltiples series', () {
      final exercise = TechExerciseModel(
        orden: 1,
        nombreEjercicio: 'Series de 200m',
        series: 8,
        repeticiones: 1,
        metricaPrincipal: 28.5,
        descansoSegundos: 90,
      );

      expect(exercise.series, 8);
      expect(exercise.metricaPrincipal, 28.5);
      expect(exercise.descansoSegundos, 90);
    });
  });
}
