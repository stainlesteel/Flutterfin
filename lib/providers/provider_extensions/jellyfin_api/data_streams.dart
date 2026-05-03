import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

import 'dart:math';

extension DataStreams on JellyfinAPI {
  // streams for homepage
  Stream<List<BaseItemDto>?> userViewsStream() async* {
    int timeOutLimit = 3;
    int attempts = 0;

    while (true) {
      try {
        final data = await uvAPI.getUserViews(
          userId: userID,
        );
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
          fields: itemFields,
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
          fields: itemFields,
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
      fields: itemFields,
    );

    int selectedNum = Random().nextInt(items.data!.items!.length);

    while (true) {
      try {
        final data = await lAPI.getSimilarItems(
          userId: userID,
          itemId: items.data!.items![selectedNum].id!,
          fields: itemFields,
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

  Future<List<BaseItemDto>?> getShowEpisodes({required String seriesId, int? season = null, required BuildContext context,}) async {
    late final _data;

    try {
      _data = await tvAPI.getEpisodes(
        seriesId: seriesId,
        userId: userID,
        season: season,
        fields: itemFields,
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

  Stream<List<BaseItemDto>?> showEpisodesStream({required String seriesId, int? season = null, required BuildContext context,}) async* {
    late final _data;

    try {
      _data = await tvAPI.getEpisodes(
        seriesId: seriesId,
        userId: userID,
        season: season,
        fields: itemFields,
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
          ],
          enableUserData: true,
          fields: itemFields,
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
            BaseItemKind.episode,
          ],
          enableUserData: true,
          fields: itemFields,
        );
        yield _data.data?.items;
      } catch (e) {
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  Future<List<BaseItemDto>?> getRecentlyAddedItems({SortOrder? sortBy, int? limit, String? parentId, List<BaseItemKind>? includeItemTypes}) async {
    final _data = await itAPI.getItems(
      userId: userID,
      includeItemTypes: includeItemTypes,
      sortOrder: <SortOrder>[sortBy ?? SortOrder.ascending],
      recursive: true,
      limit: limit,
      fields: itemFields,
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

  Future<BaseItemDto?> getItem(String id) async {
    final data = await ulAPI.getItem(
      userId: userID,
      itemId: id,
    );
    
    return data.data;
  }

  Future<PlaybackInfoResponse> getPlaybackInfo(String itemId) async {
    final data = await MIapi.getPlaybackInfo(itemId: itemId, userId: userID);
    return data.data!;
  }

  Future<String?> getRemoteSubtitles({required int id, required BuildContext context}) async {
    final SubtitleApi sAPI = appClient.getSubtitleApi();

    try {
      final data = await sAPI.getRemoteSubtitles(
        subtitleId: id.toString()
      );

      final subs = String.fromCharCodes(data.data!);
      return subs;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        SimpleErrorDiag(
          title: 'Subtitle Error',
          desc: 
          """
          HTTP 403
          Server did not want to give a external subtitle for this item,
          most likely you did not set up the provider for subtitles (i.e. OpenSubtitles) or it is down.
          """,
          context: context,
        );
      }
      return null;
    }
  }

  Stream<List<SessionInfoDto>?> getSessionsStream() async* {
    while (true) {
      try {
        final Response<List<SessionInfoDto>> data = await appClient.getSessionApi().getSessions(
          controllableByUserId: userID,
        );
        yield data.data;
        await Future.delayed(Duration(seconds: 9));
      } on DioException catch (e) {
        print('getSessionsStream error: ${e.response}');
        yield null;
      }
    }
  }

  Stream<List<ActivityLogEntry>?> getActivityStream() async* {
    while (true) {
      try {
        final Response<ActivityLogEntryQueryResult> data = await appClient.getActivityLogApi().getLogEntries(
          limit: 6,
        );
        yield data.data?.items;
        await Future.delayed(Duration(seconds: 9));
      } on DioException catch (e) {
        print('getActivityStream error: ${e.response}');
        yield null;
      }
    }
  }

  Future<SystemInfo?> getSystemInfo() async {
    try {
      final Response<SystemInfo> data = await appClient.getSystemApi().getSystemInfo();
      return data.data;
    } on DioException catch (e) {
      print('getActivityStream error: ${e.response}');
      return null;
    }
  }
}
