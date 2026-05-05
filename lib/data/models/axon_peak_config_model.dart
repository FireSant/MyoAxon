import 'package:hive/hive.dart';
import 'training_block_model.dart';

part 'axon_peak_config_model.g.dart';

@HiveType(typeId: 6)
class AxonPeakConfigModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late DateTime targetDate;

  @HiveField(3)
  late int weeksPerBlock;

  @HiveField(4)
  late bool isTaperActive;

  @HiveField(5)
  late bool isFreeFlow;

  @HiveField(6)
  late Map<String, double>
      exerciseIncrements; // Aumento planeado de % (ej. 2.5)

  @HiveField(7)
  late List<TrainingBlockModel> blocks;

  @HiveField(8, defaultValue: 'Intermedio')
  late String athleteLevel; // 'Principiante', 'Intermedio', 'Avanzado'

  @HiveField(9, defaultValue: 'StepLoading')
  late String periodizationMethod; // 'StepLoading', 'Linear'

  @HiveField(10)
  late Map<String, double> exercise1RM; // 1RM base por ejercicio

  AxonPeakConfigModel({
    required this.id,
    required this.userId,
    required this.targetDate,
    required this.weeksPerBlock,
    required this.isTaperActive,
    required this.isFreeFlow,
    this.athleteLevel = 'Intermedio',
    this.periodizationMethod = 'StepLoading',
    Map<String, double>? exerciseIncrements,
    Map<String, double>? exercise1RM,
    List<TrainingBlockModel>? blocks,
  })  : exerciseIncrements = exerciseIncrements ?? {},
        exercise1RM = exercise1RM ?? {},
        blocks = blocks ?? [];

  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'userId': userId,
      'targetDate': targetDate.toIso8601String(),
      'weeksPerBlock': weeksPerBlock,
      'isTaperActive': isTaperActive,
      'isFreeFlow': isFreeFlow,
      'athleteLevel': athleteLevel,
      'periodizationMethod': periodizationMethod,
      'exerciseIncrements': exerciseIncrements,
      'exercise1RM': exercise1RM,
      'blocks': blocks.map((b) => b.toFirebase()).toList(),
    };
  }

  factory AxonPeakConfigModel.fromFirebase(Map<String, dynamic> data) {
    return AxonPeakConfigModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      targetDate: DateTime.parse(data['targetDate']),
      weeksPerBlock: data['weeksPerBlock'] ?? 4,
      isTaperActive: data['isTaperActive'] ?? true,
      isFreeFlow: data['isFreeFlow'] ?? false,
      athleteLevel: data['athleteLevel'] ?? 'Intermedio',
      periodizationMethod: data['periodizationMethod'] ?? 'StepLoading',
      exerciseIncrements: (data['exerciseIncrements'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      exercise1RM: (data['exercise1RM'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      blocks: (data['blocks'] as List?)
              ?.map((b) => TrainingBlockModel.fromFirebase(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
