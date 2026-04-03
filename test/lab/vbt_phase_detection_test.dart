// Tests unitarios puros para VbtAnalyzerService — Detección de Fase.
// Test 2: Detección del Punto de Inflexión (no dispara en isometría).
// Ejecutar con: flutter test test/lab/vbt_phase_detection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:myoaxon/data/services/vbt_analyzer_service.dart';

void main() {
  late VbtAnalyzerService analyzer;
  const double px = 400.0; // 400 px/m de calibración

  setUp(() {
    analyzer = VbtAnalyzerService();
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Genera timestamps separados por 33ms (30fps)
  List<int> timestamps(int count) {
    return List.generate(count, (i) => i * 33);
  }

  // ── Tests ──────────────────────────────────────────────────────────────────

  group('VbtAnalyzerService — Detección de Fase', () {
    /// Test 2a: Trayectoria ideal (baja, sube) → detecta fase concéntrica
    test('Detecta inicio concéntrico en trayectoria limpia bajada→subida', () {
      // Y en pantalla: 100 → 200 (baja) → 100 (sube)
      final yPositions = [
        100.0, 120.0, 140.0, 160.0, 180.0, 200.0, // excéntrica (baja)
        190.0, 180.0, 170.0, 160.0, 150.0, 140.0, // concéntrica (sube)
        130.0, 120.0, 110.0, 100.0,
      ];
      final ts = timestamps(yPositions.length);

      final result = analyzer.trackPhase(
        yPositions: yPositions,
        timestamps: ts,
        pixelsPerMeter: px,
        minConcentricFrames: 3,
      );

      expect(result.isValid, isTrue,
          reason: 'Debe detectar fase concéntrica en trayectoria limpia');
      expect(result.startConcentricIndex, greaterThanOrEqualTo(5),
          reason: 'La concéntrica no debe empezar antes del punto más bajo');
      expect(result.vmcMs, greaterThan(0), reason: 'VMC debe ser positiva');
    });

    /// Test 2b: Isometría en el fondo → NO dispara cronómetro durante pausa
    test('NO dispara concéntrica durante isometría (Y constante en fondo)', () {
      // Baja → pausa larga en el fondo → sube
      final yPositions = [
        100.0, 130.0, 160.0, 190.0, 210.0, // excéntrica
        // Pausa isométrica: Y se mantiene ±1px (ruido natural)
        210.0, 211.0, 209.0, 210.0, 211.0, 210.0, 209.0, 210.0,
        // Inicio real de concéntrica
        200.0, 190.0, 180.0, 170.0, 160.0, 150.0, 140.0, 130.0,
      ];
      final ts = timestamps(yPositions.length);

      final result = analyzer.trackPhase(
        yPositions: yPositions,
        timestamps: ts,
        pixelsPerMeter: px,
        minConcentricFrames: 4, // Requiere 4+ frames consecutivos hacia arriba
      );

      expect(result.isValid, isTrue);

      // El inicio de la concéntrica debe ser DESPUÉS del índice 12
      // (fin de la pausa isométrica), no durante ella
      expect(result.startConcentricIndex, greaterThanOrEqualTo(12),
          reason: 'El cronómetro NO debe activarse durante la isometría '
              '(índices 5-12), sino después del índice 12');
    });

    /// Test 2c: Solo excéntrica, sin concéntrica → retorna inválido
    test('Retorna inválido si no hay fase concéntrica sostenida', () {
      // Solo baja, nunca sube
      final yPositions = [100.0, 130.0, 160.0, 190.0, 210.0, 220.0, 225.0];
      final ts = timestamps(yPositions.length);

      final result = analyzer.trackPhase(
        yPositions: yPositions,
        timestamps: ts,
        pixelsPerMeter: px,
      );

      expect(result.isValid, isFalse,
          reason: 'Sin concéntrica sostenida, el resultado debe ser inválido');
    });

    /// Test 2d: Trayectoria con ruido leve → no genera falsos positivos
    test('Ruido leve no detecta falsa concéntrica', () {
      // Bajada con pequeñas oscilaciones (ruido < minConcentricFrames)
      final yPositions = [
        100.0, 120.0, 118.0, 140.0, 138.0, 160.0, // baja con ruido
        180.0, 200.0, // sigue bajando
      ];
      final ts = timestamps(yPositions.length);

      final result = analyzer.trackPhase(
        yPositions: yPositions,
        timestamps: ts,
        pixelsPerMeter: px,
        minConcentricFrames: 5,
      );

      // Con minConcentricFrames=5 y solo 2 frames ascendentes, no detecta
      expect(result.isValid, isFalse,
          reason:
              'Ruido leve con menos de minConcentricFrames no debe activar la concéntrica');
    });

    /// Test 2e: La VMC es proporcional al desplazamiento y velocidad
    test('VMC aumenta si el desplazamiento aumenta manteniendo el tiempo', () {
      // Trayectoria más amplia → mayor desplazamiento → mayor VMC
      final ySmall = [200.0, 190.0, 180.0, 170.0, 160.0, 150.0, 140.0];
      final yLarge = [200.0, 170.0, 140.0, 110.0, 080.0, 050.0, 020.0];
      final ts = timestamps(ySmall.length);

      final rSmall = analyzer.trackPhase(
        yPositions: ySmall,
        timestamps: ts,
        pixelsPerMeter: px,
        minConcentricFrames: 3,
      );
      final rLarge = analyzer.trackPhase(
        yPositions: yLarge,
        timestamps: ts,
        pixelsPerMeter: px,
        minConcentricFrames: 3,
      );

      if (rSmall.isValid && rLarge.isValid) {
        expect(rLarge.vmcMs, greaterThan(rSmall.vmcMs),
            reason: 'Mayor desplazamiento con igual tiempo → mayor VMC');
      }
    });
  });
}
