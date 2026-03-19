// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = 0;

  @override
  SessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionModel(
      idSesion: fields[0] as String,
      userId: fields[1] as String,
      idAtleta: fields[2] as String?,
      fecha: fields[3] as DateTime,
      tipoSesion: fields[4] as String,
      faseEntrenamiento: fields[5] as String,
      horasSueno: fields[6] as double,
      fatiguaPreentrenamiento: fields[7] as int,
      intensidadPercibida: fields[8] as int,
      limitantes: fields[9] as String,
      ejerciciosGim: (fields[10] as List?)?.cast<GymExerciseModel>(),
      ejerciciosTech: (fields[11] as List?)?.cast<TechExerciseModel>(),
      isSynced: fields[12] as bool,
      jornada: fields[13] == null ? 'Matutina' : fields[13] as String,
      editadoEn: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.idSesion)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.idAtleta)
      ..writeByte(3)
      ..write(obj.fecha)
      ..writeByte(4)
      ..write(obj.tipoSesion)
      ..writeByte(5)
      ..write(obj.faseEntrenamiento)
      ..writeByte(6)
      ..write(obj.horasSueno)
      ..writeByte(7)
      ..write(obj.fatiguaPreentrenamiento)
      ..writeByte(8)
      ..write(obj.intensidadPercibida)
      ..writeByte(9)
      ..write(obj.limitantes)
      ..writeByte(10)
      ..write(obj.ejerciciosGim)
      ..writeByte(11)
      ..write(obj.ejerciciosTech)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.jornada)
      ..writeByte(14)
      ..write(obj.editadoEn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
