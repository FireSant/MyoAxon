import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/vbt_analysis_provider.dart';
import '../../data/models/vbt_analysis_session.dart';
import '../widgets/stepper_input_card.dart';
import '../widgets/frame_control_panel.dart';

class AxonVBTScreen extends ConsumerStatefulWidget {
  const AxonVBTScreen({super.key});

  @override
  ConsumerState<AxonVBTScreen> createState() => _AxonVBTScreenState();
}

class _AxonVBTScreenState extends ConsumerState<AxonVBTScreen> {
  int _currentStep = 0;
  VideoPlayerController? _controller;
  int? _lastMarkedStart;
  bool _isVideoLoading = false;
  late TextEditingController _romController;
  late TextEditingController _vmcController;
  late TextEditingController _pesoController;
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // _romController and _vmcController will be initialized in build or initialized with defaults
    _romController = TextEditingController(text: '50.0');
    _vmcController = TextEditingController(text: '0.50');
    _pesoController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _romController.dispose();
    _vmcController.dispose();
    _pesoController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideo(String path) async {
    setState(() => _isVideoLoading = true);
    if (_controller != null) await _controller!.dispose();
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }
    await _controller!.initialize();
    setState(() => _isVideoLoading = false);
  }

  void _next() {
    final vbtState = ref.read(vbtAnalysisProvider);
    if (_currentStep == 0) {
      if (vbtState.romCm <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debes especificar un ROM mayor a 0 cm')),
        );
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _shareResults() async {
    try {
      // Pequeño retraso para asegurar que el RepaintBoundary se haya procesado
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw 'No se pudo encontrar el área de captura.';
      }

      // Si aún necesita pintarse, esperamos un poco más
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        _showSharePreview(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar tarjeta: $e')));
      }
    }
  }

  void _showSharePreview(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('PREVIEW DE EXPORTACIÓN',
                  style: TextStyle(letterSpacing: 2, fontSize: 14)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(imageBytes),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                children: [
                  if (!kIsWeb)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            final tempDir = await getTemporaryDirectory();
                            final file = File(
                                '${tempDir.path}/axon_results_${DateTime.now().millisecondsSinceEpoch}.png');
                            await file.writeAsBytes(imageBytes, flush: true);
                            // No esperamos el resultado para evitar LateInitializationError en algunos drivers de Android
                            Share.shareXFiles([XFile(file.path)],
                                text: 'Mis resultados de MyoAxon ⚡');
                          } catch (e) {
                            debugPrint('Error sharing: $e');
                          }
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('COMPARTIR'),
                      ),
                    ),
                  if (!kIsWeb) const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _downloadImage(imageBytes),
                      icon: const Icon(Icons.download),
                      label:
                          const Text(kIsWeb ? 'DESCARGAR IMAGEN' : 'GUARDAR'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(Uint8List bytes) async {
    if (kIsWeb) {
      try {
        // En Web, XFile.saveTo genera automáticamente un link de descarga.
        final xFile = XFile.fromData(bytes,
            name: 'axon_vbt_results.png', mimeType: 'image/png');
        await xFile.saveTo('axon_vbt_results.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Descarga iniciada...')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error al descargar: $e')));
        }
      }
    } else {
      try {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          final file = File(
              '${directory.path}/axon_vbt_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Imagen guardada en Descargas')));
          }
        } else {
          // Fallback a path_provider si no existe la ruta directa
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/axon_results.png');
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Imagen preparada. Usa Compartir para guardar.')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      }
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vbtState = ref.watch(vbtAnalysisProvider);
    final vbtNotifier = ref.read(vbtAnalysisProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Axon VBT'),
        centerTitle: true,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                vbtNotifier.resetSession();
                setState(() => _currentStep = 0);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                StepperInputCard(
                  label: 'Paso ${_currentStep + 1}/3',
                  value: _currentStep + 1,
                  onDecrement: _back,
                  onIncrement: _next,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildStepContent(vbtState, vbtNotifier),
                ),
              ],
            ),
            // Widget de captura (Fuera de la pantalla para que se pinte pero no se vea)
            Positioned(
              left: -3000,
              child: RepaintBoundary(
                key: _shareKey,
                child: _buildShareableCard(vbtState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(vbtState, vbtNotifier) {
    switch (_currentStep) {
      case 0:
        return _buildStepParams(vbtState, vbtNotifier);
      case 1:
        return _buildStepMedia(vbtState, vbtNotifier);
      case 2:
        return _buildStepAnalysis(vbtState, vbtNotifier);
      default:
        return const SizedBox();
    }
  }

  // --- PASO 1: MEDIA ---
  Widget _buildStepMedia(vbtState, vbtNotifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.movie_filter_outlined,
            size: 100, color: Colors.blueGrey),
        const SizedBox(height: 24),
        const Text(
          'Selecciona el video del levantamiento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () async {
            await vbtNotifier.pickVideo();
            if (ref.read(vbtAnalysisProvider).videoPath != null) {
              _next();
              _initVideo(ref.read(vbtAnalysisProvider).videoPath!);
            }
          },
          icon: const Icon(Icons.video_library),
          label: const Text('ABRIR GALERÍA'),
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
        ),
      ],
    );
  }

  // --- PASO 2: ANÁLISIS ---
  Widget _buildStepAnalysis(vbtState, vbtNotifier) {
    if (_isVideoLoading) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Procesando video...'),
      ]));
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: Text('Error al cargar el video.'));
    }

    final videoWidget = ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              VideoPlayer(_controller!),
              // Technical OSD Overlay (Benchmark Style)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.greenAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pequeño indicador de "Live"
                      const Icon(Icons.circle,
                          size: 8, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Text(
                        'METADATA: ${vbtState.fps.toInt()} FPS',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Technical OSD Overlay (Bottom Right - Info)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AXON_CORE_V0.6.2',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final controlsAndListWidget = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('FPS del video:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<double>(
              value: vbtState.fps,
              items: [30.0, 60.0, 120.0, 240.0].map((fps) {
                return DropdownMenuItem(
                    value: fps, child: Text('${fps.toInt()}'));
              }).toList(),
              onChanged: (val) {
                if (val != null) vbtNotifier.setFps(val);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        FrameControlPanel(
          fps: vbtState.fps,
          controller: _controller!,
          isMarkingStart: vbtState.isMarkingStart,
          onMarkStart: (frame) {
            _lastMarkedStart = frame;
            vbtNotifier.toggleMarkingMode();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Inicio marcado en frame $frame'),
                  duration: const Duration(seconds: 1)),
            );
          },
          onMarkEnd: (frame) {
            if (_lastMarkedStart != null) {
              vbtNotifier.addRepetition(_lastMarkedStart!, frame);
              _lastMarkedStart = null;
            }
          },
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Repeticiones marcadas:',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vbtState.reps.length,
          itemBuilder: (context, index) {
            final rep = vbtState.reps[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('Tiempo: ${rep.tiempoS.toStringAsFixed(2)} s',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Frames: ${rep.frameStart} - ${rep.frameEnd}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${rep.vmc.toStringAsFixed(2)} m/s',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => vbtNotifier.removeRepetition(rep.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        if (vbtState.reps.isNotEmpty) _buildSummarySection(vbtState),
        if (vbtState.reps.isNotEmpty) const SizedBox(height: 24),
        if (vbtState.reps.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareResults,
              icon: const Icon(Icons.share),
              label: const Text('COMPARTIR RESULTADOS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );

    final bool isWide = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: videoWidget),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: controlsAndListWidget),
              ],
            )
          : Column(
              children: [
                videoWidget,
                const SizedBox(height: 16),
                controlsAndListWidget,
              ],
            ),
    );
  }

  // --- PASO 1: PARÁMETROS ---
  Widget _buildStepParams(vbtState, vbtNotifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text('Configuración del Ejercicio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: vbtState.bodyPart,
            decoration: const InputDecoration(
                labelText: 'Tren Corporal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.accessibility_new)),
            items: ['Tren Superior', 'Tren Inferior']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => vbtNotifier.setBodyPart(val!),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: vbtState.exerciseType,
            decoration: const InputDecoration(
                labelText: 'Ejercicio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center)),
            items: [
              'Sentadilla',
              'Press de Banca',
              'Peso Muerto',
              'Press Militar',
              'Remo'
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => vbtNotifier.setExercise(val!),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _pesoController,
            decoration: const InputDecoration(
              labelText: 'Carga de Entrenamiento (kg)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.replaceAll(',', '.'),
                  selection: newValue.selection,
                );
              }),
            ],
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) vbtNotifier.setPesoKg(parsed);
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _vmcController,
            decoration: const InputDecoration(
              labelText: 'VMC Objetivo (m/s)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.speed),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.replaceAll(',', '.'),
                  selection: newValue.selection,
                );
              }),
            ],
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) vbtNotifier.setTargetVmc(parsed);
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _romController,
            decoration: const InputDecoration(
              labelText: 'ROM - Rango de Movimiento (cm)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.replaceAll(',', '.'),
                  selection: newValue.selection,
                );
              }),
            ],
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) vbtNotifier.setRom(parsed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(VBTAnalysisSession vbtState) {
    final bestVmc = vbtState.bestVmc;
    final variation = vbtState.speedVariation;
    final displayVariation = variation.abs();

    Color variationColor = Colors.orange;
    if (variation < 0) {
      variationColor = Colors.green;
    } else if (variation > 15 || bestVmc < 0.35) {
      variationColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: variationColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: variationColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('RESUMEN DE SERIE',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Velocidad Mejor:'),
              Text('${bestVmc.toStringAsFixed(2)} m/s',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Velocidad Media:'),
              Text('${vbtState.avgVmc.toStringAsFixed(2)} m/s',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Velocidad Mínima:'),
              Text('${vbtState.minVmc.toStringAsFixed(2)} m/s',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pérdida de Velocidad:'),
              Text('${displayVariation.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Coef. de Variación (CV):'),
              Text('${vbtState.coeficienteVariacion.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAdvancedStats(VBTAnalysisSession vbtState) {
    if (vbtState.reps.isEmpty) {
      return {'zone': 'N/A', 'rmKg': 'N/A', 'potencia': 'N/A'};
    }
    final isLowerBody = vbtState.bodyPart == 'Tren Inferior';
    final v = vbtState.bestVmc;

    String zoneName = '';
    if (isLowerBody) {
      if (v > 1.30) {
        zoneName = 'Velocidad Máxima';
      } else if (v >= 1.10) {
        zoneName = 'Velocidad - Fuerza';
      } else if (v >= 0.80) {
        zoneName = 'Fuerza - Velocidad';
      } else if (v >= 0.60) {
        zoneName = 'Fuerza Submáxima - Hipertrofia';
      } else {
        zoneName = 'Fuerza Máxima';
      }
    } else {
      if (v > 1.30) {
        zoneName = 'Velocidad Máxima';
      } else if (v >= 1.00) {
        zoneName = 'Velocidad - Fuerza';
      } else if (v >= 0.80) {
        zoneName = 'Fuerza - Velocidad';
      } else if (v >= 0.50) {
        zoneName = 'Fuerza Submáxima';
      } else {
        zoneName = 'Fuerza Máxima';
      }
    }

    double pctRm = 0.0;
    if (isLowerBody) {
      // Polinómica Tren Inferior: -1.133x² - 42.171x + 103.38
      pctRm = (-1.133 * math.pow(v, 2)) - (42.171 * v) + 103.38;
    } else {
      // Polinómica Tren Superior: -5.961x² - 56.485x + 117.09
      pctRm = (-5.961 * math.pow(v, 2)) - (56.485 * v) + 117.09;
    }

    // Lógica de seguridad: 10% - 100%
    if (pctRm > 100.0) pctRm = 100.0;
    if (pctRm < 10.0) pctRm = 10.0;

    String rmKg = 'N/A';
    if (vbtState.pesoKg > 0) {
      final rm = (vbtState.pesoKg * 100) / pctRm;
      rmKg = '${rm.toStringAsFixed(1)} kg';
    }

    String potenciaW = 'N/A';
    if (vbtState.pesoKg > 0) {
      final p = vbtState.pesoKg * 9.81 * v; // F * v
      potenciaW = '${p.toStringAsFixed(0)} W';
    }

    return {
      'zone': zoneName,
      'rmKg': rmKg,
      'potencia': potenciaW,
      'pctRm': pctRm.toStringAsFixed(0)
    };
  }

  Widget _buildListRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildShareableCard(VBTAnalysisSession vbtState) {
    final variation = vbtState.speedVariation;
    final isGain = variation < 0;
    final stats = _calculateAdvancedStats(vbtState);

    return Container(
      width: 1080,
      height: 1080,
      color: const Color(0xFF0F172A), // Dark branding
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MyoAxon',
                  style: TextStyle(
                      color: Colors.blue.shade400,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(color: Colors.white70, fontSize: 24)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(vbtState.exerciseType.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              if (vbtState.pesoKg > 0)
                Text('${vbtState.pesoKg.toStringAsFixed(1)} KG',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          Text('ZONA: ${stats['zone']!.toUpperCase()}',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miniatura Gráfica
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blue.shade900, width: 4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildShareCardGraph(vbtState),
                  ),
                ),
                const SizedBox(width: 32),
                // Lista Elegante de Resultados
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildListRow(
                            'Mejor VMC',
                            '${vbtState.bestVmc.toStringAsFixed(2)} m/s',
                            Colors.amber),
                        _buildListRow(
                            'VMC Media',
                            '${vbtState.avgVmc.toStringAsFixed(2)} m/s',
                            Colors.blue.shade300),
                        _buildListRow(
                            'VMC Mínima',
                            '${vbtState.minVmc.toStringAsFixed(2)} m/s',
                            Colors.blueGrey),
                        const Divider(color: Colors.white10),
                        _buildListRow(
                            'Pérdida de Velocidad',
                            '${variation.abs().toStringAsFixed(1)}%',
                            isGain ? Colors.green : Colors.red),
                        _buildListRow(
                            'Coef. de Variación',
                            '${vbtState.coeficienteVariacion.toStringAsFixed(1)}%',
                            Colors.orange),
                        _buildListRow('Repeticiones', '${vbtState.reps.length}',
                            Colors.white),
                        const Divider(color: Colors.white10),
                        _buildListRow(
                            '1RM Estimado', stats['rmKg'], Colors.purpleAccent),
                        _buildListRow('% Estimado', '~${stats['pctRm']}% 1RM',
                            Colors.purpleAccent.withValues(alpha: 0.7)),
                        _buildListRow('Potencia Máx.', stats['potencia'],
                            Colors.cyanAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(
              child: Text('Generado con Axon VBT - Análisis cinemático',
                  style: TextStyle(color: Colors.white38, fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildShareCardGraph(VBTAnalysisSession vbtState) {
    if (vbtState.reps.isEmpty) {
      return const Center(
          child: Icon(Icons.show_chart, size: 120, color: Colors.white24));
    }

    final List<BarChartGroupData> barGroups = [];
    double maxVmc = 0;

    for (int i = 0; i < vbtState.reps.length; i++) {
      final rep = vbtState.reps[i];
      final vmc = (vbtState.romCm / 100) / rep.tiempoS;
      if (vmc > maxVmc) maxVmc = vmc;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: vmc,
              color: vmc >= vbtState.targetVmc
                  ? Colors.blue.shade400
                  : Colors.orange.shade400,
              width: 48,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text('EVOLUCIÓN CINEMÁTICA DE LA SERIE',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 32),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxVmc * 1.3).clamp(0.5, 3.0),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('REPETICIONES',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt() + 1}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('v/s',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.3,
                    getTitlesWidget: (value, meta) {
                      if (value < 0.1) return const SizedBox();
                      return Text(value.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14));
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: vbtState.targetVmc,
                    color: Colors.greenAccent.withValues(alpha: 0.8),
                    strokeWidth: 2,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      labelResolver: (line) => 'OBJETIVO',
                    ),
                  ),
                ],
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}
