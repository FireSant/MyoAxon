import 'package:flutter_test/flutter_test.dart';
import 'package:myoaxon/data/models/gym_exercise_model.dart';

void main() {
  group('GymExerciseModel', () {
    test('Debe crear ejercicio de gimnasio con todos los campos', () {
      final exercise = GymExerciseModel(
        orden: 1,
        nombreEjercicio: 'Sentadillas',
        series: 4,
        repeticiones: 8,
        pesoKg: 80.0,
        rir: 2,
        descansoSegundos: 150,
        notas: 'Buena técnica',
      );

      expect(exercise.orden, 1);
      expect(exercise.nombreEjercicio, 'Sentadillas');
      expect(exercise.series, 4);
      expect(exercise.repeticiones, 8);
      expect(exercise.pesoKg, 80.0);
      expect(exercise.rir, 2);
      expect(exercise.descansoSegundos, 150);
      expect(exercise.notas, 'Buena técnica');
    });

    test('Debe permitir notas vacías por defecto', () {
      final exercise = GymExerciseModel(
        orden: 1,
        nombreEjercicio: 'Press Banca',
        series: 3,
        repeticiones: 10,
        pesoKg: 50.0,
        rir: 3,
        descansoSegundos: 120,
      );

      expect(exercise.notas, '');
    });

    test('Debe serializar correctamente para Firebase', () {
      final exercise = GymExerciseModel(
        orden: 2,
        nombreEjercicio: 'Dominadas',
        series: 3,
        repeticiones: 6,
        pesoKg: 0.0, // Peso corporal
        rir: 1,
        descansoSegundos: 90,
        notas: 'Lastre añadido',
      );

      final firebaseMap = exercise.toFirebase();

      expect(firebaseMap['orden'], 2);
      expect(firebaseMap['nombre_ejercicio'], 'Dominadas');
      expect(firebaseMap['series'], 3);
      expect(firebaseMap['repeticiones'], 6);
      expect(firebaseMap['peso_kg'], 0.0);
      expect(firebaseMap['rir'], 1);
      expect(firebaseMap['descanso_segundos'], 90);
      expect(firebaseMap['notas'], 'Lastre añadido');
    });

    test('Debe deserializar correctamente desde Firebase', () {
      final data = {
        'orden': 3,
        'nombre_ejercicio': 'Zancadas',
        'series': 4,
        'repeticiones': 10,
        'peso_kg': 30.0,
        'rir': 2,
        'descanso_segundos': 120,
        'notas': 'Forma correcta',
      };

      final exercise = GymExerciseModel.fromFirebase(data);

      expect(exercise.orden, 3);
      expect(exercise.nombreEjercicio, 'Zancadas');
      expect(exercise.series, 4);
      expect(exercise.repeticiones, 10);
      expect(exercise.pesoKg, 30.0);
      expect(exercise.rir, 2);
      expect(exercise.descansoSegundos, 120);
      expect(exercise.notas, 'Forma correcta');
    });

    test('Debe manejar valores nulos en fromFirebase', () {
      final data = {
        'orden': 1,
        'nombre_ejercicio': 'Ejercicio',
        'series': 0,
        'repeticiones': 0,
      };

      final exercise = GymExerciseModel.fromFirebase(data);

      expect(exercise.orden, 1);
      expect(exercise.nombreEjercicio, 'Ejercicio');
      expect(exercise.series, 0);
      expect(exercise.repeticiones, 0);
      expect(exercise.pesoKg, 0.0);
      expect(exercise.rir, 0);
      expect(exercise.descansoSegundos, 0);
      expect(exercise.notas, '');
    });

    test('Debe calcular volumen total (series * reps * peso)', () {
      final exercise = GymExerciseModel(
        orden: 1,
        nombreEjercicio: 'Sentadillas',
        series: 4,
        repeticiones: 8,
        pesoKg: 80.0,
        rir: 2,
        descansoSegundos: 150,
      );

      // Volumen = series * reps * peso = 4 * 8 * 80 = 2560
      expect(exercise.series * exercise.repeticiones * exercise.pesoKg, 2560.0);
    });
  });
}
