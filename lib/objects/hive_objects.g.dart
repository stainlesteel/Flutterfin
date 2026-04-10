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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsObj(
      homepageCarousels: (fields[0] as List).cast<HomepageCarousels>(),
      showUsername: fields[1] as bool,
      themeType: fields[2] as int,
      themeMode: fields[3] as int,
      keepScreenAwake: fields[4] as bool,
      useSlidingPageTransition: fields[5] as bool,
      persistentPlaybackSpeed: fields[6] as double,
      useHLS: fields[7] as bool,
      playNextEpisodeAuto: fields[8] as bool,
      showSkipCreditsDialog: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsObj obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.homepageCarousels)
      ..writeByte(1)
      ..write(obj.showUsername)
      ..writeByte(2)
      ..write(obj.themeType)
      ..writeByte(3)
      ..write(obj.themeMode)
      ..writeByte(4)
      ..write(obj.keepScreenAwake)
      ..writeByte(5)
      ..write(obj.useSlidingPageTransition)
      ..writeByte(6)
      ..write(obj.persistentPlaybackSpeed)
      ..writeByte(7)
      ..write(obj.useHLS)
      ..writeByte(8)
      ..write(obj.playNextEpisodeAuto)
      ..writeByte(9)
      ..write(obj.showSkipCreditsDialog);
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

class HomepageCarouselsAdapter extends TypeAdapter<HomepageCarousels> {
  @override
  final int typeId = 3;

  @override
  HomepageCarousels read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HomepageCarousels.userViews;
      case 1:
        return HomepageCarousels.continueWatching;
      case 2:
        return HomepageCarousels.becauseYouWatched;
      case 3:
        return HomepageCarousels.recentMovies;
      case 4:
        return HomepageCarousels.recentShows;
      case 5:
        return HomepageCarousels.nextUp;
      case 6:
        return HomepageCarousels.none;
      default:
        return HomepageCarousels.userViews;
    }
  }

  @override
  void write(BinaryWriter writer, HomepageCarousels obj) {
    switch (obj) {
      case HomepageCarousels.userViews:
        writer.writeByte(0);
        break;
      case HomepageCarousels.continueWatching:
        writer.writeByte(1);
        break;
      case HomepageCarousels.becauseYouWatched:
        writer.writeByte(2);
        break;
      case HomepageCarousels.recentMovies:
        writer.writeByte(3);
        break;
      case HomepageCarousels.recentShows:
        writer.writeByte(4);
        break;
      case HomepageCarousels.nextUp:
        writer.writeByte(5);
        break;
      case HomepageCarousels.none:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomepageCarouselsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
