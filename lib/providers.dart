import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'comps.dart';
import 'objects.dart';
import 'pages.dart';
// media kit
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
        showDialog(
          context: context,
          builder: (context) =>  popUpDiag(
            title: "Server Verify Error", 
            content: [
              Text("Can connect to server but can't access it's ServerName.\nIf the URL is working for you, check if you're getting redirected to the correct URL by the server."),
            ],
          ),
        );
        return false;
      } 
      else {
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
        builder: (context) => popUpDiag(title: 'Server Verify Error', content: [Text('$text')])
      );
      return false;
    } finally {
      isVerifyingServer = false;
      notifyListeners();
    }
  }

  Stream<DioException?> pingServerStream(BuildContext context) async* {
    while (true) {
      final exception = await pingServer(context);
      await Future.delayed(Duration(seconds: 2));
      if (exception != null) {
        yield exception;
      } else {
        yield null;
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  // intended only for a stream and if user is already logged in
  Future<DioException?> pingServer(BuildContext context) async {
    try {
      final dio = await Dio().get('${serverList[lastUsedServer!].serverURL}');
      return null;
    } on DioException catch (e) {
      return e;
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
      dio: Dio(
        BaseOptions(
          responseType: ResponseType.plain,
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

    final branding = await appClient.getBrandingApi().getBrandingOptions();
    logInMsg = branding.data?.loginDisclaimer;
  }

  Future<bool> logInByName(String user, String pwd, BuildContext context) async {
    late final response;
    var uAPI = appClient.getUserApi();
    try {
      response = await uAPI.authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(
          username: user,
          pw: pwd,
        ),
      );
    } on DioException catch (e) {
      print('Login Status Code: ${e.response?.statusCode}');
      
      List<String> text = [];

      await Future.delayed(Duration(seconds: 1));

      if (e.type == DioExceptionType.badResponse) {
        LogInErrorDiag(context);
      } else if (e.response!.statusCode == 500) {
        ServerConnectErrorDiag(context);
      } else if (e.response!.statusCode == 503) {
        text = ["Server is Down", "Server is currently down and is under maintenance or got into an error. Check the URL in your browser for more info."];
        SimpleErrorDiag(
          title: text[0], 
          desc: text[1], 
          context: context
        );
      }
      throw DioException;
      return false;
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

  // start: functions related to quick connect
  
  // make request for quick connect to server
  Future<QuickConnectResult?> makeQCRequest(BuildContext context) async {
    late final result;
    final qc = appClient.getQuickConnectApi();

    try {
      result = await qc.initiateQuickConnect();
    } on DioException catch (e) {
      showDialog(
        context: context,
        builder: (context) => popUpDiag(
          title: 'Quick Connect Error',
          content: [
            Text('Quick Connect is disabled by this server.')
          ],
        ),
      );
      
    }

    return result?.data;
  }

  // check if user has accepted quick connect state
  Stream<QuickConnectResult?> getQCState(String secret) async* {
    final qc = appClient.getQuickConnectApi();

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

  Future<bool> logInByQC(String res_secret, BuildContext context) async {
    late final response;
    final uAPI = appClient.getUserApi();
    try {
      response = await uAPI.authenticateWithQuickConnect(
        quickConnectDto: QuickConnectDto(secret: res_secret),
      );
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
        MaterialPageRoute(
          builder: (context) => StartingPage(),
        ),
        (route) => false,
      );
      throw DioException;
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

  // end: functions related to quick connect

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

  Future<UserDto?> getCurrentUser() async {
    final uAPI = await appClient.getUserApi();
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
    UserViewsApi uvAPI = appClient.getUserViewsApi();
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
    ItemsApi itAPI = appClient.getItemsApi();
    int timeOutLimit = 3;
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

  Future<PlaybackInfoResponse?> getPlayBackData(String id) async {
    MediaInfoApi _api = await appClient.getMediaInfoApi();
    Response<PlaybackInfoResponse> _data = await _api.getPostedPlaybackInfo(
      itemId: id,
      userId: userID,
    );
    print('${_data?.data}');

    return _data?.data;
  }

  String? getStreamUrl(String itemId) {
    return '${serverList[lastUsedServer!].serverURL}/Videos/${itemId}/stream?Static=true';
  }

  Future<List<BaseItemDto>?> getShowEpisodes({required String seriesId, int? season = null, BuildContext? context = null}) async {
    if (context == null) {
      print('getShowEpisodes(): Your Code Sucks! Add context to getShowEpisodes()');
      return null;
    } else {
      final tvAPI = await appClient.getTvShowsApi();
      late final _data;

      try {
        _data = await tvAPI.getEpisodes(
          seriesId: seriesId,
          userId: userID,
          season: season,
        );
        return _data?.data?.items;
      } on DioException catch (e) {
        List<String> text = [];
        if (e.response?.statusCode == 500) {
          text = [
            "Could not fetch episodes", 
            "Could not connect to the Jellyfin Server as the current user cannot be used to get Show Data.\nPlease check the Jellyfin URL to see if you can log in or not."
          ];
        } else {
          text = [
            "Unknown Error",
            "Unknown Error"
          ];    
        }
        SimpleErrorDiag(
          title: text[0],
          desc: text[1],
          context: context,
        );
      }
      
      return null;

    }
  }

  // start playback report section

  Future<void> startPlayback(BaseItemDto dto) async {
    final psAPI = await appClient.getPlaystateApi();

    final playbackStart = await psAPI.reportPlaybackStart(
      playbackStartInfo: PlaybackStartInfo(
        item: dto,
        itemId: dto.id,
      ),
    );

    print('Started PlayBack Session! ITEM ID: ${dto.id}');
  }

  Future<void> stopPlayback(BaseItemDto dto) async {
    final psAPI = await appClient.getPlaystateApi();

    final playbackStop = await psAPI.reportPlaybackStopped(
      playbackStopInfo: PlaybackStopInfo(
        item: dto,
        itemId: dto.id,
      ),
    );

    print('Stopped PlayBack Session! ITEM ID: ${dto.id}');
  }

  Future<void> reportPlayback(BaseItemDto dto, Duration time) async {
    final psAPI = await appClient.getPlaystateApi();
    final timeTicks = time.inTicks;

    final playbackReport = await psAPI.reportPlaybackProgress(
      playbackProgressInfo: PlaybackProgressInfo(
        item: dto,
        itemId: dto.id,
        positionTicks: timeTicks,
      )
    );

    print('Reported PlayBack Session! ITEM ID: ${dto.id}, POSITION TICKS: $timeTicks');
  }

  // stop playback report section

  Future<List<SessionInfoDto>?> getSessionInfo() async {
    final sAPI = await appClient.getSessionApi();
    final _data = await sAPI.getSessions(
      deviceId: serverList[lastUsedServer!].deviceId,
    );

    return _data?.data;
  }

}

extension Ticks on Duration {
  int get inTicks => inMicroseconds * 10;
}

// wrapper class for MediaKit
class PlayerManager {
  late var playMedia;

  final Player player = Player(
    configuration: PlayerConfiguration(
      title: 'Jellyfin',
      logLevel: MPVLogLevel.v,
    ),
  );

  /* mediaData structure:
      {
        'BaseList': List<BaseItemDto>?,
        'subtitleList': List<????>,
      }
   */
  Map<String, dynamic> mediaData = {};

  // wrapper functions below
  Future<void> disposePlayer() async {
    await player.dispose();
  }

  Future<void> addMovie(String url, BaseItemDto dto) async {
    playMedia = Media(
      url,
    );

    mediaData['BaseList'] ??= [dto];
    print('mediaData: $mediaData');

    await player.open(playMedia);
  }

  Future<void> addShow(BaseItemDto dto, BuildContext context) async {
    late List<BaseItemDto>? showData;
    try {
      showData = await Provider.of<JellyfinAPI>(context, listen: false).getShowEpisodes(
        seriesId: dto!.seriesId!,
        season: dto?.parentIndexNumber,
        context: context,
      );
    } catch (e) {
      showData == null;
    }

    if (showData == null) {
      Navigator.pop(context);
    } else {
      List<Map<String, dynamic>> episodeData = [];

      for (BaseItemDto? item in showData! ?? {}) {
        String? url = Provider.of<JellyfinAPI>(context, listen: false).getStreamUrl(item!.id!);

        episodeData.add({'url': '$url', 'name': '${item.name}'});
      }

      // add baseitemdto list to class-wide mediaData list
      mediaData['BaseList'] ??= [];
      mediaData['BaseList'] = showData!;
      print('mediaData: $mediaData');

      playMedia = Playlist(
        [
          for (Map<String, dynamic> item in episodeData)
            Media(
              item['url'],
              extras: {
                'name': '${item['name']}',
              },
            )
        ],
        index: dto!.indexNumber! - 1,
      );

      await player.open(playMedia);
    }

  }

  Future<void> play() async {
    Future.delayed(Duration(seconds: 1),);
    await player.play();
  }

  Future<void> pause() async {
    Future.delayed(Duration(seconds: 1),);
    await player.pause();
  }

  Future<void> skipNext() async {
    Future.delayed(Duration(seconds: 1));
    await player.next();
  }

  Future<void> skipPrevious() async {
    Future.delayed(Duration(seconds: 1));
    await player.previous();
  }

  Stream<void> reportPlaybackStream(BuildContext context) async* {
    JellyfinAPI ama = context.read<JellyfinAPI>();
    int _index = player.state.playlist.index;

    while (true) {
      if (player.state.playing == false) {
        
      } else {
        Duration duration = player.state.position;
        if (player.state.playlist.index -1 == null) {
          _index = 0;
        }
        ama.reportPlayback(
          mediaData['BaseList'][_index],
          duration,
        );
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }
}
