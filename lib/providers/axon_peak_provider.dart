import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/axon_peak_config_model.dart';
import '../data/models/training_block_model.dart';
import 'auth_provider.dart';

final axonPeakConfigProvider =
    StateNotifierProvider<AxonPeakNotifier, AsyncValue<AxonPeakConfigModel?>>(
        (ref) {
  final userId = ref.watch(currentUserIdProvider);
  return AxonPeakNotifier(userId);
});

final axonPeakConfigByAthleteProvider = StateNotifierProvider.family<
    AxonPeakNotifier, AsyncValue<AxonPeakConfigModel?>, String>((ref, athleteId) {
  return AxonPeakNotifier(athleteId);
});

class AxonPeakNotifier
    extends StateNotifier<AsyncValue<AxonPeakConfigModel?>> {
  final String? userId;
  late final Box<AxonPeakConfigModel> _box;
  final _uuid = const Uuid();

  AxonPeakNotifier(this.userId, {Box<AxonPeakConfigModel>? box})
      : super(const AsyncValue.loading()) {
    if (box != null) {
      _box = box;
      _loadInitialData();
    } else {
      _init();
    }
  }

  void _loadInitialData() {
    try {
      final config = _box.values.where((c) => c.userId == userId).firstOrNull;
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _init() async {
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    _box = Hive.box<AxonPeakConfigModel>('axon_peak_config_box');

    try {
      final config = _box.values.where((c) => c.userId == userId).firstOrNull;
      if (config != null) {
        state = AsyncValue.data(config);
      } else {
        // Si no está local, intentamos bajarlo de Firebase
        await pullFromFirebase();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pullFromFirebase() async {
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('axon_peak_configs')
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        final config = AxonPeakConfigModel.fromFirebase(doc.data()!);
        await _box.put(config.id, config);
        state = AsyncValue.data(config);
      } else {
        // No hay config en Firebase → usuario nuevo, mostrar wizard
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('❌ [AxonPeak] Error bajando config de Firebase: $e');
      // Ante un error de red, mostramos el wizard en lugar de colgar
      state = const AsyncValue.data(null);
    }
  }

  Future<void> syncToFirebase() async {
    if (userId == null) return;
    final config = state.value;
    if (config == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('axon_peak_configs')
          .doc(userId)
          .set(config.toFirebase());
    } catch (e) {
      debugPrint('❌ [AxonPeak] Error sincronizando a Firebase: $e');
    }
  }

  // Brzycki formula
  double _calculate1RM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight / (1.0278 - (0.0278 * reps));
  }

  Future<void> initializeMacrocycle({
    required DateTime targetDate,
    required int weeksPerBlock,
    required bool isTaperActive,

    required String periodizationMethod,
    required Map<String, double> initialLoads,
    required Map<String, int> initialReps,
    required Map<String, double> exerciseIncrements, // Incremento Deseado en Kg
  }) async {
    if (userId == null) return;
    state = const AsyncValue.loading();

    try {
      final today = DateTime.now();
      int differenceInDays = targetDate.difference(today).inDays;
      if (differenceInDays < 0) differenceInDays = 0;
      
      final totalWeeks = differenceInDays ~/ 7;
      int blocksCount = (totalWeeks / weeksPerBlock).ceil();
      if (blocksCount <= 0) blocksCount = 1;

      final blocks = <TrainingBlockModel>[];
      DateTime currentStartDate = today;
      
      Map<String, double> global1RM = {};
      
      for (var ex in initialLoads.keys) {
        final load = initialLoads[ex] ?? 0.0;
        final reps = initialReps[ex] ?? 1;
        global1RM[ex] = _calculate1RM(load, reps);
      }

        for (int i = 0; i < blocksCount; i++) {
        Map<String, List<double>> blockLoads = {};
        Map<String, List<double>> blockPercentages = {};
        Map<String, List<double>> initialVMC = {};

        for (var entry in exerciseIncrements.entries) {
          final exercise = entry.key;
          final incrementPercent = entry.value; 
          final base1RM = global1RM[exercise] ?? 100.0;
          
          // El usuario ingresa el incremento en porcentaje (ej. 2.5%)
          // Lo convertimos a Kilos basados en el 1RM de este ejercicio
          final increment = base1RM * (incrementPercent / 100.0);
          
          List<double> weeklyPercentages = [];
          List<double> weeklyLoads = [];
          
          if (periodizationMethod == 'StepLoading') {
            // Método Por Pasos (Step Loading):
            // Los porcentajes son SIEMPRE FIJOS (70, 80, 90, 60)
            // Lo que aumenta es el 1RM base sobre el que se calculan bloque a bloque.
            if (weeksPerBlock == 4) {
              weeklyPercentages = [70.0, 80.0, 90.0, 60.0];
            } else if (weeksPerBlock == 3) {
              weeklyPercentages = [80.0, 90.0, 60.0];
            } else {
              for (int w = 0; w < weeksPerBlock; w++) {
                if (w == weeksPerBlock - 1) {
                  weeklyPercentages.add(60.0);
                } else if (w == weeksPerBlock - 2) {
                  weeklyPercentages.add(90.0);
                } else if (w == weeksPerBlock - 3) {
                  weeklyPercentages.add(80.0);
                } else {
                  weeklyPercentages.add(70.0);
                }
              }
            }
            
            // Calculamos el 1RM proyectado para este bloque i (0, 1, 2...)
            // Incremento lineal: 1RM_i = 1RM_base + (i * incremento_en_kilos)
            final currentBlockNRM = base1RM + (increment * i);
            weeklyLoads = weeklyPercentages.map((p) => currentBlockNRM * (p / 100.0)).toList();
          } else {
            // Linear Periodization (Tradicional)
            // El 1RM se mantiene fijo según la semilla inicial para toda la proyección.
            // Solo varían los porcentajes de intensidad bloque a bloque.
            final blockNRM = base1RM;
            
            double peakP = 80.0 + (5.0 * i); 
            if (weeksPerBlock == 4) {
               weeklyPercentages = [peakP - 20.0, peakP - 10.0, peakP, 60.0];
            } else {
               for(int w=0; w<weeksPerBlock; w++) {
                 if (w == weeksPerBlock - 1) {
                   weeklyPercentages.add(60.0); 
                 } else {
                   weeklyPercentages.add((peakP - 20.0) + (10.0 * w));
                 }
               }
            }
            weeklyLoads = weeklyPercentages.map((p) => blockNRM * (p / 100.0)).toList();
          }

          blockPercentages[exercise] = weeklyPercentages;
          blockLoads[exercise] = weeklyLoads;
          
          // Inicializar VMC con ceros para cada semana
          initialVMC[exercise] = List.filled(weeksPerBlock, 0.0);
        }

        blocks.add(TrainingBlockModel(
          id: _uuid.v4(),
          blockNumber: i + 1,
          status: i == 0 ? 'En curso' : 'Proyectado',
          startDate: currentStartDate,
          exerciseLoads: blockLoads,
          exercisePercentages: blockPercentages,
          recordedVMC: initialVMC,
        ));

        currentStartDate =
            currentStartDate.add(Duration(days: weeksPerBlock * 7));
      }

      final config = AxonPeakConfigModel(
        id: _uuid.v4(),
        userId: userId!,
        targetDate: targetDate,
        weeksPerBlock: weeksPerBlock,
        isTaperActive: isTaperActive,
        periodizationMethod: periodizationMethod,
        exerciseIncrements: exerciseIncrements,
        exercise1RM: global1RM,
        blocks: blocks,
      );

      final existingKeys = _box.keys.where((k) {
        final c = _box.get(k);
        return c?.userId == userId;
      }).toList();
      for (var k in existingKeys) {
        await _box.delete(k);
      }

      await _box.put(config.id, config);
      state = AsyncValue.data(config);
      await syncToFirebase();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLoad(
      int blockIndex, String exercise, int weekIndex, double newLoad) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final blocks = currentConfig.blocks;

    if (blockIndex >= 0 && blockIndex < blocks.length) {
      final block = blocks[blockIndex];
      final loads = Map<String, List<double>>.from(block.exerciseLoads);
      
      // En este modelo, blockNRM es la carga de la S3 (Pico). 
      // Por simplicidad, tomamos el global1RM + incrementos
      final base1RM = currentConfig.exercise1RM[exercise] ?? 100.0;
      final inc = currentConfig.exerciseIncrements[exercise] ?? 2.5;
      final blockNRM = base1RM + (inc * blockIndex);

      if (loads.containsKey(exercise)) {
        List<double> weekLoads = List<double>.from(loads[exercise]!);
        List<double> weekPercents = List<double>.from(block.exercisePercentages[exercise]!);

        if (weekIndex >= 0 && weekIndex < weekLoads.length) {
          final oldLoad = weekLoads[weekIndex];
          final delta = newLoad - oldLoad;

          weekLoads[weekIndex] = newLoad;
          weekPercents[weekIndex] = (newLoad / blockNRM) * 100.0;
          
          loads[exercise] = weekLoads;
          block.exercisePercentages[exercise] = weekPercents;
          block.exerciseLoads = loads;

          if (delta != 0) {
            for (int i = blockIndex + 1; i < blocks.length; i++) {
              final futureBlock = blocks[i];
              final futureLoads =
                  Map<String, List<double>>.from(futureBlock.exerciseLoads);
              final futurePercents = 
                  Map<String, List<double>>.from(futureBlock.exercisePercentages);

              final futureBlockNRM = base1RM + (inc * i);

              if (futureLoads.containsKey(exercise)) {
                List<double> futureWeekLoads =
                    List<double>.from(futureLoads[exercise]!);
                List<double> futureWeekPercents =
                    List<double>.from(futurePercents[exercise]!);
                    
                for (int w = 0; w < futureWeekLoads.length; w++) {
                  futureWeekLoads[w] += delta;
                  futureWeekPercents[w] = (futureWeekLoads[w] / futureBlockNRM) * 100.0;
                }
                
                futureLoads[exercise] = futureWeekLoads;
                futurePercents[exercise] = futureWeekPercents;
                
                futureBlock.exerciseLoads = futureLoads;
                futureBlock.exercisePercentages = futurePercents;
              }
            }
          }
        }
      }
    }

    await currentConfig.save();
    state = AsyncValue.data(currentConfig);
    await syncToFirebase();
  }
  
  Future<void> updateVMC(int blockIndex, String exercise, int weekIndex, double vmc) async {
      final currentConfig = state.value;
      if (currentConfig == null) return;
      
      final blocks = currentConfig.blocks;
      if (blockIndex >= 0 && blockIndex < blocks.length) {
          final block = blocks[blockIndex];
          final recorded = Map<String, List<double>>.from(block.recordedVMC);
          
          if (recorded.containsKey(exercise) && weekIndex < recorded[exercise]!.length) {
              List<double> weekVMC = List<double>.from(recorded[exercise]!);
              weekVMC[weekIndex] = vmc;
              recorded[exercise] = weekVMC;
              block.recordedVMC = recorded;
              
              await currentConfig.save();
              state = AsyncValue.data(currentConfig);
              await syncToFirebase();
          }
      }
  }



  Map<String, String> getRecommendations(int blockIndex) {
    final config = state.value;
    if (config == null) return {};

    final blocks = config.blocks;
    Map<String, String> recommendations = {};

    if (blockIndex >= 0 && blockIndex < blocks.length) {
      final block = blocks[blockIndex];
      final peakWeekIndex = config.weeksPerBlock - 2; // S3 en un bloque de 4 semanas

      // Regla de Estabilidad (2-Block Rule)
      for (var exercise in config.exercise1RM.keys) {
         final currentVMCList = block.recordedVMC[exercise];
         double currentVMC = 0.0;
         if (currentVMCList != null && peakWeekIndex >= 0 && peakWeekIndex < currentVMCList.length) {
             currentVMC = currentVMCList[peakWeekIndex];
         }
         
         if (blockIndex > 0) {
             final prevBlock = blocks[blockIndex - 1];
             final prevVMCList = prevBlock.recordedVMC[exercise];
             double prevVMC = 0.0;
             
             if (prevVMCList != null && peakWeekIndex >= 0 && peakWeekIndex < prevVMCList.length) {
                 prevVMC = prevVMCList[peakWeekIndex];
             }
             
             // Check 2-Block Rule: Si S3 VMC < 0.35 en dos bloques seguidos
             if (currentVMC > 0 && prevVMC > 0 && currentVMC < 0.35 && prevVMC < 0.35) {
                 recommendations[exercise] = "⚠️ VMC < 0.35 m/s por 2 bloques seguidos. Sugerimos REPETIR EL BLOQUE y enfocarse en la velocidad del levantamiento.";
             } else if (currentVMC >= prevVMC && currentVMC > 0) {
                 recommendations[exercise] = "Velocidad mantenida o mejorada ($currentVMC m/s). Sugerimos confirmar el aumento.";
             } else if (currentVMC < prevVMC - 0.05 && currentVMC > 0) {
                 recommendations[exercise] = "Caída de velocidad ($currentVMC m/s vs $prevVMC m/s). Sugerimos REPETIR EL BLOQUE para consolidar e incrementar velocidad.";
             } else {
                 recommendations[exercise] = "Progreso estable. Evalúa cómo te sentiste.";
             }
         } else if (currentVMC > 0) {
             if (currentVMC < 0.35) {
                 recommendations[exercise] = "⚠️ Velocidad inicial muy baja ($currentVMC m/s). Sugerimos REPETIR EL BLOQUE y enfocarse en la velocidad.";
             } else {
                 recommendations[exercise] = "Velocidad S3 registrada: $currentVMC m/s. Necesitamos otro bloque para evaluar tendencia.";
             }
         } else {
             recommendations[exercise] = "No se registró VMC en la Semana Pico (S3).";
         }
      }
    }
    return recommendations;
  }
  
  Future<void> applyBlockDecisions(int blockIndex, Map<String, bool> applyIncrements) async {
    final config = state.value;
    if (config == null) return;
    
    final blocks = config.blocks;

    // 1. Marcar bloque actual como completado
    if (blockIndex >= 0 && blockIndex < blocks.length) {
      final block = blocks[blockIndex];
      block.status = 'Completado';
      block.endDate = DateTime.now();
      
      // 2. Activar siguiente bloque si existe
      if (blockIndex + 1 < blocks.length) {
        blocks[blockIndex + 1].status = 'En curso';
      }
    }
    
    // 3. Aplicar incrementos o repeticiones
    for (var exercise in applyIncrements.keys) {
        final shouldIncrease = applyIncrements[exercise] ?? false;
        final incPercent = config.exerciseIncrements[exercise] ?? 2.5;
        final base1RM = config.exercise1RM[exercise] ?? 100.0;
        final inc = base1RM * (incPercent / 100.0);
        
        if (!shouldIncrease) {
            // Lógica Unificada de Repetición (Freno de Emergencia):
            for (int i = blocks.length - 1; i > blockIndex; i--) {
                final futureBlock = blocks[i];
                final prevBlock = blocks[i - 1]; 
                
                if (prevBlock.exerciseLoads.containsKey(exercise)) {
                    futureBlock.exerciseLoads[exercise] = List.from(prevBlock.exerciseLoads[exercise]!);
                    futureBlock.exercisePercentages[exercise] = List.from(prevBlock.exercisePercentages[exercise]!);
                }
            }
        } else {
            // Lógica de Confirmación de Aumento
            if (config.periodizationMethod == 'Linear') {
                for (int i = blockIndex + 1; i < blocks.length; i++) {
                    final futureBlock = blocks[i];
                    if (futureBlock.exerciseLoads.containsKey(exercise)) {
                        final percents = futureBlock.exercisePercentages[exercise]!;
                        final loads = futureBlock.exerciseLoads[exercise]!;
                        if (percents.isNotEmpty && percents[0] > 0) {
                            double currentBlockNRM = loads[0] / (percents[0] / 100.0);
                            double newBlockNRM = currentBlockNRM + inc;
                            List<double> newLoads = [];
                            for (int w = 0; w < loads.length; w++) {
                                newLoads.add(newBlockNRM * (percents[w] / 100.0));
                            }
                            futureBlock.exerciseLoads[exercise] = newLoads;
                        }
                    }
                }
            }
        }
    }
    
    await _box.put(config.id, config);
    final freshConfig = _box.get(config.id);
    state = AsyncValue.data(freshConfig);
    await syncToFirebase();
  }

  Future<void> resetProgression() async {
    if (userId == null) return;
    final existingKeys = _box.keys.where((k) {
      final c = _box.get(k);
      return c?.userId == userId;
    }).toList();
    for (var k in existingKeys) {
      await _box.delete(k);
    }
    state = const AsyncValue.data(null);
  }
}
