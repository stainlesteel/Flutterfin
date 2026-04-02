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
      userData: fields[4] as UserData?,
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
      ..write(obj.userData)
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

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 1;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      accessToken: fields[0] as String?,
      userId: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.accessToken)
      ..writeByte(1)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SettingsObjAdapter extends TypeAdapter<SettingsObj> {
  @override
  final int typeId = 2;

  @override
  SettingsObj read(BinaryReader reader) {
    return SettingsObj();
  }

  @override
  void write(BinaryWriter writer, SettingsObj obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsObjAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
