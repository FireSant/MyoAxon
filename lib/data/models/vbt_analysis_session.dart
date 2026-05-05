import 'dart:math' as math;

/// Modelo para representar una repetición individual dentro de una serie VBT.
class VBTRepetition {
  final int id;
  final int frameStart;
  final int frameEnd;
  final double vmc; // Velocidad Media Concéntrica (m/s)
  final double tiempoS; // Tiempo de ejecución (s)

  VBTRepetition({
    required this.id,
    required this.frameStart,
    required this.frameEnd,
    required this.vmc,
    required this.tiempoS,
  });

  @override
  String toString() => 'Rep $id: $frameStart-$frameEnd ($vmc m/s)';
}

/// Estado de una sesión de análisis VBT.
class VBTAnalysisSession {
  final String? videoPath;
  final double fps;
  final List<VBTRepetition> reps;
  final double romCm;
  final double targetVmc;
  final String exerciseType;
  final String bodyPart; // 'Tren Superior' o 'Tren Inferior'
  final double pesoKg; // Carga en kg
  final bool isMarkingStart;

  VBTAnalysisSession({
    this.videoPath,
    this.fps = 30.0,
    this.reps = const [],
    this.romCm = 50.0,
    this.targetVmc = 0.50,
    this.exerciseType = 'Sentadilla',
    this.bodyPart = 'Tren Inferior',
    this.pesoKg = 0.0,
    this.isMarkingStart = true,
  });

  VBTAnalysisSession copyWith({
    String? videoPath,
    double? fps,
    List<VBTRepetition>? reps,
    double? romCm,
    double? targetVmc,
    String? exerciseType,
    String? bodyPart,
    double? pesoKg,
    bool? isMarkingStart,
  }) {
    return VBTAnalysisSession(
      videoPath: videoPath ?? this.videoPath,
      fps: fps ?? this.fps,
      reps: reps ?? this.reps,
      romCm: romCm ?? this.romCm,
      targetVmc: targetVmc ?? this.targetVmc,
      exerciseType: exerciseType ?? this.exerciseType,
      bodyPart: bodyPart ?? this.bodyPart,
      pesoKg: pesoKg ?? this.pesoKg,
      isMarkingStart: isMarkingStart ?? this.isMarkingStart,
    );
  }

  // Estadísticas calculadas
  double get avgVmc => reps.isEmpty 
      ? 0.0 
      : reps.map((r) => r.vmc).reduce((a, b) => a + b) / reps.length;

  double get bestVmc => reps.isEmpty 
      ? 0.0 
      : reps.map((r) => r.vmc).reduce((a, b) => a > b ? a : b);

  double get minVmc => reps.isEmpty 
      ? 0.0 
      : reps.map((r) => r.vmc).reduce((a, b) => a < b ? a : b);

  double get speedVariation {
    if (reps.length < 2) return 0.0;
    final best = bestVmc;
    final last = reps.last.vmc;
    if (best == 0) return 0.0;
    return ((best - last) / best) * 100;
  }

  double get coeficienteVariacion {
    if (reps.isEmpty || avgVmc == 0) return 0.0;
    final mean = avgVmc;
    double sumSq = 0.0;
    for (var rep in reps) {
      sumSq += (rep.vmc - mean) * (rep.vmc - mean);
    }
    // Usamos varianza muestral (N-1) si hay más de 1 rep, sino poblacional (N)
    final divisor = reps.length > 1 ? reps.length - 1 : 1;
    final stdDev = math.sqrt(sumSq / divisor);
    return (stdDev / mean) * 100;
  }

  double get tiempoTotalS {
    if (reps.isEmpty) return 0.0;
    return reps.map((r) => r.tiempoS).reduce((a, b) => a + b);
  }
}
