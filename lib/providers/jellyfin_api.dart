import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:hive/hive.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/providers/providers.dart';

import 'dart:math';

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
  List<String>? heroIds;

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

  Future<void> updateServerList() async {
    int _tmpInt = 0;
    for (ServerObj objs in serverList) {
      await box.put(_tmpInt, objs);
      _tmpInt += 1;
    }
    notifyListeners();
  }
  
  Future removeAtServerList(int index) async {
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

  Future<void> makeClient(int? index) async {
    ServerObj _base = serverList[index!]!;

    appClient = JellyfinDart(
      dio: Dio(
        BaseOptions(
          baseUrl: _base.serverURL!,
        ),
      ),
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

  Future<bool> logInByName(
    String user,
    String pwd,
    BuildContext context,
    int index
  ) async {
    late final response;
    try {
      response = await uAPI.authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(username: user, pw: pwd),
      );
    } on DioException catch (e) {
      print('Login Status Code: ${e.response?.statusCode}');

      List<String> text = [];

      await Future.delayed(Duration(seconds: 1));

      if (e.response!.statusCode == 500) {
        ServerConnectErrorDiag(context);
      } else if (e.response!.statusCode == 503) {
        text = [
          "Server is Down",
          "Server is currently down and is under maintenance or got into an error. Check the URL in your browser for more info.",
        ];
        SimpleErrorDiag(title: text[0], desc: text[1], context: context);
      } else if (e.type == DioExceptionType.badResponse) {
        LogInErrorDiag(context);
      }
      throw DioException; // if this isn't here, the app will load the homepage even if user isn't logged in
      return false;
    }

    final token = response.data?.accessToken;
    if (token != null) {
      appClient.setToken(token);
      userID = response.data?.sessionInfo.userId;
      await saveUser(token, userID!, index);
      return true;
    } else {
      return false;
    }

  }

  Future<void> setUser(UserData data) async {
    appClient.setToken(data.accessToken);
    userID = data.userId;
    print('$userID');
  }

  // start: functions related to quick connect

  // make request for quick connect to server
  Future<QuickConnectResult?> makeQCRequest(BuildContext context) async {
    late final result;
    try {
      result = await qc.initiateQuickConnect();
    } on DioException catch (e) {
      showDialog(
        context: context,
        builder: (context) => popUpDiag(
          title: 'Quick Connect Error',
          content: [Text('Quick Connect is disabled by this server.')],
        ),
      );
    }

    return result?.data;
  }

  // check if user has accepted quick connect state
  Stream<QuickConnectResult?> getQCState(String secret) async* {
    while (true) {
      try {
        final data = await qc.getQuickConnectState(secret: secret);
        if (data.data?.authenticated == false) {
          await Future.delayed(Duration(seconds: 5));
        } else {
          yield data.data;
          break;
        }
      } catch (e) {
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  Future<bool> logInByQC(String res_secret, BuildContext context, int index) async {
    late final response;
    try {
      response = await uAPI.authenticateWithQuickConnect(
        quickConnectDto: QuickConnectDto(secret: res_secret),
      );
      serverList[index].lastLogIsQC = true;

    } on DioException catch (e) {
      late String text;
      print('Login Status Code: ${e.response?.statusCode}');
      if (e.type == DioExceptionType.badResponse) {
        LogInErrorDiag(context);
      } else if (e.response!.statusCode == 500) {
        ServerConnectErrorDiag(context);
      }

      return false;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => StartingPage()),
        (route) => false,
      );
      throw DioException;
    }

    final token = response.data?.accessToken;
    if (token != null) {
      appClient.setToken(token);
      userID = response.data?.sessionInfo.userId;
      await saveUser(token, userID!, index);
      return true;
    } else {
      return false;
    }
  }

  // end: functions related to quick connect

  Future<List<UserDto>?> getPublicUsers() async {
    late final _data;
    try {
      _data = await uAPI.getPublicUsers();
    } on DioException catch (e) {
      print(e.response);
    }
    return _data?.data;
  }

  Future<void> saveUser(String token, String userID, int? index) async {
    serverList[index!].userData = serverList[index!].userData ?? UserData();

    serverList[index].userData = UserData(accessToken: token, userId: userID);

    serverList[index].save();
    // ends saving actual user data

    updateServerList();
    notifyListeners();
  }

  Future<UserDto?> getCurrentUser() async {
    final data = await uAPI.getCurrentUser();

    return data?.data;
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
    int timeOutLimit = 3;
    int attempts = 0;

    while (true) {
      try {
        final data = await uvAPI.getUserViews(userId: userID);
        yield data.data?.items;
        await Future.delayed(Duration(seconds: 9));
      } on DioException catch (e) {
        if (attempts == timeOutLimit) {
          attempts = 0;
          yield null;
        } else {
          attempts++;
          print('userViewsStream attempts: $attempts');
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
  }

  Stream<List<BaseItemDto>?> getContinueWatching() async* {
    int attempts = 0;

    while (true) {
      try {
        final data = await itAPI.getResumeItems(
          userId: userID,
          fields: <ItemFields>[
            ItemFields.overview,
            ItemFields.taglines,
            ItemFields.tags,
          ],
        );
        yield data.data?.items ?? [];
        print('got recent items');
        await Future.delayed(Duration(seconds: 9));
      } on DioException catch (e) {
        if (attempts == 3) {
          attempts = 0;
          yield null;
        } else {
          attempts++;
          print('getContinueWatching attempts: $attempts');
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
  }

  Stream<List<BaseItemDto>?> getNextUp() async* {
    late Response<BaseItemDtoQueryResult> _data;
    while (true) {
      try {
        _data = await tvAPI.getNextUp(
          userId: userID,
          enableUserData: true,
          fields: <ItemFields>[
            ItemFields.overview,
            ItemFields.taglines,
            ItemFields.tags,
          ],
        );
        yield _data.data?.items;
      } catch (e) {
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  Stream<Map<String, List<BaseItemDto>?>?> getSimilarItems() async* {
    int attempts = 0;
    Response<BaseItemDtoQueryResult> items = await itAPI.getResumeItems(
      userId: userID,
      fields: <ItemFields>[
        ItemFields.overview,
        ItemFields.taglines,
        ItemFields.tags,
      ],
    );

    int selectedNum = Random().nextInt(items.data!.items!.length);

    while (true) {
      try {
        final data = await lAPI.getSimilarItems(
          userId: userID,
          itemId: items.data!.items![selectedNum].id!,
          fields: <ItemFields>[
            ItemFields.overview,
            ItemFields.taglines,
            ItemFields.tags,
          ],
        );
        if (data.data?.items?.isEmpty ?? false || data.data?.items == null) {
          print('retrying similar items, given data: ${items.data?.items?[selectedNum].name}');

          items.data?.items?.removeAt(selectedNum);
          selectedNum = Random().nextInt(items.data!.items!.length);

        } else {
          yield {
            '${items.data!.items![selectedNum].name}' : data.data?.items,
          };
          print('got similar items');
          await Future.delayed(Duration(seconds: 9));
        }
      } on DioException catch (e) {
        if (attempts == 3) {
          attempts = 0;
          yield null;
        } else {
          attempts++;
          print('getSimilarItems attempts: $attempts, error: ${e.message}');
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
  }

  String? getStreamUrl(String itemId) {
    return '${serverList[lastUsedServer!].serverURL}/Videos/${itemId}/stream?Static=true';
  }

  Future<List<BaseItemDto>?> getShowEpisodes({required String seriesId, int? season = null, required BuildContext context,}) async {
    late final _data;

    try {
      _data = await tvAPI.getEpisodes(
        seriesId: seriesId,
        userId: userID,
        season: season,
        fields: <ItemFields>[
          ItemFields.overview,
          ItemFields.taglines,
          ItemFields.tags,
        ],
      );
      return _data?.data?.items;
    } on DioException catch (e) {
      List<String> text = [];
      if (e.response?.statusCode == 500) {
        text = [
          "Could not fetch episodes",
          "Could not connect to the Jellyfin Server as the current user cannot be used to get Show Data.\nPlease check the Jellyfin URL to see if you can log in or not.",
        ];
      } else {
        text = ["Unknown Error", "Unknown Error"];
      }
      SimpleErrorDiag(title: text[0], desc: text[1], context: context);
    }

    return null;
  }

  Stream<List<BaseItemDto>?> showEpisodesStream ({required String seriesId, int? season = null, required BuildContext context,}) async* {
    late final _data;

    try {
      _data = await tvAPI.getEpisodes(
        seriesId: seriesId,
        userId: userID,
        season: season,
        fields: <ItemFields>[
          ItemFields.overview,
          ItemFields.taglines,
          ItemFields.tags,
        ],
      );
      yield _data?.data?.items;
    } on DioException catch (e) {
      print('showEpisodesStream(): Could not get show episodes, error: $e');
    }
    await Future.delayed(Duration(seconds: 5));
  }

  // start playback report section

  Future<void> startPlayback(BaseItemDto dto) async {

    final playbackStart = await psAPI.reportPlaybackStart(
      playbackStartInfo: PlaybackStartInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: dto.userData!.playbackPositionTicks,
      ),
    );

    print('Started PlayBack Session! ITEM ID: ${dto.id}');
  }

  Future<void> stopPlayback(BaseItemDto dto, Duration time) async {
    final timeTicks = time.inTicks;

    final playbackStop = await psAPI.reportPlaybackStopped(
      playbackStopInfo: PlaybackStopInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: timeTicks,
      ),
    );

    print(
      'Stopped PlayBack Session! ITEM ID: ${dto.id}, POSITION TICKS: $timeTicks',
    );
  }

  Future<void> reportPlayback(BaseItemDto dto, Duration time) async {
    final timeTicks = time.inTicks;

    final playbackReport = await psAPI.reportPlaybackProgress(
      playbackProgressInfo: PlaybackProgressInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: timeTicks,
      ),
    );

    print(
      'Reported PlayBack Session! ITEM ID: ${dto.id}, POSITION TICKS: $timeTicks, in seconds: ${time.inSeconds}',
    );
  }

  // stop playback report section

  Future<UserItemDataDto?> markFavorite(String itemId) async {
    final Response<UserItemDataDto> _data = await ulAPI.markFavoriteItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Future<UserItemDataDto?> unmarkFavorite(String itemId) async {
    final Response<UserItemDataDto> _data = await ulAPI.unmarkFavoriteItem(
      itemId: itemId,
      userId: userID,
    );

    return _data.data;
  }

  Stream<List<BaseItemDto>?> getUserViewItems({required String parentId,}) async* {
    late Response<BaseItemDtoQueryResult> _data;
    while (true) {
      try {
        _data = await itAPI.getItems(
          userId: userID,
          parentId: parentId,
          recursive: true,
          includeItemTypes: [
            BaseItemKind.movie,
            BaseItemKind.series,
            BaseItemKind.musicAlbum,
          ],
          enableUserData: true,
          fields: <ItemFields>[
            ItemFields.overview,
            ItemFields.taglines,
            ItemFields.tags,
          ],
        );
        yield _data.data?.items;
      } catch (e) {
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }
  
  Stream<List<BaseItemDto>?> getFavoriteItems() async* {
    late Response<BaseItemDtoQueryResult> _data;
    while (true) {
      try {
        _data = await itAPI.getItems(
          userId: userID,
          recursive: true,
          isFavorite: true,
          includeItemTypes: [
            BaseItemKind.movie,
            BaseItemKind.series,
            BaseItemKind.musicAlbum,
          ],
          enableUserData: true,
          fields: <ItemFields>[
            ItemFields.overview,
            ItemFields.taglines,
            ItemFields.tags,
          ],
        );
        yield _data.data?.items;
      } catch (e) {
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  Future<SearchHintResult?> runSearch(String term) async {
    final _data = await seAPI.getSearchHints(
      searchTerm: term,
      userId: userID,
      includeItemTypes: [BaseItemKind.episode, BaseItemKind.movie, BaseItemKind.series],
    );

    return _data.data;
  }

  Future<List<BaseItemDto>?> getRecentlyAddedItems({SortOrder? sortBy, int? limit, String? parentId, List<BaseItemKind>? includeItemTypes}) async {
    final _data = await itAPI.getItems(
      userId: userID,
      includeItemTypes: includeItemTypes,
      sortOrder: <SortOrder>[sortBy ?? SortOrder.ascending],
      recursive: true,
      limit: limit,
      fields: <ItemFields>[
        ItemFields.overview,
        ItemFields.taglines,
        ItemFields.tags,
      ],
      parentId: parentId,
    );

    return _data.data?.items;
  }

  Future<List<BaseItemDto>> getItemsbyId(List<String> idList) async {
    List<BaseItemDto> dtoList = [];
    int attempts = 0;

    for (String id in idList) {
      try {
        final _data = await ulAPI.getItem(
          userId: userID,
          itemId: id,
        );
        
        if (_data.data!.mediaType == MediaType.video) {
          dtoList.add(_data.data!);
        }

      } catch (e) {
        if (attempts == 3) {
          break;
        } else {
          continue;
        }
      }
    }

    return dtoList;
  }

  Future<List<BaseItemDto>?> getSeasons(String seriesId) async {
    final data = await tvAPI.getSeasons(
      seriesId: seriesId,
      userId: userID,
    );

    return data.data?.items;
  }
}
