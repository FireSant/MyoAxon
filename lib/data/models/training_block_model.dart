import 'package:hive/hive.dart';

part 'training_block_model.g.dart';

@HiveType(typeId: 5)
class TrainingBlockModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int blockNumber;

  @HiveField(2)
  late String status; // 'En curso', 'Completado', 'Proyectado'

  @HiveField(3)
  late DateTime startDate;

  @HiveField(4)
  late DateTime? endDate;

  @HiveField(5)
  late Map<String, List<double>> exerciseLoads; // Cargas reales en Kg

  @HiveField(6)
  late Map<String, List<double>> exercisePercentages; // Intensidades en % 1RM

  @HiveField(7)
  late Map<String, List<double>> recordedVMC; // Lista de velocidades (m/s) por semana

  TrainingBlockModel({
    required this.id,
    required this.blockNumber,
    required this.status,
    required this.startDate,
    this.endDate,
    Map<String, List<double>>? exerciseLoads,
    Map<String, List<double>>? exercisePercentages,
    Map<String, List<double>>? recordedVMC,
  })  : exerciseLoads = exerciseLoads ?? {},
        exercisePercentages = exercisePercentages ?? {},
        recordedVMC = recordedVMC ?? {};

  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'blockNumber': blockNumber,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'exerciseLoads': exerciseLoads,
      'exercisePercentages': exercisePercentages,
      'recordedVMC': recordedVMC,
    };
  }

  factory TrainingBlockModel.fromFirebase(Map<String, dynamic> data) {
    return TrainingBlockModel(
      id: data['id'] ?? '',
      blockNumber: data['blockNumber'] ?? 0,
      status: data['status'] ?? '',
      startDate: DateTime.parse(data['startDate']),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      exerciseLoads: (data['exerciseLoads'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()),
          ) ??
          {},
      exercisePercentages: (data['exercisePercentages'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()),
          ) ??
          {},
      recordedVMC: (data['recordedVMC'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()),
          ) ??
          {},
    );
  }
}
