import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Resultado de un análisis VBT completo.
class VbtResult {
  final double vmcMs; // Velocidad Media Concéntrica (m/s)
  final double displacementM; // Desplazamiento vertical (m)
  final int concentricDurationMs; // Duración de la fase concéntrica (ms)
  final int
      startConcentricIndex; // Índice del frame donde inicia la concéntrica
  final List<double> yPositions; // Trayectoria completa Y
  final List<int> timestamps; // Timestamps completos
  final double pixelsPerMeter; // Factor de escala
  final bool isValid; // Si el resultado es confiable

  const VbtResult({
    required this.vmcMs,
    required this.displacementM,
    required this.concentricDurationMs,
    required this.startConcentricIndex,
    required this.yPositions,
    required this.timestamps,
    required this.pixelsPerMeter,
    required this.isValid,
  });

  static const VbtResult empty = VbtResult(
    vmcMs: 0,
    displacementM: 0,
    concentricDurationMs: 0,
    startConcentricIndex: -1,
    yPositions: [],
    timestamps: [],
    pixelsPerMeter: 1,
    isValid: false,
  );
}

/// Servicio puro (sin Flutter ni cámara) para análisis VBT.
/// Toda la lógica es testeable de forma unitaria.
class VbtAnalyzerService {
  // ── Calibración ─────────────────────────────────────────────

  /// Calcula la relación píxeles/metro a partir del diámetro conocido del disco.
  ///
  /// [diskDiameterMeters]: diámetro real del disco (ej. 0.45 m)
  /// [diskDiameterPixels]: diámetro medido del disco en píxeles
  ///
  /// Returns: píxeles por metro (px/m)
  double calibrate({
    required double diskDiameterMeters,
    required double diskDiameterPixels,
  }) {
    assert(diskDiameterMeters > 0, 'El diámetro en metros debe ser > 0');
    assert(diskDiameterPixels > 0, 'El diámetro en píxeles debe ser > 0');
    return diskDiameterPixels / diskDiameterMeters;
  }

  /// Convierte un desplazamiento en píxeles a metros.
  double pixelsToMeters(double pixels, double pixelsPerMeter) {
    if (pixelsPerMeter <= 0) return 0;
    return pixels / pixelsPerMeter;
  }

  // ── Análisis de Trayectoria ──────────────────────────────────

