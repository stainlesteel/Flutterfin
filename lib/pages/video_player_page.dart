import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlayment/overlayment.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';

class SettingsSheet extends StatefulWidget {
  final PlayerManager player;
  final int episodeIndex;
  
  const SettingsSheet({super.key, required this.player, required this.episodeIndex});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> with SingleTickerProviderStateMixin {
  ValueNotifier<int> pageIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
  }

  late final Widget backButton =  SizedBox(
    width: MediaQuery.widthOf(context) * 0.75,
    child: FilledButton.tonal(
      onPressed: () {
        print('SettingsSheet(): Updating pageIndex to 0');
        pageIndex.value = 0;
      },
      child: Text('Back'),
    ),
  );

  late List<MediaStream>? audioStreamList = widget.player.currentMediaSource!.mediaStreams!
  .where((MediaStream stream) => stream.type == MediaStreamType.audio)
  .toList();

  List<double> playbackSpeedPresets = [0.25, 0.50, 0.75, 1.00, 1.25, 1.50];

  @override
  Widget build(BuildContext context) {

    final List<List<Widget>> sheetPages = [
[
        ListView(
          shrinkWrap: true,
          children: [
            Card.filled(
              child: ListTile(
                title: Text('Playback Speed'),
                onTap: () {
                  print('SettingsSheet(): Updating pageIndex to 1');
                  pageIndex.value = 1;
                },
              ),
            ),
            SizedBox(height: 7),
            Card.filled(
              child: ListTile(
                title: Text('Video Tracks'),
                onTap: () {
                  print('SettingsSheet(): Updating pageIndex to 2');
                  pageIndex.value = 2;
                },
              ),
            ),
            Card.filled(
              child: ListTile(
                title: Text('Audio Tracks'),
                onTap: () {
                  print('SettingsSheet(): Updating pageIndex to 3');
                  pageIndex.value = 3;
                },
              ),
            ),
          ],
        ),
      ],
      [
        SizedBox(height: 3,),
        Text('Playback Speed', style: getTextStyling(2, context),),
        Text('Wrong positions will not affect the speed'),
        SizedBox(height: 3,),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              hintText: 'Type the number here',
            ),
            onChanged: (string) async {
              try {
                double rate = double.parse(string);
          
                await widget.player.setRate(rate);
                print('Playback rate is now: ${double.parse(string)}');
              } catch (e) {
                print('User gave wrong playback rate');
              }
            },
          ),
        ),
        Wrap(
          spacing: 5,
          children: [
            for (double num in playbackSpeedPresets)
              InkWell(
                onTap: () async {
                  await widget.player.setRate(num);
                  print('Playback rate is now: $num');
                },
                child: Chip( 
                  label: Text('$num'),
                ),
              )
          ],
        ),
        SizedBox(height: 3,),
        SizedBox(
          width: MediaQuery.widthOf(context) * 0.75,
          child: FilledButton.tonal(
            onPressed: () async {
              await widget.player.setRate(1);
            },
            child: Text('Reset to Default'),
          ),
        ),
        SizedBox(height: 3,),
        backButton,
      ],
       [
        SizedBox(height: 3,),
        Text('Video Tracks', style: getTextStyling(2, context),),
        Text(
          'Warning: setting a Video track will reset the other audio and subtitle tracks, this is a limitation of MediaKit.'
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: widget.player.mediaData[widget.episodeIndex].mediaSources?.length ?? 0,
          itemBuilder: (context, index) {
            MediaSourceInfo data = widget.player.mediaData[widget.episodeIndex].mediaSources![index];
            return SizedBox(
              width: MediaQuery.widthOf(context) * 0.75,
              child: Card.outlined(
                child: ListTile(
                  title: Text('${data.name}', style: getTextStyling(1, context),),
                  subtitle: Text('${data.mediaStreams?.first.videoRange ?? ''}'),
                  trailing: Text('${data.mediaStreams?.first.codec ?? ''}'),
                  onTap: () async {
                    if (data == widget.player.currentMediaSource) {
                      SimpleErrorDiag(
                        title: 'Same Source',
                        desc: 'The source you tried to change to is already playing.',
                        context: context,
                      );
                    }
                    await widget.player.loadMedia(
                      dto: widget.player.mediaData[widget.episodeIndex], 
                      context: context, 
                      resume: false,
                      mediaSourceId: data.id,
                    );
                    widget.player.currentMediaSource = data;
                  },
                ),
              ),
            );
          },
        ),
        SizedBox(height: 3,),
        backButton,
      ],
      [
        SizedBox(height: 3,),
        Text('Audio Tracks', style: getTextStyling(2, context),),
        ListView.builder(
          shrinkWrap: true,
          itemCount: audioStreamList?.length ?? 0,
          itemBuilder: (context, index) {
            MediaStream data = audioStreamList![index];
            return Card.outlined(
              child: ListTile(
                title: Text('${data.displayTitle}', style: getTextStyling(1, context),),
                trailing: Text('${data.codec ?? ''}'),
                onTap: () async {
                  await widget.player.setAudioTrack(
                    AudioTrack.uri(
                      Provider.of<JellyfinAPI>(context, listen: false).getStreamUrl(
                        dto: widget.player.mediaData[widget.episodeIndex],
                        audioStreamIndex: data.index,
                      )!,
                    ),
                  );
                },
              ),
            );
          },
        ),
        SizedBox(height: 3,),
        backButton,
      ],
    ];

    return (widget.player.currentMediaSource != null) 
      ? IconButton(
      onPressed: () {
        showAnimatedSheet(
          context: context,
          child: ValueListenableBuilder(
            valueListenable: pageIndex,
            builder: (context, value, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: sheetPages[value],
              );
            } 
          ),
        );
      },
      icon: Icon(Icons.settings),
      color: Colors.white,
    )
    : Text('');
  }
}



