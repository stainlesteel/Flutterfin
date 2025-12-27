// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objects.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServerObjAdapter extends TypeAdapter<ServerObj> {
  @override
  final int typeId = 0;

  @override
  ServerObj read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServerObj(
      id: fields[0] as int?,
      serverURL: fields[1] as String?,
      serverName: fields[2] as String?,
      version: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServerObj obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverURL)
      ..writeByte(2)
      ..write(obj.serverName)
      ..writeByte(3)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerObjAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
