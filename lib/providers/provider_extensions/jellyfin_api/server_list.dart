import 'package:jellyfin/providers/jellyfin_api.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:hive/hive.dart';

extension ServerList on JellyfinAPI {
  Future<void> updateServerList() async {
    int _tmpInt = 0;
    for (ServerObj objs in serverList) {
      await box.put(_tmpInt, objs);
      _tmpInt += 1;
    }
    notifyListeners();
  }
  
  Future<void> removeAtServerList(int index) async {
    if (lastUsedServer == index) {
      lastUsedServer = null;
      await box.put('lastUsedServer', null);
    }
    serverList.removeAt(index);
    await box.delete(index);
    notifyListeners();
  }

  Future<void> addServer(String url, String vers, String name) async {
    int _index = serverList.isEmpty ? 0 : serverList.length;

    serverList.add(ServerObj(id: _index));
    await box.put(_index, serverList[_index]);

    serverList[_index].serverURL = url;
    serverList[_index].version = vers;
    serverList[_index].serverName = name;

    await serverList[_index].save();

    notifyListeners();
  }
} 
