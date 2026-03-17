import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';

extension PostFutures on JellyfinAPI {
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


  Future<SearchHintResult?> runSearch(String term) async {
    final _data = await seAPI.getSearchHints(
      searchTerm: term,
      userId: userID,
      includeItemTypes: [BaseItemKind.episode, BaseItemKind.movie, BaseItemKind.series],
    );

    return _data.data;
  }
}
