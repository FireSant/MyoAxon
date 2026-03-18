// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 3;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      uid: fields[0] as String,
      nombreCompleto: fields[1] as String,
      fechaNacimiento: fields[2] as DateTime,
      sexo: fields[3] as String,
      perfilDeportivo: fields[4] as String,
      mejorMarca: fields[5] as String,
      fechaMejorMarca: fields[6] as DateTime,
      competenciaObjetivo: fields[7] as String,
      categoria: fields[8] as String,
      rol: fields[9] as String,
      coachId: fields[10] as String,
      isSynced: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.nombreCompleto)
      ..writeByte(2)
      ..write(obj.fechaNacimiento)
      ..writeByte(3)
      ..write(obj.sexo)
      ..writeByte(4)
      ..write(obj.perfilDeportivo)
      ..writeByte(5)
      ..write(obj.mejorMarca)
      ..writeByte(6)
      ..write(obj.fechaMejorMarca)
      ..writeByte(7)
      ..write(obj.competenciaObjetivo)
      ..writeByte(8)
      ..write(obj.categoria)
      ..writeByte(9)
      ..write(obj.rol)
      ..writeByte(10)
      ..write(obj.coachId)
      ..writeByte(11)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
