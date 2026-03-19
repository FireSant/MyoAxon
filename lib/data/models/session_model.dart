import 'package:hive/hive.dart';
import 'gym_exercise_model.dart';
import 'tech_exercise_model.dart';

part 'session_model.g.dart';

@HiveType(typeId: 0)
class SessionModel extends HiveObject {
  @HiveField(0)
  late String idSesion;

  @HiveField(1)
  late String userId; // Firebase UID del usuario dueño

  @HiveField(2)
  String? idAtleta; // ID interno del atleta (se genera si es null)

  @HiveField(3)
  late DateTime fecha;

  @HiveField(4)
  late String tipoSesion; // 'Gimnasio' o 'Técnica'

  @HiveField(5)
  late String faseEntrenamiento;

  @HiveField(6)
  late double horasSueno;

  @HiveField(7)
  late int fatiguaPreentrenamiento; // 1-5

  @HiveField(8)
  late int intensidadPercibida; // 1-10

  @HiveField(9)
  late String limitantes;

  @HiveField(10)
  late List<GymExerciseModel> ejerciciosGim;

  @HiveField(11)
  late List<TechExerciseModel> ejerciciosTech;

  @HiveField(12)
  bool isSynced;

  @HiveField(13, defaultValue: 'Matutina')
  String jornada; // 'Matutina' o 'Vespertina'

  @HiveField(14)
  DateTime? editadoEn;

  SessionModel({
    required this.idSesion,
    this.userId = '', // Opcional para compatibilidad
    this.idAtleta,
    required this.fecha,
    required this.tipoSesion,
    required this.faseEntrenamiento,
    required this.horasSueno,
    required this.fatiguaPreentrenamiento,
    required this.intensidadPercibida,
    this.limitantes = '',
    List<GymExerciseModel>? ejerciciosGim,
    List<TechExerciseModel>? ejerciciosTech,
    this.isSynced = false,
    this.jornada = 'Matutina',
    this.editadoEn,
  })  : ejerciciosGim = ejerciciosGim ?? [],
        ejerciciosTech = ejerciciosTech ?? [];

  // Para Firebase: Serializa los ejercicios según el tipo de sesión
  Map<String, dynamic> toFirebase() {
    return {
      'id_sesion': idSesion,
      'user_id': userId,
      'id_atleta': idAtleta,
      'fecha': fecha.toIso8601String(),
      'tipo_sesion': tipoSesion,
      'fase_entrenamiento': faseEntrenamiento,
      'horas_sueno': horasSueno,
      'fatiga_preentreno': fatiguaPreentrenamiento,
      'intensidad_percibida': intensidadPercibida,
      'limitantes': limitantes,
      'jornada': jornada,
      'editado_en': editadoEn?.toIso8601String(),
      'ejercicios_gym': ejerciciosGim.map((e) => e.toFirebase()).toList(),
      'ejercicios_tech': ejerciciosTech.map((e) => e.toFirebase()).toList(),
    };
  }

  // Factory para crear desde Firebase
  factory SessionModel.fromFirebase(Map<String, dynamic> data, String userId) {
    return SessionModel(
      idSesion: data['id_sesion'] ?? '',
      userId: userId,
      idAtleta: data['id_atleta'] ?? '',
      fecha: DateTime.parse(data['fecha'] ?? DateTime.now().toIso8601String()),
      tipoSesion: data['tipo_sesion'] ?? 'Gimnasio',
      faseEntrenamiento: data['fase_entrenamiento'] ?? '',
      horasSueno: (data['horas_sueno'] ?? 0.0).toDouble(),
      fatiguaPreentrenamiento: data['fatiga_preentreno'] ?? 0,
      intensidadPercibida: data['intensidad_percibida'] ?? 0,
      limitantes: data['limitantes'] ?? '',
      jornada: data['jornada'] ?? 'Matutina',
      isSynced: true,
      editadoEn: data['editado_en'] != null
          ? DateTime.parse(data['editado_en'])
          : null,
      // --- AGREGAR ESTO PARA RECUPERAR LOS EJERCICIOS ---
      ejerciciosGim: (data['ejercicios_gym'] as List?)
          ?.map((e) =>
              GymExerciseModel.fromFirebase(Map<String, dynamic>.from(e)))
          .toList(),
      ejerciciosTech: (data['ejercicios_tech'] as List?)
          ?.map((e) =>
              TechExerciseModel.fromFirebase(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
