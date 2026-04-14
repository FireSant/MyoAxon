import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/axon_analysis_model.dart';
import '../../data/services/plyometry_analyzer_service.dart';
import '../../data/services/video_processor_service.dart';
import '../../providers/axon_lab_provider.dart';
import '../../providers/auth_provider.dart';

class PlyometryAnalysisScreen extends ConsumerStatefulWidget {
  const PlyometryAnalysisScreen({super.key});

  @override
  ConsumerState<PlyometryAnalysisScreen> createState() =>
      _PlyometryAnalysisScreenState();
}

class _PlyometryAnalysisScreenState
    extends ConsumerState<PlyometryAnalysisScreen> {
  final _picker = ImagePicker();
  final _videoProcessor = VideoProcessorService();

  File? _videoFile;
  VideoPlayerController? _videoCtrl;

  bool _isProcessing = false;
  String _statusText = 'Selecciona un video';
  double _progress = 0; // Solo para mostrar un indicador visual simulado o real

  List<PlyometryResult>? _analysisResults;

  // ignore: prefer_final_fields
  String _folderName = 'Pliometría y Carrera';
  String _exerciseLabel = 'CMJ';
  static const List<String> _exercises = [
    'CMJ',
    'SJ',
    'DJ',
    'Bounds',
    'Sprints'
  ];

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      setState(() {
        _videoFile = File(video.path);
        _analysisResults = null;
        _statusText = 'Video cargado. Presiona Procesar.';
      });

      await _initVideoPlayer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cargar video: $e')));
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    if (_videoFile == null) return;
    _videoCtrl?.dispose();
    _videoCtrl = VideoPlayerController.file(_videoFile!);
    await _videoCtrl!.initialize();
    _videoCtrl!.setLooping(true);
    setState(() {});
  }

  Future<void> _processVideo() async {
    if (_videoFile == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = '1/2: Extrayendo cuadros (Nativo)...';
      _progress = 0.3;
    });

    VideoProcessResult? processResult;
    try {
      // 1. Extraer secuencia completa a 30fps para el análisis (RSI)
      final duration = _videoCtrl!.value.duration.inMilliseconds;
      processResult = await _videoProcessor.extractFrameSequence(
          _videoFile!.path, 30, duration);

      if (processResult.frames.isEmpty) {
        throw Exception('No se extrajeron frames.');
      }

      setState(() {
        _statusText = '2/2: Analizando saltos... (ML Kit Isolate)';
        _progress = 0.6;
      });

      // 2. Procesar en Isolate
      final rootToken = RootIsolateToken.instance!;
      final framePaths = processResult.frames.map((f) => f.path).toList();
      final fps = processResult.fps;
      final double videoH = _videoCtrl!.value.size.height.toDouble();

      // Ejecutar Isolate
      final results = await Isolate.run(() => _analyzeFramesIsolate(
            token: rootToken,
            framePaths: framePaths,
            fps: fps,
            videoHeight: videoH,
          ));

      setState(() {
        _analysisResults = results;
        _isProcessing = false;
        _statusText =
            'Análisis completado: ${results.length} salto(s) detectado(s)';
        _progress = 1.0;
        _videoCtrl?.play();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error en análisis: $e';
        _progress = 0;
      });
    } finally {
      if (processResult != null) {
        _videoProcessor.clearCache(processResult.cacheDir);
      }
    }
  }

  // --- Método que se ejecutará en un Isolate separado ---
  static Future<List<PlyometryResult>> _analyzeFramesIsolate({
    required RootIsolateToken token,
    required List<String> framePaths,
    required double fps,
    required double videoHeight,
  }) async {
    // Inicializar canales de plataforma en este Isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final analyzer = PlyometryAnalyzerService();
    // NOTA: Acá se integrará en el futuro el análisis manual o MediaPipe

    return analyzer.results;
  }

  void _saveResults() async {
    if (_analysisResults == null || _analysisResults!.isEmpty) return;

    // Mostramos modal inferno como antes
    // Calculamos los mejores resultados para un resumen o guardamos el mejor RSI
    final bestResult =
        _analysisResults!.reduce((a, b) => a.rsi > b.rsi ? a : b);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlyometrySaveSheetOffline(
        bestResult: bestResult,
        totalJumps: _analysisResults!.length,
        exerciseLabel: _exerciseLabel,
        folderName: _folderName,
        onSave: (label, folder) async {
          final user = ref.read(authStateProvider).valueOrNull;
          final model = AxonAnalysisModel(
            id: const Uuid().v4(),
            timestamp: DateTime.now(),
            tipo: 'plyometry_offline',
            exerciseLabel: label,
            folderName: folder,
            athleteUid: user?.uid ?? '',
            flightTimeMs: bestResult.flightTimeMs,
            contactTimeMs: bestResult.contactTimeMs,
            rsi: bestResult.rsi,
          );
          try {
            await ref.read(axonLabProvider.notifier).saveResult(model);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Mejor RSI guardado en ADN del Atleta'),
                backgroundColor: Color(0xFF7C3AED),
              ));
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('❌ Error al guardar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('RSI Pliometría (Offline)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Preview Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
                        AspectRatio(
                          aspectRatio: _videoCtrl!.value.aspectRatio,
                          child: Stack(
                            children: [
                              VideoPlayer(_videoCtrl!),
                              if (_analysisResults != null)
                                Positioned.fill(
                                  child: _VideoOverlaySync(
                                    controller: _videoCtrl!,
                                    results: _analysisResults!,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else if (_videoFile == null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.video_library_rounded,
                                color: Colors.white38, size: 48),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _pickVideo,
                              icon:
                                  const Icon(Icons.add_photo_alternate_rounded),
                              label: const Text('Seleccionar Video'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                              ),
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress Indicator
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                        value: _progress,
                        color: const Color(0xFF7C3AED),
                        backgroundColor: Colors.white12),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            // Status Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            // Control Panel
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(
                    top:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _exerciseLabel,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white54),
                            onChanged: _isProcessing
                                ? null
                                : (v) => setState(() => _exerciseLabel = v!),
                            items: _exercises
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                          ),
                        ),
                      ),
                      if (_videoFile != null)
                        TextButton(
                          onPressed: _isProcessing ? null : _pickVideo,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white60),
                          child: const Text('Cambiar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Analizar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (_videoFile == null || _isProcessing)
                              ? null
                              : _processVideo,
                        ),
                      ),
                      if (_analysisResults != null &&
                          _analysisResults!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _saveResults,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sync Visual: Muestra el estado del RSI encima del video reproduciéndose ──
class _VideoOverlaySync extends StatefulWidget {
  final VideoPlayerController controller;
  final List<PlyometryResult> results;

  const _VideoOverlaySync({required this.controller, required this.results});

  @override
  State<_VideoOverlaySync> createState() => _VideoOverlaySyncState();
}

class _VideoOverlaySyncState extends State<_VideoOverlaySync> {
  PlyometryResult? _currentJump;
  String _phaseLabel = '';
  Color _phaseColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    final ms = widget.controller.value.position.inMilliseconds;

    // Buscar en qué fase está el video actual
    PlyometryResult? jump;
    String label = '';
    Color color = Colors.transparent;

    for (final r in widget.results) {
      if (ms >= r.groundedMs && ms <= r.landingMs) {
        jump = r;
        if (ms < r.takeoffMs) {
          label = '🟢 CONTACTO';
          color = const Color(0xFF22C55E);
        } else {
          label = '🔵 VUELO';
          color = const Color(0xFF38BDF8);
        }
        break;
      }
    }

    if (_currentJump != jump || _phaseLabel != label) {
      setState(() {
        _currentJump = jump;
        _phaseLabel = label;
        _phaseColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentJump == null) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _phaseColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _phaseLabel,
              style: TextStyle(
                  color: _phaseColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('RSI: ${_currentJump!.rsi.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFFAD85FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(
                    'TV: ${_currentJump!.flightTimeMs}ms  TC: ${_currentJump!.contactTimeMs}ms',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ── Botonera de Guardado ───────────────────────────────────────────────
class _PlyometrySaveSheetOffline extends StatefulWidget {
  final PlyometryResult bestResult;
  final int totalJumps;
  final String exerciseLabel, folderName;
  final Future<void> Function(String label, String folder) onSave;

  const _PlyometrySaveSheetOffline({
    required this.bestResult,
    required this.totalJumps,
    required this.exerciseLabel,
    required this.folderName,
    required this.onSave,
  });

  @override
  State<_PlyometrySaveSheetOffline> createState() =>
      _PlyometrySaveSheetOfflineState();
}

class _PlyometrySaveSheetOfflineState
    extends State<_PlyometrySaveSheetOffline> {
  late String _label;
  late String _folder;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _label = widget.exerciseLabel;
    _folder = widget.folderName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Resumen del Set (Mejor RSI)',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _R('TV', '${widget.bestResult.flightTimeMs} ms',
                  const Color(0xFF38BDF8)),
              _R('TC', '${widget.bestResult.contactTimeMs} ms',
                  const Color(0xFF22C55E)),
              _R('RSI Max', widget.bestResult.rsi.toStringAsFixed(2),
                  const Color(0xFFAD85FF)),
              _R('Saltos', '${widget.totalJumps}', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Carpeta de análisis',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
            ),
            controller: TextEditingController(text: _folder),
            onChanged: (v) => _folder = v,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save_alt_rounded),
              label:
                  Text(_saving ? 'Guardando...' : 'Guardar en ADN del Atleta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave(_label, _folder);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _R extends StatelessWidget {
  final String label, value;
  final Color color;
  const _R(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]);
}