class VideoPlayerPage extends StatefulWidget {
  final BaseItemDto viewData;
  final bool resume;

  const VideoPlayerPage({
    super.key,
    required this.viewData,
    this.resume = true,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  // streams used in the starter() method
  StreamSubscription? completeTracker;
  StreamSubscription? trackerForAutonext;
  late StreamSubscription playbackReport;

  late PlayerManager player;

  String? diagName; // this is for the auto-next dialog, and to stop stream from duplicating it
  double percentage = 0; // this is for the percentage tracking stream

  ValueNotifier<bool> loaded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    player = PlayerManager();
    starter();
  }

  @override
  void dispose() {
    Overlay.of(context).dispose();
    super.dispose();
  }

  Future<void> starter() async {
    await player.loadMedia(
      dto: widget.viewData, 
      context: context, 
      resume: widget.resume
    );

    // stream for reporting playback to Jellyfin
    playbackReport = player.reportPlaybackStream(context).listen(
      (event) {
        print('reported Playback Session!');
      },
    );

    // stream for checking completion 
    if (widget.viewData.type == BaseItemKind.episode) {
      completeTracker =  player.player.stream.completed.listen(
        (value) async {
          if (widget.viewData.type != BaseItemKind.episode) {
            return;
          }
          if (value == true) {
            await autoPlayNext();
          }
        },
      );

      trackerForAutonext = player.player.stream.position.listen(
        (value) async {
          await Future.delayed(Duration(seconds: 1));

          if (player.player.state.buffering || !player.player.state.playing) {}
          else {
            final valueTicks = value.inMicroseconds * 10;

            double playedPercentage = valueTicks / player.mediaData[episodeIndex].runTimeTicks!.toDouble();
            playedPercentage = playedPercentage * 100;
            print('$playedPercentage');
            if (playedPercentage >= 95 && diagName == null) {
              diagName = randomString();

              Overlayment.show(
                OverWindow(
                  name: diagName,
                  alignment: Alignment.bottomCenter,
                  backgroundSettings: BackgroundSettings(
                    dismissOnClick: false,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      children: [
                        Text('Next Episode Approaching...'),
                        Text('${player.mediaData[episodeIndex + 1].name}'),
                        FilledButton(
                          onPressed: () {
                            Overlayment.dismissName(diagName!);
                          },
                          child: Text('Dismiss'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await player.pause();

                            Overlayment.dismissName(diagName!);
                            await autoPlayNext();
                          },
                          child: Text('Play Next Episode'),
                        ),
                      ],
                    ),
                  ),
                ),
                context: context,
              );
            }
          }
        }
      );
    }

    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> autoPlayBack() async {
    final ama = Provider.of<JellyfinAPI>(context, listen: false);
    try {
      percentage = 0;
      diagName = null;

      if (player.player.state.position.inMicroseconds * 10 ~/ player.mediaData[episodeIndex].runTimeTicks! >= 90 ) {
        player.mediaData[episodeIndex].copyWith(
          userData: player.mediaData[episodeIndex].userData?.copyWith(
            played: true,
          ),
        );
      }

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      final newDuration = Duration(
        seconds: (player.mediaData[episodeIndex].userData != null)
        ? player.mediaData[episodeIndex].userData!.playbackPositionTicks! ~/ 10000000
        : 0,
      );

      await player.seek(newDuration);

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      await ama.stopPlayback(
        player.mediaData[episodeIndex],
        player.player.state.position,
      );

      episodeIndex--;

      await player.skipPrevious();

      final playbackInfo = await Provider.of<JellyfinAPI>(context, listen: false).getPlaybackInfo(player.mediaData[episodeIndex].id!);
      player.currentMediaSource = playbackInfo.mediaSources!.first;

      await ama.startPlayback(player.mediaData[episodeIndex]);

      await Future.delayed(Duration(seconds: 1));

      playerTitle.value = '${widget.viewData.seriesName} - ${player.mediaData[episodeIndex].name ?? 'Unknown Name'}';
    } on RangeError catch (e) {
      print('VideoPlayerPage: Episode limit reached!');
    }
  }

  Future<void> autoPlayNext() async {
    final ama = Provider.of<JellyfinAPI>(context, listen: false);
    try {
      percentage = 0;
      diagName = null;

      if (player.player.state.position.inMicroseconds * 10 ~/ player.mediaData[episodeIndex].runTimeTicks! >= 90) {
        player.mediaData[episodeIndex].copyWith(
          userData: player.mediaData[episodeIndex].userData?.copyWith(
            played: true,
          ),
        );
      }

      await ama.stopPlayback(
        player.mediaData[episodeIndex],
        player.player.state.position,
      );

      episodeIndex++;
      print('Episode Index: $episodeIndex');
      await player.skipNext();

      final newDuration = Duration(
        seconds: (player.mediaData[episodeIndex].userData != null)
        ? player.mediaData[episodeIndex].userData!.playbackPositionTicks! ~/ 10000000
        : 0,
      );

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      await player.seek(newDuration);

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      final playbackInfo = await Provider.of<JellyfinAPI>(context, listen: false).getPlaybackInfo(player.mediaData[episodeIndex].id!);
      player.currentMediaSource = playbackInfo.mediaSources!.first;

      await ama.startPlayback(player.mediaData[episodeIndex]);
      print('new episodeData: ${player.mediaData[episodeIndex]}');

      await Future.delayed(Duration(seconds: 1));

      playerTitle.value = '${widget.viewData.seriesName} - ${player.mediaData[episodeIndex].name ?? 'Unknown Episode'}';
    } on RangeError catch (e) {
      print('VideoPlayerPage: Episode limit reached!');
    }
  }

  /// leaving the page
  Future<void> pop(JellyfinAPI ama) async {
    int? newPosition = player.player.state.position.inMicroseconds * 10;

    await ama.stopPlayback(
      player.mediaData[episodeIndex],
      (newPosition! / player.mediaData[episodeIndex].runTimeTicks! >= 95) ? Duration(seconds: 0) : player.player.state.position,
    );

    playbackReport.cancel();
    if (completeTracker != null && trackerForAutonext != null) {
      completeTracker!.cancel();
      trackerForAutonext!.cancel();
    }

    await player.pause();
    await player.disposePlayer();


    await Future.delayed(Duration(milliseconds: 100));

    Navigator.pop(
      context, 
      'rebuild',
    );
  }

  late ValueNotifier<bool> favorited = ValueNotifier<bool>(widget.viewData.userData?.isFavorite ?? false);
  ValueNotifier<String> playerTitle = ValueNotifier('');

  late int episodeIndex = player.getJellyfinIndex(widget.viewData.indexNumber ?? 0); // the number for skip buttons to use as the base (skip previous: skipInt - 1) (skip next: skipInt + 1)
   // if null, video is probably a movie, in that case, this isn't going to be used

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    VideoController videoConts = VideoController(player.player);

    loaded.value = true;

    List<Widget> skipButtonList = [
      IconButton(
        // skip previous
        icon: Icon(Icons.skip_previous, color: Colors.white),
        onPressed: autoPlayBack,
      ),
      IconButton(
        // skip next
        icon: Icon(Icons.skip_next, color: Colors.white),
        onPressed: autoPlayNext,
      ),
    ];

    if (widget.viewData.seriesName != null) {
      playerTitle.value = '${widget.viewData.seriesName} - ${widget.viewData.name}';
    } else {
      playerTitle.value = '${widget.viewData.name}';
    }

    // player theme for both normal and fullscreen
    MaterialVideoControlsThemeData themeData = MaterialVideoControlsThemeData(
      seekOnDoubleTap: true,
      topButtonBar: [
        InkWell(
          onTap: () async {
            await pop(ama);
          },
          child: Row(
            spacing: 3,
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
        ),
        Spacer(),
        ValueListenableBuilder(
          valueListenable: playerTitle,
          builder: (context, value, child) {
            return Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        ),
        Spacer(),
        ValueListenableBuilder(
          valueListenable: favorited,
          builder: (context, value, child) {
            return IconButton( // mark favorite
              onPressed: () async {
                BaseItemDto? dto = player.mediaData[episodeIndex];
                UserItemDataDto? userDto = player.mediaData[episodeIndex].userData;
                if (userDto?.isFavorite == true) {
                  await ama.unmarkFavorite(player.mediaData[player.getJellyfinIndex(episodeIndex)].id!);
                  player.mediaData[episodeIndex] = dto.copyWith(
                    userData: userDto?.copyWith(
                      isFavorite: false,
                    ),
                  );
                  print('marked unfavorite, isFavorite: ${player.mediaData[episodeIndex].userData!.isFavorite!}');
                  favorited.value = false;
                } else {
                  await ama.markFavorite(player.mediaData[player.getJellyfinIndex(episodeIndex)].id!);
                  player.mediaData[episodeIndex] = dto.copyWith(
                    userData: userDto?.copyWith(
                      isFavorite: true,
                    ),
                  );
                  favorited.value = true;
                  print('marked favorite, isFavorite: ${player.mediaData[episodeIndex].userData!.isFavorite}');
                }
                await Future.delayed(Duration(seconds: 1));
              },
              icon: Icon(
                Icons.favorite,
                color: value ? Colors.red : Colors.white,
              ),
            );
          }
        ),
      ],
      primaryButtonBar: [
        Spacer(),
        IconButton(
          color: Colors.white,
          icon: Icon(Icons.replay_10),
          onPressed: () async {
            await player.seek(Duration(seconds: player.player.state.position.inSeconds - 10));
          },
        ),
        Spacer(),
        if (widget.viewData.seriesName != null) skipButtonList[0],
        Spacer(),
        MaterialPlayOrPauseButton(),
        Spacer(),
        if (widget.viewData.seriesName != null) skipButtonList[1],
        Spacer(),
        IconButton(
          color: Colors.white,
          icon: Icon(Icons.replay_10),
          onPressed: () async {
            await player.seek(Duration(seconds: player.player.state.position.inSeconds + 10));
          },
        ),
        Spacer(),
      ],
      bottomButtonBar: [
        MaterialPlayOrPauseButton(), // play pause
        MaterialPositionIndicator(), // position indicator
        Spacer(), // separate left from right
        loaded.value
        ? SettingsSheet(player: player, episodeIndex: episodeIndex)
        : CircularProgressIndicator(),
        MaterialFullscreenButton(), // fullscreen button
      ],
    );

    Widget _scaffold = PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        await pop(ama);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height,
                child: MaterialVideoControlsTheme(
                  normal: themeData,
                  fullscreen: themeData,
                  child: Video(
                    controller: videoConts,
                    controls: MaterialVideoControls,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return _scaffold;
  }
}
