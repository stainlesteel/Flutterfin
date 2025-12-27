import 'package:hive/hive.dart';

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

    ServerObj({
      this.id,
      this.serverURL,
      this.serverName,
      this.version,
    });
}
