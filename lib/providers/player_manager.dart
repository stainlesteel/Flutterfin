import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/comps/dialogs.dart';
import 'package:dio/dio.dart';

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
  List<BaseItemDto> mediaData = [];
  MediaSourceInfo? currentMediaSource;

  // wrapper functions below
  Future<void> disposePlayer() async {
    mediaData = [];
    currentMediaSource = null;
    await player.dispose();
  }

  Future<void> loadMedia({
    required BaseItemDto dto, 
    required BuildContext context, 
    bool resume = true, 
    String? mediaSourceId
  }) async {
    Duration? runtimeDuration;
    SettingsProvider sets = context.read<SettingsProvider>();

    if (mediaSourceId != null) {
      await pause();
    }

    if (mediaSourceId != null) {
      runtimeDuration = Duration(
        seconds: player.state.position.inSeconds,
      );
    }

    if (dto.type == BaseItemKind.movie) {
      await addMovie(
        dto: dto, 
        context: context,
        mediaSourceId: (mediaSourceId != null) ? mediaSourceId : null,
        useHLS: sets.settingsObj!.useHLS,
      );
    } else if (dto.type == BaseItemKind.episode) {
      await addShow(
        dto: dto,
        context: context,
        mediaSourceId: mediaSourceId,
        useHLS: sets.settingsObj!.useHLS,
      );
    }

    if (resume == true) {
      print(
        'current progress of video (in seconds): ${dto.userData!.playbackPositionTicks! ~/ 10000000}',
      );

      runtimeDuration = Duration(
        seconds: dto.userData!.playbackPositionTicks! ~/ 10000000,
      );
    }

    await Future.delayed(Duration(milliseconds: 500));

    try {
      await play();
      await player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      if (resume == true || mediaSourceId != null) {
        await player.seek(runtimeDuration!);
      }

      await player.stream.buffering.firstWhere(
        (value) => value == false,
      );
      if (mediaSourceId == null) {
        await Provider.of<JellyfinAPI>(
          context,
          listen: false,
        ).startPlayback(dto);
      }
    } on DioException catch (e) {
      SimpleErrorDiag(
        title: 'Reporting Error',
        desc: 'This app could not tell the server that a playback session has started, and will not play the video to interfere with video progress.\nHTTP code: ${e.response?.statusCode}.',
        context: context,
      );
      Navigator.pop(context);
    }
  }

  Future<void> addMovie({required BaseItemDto dto, required BuildContext context, String? mediaSourceId, bool? useHLS}) async {
    BaseItemDto newDto = dto;

    final url = Provider.of<JellyfinAPI>(context, listen: false).getStreamUrl(
      dto: newDto, 
      mediaSourceId: mediaSourceId,
      useHLS: useHLS,
    );
    playMedia = Media(url!);

    final playbackInfo = await Provider.of<JellyfinAPI>(context, listen: false).getPlaybackInfo(newDto.id!);
    newDto = newDto.copyWith(
      mediaSources: playbackInfo.mediaSources,
    );
    currentMediaSource = playbackInfo.mediaSources!.first;

    mediaData = [newDto];

    await player.open(playMedia, play: false);
  }

  Future<void> addShow({required BaseItemDto dto, required BuildContext context, String? mediaSourceId, bool? useHLS}) async {
    late List<BaseItemDto>? showData;
    try {
      showData = await Provider.of<JellyfinAPI>(context, listen: false).getShowEpisodes(
        seriesId: dto.seriesId!,
        season: dto.parentIndexNumber,
        context: context,
      );
    } catch (e) {
      showData == null;
    }

    final playbackInfo = await Provider.of<JellyfinAPI>(context, listen: false).getPlaybackInfo(dto.id!);
    currentMediaSource = playbackInfo.mediaSources!.first;

    if (showData == null) {
      Navigator.pop(context);
    } else {
      List<Map<String, dynamic>> episodeData = [];

      for (BaseItemDto? item in showData ?? {}) {
        String? url = Provider.of<JellyfinAPI>(context, listen: false,).getStreamUrl(
          dto: item!, 
          mediaSourceId: mediaSourceId,
          useHLS: useHLS,
        );

        BaseItemDto newDto = item;
        final playbackInfo = await Provider.of<JellyfinAPI>(context, listen: false).getPlaybackInfo(newDto.id!);
        newDto = newDto.copyWith(
          mediaSources: playbackInfo.mediaSources,
        );
        item = newDto;


        episodeData.add({'url': '$url'});
      }

      // add baseitemdto list to class-wide mediaData list
      mediaData = showData!;
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
        ama.reportPlayback(mediaData[_index], duration);
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> seek(Duration duration) async {
    await Future.delayed(Duration(seconds: 1));
    await player.seek(duration);
  }

  Future<void> setRate(double rate) async {
    await Future.delayed(Duration(seconds: 1));
    await player.setRate(rate);
  }

  int getJellyfinIndex(int index) {
    return (index == 0) ? 0 : index - 1;
  }

  Future<void> setVideoTrack(VideoTrack track) async {
    await Future.delayed(Duration(seconds: 1));
    await player.setVideoTrack(track);
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    await Future.delayed(Duration(seconds: 1));
    await player.setAudioTrack(track);
  }
}
