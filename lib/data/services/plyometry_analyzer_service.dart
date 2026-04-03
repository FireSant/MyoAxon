// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Estados posibles del ciclo pliométrico
enum PlyometryPhase { idle, grounded, takeoff, flight, landing }

/// Resultado de un ciclo pliométrico completo (1 salto)
class PlyometryResult {
  final int groundedMs; // Cuándo tocó el suelo (inicio del TC)
  final int takeoffMs; // Cuándo despegó (inicio del TV)
  final int landingMs; // Cuándo aterrizó (fin del ciclo)
  final int flightTimeMs;
  final int contactTimeMs;
  final double rsi; // RSI = flightTime(s) / contactTime(s)
  final bool isValid;

  const PlyometryResult({
    required this.groundedMs,
    required this.takeoffMs,
    required this.landingMs,
    required this.flightTimeMs,
    required this.contactTimeMs,
    required this.rsi,
    required this.isValid,
  });

  static const PlyometryResult empty = PlyometryResult(
    groundedMs: 0,
    takeoffMs: 0,
    landingMs: 0,
    flightTimeMs: 0,
    contactTimeMs: 0,
    rsi: 0,
    isValid: false,
  );
}

/// Servicio de análisis pliométrico basado en ML Kit Pose Detection.
/// Detecta fases de vuelo y contacto analizando la posición de los tobillos.
class PlyometryAnalyzerService {
  // ── Umbrales de detección ───────────────────────────────────
  /// Fracción de la altura de la imagen por debajo de la cual los tobillos
  /// se consideran en contacto con el suelo.
  static const double groundThresholdFraction = 0.85;

  /// Número mínimo de frames consecutivos en cada fase para confirmarla
  /// (evita falsos positivos por ruido del detector).
  static const int minFramesToConfirmPhase = 2;

  // ── Estado de la máquina de estados ─────────────────────────
  PlyometryPhase _phase = PlyometryPhase.idle;
  int _phaseStartMs = 0;
  int _groundedStartMs = 0;
  int _takeoffMs = 0;

  int _framesInCurrentPhase = 0;
  double _imageHeight = 1;

  // Resultados del ciclo actual
  final List<PlyometryResult> _results = [];

  List<PlyometryResult> get results => List.unmodifiable(_results);
  PlyometryPhase get currentPhase => _phase;

  // ── API pública ──────────────────────────────────────────────

  void setImageHeight(double height) {
    _imageHeight = height;
  }

  void reset() {
    _phase = PlyometryPhase.idle;
    _phaseStartMs = 0;
    _groundedStartMs = 0;
    _takeoffMs = 0;
    _framesInCurrentPhase = 0;
    _results.clear();
  }

  /// Procesa un frame con poses detectadas por ML Kit y actualiza la máquina de estados.
  ///
  /// [poses]: lista de poses del frame actual
  /// [timestampMs]: timestamp del frame en milisegundos
  ///
  /// Returns: el [PlyometryResult] si se completó un ciclo en este frame, o null.
  PlyometryResult? processFrame(List<dynamic> poses, int timestampMs) {
    // ML Kit is temporarily disabled for debugging startup issues
    return null;
  }

  /// Calcula el RSI dado tiempos en milisegundos (función pura, testeable).
  static double computeRsi(int flightTimeMs, int contactTimeMs) {
    if (contactTimeMs <= 0) return 0;
    // RSI = TV(s) / TC(s)
    return (flightTimeMs / 1000.0) / (contactTimeMs / 1000.0);
  }

  // ── Lógica interna ───────────────────────────────────────────

  /// Determina si los tobillos están cerca del suelo según su posición Y normalizada.
  bool _areAnklesOnGround(dynamic pose) {
    // ML Kit is temporarily disabled for debugging startup issues
    return true;
  }

  /// Máquina de estados del ciclo pliométrico.
  ///
  /// Transiciones:
  /// idle → grounded: tobillos en tierra por primera vez
  /// grounded → takeoff: tobillos se elevan (dejan el suelo)
  /// takeoff → flight: se confirma la elevación
  /// flight → landing: tobillos vuelven al suelo
  /// landing → grounded: se calcula el resultado y se resetea para el siguiente ciclo
  PlyometryResult? _updateStateMachine(bool anklesOnGround, int timestampMs) {
    switch (_phase) {
      case PlyometryPhase.idle:
        if (anklesOnGround) {
          _phase = PlyometryPhase.grounded;
          _groundedStartMs = timestampMs;
          _framesInCurrentPhase = 1;
        }
        break;

      case PlyometryPhase.grounded:
        if (anklesOnGround) {
          _framesInCurrentPhase++;
        } else {
          // Despegue detectado
          _framesInCurrentPhase = 1;
          _phase = PlyometryPhase.takeoff;
          _takeoffMs = timestampMs;
        }
        break;

      case PlyometryPhase.takeoff:
        if (!anklesOnGround) {
          _framesInCurrentPhase++;
          if (_framesInCurrentPhase >= minFramesToConfirmPhase) {
            _phase = PlyometryPhase.flight;
            _phaseStartMs = _takeoffMs;
          }
        } else {
          // Falso positivo → volver a tierra
          _phase = PlyometryPhase.grounded;
          _framesInCurrentPhase = 1;
        }
        break;

      case PlyometryPhase.flight:
        if (anklesOnGround) {
          _phase = PlyometryPhase.landing;
          _framesInCurrentPhase = 1;
        }
        break;

      case PlyometryPhase.landing:
        if (anklesOnGround) {
          _framesInCurrentPhase++;
          if (_framesInCurrentPhase >= minFramesToConfirmPhase) {
            // Ciclo completado → calcular resultado
            final int flightTimeMs = timestampMs - _phaseStartMs;
            final int contactTimeMs =
                _groundedStartMs > 0 ? _takeoffMs - _groundedStartMs : 0;
            final double rsi = computeRsi(flightTimeMs, contactTimeMs);

            final result = PlyometryResult(
              groundedMs: _groundedStartMs,
              takeoffMs: _takeoffMs,
              landingMs: timestampMs,
              flightTimeMs: flightTimeMs,
              contactTimeMs: contactTimeMs,
              rsi: rsi,
              isValid: flightTimeMs > 50 && contactTimeMs > 50,
            );

            _results.add(result);

            // Preparar para el siguiente ciclo
            _phase = PlyometryPhase.grounded;
            _groundedStartMs = timestampMs;
            _framesInCurrentPhase = 1;

            return result;
          }
        } else {
          // Falso positivo: volver a vuelo
          _phase = PlyometryPhase.flight;
          _framesInCurrentPhase = 1;
        }
        break;
    }
    return null;
  }
}
