import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import '../data/models/vbt_analysis_session.dart';

class VBTAnalysisNotifier extends StateNotifier<VBTAnalysisSession> {
  VBTAnalysisNotifier() : super(VBTAnalysisSession());

  final ImagePicker _picker = ImagePicker();

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      double detectedFps = 30.0;
      if (!kIsWeb) {
        try {
          final videoInfo = FlutterVideoInfo();
          final info = await videoInfo.getVideoInfo(video.path);
          if (info != null && info.framerate != null) {
            detectedFps = info.framerate!;
          }
        } catch (e) {
          debugPrint('Error leyendo FPS del video: $e');
        }
      }
      
      state = state.copyWith(videoPath: video.path, reps: [], fps: detectedFps);
    }
  }

  void setFps(double fps) {
    state = state.copyWith(fps: fps);
  }

  void setExercise(String exercise) {
    state = state.copyWith(exerciseType: exercise);
  }

  void setRom(double romCm) {
    state = state.copyWith(romCm: romCm);
  }

  void setTargetVmc(double vmc) {
    state = state.copyWith(targetVmc: vmc);
  }

  void setPesoKg(double peso) {
    state = state.copyWith(pesoKg: peso);
  }

  void setBodyPart(String part) {
    state = state.copyWith(bodyPart: part);
  }

  void addRepetition(int frameStart, int frameEnd) {
    final double timeS = (frameEnd - frameStart) / state.fps;
    final double vmc = (state.romCm / 100.0) / timeS;

    final newRep = VBTRepetition(
      id: state.reps.length + 1,
      frameStart: frameStart,
      frameEnd: frameEnd,
      vmc: double.parse(vmc.toStringAsFixed(2)),
      tiempoS: double.parse(timeS.toStringAsFixed(2)),
    );

    state = state.copyWith(
      reps: [...state.reps, newRep],
      isMarkingStart: true,
    );
  }

  void removeRepetition(int id) {
    final updatedReps = state.reps.where((r) => r.id != id).toList();
    // Re-indexar para mantener 1, 2, 3...
    final reindexedReps = List.generate(updatedReps.length, (index) {
      final oldRep = updatedReps[index];
      return VBTRepetition(
        id: index + 1,
        frameStart: oldRep.frameStart,
        frameEnd: oldRep.frameEnd,
        vmc: oldRep.vmc,
        tiempoS: oldRep.tiempoS,
      );
    });
    state = state.copyWith(reps: reindexedReps);
  }

  void toggleMarkingMode() {
    state = state.copyWith(isMarkingStart: !state.isMarkingStart);
  }

  void resetSession() {
    state = VBTAnalysisSession();
  }
}

final vbtAnalysisProvider =
    StateNotifierProvider<VBTAnalysisNotifier, VBTAnalysisSession>((ref) {
  return VBTAnalysisNotifier();
});