  /// Analiza una trayectoria de posiciones Y para determinar VMC.
  ///
  /// [yPositions]: lista de coordenadas Y (positivo = abajo en pantalla)
  /// [timestamps]: lista paralela de timestamps en milisegundos
  /// [pixelsPerMeter]: ratio de calibración
  /// [minConcentricFrames]: número mínimo de frames consecutivos hacia arriba
  ///   antes de confirmar inicio de concéntrica (anti-ruido/anti-isometría)
  ///
  /// La fase concéntrica se detecta cuando el Y disminuye (barra sube)
  /// de forma SOSTENIDA por al menos [minConcentricFrames] frames.
  VbtResult trackPhase({
    required List<double> yPositions,
    required List<int> timestamps,
    required double pixelsPerMeter,
    int minConcentricFrames = 5,
    double minConcentricDistancePx = 15.0, // Aprox ~2.5-3cm
  }) {
    assert(yPositions.length == timestamps.length,
        'yPositions y timestamps deben tener el mismo largo');

    if (yPositions.length < 3) return VbtResult.empty;

    // 1. Encuentra el punto más bajo (Y máximo)
    int lowestIndex = 0;
    double maxY = yPositions[0];
    for (int i = 1; i < yPositions.length; i++) {
      if (yPositions[i] > maxY) {
        maxY = yPositions[i];
        lowestIndex = i;
      }
    }

    if (lowestIndex >= yPositions.length - minConcentricFrames) {
      return VbtResult.empty;
    }

    // 2. Busca inicio de concéntrica con Doble Validación:
    //    a) Frames consecutivos hacia arriba.
    //    b) Desplazamiento mínimo (Threshold de Isometría).
    int startConcentricIndex = -1;
    final double yStartRef = yPositions[lowestIndex];

    for (int i = lowestIndex;
        i < yPositions.length - minConcentricFrames;
        i++) {
      // Verificamos si desde este punto i hay una subida sostenida
      bool isRising = true;
      for (int k = i; k < i + minConcentricFrames; k++) {
        if (k + 1 >= yPositions.length || yPositions[k + 1] >= yPositions[k]) {
          isRising = false;
          break;
        }
      }

      if (isRising) {
        // Verificamos si el desplazamiento total desde el punto más bajo es suficiente
        final double currentDist =
            (yStartRef - yPositions[i + minConcentricFrames]).abs();
        if (currentDist >= minConcentricDistancePx) {
          startConcentricIndex = i;
          break;
        }
      }
    }

    if (startConcentricIndex == -1) return VbtResult.empty;

    // 3. El final es el punto más alto después del inicio (o el final del array)
    int endIndex = startConcentricIndex;
    double minY = yPositions[startConcentricIndex];
    for (int i = startConcentricIndex; i < yPositions.length; i++) {
      if (yPositions[i] <= minY) {
        minY = yPositions[i];
        endIndex = i;
      } else {
        // Si empieza a bajar de nuevo (excéntrica de la siguiente rep o descanso)
        // podríamos cortar aquí o seguir hasta el final si es una sola rep.
        // Para VBT offline de una sola rep, seguimos hasta el pico máximo.
      }
    }

    // 4. Cálculos finales
    final double yStartPx = yPositions[startConcentricIndex];
    final double yEndPx = yPositions[endIndex];
    final double displacementPx = (yStartPx - yEndPx); // Debe ser positivo
    final double displacementM = pixelsToMeters(displacementPx, pixelsPerMeter);

    final int durationMs =
        timestamps[endIndex] - timestamps[startConcentricIndex];

    if (durationMs <= 100 || displacementM <= 0.05) return VbtResult.empty;

    final double vmcMs = displacementM / (durationMs / 1000.0);

    return VbtResult(
      vmcMs: vmcMs,
      displacementM: displacementM,
      concentricDurationMs: durationMs,
      startConcentricIndex: startConcentricIndex,
      yPositions: yPositions,
      timestamps: timestamps,
      pixelsPerMeter: pixelsPerMeter,
      isValid: true,
    );
  }

