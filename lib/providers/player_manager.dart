import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';

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
    playMedia = Media(url);

    mediaData['BaseList'] ??= [dto];
    print('mediaData: $mediaData');

    await player.open(playMedia, play: false);
  }

  Future<void> addShow(BaseItemDto dto, BuildContext context) async {
    late List<BaseItemDto>? showData;
    try {
      showData = await Provider.of<JellyfinAPI>(context, listen: false)
          .getShowEpisodes(
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
        String? url = Provider.of<JellyfinAPI>(
          context,
          listen: false,
        ).getStreamUrl(item!.id!);

        episodeData.add({'url': '$url', 'name': '${item.name}'});
      }

      // add baseitemdto list to class-wide mediaData list
      mediaData['BaseList'] ??= [];
      mediaData['BaseList'] = showData!;
      print('mediaData: $mediaData');

      playMedia = Playlist(
        [
          for (Map<String, dynamic> item in episodeData)
            Media(item['url'], extras: {'name': '${item['name']}'}),
        ], 
        index: dto!.indexNumber! - 1
      );

      await player.open(playMedia, play: false);
    }
  }

  Future<void> play() async {
    Future.delayed(Duration(seconds: 1));
    await player.play();
  }

  Future<void> pause() async {
    Future.delayed(Duration(seconds: 1));
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

    await Future.delayed(Duration(seconds: 2));
    while (true) {
      if (player.state.duration == Duration.zero || !player.state.playing) {
      } else {
        Duration duration = player.state.position;
        if (player.state.playlist.index - 1 == null) {
          _index = 0;
        }
        ama.reportPlayback(mediaData['BaseList'][_index], duration);
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> seek(Duration duration) async {
    await Future.delayed(Duration(seconds: 1));
    await player.seek(duration);
  }

  int getJellyfinIndex(int index) {
    return (index == 0) ? 0 : index - 1;
  }
}
