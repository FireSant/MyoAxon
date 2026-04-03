// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written adapter to avoid requiring build_runner for this model.
// If you run build_runner, delete this file and let it regenerate.

part of 'axon_analysis_model.dart';

class AxonAnalysisModelAdapter extends TypeAdapter<AxonAnalysisModel> {
  @override
  final int typeId = 4;

  @override
  AxonAnalysisModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AxonAnalysisModel(
      id: (fields[0] ?? '') as String,
      timestamp: (fields[1] ?? DateTime.now()) as DateTime,
      tipo: (fields[2] ?? '') as String,
      exerciseLabel: (fields[3] ?? '') as String,
      folderName: (fields[4] ?? '') as String,
      athleteUid: (fields[5] ?? '') as String,
      vmcMs: (fields[6] ?? 0.0).toDouble(),
      displacementM: (fields[7] ?? 0.0).toDouble(),
      concentricDurationMs: (fields[8] ?? 0) as int,
      pixelsPerMeter: (fields[9] ?? 0.0).toDouble(),
      flightTimeMs: (fields[10] ?? 0) as int,
      contactTimeMs: (fields[11] ?? 0) as int,
      rsi: (fields[12] ?? 0.0).toDouble(),
      isSynced: (fields[13] ?? false) as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AxonAnalysisModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.exerciseLabel)
      ..writeByte(4)
      ..write(obj.folderName)
      ..writeByte(5)
      ..write(obj.athleteUid)
      ..writeByte(6)
      ..write(obj.vmcMs)
      ..writeByte(7)
      ..write(obj.displacementM)
      ..writeByte(8)
      ..write(obj.concentricDurationMs)
      ..writeByte(9)
      ..write(obj.pixelsPerMeter)
      ..writeByte(10)
      ..write(obj.flightTimeMs)
      ..writeByte(11)
      ..write(obj.contactTimeMs)
      ..writeByte(12)
      ..write(obj.rsi)
      ..writeByte(13)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxonAnalysisModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
