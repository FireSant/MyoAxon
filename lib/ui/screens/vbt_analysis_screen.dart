import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../data/models/axon_analysis_model.dart';
import '../../data/services/vbt_analyzer_service.dart';
import '../../data/services/video_processor_service.dart';
import '../../providers/axon_lab_provider.dart';
import '../../providers/auth_provider.dart';

class VbtAnalysisScreen extends ConsumerStatefulWidget {
  final double diskDiameterMeters;
  const VbtAnalysisScreen({super.key, required this.diskDiameterMeters});

  @override
  ConsumerState<VbtAnalysisScreen> createState() => _VbtAnalysisScreenState();
}

class _VbtAnalysisScreenState extends ConsumerState<VbtAnalysisScreen> {
  final _picker = ImagePicker();
  final _videoProcessor = VideoProcessorService();

  File? _videoFile;
  VideoPlayerController? _videoCtrl;

  bool _isProcessing = false;
  String _statusText = 'Selecciona un video';
  double _progress = 0;

  VbtResult? _result;

  // ignore: prefer_final_fields
  String _folderName = 'Potencia y Gimnasio (VBT)';
  String _exerciseLabel = 'Sentadilla Posterior';
  static const List<String> _exercises = [
    'Sentadilla Posterior',
    'Sentadilla Frontal',
    'Arranque',
    'Cargada',
    'Press Banca',
    'Peso Muerto'
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
        _result = null;
        _statusText = 'Video cargado. Presiona Procesar.';
      });

      await _initVideoPlayer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      _statusText = '1/2: FFmpeg extrayendo cuadros...';
      _progress = 0.3;
    });

    VideoProcessResult? processResult;
    try {
      processResult = await _videoProcessor.extractFrames(_videoFile!.path);
      if (processResult.frames.isEmpty) {
        throw Exception('No se extrajeron frames.');
      }

      setState(() {
        _statusText = '2/2: Analizando VBT (Isolate)...';
        _progress = 0.6;
      });

      final rootToken = RootIsolateToken.instance!;
      final framePaths = processResult.frames.map((f) => f.path).toList();

      final result = await Isolate.run(() => _analyzeFramesIsolate(
            token: rootToken,
            framePaths: framePaths,
            fps: processResult!.fps,
            diskMeters: widget.diskDiameterMeters,
          ));

      setState(() {
        _result = result;
        _isProcessing = false;
        _statusText = result.isValid
            ? 'Análisis completado: VMC ${result.vmcMs.toStringAsFixed(2)} m/s'
            : 'No se detectó fase concéntrica sostenida';
        _progress = 1.0;
        if (result.isValid) _videoCtrl?.play();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error en VBT: $e';
        _progress = 0;
      });
    } finally {
      if (processResult != null) {
        _videoProcessor.clearCache(processResult.cacheDir);
      }
    }
  }

  static Future<VbtResult> _analyzeFramesIsolate({
    required RootIsolateToken token,
    required List<String> framePaths,
    required double fps,
    required double diskMeters,
  }) async {
    // Si bien no usamos PlatformChannels aquí, es buena práctica inicializarlo
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final analyzer = VbtAnalyzerService();
    // Calibración inicial: asumimos que el disco en visual de preview tiene 120px de diámetro real.
    // En video full HD será más, pero usamos un estimado si no hay calibración manual de frame.
    const double diskPx = 200.0;
    final pxPerMeter = analyzer.calibrate(
        diskDiameterMeters: diskMeters, diskDiameterPixels: diskPx);

    final double msPerFrame = 1000.0 / fps;
    List<double> yPositions = [];
    List<int> timestamps = [];

    // Tracker simple (si no detecta, usa la posición anterior para suavizar)
    double lastY = -1;

    for (int i = 0; i < framePaths.length; i++) {
      final bytes = File(framePaths[i]).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      // Extracción RGBA de package:image.
      // decoded.getBytes(order: img.ChannelOrder.rgba) sirve en v4+
      final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);

      // Asumimos Target Color Azul oscuro por defecto para discos bumper?
      // Como ejemplo en este código buscamos un color de alta saturación (ej. discos o marcadores)
      // Para test offline, si `detectDiskCenter` falla por luz usamos la posición previa ± ruido
      final center = analyzer.detectDiskCenter(
        rgbaBytes: rgba,
        width: decoded.width,
        height: decoded.height,
        minSaturation: 0.3, // Menos estricto en offline
      );

      if (center != null) {
        lastY = center['cy']!;
      } else if (lastY == -1) {
        lastY = decoded.height / 2; // Init fallback
      }

      yPositions.add(lastY);
      timestamps.add((i * msPerFrame).round());
    }

    return analyzer.trackPhase(
      yPositions: yPositions,
      timestamps: timestamps,
      pixelsPerMeter: pxPerMeter,
    );
  }

  void _saveResult() async {
    if (_result == null || !_result!.isValid) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final model = AxonAnalysisModel(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      tipo: 'vbt_offline',
      exerciseLabel: _exerciseLabel,
      folderName: _folderName,
      athleteUid: user?.uid ?? '',
      vmcMs: _result!.vmcMs,
      concentricDurationMs: _result!.concentricDurationMs,
      displacementM: _result!.displacementM,
    );

    try {
      await ref.read(axonLabProvider.notifier).saveResult(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ VBT guardado en ADN del Atleta'),
          backgroundColor: Color(0xFF0284C7),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error VBT: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VBT (Offline)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview de Video y Gráfico
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
                          child: VideoPlayer(_videoCtrl!),
                        )
                      else if (_videoFile == null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fitness_center_rounded,
                                color: Colors.white38, size: 48),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _pickVideo,
                              icon:
                                  const Icon(Icons.add_photo_alternate_rounded),
                              label: const Text('Seleccionar Video'),
                              style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7)),
                            )
                          ],
                        ),

                      // Overlay de Chart Fl Chart si hay resultado
                      if (_result != null &&
                          _result!.isValid &&
                          _result!.yPositions.isNotEmpty)
                        Positioned(
                          bottom: 10, left: 10, right: 10,
                          height: 120, // Altura del gráfico mini
                          child: _VbtMiniChart(result: _result!),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                    value: _progress,
                    color: const Color(0xFF0284C7),
                    backgroundColor: Colors.white12),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(_statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center),
            ),

            if (_result != null && _result!.isValid)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric('VMC', '${_result!.vmcMs.toStringAsFixed(2)} m/s',
                        const Color(0xFF38BDF8)),
                    _Metric(
                        'Rango',
                        '${_result!.displacementM.toStringAsFixed(2)} m',
                        Colors.white),
                    _Metric('Tiempo', '${_result!.concentricDurationMs} ms',
                        Colors.white70),
                  ],
                ),
              ),

            // Controles Bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)))),
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
                          icon: const Icon(Icons.network_ping_rounded),
                          label: const Text('Analizar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (_videoFile == null || _isProcessing)
                              ? null
                              : _processVideo,
                        ),
                      ),
                      if (_result != null && _result!.isValid) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _saveResult,
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

// ── Widget que muestra la gráfica de trayectoria Y ──
class _VbtMiniChart extends StatelessWidget {
  final VbtResult result;
  const _VbtMiniChart({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.yPositions.isEmpty) return const SizedBox();

    // Normalizar Y para graficar: fl_chart mapea Y hacia arriba.
    // Nosotros tenemos Y = px (0 en top). Para ver la trayectoria real (barra bajando = chart bajando),
    // invertimos el valor. MAX_Y = 0, MIN_Y = -max_pantalla
    final maxY = result.yPositions.reduce((a, b) => a > b ? a : b);

    final spots = <FlSpot>[];
    for (int i = 0; i < result.yPositions.length; i++) {
      spots.add(FlSpot(i.toDouble(), maxY - result.yPositions[i]));
    }

    // Identificamos inicio de la concéntrica
    final double cx = result.startConcentricIndex.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0284C7),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, data) => spot.x == cx,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF22C55E),
                          strokeWidth: 2,
                          strokeColor: Colors.white)),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
              ),
            ),
          ],
          lineTouchData:
              const LineTouchData(enabled: false), // Desactivar tooltips
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Metric(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]);
}
