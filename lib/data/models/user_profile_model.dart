import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  late String uid;

  @HiveField(1)
  late String nombreCompleto;

  @HiveField(2)
  late DateTime fechaNacimiento;

  @HiveField(3)
  late String sexo; // 'Masculino', 'Femenino', 'Otro'

  @HiveField(4)
  late String
      perfilDeportivo; // e.g., 'Powerlifting', 'Halterofilia', 'Culturismo'

  @HiveField(5)
  late String mejorMarca;

  @HiveField(6)
  late DateTime fechaMejorMarca;

  @HiveField(7)
  late String competenciaObjetivo;

  @HiveField(8)
  late String categoria;

  @HiveField(9)
  late String rol; // 'atleta' o 'entrenador'

  @HiveField(10)
  late String coachId; // ID of the coach, if 'atleta'

  @HiveField(11)
  bool isSynced;

  UserProfileModel({
    required this.uid,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.sexo,
    required this.perfilDeportivo,
    required this.mejorMarca,
    required this.fechaMejorMarca,
    required this.competenciaObjetivo,
    required this.categoria,
    required this.rol,
    required this.coachId,
    this.isSynced = false,
  });

  // Para Firebase: Serializa
  Map<String, dynamic> toFirebase() {
    return {
      'uid': uid,
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'sexo': sexo,
      'perfil_deportivo': perfilDeportivo,
      'mejor_marca': mejorMarca,
      'fecha_mejor_marca': fechaMejorMarca.toIso8601String(),
      'competencia_objetivo': competenciaObjetivo,
      'categoria': categoria,
      'rol': rol,
      'coach_id': coachId,
    };
  }

  // Factory para crear desde Firebase
  factory UserProfileModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserProfileModel(
      uid: uid,
      nombreCompleto: data['nombre_completo'] ?? '',
      fechaNacimiento: DateTime.parse(
          data['fecha_nacimiento'] ?? DateTime.now().toIso8601String()),
      sexo: data['sexo'] ?? '',
      perfilDeportivo: data['perfil_deportivo'] ?? '',
      mejorMarca: data['mejor_marca'] ?? '',
      fechaMejorMarca: DateTime.parse(
          data['fecha_mejor_marca'] ?? DateTime.now().toIso8601String()),
      competenciaObjetivo: data['competencia_objetivo'] ?? '',
      categoria: data['categoria'] ?? '',
      rol: data['rol'] ?? 'atleta',
      coachId: data['coach_id'] ?? '',
      isSynced: true,
    );
  }
}
