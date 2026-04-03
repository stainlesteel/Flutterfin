import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';

extension Misc on JellyfinAPI {
  Future<void> loadAppData() async {
    final _data = box.values.whereType<ServerObj>().toList();

    serverList = _data;

    int? _tmpIndex = await box.get('lastUsedServer');
    if (_tmpIndex != null) {
      lastUsedServer = _tmpIndex;
    } else {}

    notifyListeners();
  }

  Future<bool> verifyServer(String url, BuildContext context) async {
    try {
      final dio = await Dio().get('$url/System/Info/Public');
      final conType = dio.headers.value('content-type') ?? '';

      if (dio.data['ServerName'] == null) {
        return false;
      } else if (conType.contains('text/html')) {
        showDialog(
          context: context,
          builder: (context) => popUpDiag(
            title: "Server Verify Error",
            content: [
              Text(
                "Can connect to server but can't access it's ServerName.\nIf the URL is working for you, check if you're getting redirected to the correct URL by the server.",
              ),
            ],
          ),
        );
        return false;
      } else {
        await addServer(url, dio.data['Version'], dio.data['ServerName']);
        notifyListeners();
        Navigator.pop(context);
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
      } else {
        text = 'Unknown Error.';
      }
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) =>
            popUpDiag(title: 'Server Verify Error', content: [Text('$text')]),
      );

      await Future.delayed(Duration(seconds: 2));
      return false;
    } finally {
      isVerifyingServer = false;
      notifyListeners();
    }
  }

  Future<void> makeClient(int? index) async {
    ServerObj _base = serverList[index!]!;

    appClient = JellyfinDart(
      basePathOverride: _base.serverURL,
    );

    String randrStr = randomString();
    if (serverList[index!].deviceId == null) {
      serverList[index!].deviceId = randrStr;
    }

    appClient.setMediaBrowserAuth(
      deviceId: serverList[index!].deviceId ?? randrStr,
      version: '${_base.version}',
    );

    uAPI = await appClient.getUserApi();
    qc = await appClient.getQuickConnectApi();
    uvAPI = await appClient.getUserViewsApi();
    itAPI = await appClient.getItemsApi();
    MIapi = await appClient.getMediaInfoApi();
    tvAPI = await appClient.getTvShowsApi();
    psAPI = await appClient.getPlaystateApi();
    ulAPI = await appClient.getUserLibraryApi();
    seAPI = await appClient.getSearchApi();
    lAPI = await appClient.getLibraryApi();
    notifyListeners();

    print('made client, url: ${_base.serverURL}');

    final branding = await appClient.getBrandingApi().getBrandingOptions();
    logInMsg = branding.data?.loginDisclaimer;
  }
  
  // this function updates lastUsedServer and pushes to homepage
  Future<void> goToHome(int? index, BuildContext context) async {
    lastUsedServer = index;
    await box.put('lastUsedServer', lastUsedServer);
    notifyListeners();
    Future.microtask(
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(index: index)),
        (route) => false,
      )
    );
  }

  Future<void> logOut(int index, BuildContext context) async {

    if (lastUsedServer == index) {
      lastUsedServer = null;
      await box.put('lastUsedServer', null);
    }
    serverList[index].userData == null;
    serverList[index].lastLogIsQC == null;
    serverList[index].save();
    await box.put(index, serverList[index]);
    setUser(UserData());

    Future.microtask(
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => StartingPage()),
        (route) => false,
      )
    );
    notifyListeners();
  }

  String? getStreamUrl({required BaseItemDto dto, String? mediaSourceId, int? audioStreamIndex}) {
    String baseUrl = '${serverList[lastUsedServer!].serverURL}/Videos/${dto.id}/stream?Static=true&api_key=${serverList[lastUsedServer!].userData!.accessToken}';

    if (mediaSourceId != null) {
      baseUrl = '$baseUrl&MediaSourceId=$mediaSourceId';
    }
    if (audioStreamIndex != null) {
      baseUrl = '$baseUrl&AudioStreamIndex=$audioStreamIndex';
    }

    return baseUrl;
  }
}
