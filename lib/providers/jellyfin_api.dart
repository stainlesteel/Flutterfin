import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:hive/hive.dart';
import 'package:jellyfin/objects/objects.dart';

class JellyfinAPI extends ChangeNotifier {
  final Box box;

  JellyfinAPI(this.box);

  // app data that may or may not require interaction with the jellyfin server
  List<ServerObj> serverList = [];
  int? lastUsedServer;
  dynamic appClient; // jellyfin_dart client

  // server data collected for later use
  String? logInMsg;
  String? userID;
  final List<ItemFields> itemFields = [
    ItemFields.overview,
    ItemFields.taglines,
    ItemFields.tags,
    ItemFields.remoteTrailers,
    ItemFields.mediaSources,
    ItemFields.mediaStreams,
    ItemFields.people,
  ];

  // boolean loading locks
  bool isVerifyingServer = false;

  late UserApi uAPI = appClient.getUserApi();
  late QuickConnectApi qc = appClient.getQuickConnectApi();
  late UserViewsApi uvAPI = appClient.getUserViewsApi();
  late ItemsApi itAPI = appClient.getItemsApi();
  late MediaInfoApi MIapi = appClient.getMediaInfoApi();
  late TvShowsApi tvAPI = appClient.getTvShowsApi();
  late PlaystateApi psAPI = appClient.getPlaystateApi();
  late UserLibraryApi ulAPI = appClient.getUserLibraryApi();
  late SearchApi seAPI = appClient.getSearchApi();
  late LibraryApi lAPI = appClient.getLibraryApi();

  // there is nothing here, this is because everything for this ChangeNotifier is in provider_extensions/jellyfin_api/
  // and everything is an extension
}

