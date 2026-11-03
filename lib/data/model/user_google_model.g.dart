// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_google_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserGoogleModelAdapter extends TypeAdapter<UserGoogleModel> {
  @override
  final int typeId = 17;

  @override
  UserGoogleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserGoogleModel(
      id: fields[0] as String?,
      name: fields[1] as String?,
      email: fields[2] as String,
      urlImage: fields[3] as String?,
      createdAt: fields[4] as DateTime?,
      avatarBase64: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserGoogleModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.urlImage)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.avatarBase64);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGoogleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
