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

  // -- NUEVOS ESTADOS PARA MOSAICO NATIVO --
  List<String> _thumbnailPaths = [];
  bool _isGeneratingMosaico = false;
  int _currentScrollMs = 0;

  // -- NUEVOS ESTADOS PARA CALIBRACIÓN POR TOQUE --
  File? _calibrationFrame; // El frame seleccionado para calibrar
  Offset? _selectedPoint; // Punto tocado por el usuario
  double? _detectedDiameterPx;
  double? _targetHue;
  bool _isCalibrating = false;
  double _pixelsPerMeter = 1.0;

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

  Future<void> _generateMosaico() async {
    if (_videoFile == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = '1/2: Generando Mosaico Nativo...';
      _progress = 0.1;
    });

    try {
      final int duration = _videoCtrl!.value.duration.inMilliseconds;
      // Generamos un thumb cada 200ms para una navegación fluida
      _thumbnailPaths = await _videoProcessor.generateThumbnailStrip(
          _videoFile!.path, duration, 200);

      setState(() {
        _isProcessing = false;
        _isGeneratingMosaico = true;
        _statusText = '🎞️ Desliza para buscar el inicio del movimiento';
        _progress = 0.5;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error en Mosaico: $e';
      });
    }
  }

  Future<void> _confirmMosaicoFrame() async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Extrayendo cuadro de alta resolución...';
    });

    final framePath = await _videoProcessor.extractHighResFrame(
        _videoFile!.path, _currentScrollMs);

    if (framePath != null) {
      setState(() {
        _calibrationFrame = File(framePath);
        _isCalibrating = true;
        _isGeneratingMosaico = false;
        _isProcessing = false;
        _statusText = '🎯 Toca el CENTRO del disco para calibrar';
      });
    }
  }

  VideoProcessResult? _lastProcessResult;

  void _onCalibrationTap(Offset localPosition, double containerWidth,
      double containerHeight) async {
    if (_calibrationFrame == null || !_isCalibrating || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Detectando disco...';
    });

    final bytes = await _calibrationFrame!.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    // Mapeo de coordenadas locales de la UI a coordenadas reales de la imagen
    final double scaleX = decoded.width / containerWidth;
    final double scaleY = decoded.height / containerHeight;
    final int cx = (localPosition.dx * scaleX).round();
    final int cy = (localPosition.dy * scaleY).round();

    final analyzer = VbtAnalyzerService();
    final color = analyzer.sampleColorAt(
        decoded.getBytes(order: img.ChannelOrder.rgba), decoded.width, cx, cy);

    final diameter = analyzer.detectDiameterFromPoint(
        decoded.getBytes(order: img.ChannelOrder.rgba),
        decoded.width,
        decoded.height,
        cx,
        cy,
        color[0]);

    setState(() {
      _selectedPoint = localPosition;
      _detectedDiameterPx = diameter;
      _targetHue = color[0];
      _pixelsPerMeter = diameter / widget.diskDiameterMeters;
      _isProcessing = false;
      _statusText =
          'Disco detectado (${diameter.toStringAsFixed(1)}px). ¿Correcto?';
    });
  }

  Future<void> _startFinalAnalysis() async {
    if (_videoFile == null || _targetHue == null) return;

    setState(() {
      _isProcessing = true;
      _isCalibrating = false;
      _statusText = '1/2: Extrayendo frames (Secuencia Nativa)...';
      _progress = 0.7;
    });

    try {
      // 1. Extraer secuencia completa a 30fps para el tracking
      final duration = _videoCtrl!.value.duration.inMilliseconds;
      _lastProcessResult = await _videoProcessor.extractFrameSequence(
          _videoFile!.path, 30, duration);

      if (_lastProcessResult == null || _lastProcessResult!.frames.isEmpty) {
        throw Exception('No se pudieron extraer los frames para el análisis.');
      }

      setState(() {
        _statusText = '2/2: Analizando trayectoria (Isolate)...';
        _progress = 0.9;
      });

      // 2. Ejecutar análisis en Isolate
      final rootToken = RootIsolateToken.instance!;
      final List<String> framePaths =
          _lastProcessResult!.frames.map((File f) => f.path).toList();

      final result = await Isolate.run(() => _analyzeFramesIsolate(
            token: rootToken,
            framePaths: framePaths,
            fps: _lastProcessResult!.fps,
            pxPerMeter: _pixelsPerMeter,
            targetHue: _targetHue!,
          ));

      setState(() {
        _result = result;
        _isProcessing = false;
        _statusText = result.isValid
            ? 'VMC: ${result.vmcMs.toStringAsFixed(2)} m/s'
            : 'Fase concéntrica no detectada o muy corta';
        _progress = 1.0;
        if (result.isValid) _videoCtrl?.play();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error: $e';
      });
    } finally {
      if (_lastProcessResult != null) {
        _videoProcessor.clearCache(_lastProcessResult!.cacheDir);
        _lastProcessResult = null;
      }
    }
  }

  static Future<VbtResult> _analyzeFramesIsolate({
    required RootIsolateToken token,
    required List<String> framePaths,
    required double fps,
    required double pxPerMeter,
    required double targetHue,
  }) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final analyzer = VbtAnalyzerService();

    final double msPerFrame = 1000.0 / fps;
    List<double> rawY = [];
    List<int> timestamps = [];

    double lastY = -1;

    for (int i = 0; i < framePaths.length; i++) {
      final bytes = File(framePaths[i]).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
      final center = analyzer.detectDiskCenter(
        rgbaBytes: rgba,
        width: decoded.width,
        height: decoded.height,
        targetHue: targetHue,
        minSaturation: 0.25,
      );

      if (center != null) {
        lastY = center['cy']!;
      }

      if (lastY != -1) {
        rawY.add(lastY);
        timestamps.add((i * msPerFrame).round());
      }
    }

    // Suavizado de trayectoria para evitar "temblor"
    final smoothedY = analyzer.smoothTrajectory(rawY, windowSize: 5);

    return analyzer.trackPhase(
      yPositions: smoothedY,
      timestamps: timestamps,
      pixelsPerMeter: pxPerMeter,
      minConcentricFrames: 5,
      minConcentricDistancePx: 10.0, // Umbral mínimo de subida
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
      pixelsPerMeter: _pixelsPerMeter,
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
        title: Text(_isCalibrating ? 'Calibrar Disco' : 'VBT (Offline)'),
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
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // MODO CALIBRACIÓN (Imagen Estática)
                        if (_isCalibrating && _calibrationFrame != null)
                          GestureDetector(
                            onTapDown: (details) => _onCalibrationTap(
                                details.localPosition,
                                constraints.maxWidth,
                                constraints.maxHeight),
                            child: Stack(
                              children: [
                                Image.file(_calibrationFrame!,
                                    fit: BoxFit.contain,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight),
                                if (_selectedPoint != null)
                                  Positioned(
                                    left: _selectedPoint!.dx - 20,
                                    top: _selectedPoint!.dy - 20,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF22C55E),
                                            width: 2),
                                      ),
                                      child: const Center(
                                          child: Icon(Icons.add,
                                              color: Color(0xFF22C55E),
                                              size: 20)),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        // MODO VIDEO / RESULTADO
                        else if (_videoCtrl != null &&
                            _videoCtrl!.value.isInitialized)
                          AspectRatio(
                            aspectRatio: _videoCtrl!.value.aspectRatio,
                            child: VideoPlayer(_videoCtrl!),
                          )
                        // MODO MOSAICO (Scrubber)
                        else if (_isGeneratingMosaico &&
                            _thumbnailPaths.isNotEmpty)
                          _MosaicoScrubber(
                            thumbnailPaths: _thumbnailPaths,
                            durationMs:
                                _videoCtrl!.value.duration.inMilliseconds,
                            onChanged: (ms) {
                              setState(() => _currentScrollMs = ms);
                              _videoCtrl?.seekTo(Duration(milliseconds: ms));
                            },
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
                                icon: const Icon(
                                    Icons.add_photo_alternate_rounded),
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
                            bottom: 10,
                            left: 10,
                            right: 10,
                            height: 120, // Altura del gráfico mini
                            child: _VbtMiniChart(result: _result!),
                          ),
                      ],
                    );
                  }),
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
              child: Column(
                children: [
                  Text(_statusText,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center),
                  if (_isCalibrating && _detectedDiameterPx != null)
                    Text(
                      'Escala detectada: ${(_detectedDiameterPx! / widget.diskDiameterMeters).toStringAsFixed(1)} px/m',
                      style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
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
                      if (_isCalibrating)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            label: const Text('Confirmar y Analizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (_selectedPoint == null || _isProcessing)
                                ? null
                                : _startFinalAnalysis,
                          ),
                        )
                      else ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(_isGeneratingMosaico
                                ? Icons.check_circle_outline_rounded
                                : Icons.grid_view_rounded),
                            label: Text(_isGeneratingMosaico
                                ? 'Seleccionar este Cuadro'
                                : 'Seleccionar y Calibrar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (_videoFile == null || _isProcessing)
                                ? null
                                : _isGeneratingMosaico
                                    ? _confirmMosaicoFrame
                                    : _generateMosaico,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _saveResult,
                            ),
                          ),
                        ]
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

// ── Widget de Mosaico para Navegación Visual ──
class _MosaicoScrubber extends StatefulWidget {
  final List<String> thumbnailPaths;
  final int durationMs;
  final Function(int) onChanged;

  const _MosaicoScrubber({
    required this.thumbnailPaths,
    required this.durationMs,
    required this.onChanged,
  });

  @override
  State<_MosaicoScrubber> createState() => _MosaicoScrubberState();
}

class _MosaicoScrubberState extends State<_MosaicoScrubber> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.thumbnailPaths.isEmpty) return const SizedBox();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Preview del Thumb actual
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            image: DecorationImage(
              image: FileImage(
                File(widget.thumbnailPaths[
                    (_value * (widget.thumbnailPaths.length - 1)).round()]),
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Slider de Mosaico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Slider(
            value: _value,
            onChanged: (v) {
              setState(() => _value = v);
              final ms = (v * widget.durationMs).round();
              widget.onChanged(ms);
            },
            activeColor: const Color(0xFF0284C7),
            inactiveColor: Colors.white12,
          ),
        ),
        const Text(
          'Desliza para buscar el punto exacto',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
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
