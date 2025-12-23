import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'comps.dart';

class JellyfinAPI extends ChangeNotifier {
  final Box box;

  JellyfinAPI(this.box);

  Map<int, Map<String, dynamic>> serverList = {}; // server data list
  int? lastUsedServer; // last used server
  late JellyfinDart appClient; // jellyfin_dart client

  // boolean loading locks
  bool isVerifyingServer = false;

  Future<void> loadAppData() async {
    Map<int, Map<String, dynamic>>? _servers = await (box.get('serverList') as Map).cast<int, Map<String, dynamic>>();
    if (_servers == null) {
      
    } else if (_servers!.isEmpty) {
      
    } else {
      final _tmpMap = Map<int, Map<String, dynamic>>.from(_servers); 
      serverList.addAll(_tmpMap);
    }
    print('$serverList');

    int? _lastServer = await box.get('lastUsedServer'); 
    if (_lastServer == null) {
      
    } else {
      _lastServer = lastUsedServer;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Can connect to server but can't access it's ServerName.\nIf the URL is working for you, check if you're getting redirected to the correct URL by the server."),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
      return false;
    } finally {
      isVerifyingServer = false;
      notifyListeners();
    }
  }

  Future<void> updateServerList() async {
    await box.put('serverList', serverList);
    print('updated server list, updated box');
  }

  Future<void> addServer(String url, String verison, String name) async {
    int _index = serverList.isEmpty ? 0 : serverList.length;
    // make map keys if they don't exist
    serverList[_index] ??= {};
    serverList[_index] ??= {};
    serverList[_index] ??= {};

    serverList[_index]!['ServerURL'] ??= {};
    serverList[_index]!['Version'] ??= {};
    serverList[_index]!['ServerName'] ??= {};

    serverList[_index]!['ServerURL'] = '$url';
    serverList[_index]!['Version'] = '$verison';
    serverList[_index]!['ServerName'] = '$name';
    await updateServerList();
    notifyListeners();
  }

  Future<void> makeClient(int index) async {
    Map<String, dynamic> _base = serverList[index]!;

    appClient = JellyfinDart(
      basePathOverride: _base['ServerURL']
    );

    appClient.setMediaBrowserAuth(
      deviceId: randomString(),
      version: _base['Version'],
    );
  }
}
