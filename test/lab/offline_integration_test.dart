import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoaxon/data/services/video_processor_service.dart';
import 'package:myoaxon/data/services/vbt_analyzer_service.dart';

void main() {
  group('Análisis Offline (v0.2.0) - Tests de Integración', () {
    /// Test 5: Manejo de FPS Variables
    /// Simularemos la extracción de variables de dos videos ficticios
    /// con la misma trayectoria pero diferentes FPS (30 y 60).
    test('Test 5: Consistencia VMC en diferentes FPS (30 vs 60fps)', () {
      final analyzer = VbtAnalyzerService();
      // Misma subida de 0.5m
      const double pixelsPerMeter = 100.0;

      // Simulación 30fps: 15 frames para recorrer 50px (0.5m)
      final List<double> path30 =
          List.generate(15, (i) => 200.0 - (i * (50 / 14)));
      final ts30 = List.generate(15, (i) => (i * (1000 / 30)).round());

      final res30 = analyzer.trackPhase(
        yPositions: path30.reversed.toList() + path30, // Baja y sube
        timestamps: [
          ...ts30,
          ...List.generate(15, (i) => ts30.last + ((i + 1) * 1000 / 30).round())
        ],
        pixelsPerMeter: pixelsPerMeter,
      );

      // Simulación 60fps: 30 frames para la misma distancia (el doble de resolución)
      final List<double> path60 =
          List.generate(30, (i) => 200.0 - (i * (50 / 29)));
      final ts60 = List.generate(30, (i) => (i * (1000 / 60)).round());

      final res60 = analyzer.trackPhase(
        yPositions: path60.reversed.toList() + path60,
        timestamps: [
          ...ts60,
          ...List.generate(30, (i) => ts60.last + ((i + 1) * 1000 / 60).round())
        ],
        pixelsPerMeter: pixelsPerMeter,
      );

      expect(res30.isValid, isTrue);
      expect(res60.isValid, isTrue);

      // La velocidad media (m/s) debe ser idéntica (dentro de un margen de redondeo natural)
      // Ambos tardan ~0.5 segundos en subir 0.5 metros -> ~1.0 m/s
      expect(res30.vmcMs, closeTo(1.0, 0.05));
      expect(res60.vmcMs, closeTo(1.0, 0.05));
      expect((res30.vmcMs - res60.vmcMs).abs(), lessThan(0.02),
          reason: 'La independencia del FPS mantiene la VMC pura');
    });

    /// Test 6: Integridad de Caché y Storage tras el análisis
    test('Test 6: Limpieza recursiva de frames en memoria/cache temporal',
        () async {
      // Mockear la creación de un directorio real en la máquina host
      final tempDir = Directory.systemTemp.createTempSync('axon_cache_test_');

      // Llenar con archivos "frames"
      for (int i = 0; i < 100; i++) {
        // Simulamos 100 frames
        File('${tempDir.path}/frame_$i.jpg').createSync();
      }

      expect(tempDir.listSync().length, equals(100));

      final service = VideoProcessorService();
      await service.clearCache(tempDir);

      expect(tempDir.existsSync(), isFalse,
          reason: 'El directorio debe eliminarse para evitar leaks de memoria');
    });
  });
}
