import 'package:flutter_test/flutter_test.dart';
import 'package:myoaxon/data/models/session_model.dart';
import 'package:myoaxon/data/models/gym_exercise_model.dart';
import 'package:myoaxon/data/models/tech_exercise_model.dart';

void main() {
  group('SessionModel', () {
    late SessionModel session;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 3, 10);
    });

    test('Debe crear una sesión de Gimnasio con todos los campos requeridos',
        () {
      final gymExercise = GymExerciseModel(
        orden: 1,
        nombreEjercicio: 'Sentadillas',
        series: 4,
        repeticiones: 8,
        pesoKg: 80.0,
        rir: 2,
        descansoSegundos: 150,
        notas: 'Buena técnica',
      );

      session = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'general',
        horasSueno: 7.5,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 8,
        limitantes: 'Molestia leve',
        ejerciciosGim: [gymExercise],
        isSynced: false,
      );

      expect(session.idSesion, '01_20250310_Gimnasio');
      expect(session.idAtleta, '01');
      expect(session.tipoSesion, 'Gimnasio');
      expect(session.ejerciciosGim.length, 1);
      expect(session.ejerciciosGim.first.nombreEjercicio, 'Sentadillas');
      expect(session.isSynced, false);
    });

    test('Debe crear una sesión de Técnica con ejercicios técnicos', () {
      final techExercise = TechExerciseModel(
        orden: 1,
        nombreEjercicio: '100m planos',
        series: 3,
        repeticiones: 1,
        metricaPrincipal: 100.0,
        descansoSegundos: 180,
        notasSerie: 'Viento +1.2',
      );

      session = SessionModel(
        idSesion: '01_20250310_Técnica',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Técnica',
        faseEntrenamiento: 'especial',
        horasSueno: 8.0,
        fatiguaPreentrenamiento: 2,
        intensidadPercibida: 7,
        ejerciciosTech: [techExercise],
      );

      expect(session.tipoSesion, 'Técnica');
      expect(session.ejerciciosTech.length, 1);
      expect(session.ejerciciosTech.first.metricaPrincipal, 100.0);
    });

    test('Debe serializar correctamente para Firebase', () {
      final gymExercise = GymExerciseModel(
        orden: 1,
        nombreEjercicio: 'Press Banca',
        series: 5,
        repeticiones: 5,
        pesoKg: 60.0,
        rir: 1,
        descansoSegundos: 180,
        notas: '',
      );

      session = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'fuerza',
        horasSueno: 7.0,
        fatiguaPreentrenamiento: 4,
        intensidadPercibida: 9,
        limitantes: '',
        ejerciciosGim: [gymExercise],
      );

      final firebaseMap = session.toFirebase();

      expect(firebaseMap['id_sesion'], '01_20250310_Gimnasio');
      expect(firebaseMap['id_atleta'], '01');
      expect(firebaseMap['tipo_sesion'], 'Gimnasio');
      expect(firebaseMap['ejercicios_gym'].length, 1);
      expect(
          firebaseMap['ejercicios_gym'][0]['nombre_ejercicio'], 'Press Banca');
      expect(firebaseMap['fatiga_preentreno'], 4);
    });

    test('Debe manejar lista vacía de ejercicios', () {
      session = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'general',
        horasSueno: 7.5,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 8,
      );

      expect(session.ejerciciosGim, isEmpty);
      expect(session.ejerciciosTech, isEmpty);
    });

    test('Debe permitir limitantes vacíos por defecto', () {
      session = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'general',
        horasSueno: 7.5,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 8,
      );

      expect(session.limitantes, '');
    });

    test('Debe comparar sesiones por ID', () {
      final session1 = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'general',
        horasSueno: 7.5,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 8,
      );

      final session2 = SessionModel(
        idSesion: '01_20250310_Gimnasio',
        idAtleta: '01',
        fecha: testDate,
        tipoSesion: 'Gimnasio',
        faseEntrenamiento: 'general',
        horasSueno: 7.5,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 8,
      );

      expect(session1.idSesion, session2.idSesion);
    });
  });
}
