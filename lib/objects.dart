// contains hive objects and data enums

import 'package:hive/hive.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

part 'objects.g.dart';

@HiveType(typeId: 0)
class ServerObj extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? serverURL;

  @HiveField(2)
  String? serverName;

  @HiveField(3)
  String? version;

  @HiveField(4)
  Map<String, String>? userMap;

  @HiveField(5)
  bool? lastLogIsQC;

  @HiveField(7)
  String? deviceId;

  @HiveField(8)
  DeviceProfile? profile;

  ServerObj({
    this.id,
    this.serverURL,
    this.serverName,
    this.version,
    this.userMap,
    this.lastLogIsQC,
    this.profile,
  });
}
