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

  // Campos específicos para entrenadores
  @HiveField(11)
  late String nombreCoach; // Nombre del entrenador
  @HiveField(12)
  late String especialidadCoach; // Ej: Lanzamientos, Sprints
  @HiveField(13)
  late String institucionCoach; // Club o institución
  @HiveField(14)
  late String? redSocialCoach; // Opcional, enlace a red social

  // Código de vinculación para que un atleta pueda compartir con su entrenador
  @HiveField(15)
  late String? linkCode;

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
    this.nombreCoach = '',
    this.especialidadCoach = '',
    this.institucionCoach = '',
    this.redSocialCoach,
    this.linkCode,
    this.isSynced = false,
  });

  UserProfileModel copyWith({
    String? uid,
    String? nombreCompleto,
    DateTime? fechaNacimiento,
    String? sexo,
    String? perfilDeportivo,
    String? mejorMarca,
    DateTime? fechaMejorMarca,
    String? competenciaObjetivo,
    String? categoria,
    String? rol,
    String? coachId,
    String? nombreCoach,
    String? especialidadCoach,
    String? institucionCoach,
    String? redSocialCoach,
    String? linkCode,
    bool? isSynced,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      perfilDeportivo: perfilDeportivo ?? this.perfilDeportivo,
      mejorMarca: mejorMarca ?? this.mejorMarca,
      fechaMejorMarca: fechaMejorMarca ?? this.fechaMejorMarca,
      competenciaObjetivo: competenciaObjetivo ?? this.competenciaObjetivo,
      categoria: categoria ?? this.categoria,
      rol: rol ?? this.rol,
      coachId: coachId ?? this.coachId,
      nombreCoach: nombreCoach ?? this.nombreCoach,
      especialidadCoach: especialidadCoach ?? this.especialidadCoach,
      institucionCoach: institucionCoach ?? this.institucionCoach,
      redSocialCoach: redSocialCoach ?? this.redSocialCoach,
      linkCode: linkCode ?? this.linkCode,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  static String calcularCategoria(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age <= 13) return 'U14';
    if (age <= 15) return 'U16';
    if (age <= 17) return 'U18';
    if (age <= 19) return 'U20';
    if (age <= 22) return 'U23';
    return 'Senior';
  }

  String get categoriaCalculada => calcularCategoria(fechaNacimiento);

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
      'nombre_coach': nombreCoach,
      'especialidad_coach': especialidadCoach,
      'institucion_coach': institucionCoach,
      'red_social_coach': redSocialCoach,
      'link_code': linkCode,
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
      nombreCoach: data['nombre_coach'] ?? '',
      especialidadCoach: data['especialidad_coach'] ?? '',
      institucionCoach: data['institucion_coach'] ?? '',
      redSocialCoach: data['red_social_coach'],
      linkCode: data['link_code'],
      isSynced: true,
    );
  }
}
