// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'axon_peak_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AxonPeakConfigModelAdapter extends TypeAdapter<AxonPeakConfigModel> {
  @override
  final int typeId = 6;

  @override
  AxonPeakConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AxonPeakConfigModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      targetDate: fields[2] as DateTime,
      weeksPerBlock: fields[3] as int,
      isTaperActive: fields[4] as bool,
      isFreeFlow: fields[5] as bool,
      athleteLevel: fields[8] == null ? 'Intermedio' : fields[8] as String,
      periodizationMethod:
          fields[9] == null ? 'StepLoading' : fields[9] as String,
      exerciseIncrements: (fields[6] as Map?)?.cast<String, double>(),
      exercise1RM: (fields[10] as Map?)?.cast<String, double>(),
      blocks: (fields[7] as List?)?.cast<TrainingBlockModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, AxonPeakConfigModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetDate)
      ..writeByte(3)
      ..write(obj.weeksPerBlock)
      ..writeByte(4)
      ..write(obj.isTaperActive)
      ..writeByte(5)
      ..write(obj.isFreeFlow)
      ..writeByte(6)
      ..write(obj.exerciseIncrements)
      ..writeByte(7)
      ..write(obj.blocks)
      ..writeByte(8)
      ..write(obj.athleteLevel)
      ..writeByte(9)
      ..write(obj.periodizationMethod)
      ..writeByte(10)
      ..write(obj.exercise1RM);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxonPeakConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
