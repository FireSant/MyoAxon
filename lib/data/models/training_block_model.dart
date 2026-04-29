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
}
