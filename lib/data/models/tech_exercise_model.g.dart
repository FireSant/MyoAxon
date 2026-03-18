// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tech_exercise_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechExerciseModelAdapter extends TypeAdapter<TechExerciseModel> {
  @override
  final int typeId = 2;

  @override
  TechExerciseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TechExerciseModel(
      orden: fields[0] as int,
      nombreEjercicio: fields[1] as String,
      series: fields[2] as int,
      repeticiones: fields[3] as int,
      metricaPrincipal: fields[4] as double,
      descansoSegundos: fields[5] as int,
      notasSerie: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TechExerciseModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.orden)
      ..writeByte(1)
      ..write(obj.nombreEjercicio)
      ..writeByte(2)
      ..write(obj.series)
      ..writeByte(3)
      ..write(obj.repeticiones)
      ..writeByte(4)
      ..write(obj.metricaPrincipal)
      ..writeByte(5)
      ..write(obj.descansoSegundos)
      ..writeByte(6)
      ..write(obj.notasSerie);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechExerciseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
