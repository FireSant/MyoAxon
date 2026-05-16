import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import '../../config/app_config.dart';
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
  final ScreenshotController _screenshotController = ScreenshotController();

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
      if (vbtState.videoPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes seleccionar un video primero')),
        );
        return;
      }
    }
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _shareResults() async {
    try {
      final vbtState = ref.read(vbtAnalysisProvider);

      // captureFromWidget renderiza el widget a imagen sin montarlo en el árbol.
      // Usa dart:ui PictureRecorder internamente — funciona en todas las plataformas.
      final bytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQueryData.fromView(View.of(context)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _buildShareableCard(vbtState),
          ),
        ),
        targetSize: const Size(1080, 1080),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      if (!mounted) return;
      _showSharePreview(bytes);
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
                            // 1. Guardar en galería (Recientes) primero
                            bool hasAccess = await Gal.hasAccess();
                            if (!hasAccess) {
                              hasAccess = await Gal.requestAccess();
                              if (!hasAccess) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Permiso de galería denegado')),
                                  );
                                }
                                return;
                              }
                            }
                            final timestamp =
                                DateTime.now().millisecondsSinceEpoch;
                            await Gal.putImageBytes(
                              imageBytes,
                              name: 'myoaxon_results_$timestamp',
                              album: 'MyoAxon',
                            );

                            // 2. Guardar en archivo temporal para compartir
                            final tempDir = await getTemporaryDirectory();
                            final file = File(
                                '${tempDir.path}/myoaxon_results_$timestamp.png');
                            await file.writeAsBytes(imageBytes);

                            final xFile = XFile(file.path);

                            await Share.shareXFiles(
                              [xFile],
                              text: 'Mis resultados de MyoAxon ⚡',
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Imagen guardada en Galería (Recientes) y compartida')),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error sharing: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error al compartir: $e')),
                              );
                            }
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
        // Verificar y solicitar permiso de galería
        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          hasAccess = await Gal.requestAccess();
          if (!hasAccess) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso de galería denegado')),
              );
            }
            return;
          }
        }
        // Guardar imagen en galería (aparece en Recientes)
        await Gal.putImageBytes(
          bytes,
          name: 'axon_vbt_${DateTime.now().millisecondsSinceEpoch}',
          album: 'MyoAxon',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Imagen guardada en Galería (Recientes)')),
          );
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
              tooltip: 'Reiniciar sesión',
              onPressed: () {
                vbtNotifier.resetSession();
                _controller?.dispose();
                _controller = null;
                setState(() {
                  _currentStep = 0;
                  _isVideoLoading = false;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepperInputCard(
              label: 'Paso ${_currentStep + 1}/2',
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
      ),
    );
  }

  Widget _buildStepContent(vbtState, vbtNotifier) {
    switch (_currentStep) {
      case 0:
        return _buildStepParams(vbtState, vbtNotifier);
      case 1:
        return _buildStepAnalysis(vbtState, vbtNotifier);
      default:
        return const SizedBox();
    }
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
            ],
          ),
        ),
      ),
    );

    final controlsAndListWidget = Column(
      children: [
        FrameControlPanel(
          controller: _controller!,
          isMarkingStart: vbtState.isMarkingStart,
          fps: vbtState.fps,
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
        if (vbtState.reps.isNotEmpty) _buildSummarySection(context, vbtState),
        if (vbtState.reps.isNotEmpty) const SizedBox(height: 24),
        if (vbtState.reps.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareResults,
              icon: const Icon(Icons.visibility),
              label: const Text('Ver informe completo'),
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

  // --- PASO 1: PARÁMETROS + MEDIA ---
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
          Builder(builder: (context) {
            final isLowerBody = vbtState.bodyPart == 'Tren Inferior';
            final List<String> exerciseOptions = isLowerBody
                ? ['Sentadilla', 'Peso Muerto']
                : ['Press de Banca', 'Press Militar', 'Remo'];

            String selectedExercise = vbtState.exerciseType;
            if (!exerciseOptions.contains(selectedExercise)) {
              selectedExercise = exerciseOptions.first;
              Future.microtask(() {
                vbtNotifier.setExercise(selectedExercise);
              });
            }

            return DropdownButtonFormField<String>(
              key: ValueKey('exercise_${vbtState.bodyPart}'),
              initialValue: selectedExercise,
              decoration: const InputDecoration(
                  labelText: 'Ejercicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center)),
              items: exerciseOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) vbtNotifier.setExercise(val);
              },
            );
          }),
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
          Builder(builder: (context) {
            final isLowerBody = vbtState.bodyPart == 'Tren Inferior';
            final List<Map<String, dynamic>> vmcOptions = isLowerBody
                ? [
                    {'value': 1.30, 'label': '1.30 m/s - Velocidad Máxima'},
                    {'value': 1.10, 'label': '1.10 m/s - Velocidad - Fuerza'},
                    {'value': 0.80, 'label': '0.80 m/s - Fuerza - Velocidad'},
                    {
                      'value': 0.60,
                      'label': '0.60 m/s - Fuerza Submáxima - Hipertrofia'
                    },
                    {'value': 0.30, 'label': '0.30 m/s - Fuerza Máxima'},
                  ]
                : [
                    {'value': 1.10, 'label': '1.10 m/s - Velocidad Máxima'},
                    {'value': 0.80, 'label': '0.80 m/s - Velocidad - Fuerza'},
                    {'value': 0.60, 'label': '0.60 m/s - Fuerza - Velocidad'},
                    {
                      'value': 0.41,
                      'label': '0.41 m/s - Fuerza Submáxima - Hipertrofia'
                    },
                    {'value': 0.17, 'label': '0.17 m/s - Fuerza Máxima'},
                  ];

            double selectedVmc = vbtState.targetVmc;
            if (!vmcOptions.any((opt) => opt['value'] == selectedVmc)) {
              selectedVmc = vmcOptions.reduce((a, b) =>
                  (a['value'] - vbtState.targetVmc).abs() <
                          (b['value'] - vbtState.targetVmc).abs()
                      ? a
                      : b)['value'];
              Future.microtask(() {
                vbtNotifier.setTargetVmc(selectedVmc);
              });
            }

            return DropdownButtonFormField<double>(
              key: ValueKey(vbtState.bodyPart),
              initialValue: selectedVmc,
              decoration: const InputDecoration(
                labelText: 'VMC Objetivo (m/s)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
              items: vmcOptions.map((opt) {
                return DropdownMenuItem<double>(
                  value: opt['value'],
                  child:
                      Text(opt['label'], style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) vbtNotifier.setTargetVmc(val);
              },
            );
          }),
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
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Selección de Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                    vbtState.videoPath == null
                        ? Icons.movie_filter_outlined
                        : Icons.check_circle_outline,
                    size: 80,
                    color: vbtState.videoPath == null
                        ? Colors.blueGrey
                        : Colors.green),
                const SizedBox(height: 16),
                if (vbtState.videoPath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Video: ${vbtState.videoPath!.split('/').last}',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await vbtNotifier.pickVideo();
                    if (ref.read(vbtAnalysisProvider).videoPath != null) {
                      _next();
                      _initVideo(ref.read(vbtAnalysisProvider).videoPath!);
                    }
                  },
                  icon: const Icon(Icons.video_library),
                  label: Text(vbtState.videoPath == null
                      ? 'ABRIR GALERÍA'
                      : 'CAMBIAR VIDEO'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, VBTAnalysisSession vbtState) {
    final bestVmc = vbtState.bestVmc;
    final variation = vbtState.speedVariation;
    final displayVariation = variation.abs();

    Color variationColor = Colors.orange;
    if (variation < 0) {
      variationColor = Colors.green;
    } else if (variation > 15 || bestVmc < 0.35) {
      variationColor = Colors.red;
    }

    final textColor = Theme.of(context).colorScheme.onSurface;

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
          Text('RESUMEN DE SERIE',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: textColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Velocidad Mejor:', style: TextStyle(color: textColor)),
              Text('${bestVmc.toStringAsFixed(2)} m/s',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Velocidad Media:', style: TextStyle(color: textColor)),
              Text('${vbtState.avgVmc.toStringAsFixed(2)} m/s',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Velocidad Mínima:', style: TextStyle(color: textColor)),
              Text('${vbtState.minVmc.toStringAsFixed(2)} m/s',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pérdida de Velocidad:', style: TextStyle(color: textColor)),
              Text('${displayVariation.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coef. de Variación (CV):',
                  style: TextStyle(color: textColor)),
              Text('${vbtState.coeficienteVariacion.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
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

    final pctRm = AppConfig.estimatePctRMFromVMC(v, isLowerBody);

    String rmKg = 'N/A';
    if (vbtState.pesoKg > 0) {
      final rm = (vbtState.pesoKg * 100) / pctRm;
      rmKg = '${rm.toStringAsFixed(1)} kg';
    }

    String potenciaW = 'N/A';
    if (vbtState.pesoKg > 0) {
      final p = AppConfig.calculatePower(vbtState.pesoKg, v);
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
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppConfig.reportFooter,
                  style: TextStyle(color: Colors.white38, fontSize: 18)),
              SizedBox(height: 4),
              Text(AppConfig.fullVersion,
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          )),
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
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  axisNameSize: 28,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt() + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('m/s',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  axisNameSize: 28,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 0.3,
                    getTitlesWidget: (value, meta) {
                      if (value < 0.1) return const SizedBox();
                      return Text(value.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16));
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
                    color: Colors.greenAccent.shade400,
                    strokeWidth: 3,
                    dashArray: [10, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.greenAccent, blurRadius: 8),
                          ]),
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
