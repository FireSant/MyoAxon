// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_exercise_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GymExerciseModelAdapter extends TypeAdapter<GymExerciseModel> {
  @override
  final int typeId = 1;

  @override
  GymExerciseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GymExerciseModel(
      orden: fields[0] as int,
      nombreEjercicio: fields[1] as String,
      series: fields[2] as int,
      repeticiones: fields[3] as int,
      pesoKg: fields[4] as double,
      rir: fields[5] as int,
      descansoSegundos: fields[6] as int,
      notas: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GymExerciseModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.orden)
      ..writeByte(1)
      ..write(obj.nombreEjercicio)
      ..writeByte(2)
      ..write(obj.series)
      ..writeByte(3)
      ..write(obj.repeticiones)
      ..writeByte(4)
      ..write(obj.pesoKg)
      ..writeByte(5)
      ..write(obj.rir)
      ..writeByte(6)
      ..write(obj.descansoSegundos)
      ..writeByte(7)
      ..write(obj.notas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
