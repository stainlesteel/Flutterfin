// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_objects.dart';

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
      userMap: (fields[4] as Map?)?.cast<String, String>(),
      lastLogIsQC: fields[5] as bool?,
      profile: fields[8] as DeviceProfile?,
    )..deviceId = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, ServerObj obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverURL)
      ..writeByte(2)
      ..write(obj.serverName)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.userMap)
      ..writeByte(5)
      ..write(obj.lastLogIsQC)
      ..writeByte(7)
      ..write(obj.deviceId)
      ..writeByte(8)
      ..write(obj.profile);
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
