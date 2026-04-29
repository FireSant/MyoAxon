// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_block_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingBlockModelAdapter extends TypeAdapter<TrainingBlockModel> {
  @override
  final int typeId = 5;

  @override
  TrainingBlockModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingBlockModel(
      id: fields[0] as String,
      blockNumber: fields[1] as int,
      status: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime?,
      exerciseLoads: (fields[5] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<double>())),
      exercisePercentages: (fields[6] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<double>())),
      recordedVMC: (fields[7] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<double>())),
    );
  }

  @override
  void write(BinaryWriter writer, TrainingBlockModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.blockNumber)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.exerciseLoads)
      ..writeByte(6)
      ..write(obj.exercisePercentages)
      ..writeByte(7)
      ..write(obj.recordedVMC);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingBlockModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
