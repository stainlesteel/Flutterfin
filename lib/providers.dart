import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';

class JellyfinAPI extends ChangeNotifier {
  final Box box;

  JellyfinAPI(this.box);

  Map<int, Map<String, dynamic>> serverList = {};
  int? lastUsedServer;

  // boolean loading locks
  bool isVerifyingServer = false;

  Future<void> loadAppData() async {
    Map<int, Map<String, dynamic>> _servers = await box.get('serverList');
    if (_servers.isEmpty) {
      
    } else {
      _servers = serverList;
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
        return true;
        await Provider.of<JellyfinAPI>(context, listen: false).addServer(url, dio.data['Version'], dio.data['ServerName']);
      }
    } on DioException catch (e) {
      print('dio errror type in add server: ${e.type}');
      String text = '';
      if (e.type == DioExceptionType.unknown) {
        text = 'Unknown error when trying to verify server.';
      } else if (e.type == DioExceptionType.connectionError) {
        text = 'Failed to connect to server.';
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
      return false;
    } on TypeError catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Can connect to server but is not a Jellyfin Instance (couldn't get ServerName)."),
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
    if (serverList.isEmpty) {
        serverList[0]!['ServerURL'] = url;
        serverList[0]!['Version'] = verison;
        serverList[0]!['ServerName'] = name;
    } else {    
        serverList[serverList.length]!['ServerURL'] = url;
        serverList[serverList.length]!['Version'] = verison;
        serverList[serverList.length]!['ServerName'] = name;
    }
    await updateServerList();
    notifyListeners();
  }

  void makeClient(String url) {

  }
}
