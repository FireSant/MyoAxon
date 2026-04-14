import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../models/gym_exercise_model.dart';
import '../models/tech_exercise_model.dart';

class SessionExportService {
  /// Transforma una Sesión real en un código de texto comprimido
  static String generarAxonCode(SessionModel session, String authorName) {
    try {
      final Map<String, dynamic> seed = {
        'v': 3, // Version 3 uses archive package for ZLib
        'a': authorName,
        'n': session.tipoSesion,
        'g': session.ejerciciosGim
            .map((ex) => {
                  'nm': ex.nombreEjercicio,
                  's': ex.series,
                  'r': ex.repeticiones,
                })
            .toList(),
        't': session.ejerciciosTech
            .map((ex) => {
                  'nm': ex.nombreEjercicio,
                  's': ex.series,
                  'r': ex.repeticiones,
                  'm': ex.metricaPrincipal,
                })
            .toList(),
      };

      final String jsonStr = jsonEncode(seed);
      final List<int> bytes = utf8.encode(jsonStr);
      final List<int> compressed = const ZLibEncoder().encode(bytes);
      return base64Encode(compressed);
    } catch (e, st) {
      debugPrint('❌ ERROR EN GENERAR AXON CODE: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Revierte el código base64 a un modelo de sesión plantilla
  static SessionModel decodificarAxonCode(String inputCode) {
    try {
      // Extraer el bloque Base64 del mensaje completo usando RegEx.
      // Busca un string largo (mínimo 20 chars) continuado al final del texto.
      final matches = RegExp(r'[A-Za-z0-9+/=]{20,}').allMatches(inputCode);
      final String code =
          matches.isNotEmpty ? matches.last.group(0)! : inputCode;

      final List<int> bytes = base64Decode(code.trim());
      String jsonStr;

      try {
        final decompressed = const ZLibDecoder().decodeBytes(bytes);
        jsonStr = utf8.decode(decompressed);
      } catch (_) {
        // Fallback for v1 strings
        jsonStr = utf8.decode(bytes);
      }

      final Map<String, dynamic> data = jsonDecode(jsonStr);

      final String tipoSesion = data['n'] ?? 'Gimnasio';
      final String author = data['a'] ?? 'Desconocido';

      final List<dynamic> rawGym = data['g'] ?? [];
      final List<GymExerciseModel> gymExercises =
          rawGym.asMap().entries.map((entry) {
        final Map<String, dynamic> item = entry.value;
        return GymExerciseModel(
          orden: entry.key + 1,
          nombreEjercicio: item['nm'] ?? '',
          series: item['s'] ?? 0,
          repeticiones: item['r'] ?? 0,
          pesoKg: 0.0,
          rir: 0,
          descansoSegundos: 60,
        );
      }).toList();

      final List<dynamic> rawTech = data['t'] ?? [];
      final List<TechExerciseModel> techExercises =
          rawTech.asMap().entries.map((entry) {
        final Map<String, dynamic> item = entry.value;
        return TechExerciseModel(
          orden: entry.key + 1,
          nombreEjercicio: item['nm'] ?? '',
          series: item['s'] ?? 0,
          repeticiones: item['r'] ?? 0,
          metricaPrincipal: (item['m'] ?? 0).toDouble(),
          descansoSegundos: 60,
        );
      }).toList();

      return SessionModel(
        idSesion: '', // ID vacío, se generará al guardar
        fecha: DateTime.now(), // La fecha de importación
        tipoSesion: tipoSesion,
        faseEntrenamiento: '',
        horasSueno: 8.0,
        fatiguaPreentrenamiento: 3,
        intensidadPercibida: 5,
        limitantes: 'Plantilla original compartida por: $author',
        ejerciciosGim: gymExercises,
        ejerciciosTech: techExercises,
      );
    } catch (e) {
      throw Exception('Código de entrenamiento inválido o corrupto.');
    }
  }

  /// Genera el texto para el portapapeles
  static String generarMensajeCompartir(
      SessionModel session, String authorName) {
    final code = generarAxonCode(session, authorName);
    final totalEjercicios =
        session.ejerciciosGim.length + session.ejerciciosTech.length;

    final StringBuffer details = StringBuffer();
    for (final ex in session.ejerciciosGim) {
      final summary = ex.series > 0 ? '(${ex.series} series)' : '';
      details.writeln('- ${ex.nombreEjercicio} $summary'.trim());
    }
    for (final ex in session.ejerciciosTech) {
      final summary = ex.series > 0 ? '(${ex.series} series)' : '';
      details.writeln('- ${ex.nombreEjercicio} $summary'.trim());
    }

    return '''🚀 Entrenamiento MyoAxon
Autor de la rutina: $authorName
Sesión: ${session.tipoSesion}
Ejercicios ($totalEjercicios movimientos):
${details.toString().trim()}

📲 Copia TODO este grupo de mensajes para importarlo en tu app:

$code''';
  }
}
