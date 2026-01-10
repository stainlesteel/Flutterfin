import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'comps.dart';
import 'objects.dart';
import 'pages.dart';

class JellyfinAPI extends ChangeNotifier {
  final Box box;

  JellyfinAPI(this.box);

  // app data that may or may not require interaction with the jellyfin server
  List<ServerObj> serverList = []; 
  int? lastUsedServer;
  int? lastUser;
  late JellyfinDart appClient; // jellyfin_dart client
  
  // server data collected for later use
  String? logInMsg;
  String? userID;

  // boolean loading locks
  bool isVerifyingServer = false;

  Future<void> loadAppData() async {
    final _data = box.values.whereType<ServerObj>().toList();

    serverList = _data;

    int? _tmpIndex = await box.get('lastUsedServer');
    if (_tmpIndex != null) {
      lastUsedServer = _tmpIndex;
    } else {

    }

    int? _tmpUser = await box.get('lastUser');
    if (_tmpUser != null) {
      lastUser = _tmpUser;
    } else {

    }

    notifyListeners();
  }

  Future<bool> verifyServer(String url, BuildContext context) async {
    isVerifyingServer = true;
    notifyListeners();
    try {
      final dio = await Dio().get('$url/System/Info/Public');
      final conType = dio.headers.value('content-type') ?? '';

      if (dio.data['ServerName'] == null) {
        return false;
      } else if (conType.contains('text/html')) {
        showScaffold("Can connect to server but can't access it's ServerName.\nIf the URL is working for you, check if you're getting redirected to the correct URL by the server.", context);
        return false;
      } 
      else {
        await addServer(url, dio.data['Version'], dio.data['ServerName']);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      print('dio errror type in add server: ${e.type}');
      String text = '';
      if (e.type == DioExceptionType.unknown) {
        text = 'Unknown error when trying to verify server.';
      } else if (e.type == DioExceptionType.connectionError) {
        text = 'Failed to connect to server.';
      } else if (e.type == DioExceptionType.badResponse) {
        text = 'Got bad response from server url.';
      }
      Navigator.pop(context);
      showScaffold(text, context);
      return false;
    } finally {
      isVerifyingServer = false;
      notifyListeners();
    }
  }

  Future<void> updateServerList() async {
    int _tmpInt = 0;
    for (ServerObj objs in serverList) {
      await box.put(_tmpInt, objs);
      _tmpInt += 1;
    }
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

  Future<void> makeClient(int? index) async {
    ServerObj _base = serverList[index!]!;

    appClient = JellyfinDart(
      basePathOverride: _base.serverURL,
    );

    appClient.setMediaBrowserAuth(
      deviceId: serverList[index!].deviceId ?? randomString(),
      version: '${_base.version}',
    );

    final branding = await appClient.getBrandingApi().getBrandingOptions();
    logInMsg = branding.data?.loginDisclaimer;
  }

  Future<bool> logInByName(String user, String pwd, BuildContext context) async {
    late final response;
    final uAPI = appClient.getUserApi();
    try {
      response = await uAPI.authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(
          username: user,
          pw: pwd,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        showScaffold('Tried to log in to previous/selected server but got a bad response, either the Jellyfin instance is not available, or you entered the wrong username/password', context);
        throw DioException;
        return false;
      }
    }
    
    final token = response.data?.accessToken;
    if (token != null) {
      appClient.setToken(token);   
      userID = response.data?.sessionInfo.userId;
      return true;
    } else {
      return false;
    }
  }

  Future<List<UserDto>?> getPublicUsers() async {
    final UserApi uAPI = await appClient.getUserApi();
    late final _data;
    try {
      _data = await uAPI.getPublicUsers();
    } on DioException catch (e) {
      print(e.response);
    }
    return _data?.data;
  } 

  Future<void> saveUser(String user, String pwd, int? index) async {
    serverList[index!].userMap = serverList[index!].userMap ?? {};

    serverList[index!].userMap!['$user'] ??= '';
    serverList[index!].userMap!['$user'] = '$pwd';

    serverList[index!].save();
    // ends saving actual user data
    
    // starts saving last user
    lastUser = serverList[index!].userMap?.keys.toList().indexOf('$user');
    print('$lastUser');
    await box.put('lastUser', lastUser);

    updateServerList();
    notifyListeners();
  }

  // this function updates lastUsedServer and pushes to homepage
  Future<void> goToHome(int? index, BuildContext context) async {
    lastUsedServer = index;
    await box.put('lastUsedServer', lastUsedServer);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage(index: index)),
      (route) => false,
    );
  }
  
  // streams for homepage
  Stream<List<BaseItemDto>?> userViewsStream() async* {
    final uvAPI = appClient.getUserViewsApi();

    while (true) {
      final data = await uvAPI.getUserViews(userId: userID);
      yield data.data?.items;
      await Future.delayed(Duration(seconds: 9));
    }

  }

  Stream<List<BaseItemDto>?> getContinueWatching() async* {
    final itAPI = appClient.getItemsApi();

    while (true) {
      final data = await itAPI.getResumeItems(
        userId: userID,
        fields: <ItemFields>[
          ItemFields.overview, 
          ItemFields.taglines,
          ItemFields.tags,
        ],
      );
      yield data.data?.items ?? [];
      await Future.delayed(Duration(seconds: 9));
    }
  }

  Stream<List<BaseItemDto>?> getNextUp() async* {
    final itAPI = appClient.getItemsApi();

    while (true) {
      final data = await itAPI.getResumeItems(userId: userID);
      yield data.data?.items ?? [];
      await Future.delayed(Duration(seconds: 9));
    }
  }
}
