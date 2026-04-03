import 'package:hive/hive.dart';

part 'axon_analysis_model.g.dart';

/// Tipos de análisis soportados por Laboratorio Axon
enum AxonAnalysisType { vbt, plyometry }

/// Resultado unificado de un análisis del Laboratorio Axon.
/// Soporta tanto VBT (velocidad de barra) como Pliometría (RSI).
@HiveType(typeId: 4)
class AxonAnalysisModel extends HiveObject {
  // ── Identificadores ─────────────────────────────────────────
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime timestamp;

  @HiveField(2)
  late String tipo; // 'vbt' | 'plyometry'

  @HiveField(3)
  late String exerciseLabel; // ej. "Sentadilla Posterior ½"

  @HiveField(4)
  late String folderName; // Carpeta de Análisis, ej. "Potencia y Gimnasio"

  @HiveField(5)
  late String athleteUid; // UID del atleta para integrar con ADN

  // ── Datos VBT ────────────────────────────────────────────────
  @HiveField(6)
  double vmcMs; // Velocidad Media Concéntrica (m/s)

  @HiveField(7)
  double displacementM; // Desplazamiento vertical concéntrico (m)

  @HiveField(8)
  int concentricDurationMs; // Duración fase concéntrica (ms)

  @HiveField(9)
  double pixelsPerMeter; // Ratio de calibración usado

  // ── Datos Pliometría ─────────────────────────────────────────
  @HiveField(10)
  int flightTimeMs; // Tiempo de vuelo (ms)

  @HiveField(11)
  int contactTimeMs; // Tiempo de contacto (ms)

  @HiveField(12)
  double rsi; // Reactive Strength Index = flightTimeMs / contactTimeMs (en s)

  // ── Sync ─────────────────────────────────────────────────────
  @HiveField(13)
  bool isSynced;

  AxonAnalysisModel({
    required this.id,
    required this.timestamp,
    required this.tipo,
    required this.exerciseLabel,
    required this.folderName,
    required this.athleteUid,
    this.vmcMs = 0.0,
    this.displacementM = 0.0,
    this.concentricDurationMs = 0,
    this.pixelsPerMeter = 0.0,
    this.flightTimeMs = 0,
    this.contactTimeMs = 0,
    this.rsi = 0.0,
    this.isSynced = false,
  });

  // ── Helpers de tipo ──────────────────────────────────────────
  bool get isVbt => tipo == 'vbt';
  bool get isPlyometry => tipo == 'plyometry';

  // ── Serialización Firebase ───────────────────────────────────
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'tipo': tipo,
      'exercise_label': exerciseLabel,
      'folder_name': folderName,
      'athlete_uid': athleteUid,
      // VBT
      'vmc_ms': vmcMs,
      'displacement_m': displacementM,
      'concentric_duration_ms': concentricDurationMs,
      'pixels_per_meter': pixelsPerMeter,
      // Plyometry
      'flight_time_ms': flightTimeMs,
      'contact_time_ms': contactTimeMs,
      'rsi': rsi,
    };
  }

  factory AxonAnalysisModel.fromFirebase(Map<String, dynamic> data) {
    return AxonAnalysisModel(
      id: data['id'] ?? '',
      timestamp:
          DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      tipo: data['tipo'] ?? 'vbt',
      exerciseLabel: data['exercise_label'] ?? '',
      folderName: data['folder_name'] ?? '',
      athleteUid: data['athlete_uid'] ?? '',
      vmcMs: (data['vmc_ms'] ?? 0).toDouble(),
      displacementM: (data['displacement_m'] ?? 0).toDouble(),
      concentricDurationMs: data['concentric_duration_ms'] ?? 0,
      pixelsPerMeter: (data['pixels_per_meter'] ?? 0).toDouble(),
      flightTimeMs: data['flight_time_ms'] ?? 0,
      contactTimeMs: data['contact_time_ms'] ?? 0,
      rsi: (data['rsi'] ?? 0).toDouble(),
      isSynced: true,
    );
  }

  AxonAnalysisModel copyWith({
    String? exerciseLabel,
    String? folderName,
    bool? isSynced,
  }) {
    return AxonAnalysisModel(
      id: id,
      timestamp: timestamp,
      tipo: tipo,
      exerciseLabel: exerciseLabel ?? this.exerciseLabel,
      folderName: folderName ?? this.folderName,
      athleteUid: athleteUid,
      vmcMs: vmcMs,
      displacementM: displacementM,
      concentricDurationMs: concentricDurationMs,
      pixelsPerMeter: pixelsPerMeter,
      flightTimeMs: flightTimeMs,
      contactTimeMs: contactTimeMs,
      rsi: rsi,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
