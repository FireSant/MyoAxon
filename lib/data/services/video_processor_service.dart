import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoProcessResult {
  final Directory cacheDir;
  final List<File> frames;
  final double fps;

  VideoProcessResult({
    required this.cacheDir,
    required this.frames,
    required this.fps,
  });
}

class VideoProcessorService {
  /// Extrae una tira de imágenes (thumbnails) para el mosaico
  Future<List<String>> generateThumbnailStrip(
      String videoPath, int durationMs, int intervalMs) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
        '${tempDir.path}/axon_thumbs_${DateTime.now().millisecondsSinceEpoch}');
    await cacheDir.create();

    List<Future<String?>> tasks = [];
    int frameCount = 0;

    for (int timeMs = 0; timeMs <= durationMs; timeMs += intervalMs) {
      final fileName = 'thumb_${frameCount.toString().padLeft(4, '0')}.jpg';
      final path = '${cacheDir.path}/$fileName';
      tasks.add(VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: path,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        quality: 10, // Baja calidad para carga ultra rápida del mosaico
      ));
      frameCount++;
    }

    final results = await Future.wait(tasks);
    return results.whereType<String>().toList();
  }

  /// Extrae un frame en alta calidad en un milisegundo exacto (Despegue / Aterrizaje)
  Future<String?> extractHighResFrame(String videoPath, int timeMs) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'frame_${timeMs}ms_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = '${tempDir.path}/$fileName';

    return await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: targetPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      quality: 100, // Alta calidad para precisión de píxeles
    );
  }

  /// Extrae una secuencia completa de frames para análisis automático en Isolate.
  Future<VideoProcessResult> extractFrameSequence(
      String videoPath, int targetFps, int durationMs) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
        '${tempDir.path}/axon_seq_${DateTime.now().millisecondsSinceEpoch}');
    await cacheDir.create();

    final int intervalMs = (1000 / targetFps).round();
    List<File> frames = [];

    // Extraemos frames en un bucle controlado por la duración
    for (int timeMs = 0; timeMs <= durationMs; timeMs += intervalMs) {
      final path = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath:
            '${cacheDir.path}/frame_${(timeMs ~/ intervalMs).toString().padLeft(4, '0')}.jpg',
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        quality: 50,
      );
      if (path != null) frames.add(File(path));

      // Seguridad: No extraer más de 500 frames por sesión para evitar OOM
      if (frames.length > 500) break;
    }

    return VideoProcessResult(
      cacheDir: cacheDir,
      frames: frames,
      fps: targetFps.toDouble(),
    );
  }

  /// Limpia la carpeta temporal.
  Future<void> clearCache(Directory cacheDir) async {
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