  /// Suaviza una trayectoria Y usando una media móvil simple.
  List<double> smoothTrajectory(List<double> input, {int windowSize = 5}) {
    if (input.length < windowSize) return input;
    List<double> output = [];
    for (int i = 0; i < input.length; i++) {
      int start = math.max(0, i - windowSize ~/ 2);
      int end = math.min(input.length - 1, i + windowSize ~/ 2);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += input[j];
      }
      output.add(sum / (end - start + 1));
    }
    return output;
  }

  /// Captura el color HSV exacto en una coordenada (x, y).
  List<double> sampleColorAt(Uint8List rgbaBytes, int width, int x, int y) {
    final int idx = (y * width + x) * 4;
    if (idx + 3 >= rgbaBytes.length) return [0, 0, 0];
    return _rgbToHsv(
      rgbaBytes[idx] / 255.0,
      rgbaBytes[idx + 1] / 255.0,
      rgbaBytes[idx + 2] / 255.0,
    );
  }

  /// Detecta el diámetro de un disco buscando bordes desde un punto central.
  double detectDiameterFromPoint(Uint8List rgbaBytes, int width, int height,
      int cx, int cy, double targetHue,
      {double tolerance = 20.0}) {
    // Buscamos borde izquierdo
    int left = cx;
    while (left > 0) {
      final color = sampleColorAt(rgbaBytes, width, left, cy);
      if (_hueDiff(color[0], targetHue) > tolerance) break;
      left--;
    }
    // Buscamos borde derecho
    int right = cx;
    while (right < width - 1) {
      final color = sampleColorAt(rgbaBytes, width, right, cy);
      if (_hueDiff(color[0], targetHue) > tolerance) break;
      right++;
    }
    return (right - left).toDouble();
  }

  double _hueDiff(double h1, double h2) {
    double diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  // ── Detección de Disco por Color ─────────────────────────────

  /// Busca el centro de un disco (o marcador circular) en una imagen RGBA.
  ///
  /// Implementa detección de blobs por color en el espacio HSV.
  /// Devuelve el centroide del blob más grande que coincida con el color objetivo.
  ///
  /// [rgbaBytes]: bytes crudos RGBA de la imagen (ancho * alto * 4 bytes)
  /// [width], [height]: dimensiones
  /// [targetHue]: matiz objetivo en grados [0–360] (ej. 0 = rojo, 210 = azul)
  /// [hueTolerance]: tolerancia del matiz (±grados)
  /// [minSaturation]: saturación mínima [0–1] para filtrar colores grises
  ///
  /// Returns: {center: Offset, radiusPx: double} o null si no se detecta
  Map<String, double>? detectDiskCenter({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    double targetHue = 0, // Rojo por defecto
    double hueTolerance = 20,
    double minSaturation = 0.4,
    double minValue = 0.3,
  }) {
    // Lista de píxeles que coinciden con el color objetivo
    double sumX = 0, sumY = 0;
    int count = 0;
    double minX = width.toDouble(), maxX = 0;
    double minY = height.toDouble(), maxY = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = (y * width + x) * 4;
        if (idx + 3 >= rgbaBytes.length) continue;

        final double r = rgbaBytes[idx] / 255.0;
        final double g = rgbaBytes[idx + 1] / 255.0;
        final double b = rgbaBytes[idx + 2] / 255.0;

        final hsv = _rgbToHsv(r, g, b);
        final double h = hsv[0]; // [0–360]
        final double s = hsv[1]; // [0–1]
        final double v = hsv[2]; // [0–1]

        if (s < minSaturation || v < minValue) continue;

        // Distancia circular del matiz
        double hueDiff = (h - targetHue).abs();
        if (hueDiff > 180) hueDiff = 360 - hueDiff;

        if (hueDiff <= hueTolerance) {
          sumX += x;
          sumY += y;
          count++;
          if (x < minX) minX = x.toDouble();
          if (x > maxX) maxX = x.toDouble();
          if (y < minY) minY = y.toDouble();
          if (y > maxY) maxY = y.toDouble();
        }
      }
    }

    if (count < 50) return null; // muy pocos píxeles → falso positivo

    // Radio aproximado como promedio de extensiones horizontal y vertical
    final double radiusX = (maxX - minX) / 2;
    final double radiusY = (maxY - minY) / 2;
    final double radius = (radiusX + radiusY) / 2;

    return {
      'cx': sumX / count,
      'cy': sumY / count,
      'radius': radius,
    };
  }

  // ── Utilidades ───────────────────────────────────────────────

  /// Convierte RGB [0–1] a HSV. Returns [hue°, saturation, value].
  List<double> _rgbToHsv(double r, double g, double b) {
    final double maxC = math.max(r, math.max(g, b));
    final double minC = math.min(r, math.min(g, b));
    final double delta = maxC - minC;

    double h = 0;
    if (delta != 0) {
      if (maxC == r) {
        h = 60 * (((g - b) / delta) % 6);
      } else if (maxC == g) {
        h = 60 * (((b - r) / delta) + 2);
      } else {
        h = 60 * (((r - g) / delta) + 4);
      }
      if (h < 0) h += 360;
    }

    final double s = maxC == 0 ? 0 : delta / maxC;
    final double v = maxC;

    return [h, s, v];
  }
}
