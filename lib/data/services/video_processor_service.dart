import 'dart:io';
// import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
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
  /// Extrae todos los cuadros (frames) de un archivo de video a una carpeta
  /// temporal local y determina la tasa real de cuadros por segundo (FPS).
  Future<VideoProcessResult> extractFrames(String videoPath) async {
    // FFmpeg is temporarily disabled for debugging startup issues
    double fps = 30.0;

    // Preparar el directorio temporal de caché
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
        '${tempDir.path}/axon_frames_${DateTime.now().millisecondsSinceEpoch}');
    await cacheDir.create();

    // Stub result
    return VideoProcessResult(
      cacheDir: cacheDir,
      frames: [],
      fps: fps,
    );
  }

  /// Limpia la carpeta temporal generada tras el análisis.
  Future<void> clearCache(Directory cacheDir) async {
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
