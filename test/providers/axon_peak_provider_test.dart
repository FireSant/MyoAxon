import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:myoaxon/providers/axon_peak_provider.dart';
import 'package:myoaxon/data/models/axon_peak_config_model.dart';

// Mock manual de Box para evitar dependencias de mockito
class ManualMockBox<T> implements Box<T> {
  final Map<dynamic, T> _storage = {};
  @override
  Future<int> add(T value) async {
    final key = _storage.length;
    _storage[key] = value;
    return key;
  }
  @override
  Iterable<T> get values => _storage.values;
  @override
  Iterable get keys => _storage.keys;
  @override
  Future<void> put(dynamic key, T value) async => _storage[key] = value;
  @override
  T? get(dynamic key, {T? defaultValue}) => _storage[key] ?? defaultValue;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AxonPeakNotifier Periodization Tests', () {
    late AxonPeakNotifier notifier;
    late ManualMockBox<AxonPeakConfigModel> mockBox;
    const userId = 'test_user';

    setUp(() {
      mockBox = ManualMockBox<AxonPeakConfigModel>();
      notifier = AxonPeakNotifier(userId, box: mockBox);
    });

    test('Initial Macrocycle Generation - StepLoading', () async {
      final targetDate = DateTime.now().add(const Duration(days: 90));
      final initialLoads = {'Squat': 100.0}; // 1RM base approx 112kg
      final initialReps = {'Squat': 5};
      final increments = {'Squat': 5.0}; // 5% increment

      await notifier.initializeMacrocycle(
        targetDate: targetDate,
        weeksPerBlock: 4,
        isTaperActive: false,
        periodizationMethod: 'StepLoading',
        initialLoads: initialLoads,
        initialReps: initialReps,
        exerciseIncrements: increments,
      );

      final config = notifier.state.value;
      expect(config, isNotNull);
      expect(config!.periodizationMethod, 'StepLoading');
      
      // Verificar Bloque 1
      final b1 = config.blocks[0];
      final b1Loads = b1.exerciseLoads['Squat']!;
      // 1RM Brzycki (100 / (1.0278 - 0.0278 * 5)) = ~112.5
      const base1RM = 100.0 / (1.0278 - (0.0278 * 5));
      expect(b1Loads[2], closeTo(base1RM * 0.90, 0.1)); // S3 = 90%

      // Verificar Bloque 2 (Incrementado)
      final b2 = config.blocks[1];
      final b2Loads = b2.exerciseLoads['Squat']!;
      const b2NRM = base1RM * (1 + 0.05); // 1RM + 5%
      expect(b2Loads[2], closeTo(b2NRM * 0.90, 0.1)); // S3 = 90% del nuevo NRM
      expect(b2.exercisePercentages['Squat']![0], 70.0); // Labels fijos
    });

    test('Initial Macrocycle Generation - Linear', () async {
      final initialLoads = {'Bench': 100.0};
      final initialReps = {'Bench': 1}; // 1RM = 100
      final increments = {'Bench': 2.5};

      await notifier.initializeMacrocycle(
        targetDate: DateTime.now().add(const Duration(days: 90)),
        weeksPerBlock: 4,
        isTaperActive: false,
        periodizationMethod: 'Linear',
        initialLoads: initialLoads,
        initialReps: initialReps,
        exerciseIncrements: increments,
      );

      final config = notifier.state.value;
      // En Lineal el 1RM es fijo, suben los %
      final b1 = config!.blocks[0];
      final b2 = config.blocks[1];
      
      expect(b1.exercisePercentages['Bench']![2], 80.0); // Peak P starts at 80%
      expect(b2.exercisePercentages['Bench']![2], 85.0); // Peak P increases to 85%
      
      // Cargas calculadas sobre el MISMO 1RM (100kg)
      expect(b1.exerciseLoads['Bench']![2], 80.0);
      expect(b2.exerciseLoads['Bench']![2], 85.0);
    });

    test('Block Repetition Logic (shouldIncrease = false)', () async {
      // 1. Generar macrocycle
      await notifier.initializeMacrocycle(
        targetDate: DateTime.now().add(const Duration(days: 60)),
        weeksPerBlock: 4,
        isTaperActive: false,
        periodizationMethod: 'StepLoading',
        initialLoads: {'Deadlift': 200.0},
        initialReps: {'Deadlift': 1},
        exerciseIncrements: {'Deadlift': 2.0},
      );

      final config = notifier.state.value!;
      final b0Loads = List<double>.from(config.blocks[0].exerciseLoads['Deadlift']!);
      
      // 2. Simular fin de bloque con decisión de NO incrementar
      await notifier.applyBlockDecisions(0, {'Deadlift': false});

      // 3. Verificar que el Bloque 1 sea copia fiel del Bloque 0
      final b1Loads = notifier.state.value!.blocks[1].exerciseLoads['Deadlift']!;
      expect(b1Loads, equals(b0Loads));
    });
  });
}
