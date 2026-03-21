import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlayment/overlayment.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:dio/dio.dart';
import 'package:jellyfin/comps/comps.dart';

class SettingsSheet extends StatefulWidget {
  final PlayerManager player;

  const SettingsSheet({super.key, required this.player});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  ValueNotifier<int> pageIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> sheetPages = [
      Column( // main page
        children: [
          ListView(
            shrinkWrap: true,
            children: [
              Card.filled(
                child: ListTile(
                  title: Text('Playback Speed'),
                  onTap: () {
                    pageIndex.value = 1;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      Center(
        child: Column(
          children: [
            Text('Playback Speed', style: getTextStyling(2, context),),
            Text('Wrong positions will not affect the speed'),
            SizedBox(height: 3,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
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
            SizedBox(height: 3,),
            FilledButton.tonal(
              onPressed: () async {
                await widget.player.setRate(1);
              },
              child: Text('Reset to Default'),
            ),
          ],
        ),
      ),
    ];

    return IconButton(
      onPressed: () {
        showSheet(
          context: context,
          heightMultipler: 0.5,
          children: [
            ValueListenableBuilder(
              valueListenable: pageIndex,
              builder: (context, value, child) => sheetPages[value],
            ),
          ],
        );
      },
      icon: Icon(Icons.settings),
      color: Colors.white,
    );
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

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    player = PlayerManager();
    starter();
  }

  @override
  void dispose() {
    super.dispose();
    Overlay.of(context).dispose();
  }

  Future<void> starter() async {
    Duration? runtimeDuration;

    final url = Provider.of<JellyfinAPI>(context, listen: false,).getStreamUrl(widget.viewData.id!);
    print('Stream Url: $url');
    if (widget.viewData.type == BaseItemKind.movie) {
      await player.addMovie(url!, widget.viewData);
    } else {
      await player.addShow(widget.viewData, context);
    }

    if (widget.resume == true) {
      print(
        'current progress of video (in seconds): ${widget.viewData.userData!.playbackPositionTicks! ~/ 10000000}',
      );

      runtimeDuration = Duration(
        seconds: widget.viewData.userData!.playbackPositionTicks! ~/ 10000000,
      );
    }

    await Future.delayed(Duration(milliseconds: 1500));

    try {
      await player.play();
      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      if (widget.resume == true) {
        await player.seek(runtimeDuration!);
      }

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );
      await Provider.of<JellyfinAPI>(
        context,
        listen: false,
      ).startPlayback(widget.viewData);
    } on DioException catch (e) {
      SimpleErrorDiag(
        title: 'Reporting Error',
        desc: 'This app could not tell the server that a playback session has started, and will not play the video to interfere with video progress.\nHTTP code: ${e.response?.statusCode}.',
        context: context,
      );
      Navigator.pop(context);
    }

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

            double playedPercentage = valueTicks / player.mediaData['BaseList'][episodeIndex].runTimeTicks.toDouble();
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
                        Text('${player.mediaData['BaseList'][episodeIndex + 1].name}'),
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

    // set the episode index here

    // stream for checking position to see if we need to add overlay

    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> autoPlayBack() async {
    final ama = Provider.of<JellyfinAPI>(context, listen: false);
    try {
        percentage = 0;
        diagName = null;

        if (player.player.state.position.inMicroseconds * 10 ~/ player.mediaData['BaseList'][episodeIndex].runTimeTicks >= 90) {
          player.mediaData['BaseList'][episodeIndex].copyWith(
            userData: player.mediaData['BaseList'][episodeIndex].userData.copyWith(
              played: true,
            ),
          );
        }

        await player.player.stream.buffering.firstWhere(
          (value) => value == false,
        );

        final newDuration = Duration(
          seconds: player.mediaData['BaseList'][episodeIndex].userData.playbackPositionTicks! ~/ 10000000,
        );

        await player.seek(newDuration);

        await player.player.stream.buffering.firstWhere(
          (value) => value == false,
        );

        await ama.stopPlayback(
          player.mediaData['BaseList'][episodeIndex],
          player.player.state.position,
        );

        episodeIndex--;

        await player.skipPrevious();

        await ama.startPlayback(player.mediaData['BaseList'][episodeIndex]);

        await Future.delayed(Duration(seconds: 1));

        playerTitle.value = '${widget.viewData.seriesName} - ${player.mediaData['BaseList'][episodeIndex].name}';
      } on RangeError catch (e) {
        print('VideoPlayerPage: Episode limit reached!');
      }
    }

  Future<void> autoPlayNext() async {
    final ama = Provider.of<JellyfinAPI>(context, listen: false);
    try {
      percentage = 0;
      diagName = null;

      if (player.player.state.position.inMicroseconds * 10 ~/ player.mediaData['BaseList'][episodeIndex].runTimeTicks >= 90) {
        player.mediaData['BaseList'][episodeIndex].copyWith(
          userData: player.mediaData['BaseList'][episodeIndex].userData.copyWith(
            played: true,
          ),
        );
      }

      await ama.stopPlayback(
        player.mediaData['BaseList'][episodeIndex],
        player.player.state.position,
      );

      episodeIndex++;
      print('Episode Index: $episodeIndex');
      await player.skipNext();

      final newDuration = Duration(
        seconds: player.mediaData['BaseList'][episodeIndex].userData.playbackPositionTicks! ~/ 10000000,
      );

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      await player.seek(newDuration);

      await player.player.stream.buffering.firstWhere(
        (value) => value == false,
      );

      await ama.startPlayback(player.mediaData['BaseList'][episodeIndex]);
      print('new episodeData: ${player.mediaData['BaseList'][episodeIndex]}');

      await Future.delayed(Duration(seconds: 1));

      playerTitle.value = '${widget.viewData.seriesName} - ${player.mediaData['BaseList'][episodeIndex].name}';
    } on RangeError catch (e) {
      print('VideoPlayerPage: Episode limit reached!');
    }
  }

  late ValueNotifier<bool> favorited = ValueNotifier<bool>(widget.viewData.userData?.isFavorite ?? false);
  ValueNotifier<String> playerTitle = ValueNotifier('');


  late int episodeIndex = player.getJellyfinIndex(widget.viewData.indexNumber ?? 0); // the number for skip buttons to use as the base (skip previous: skipInt - 1) (skip next: skipInt + 1)
   // if null, video is probably a movie, in that case, this isn't going to be used

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    VideoController videoConts = VideoController(player.player);
    MenuController menuConts = MenuController();

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
      topButtonBar: [
        IconButton(
          onPressed: () async {
            try {
              int? newPosition = player.player.state.position.inMicroseconds * 10;

              await ama.stopPlayback(
                player.mediaData['BaseList'][episodeIndex],
                (newPosition! / player.mediaData['BaseList'][episodeIndex].runTimeTicks >= 95) ? Duration(seconds: 0) : player.player.state.position,

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

            } catch (e) {
              print('back error: ${e}');
            }
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
        ValueListenableBuilder(
          valueListenable: favorited,
          builder: (context, value, child) {
            return IconButton( // mark favorite
              onPressed: () async {
                BaseItemDto? dto = player.mediaData['BaseList'][episodeIndex];
                UserItemDataDto? userDto = player.mediaData['BaseList'][episodeIndex].userData;
                if (userDto?.isFavorite == true) {
                  await ama.unmarkFavorite(player.mediaData['BaseList'][player.getJellyfinIndex(episodeIndex)].id!);
                  player.mediaData['BaseList'][episodeIndex] = dto?.copyWith(
                    userData: userDto?.copyWith(
                      isFavorite: false,
                    ),
                  );
                  print('marked unfavorite, isFavorite: ${player.mediaData['BaseList'][episodeIndex].userData.isFavorite}');
                  favorited.value = false;
                } else {
                  await ama.markFavorite(player.mediaData['BaseList'][player.getJellyfinIndex(episodeIndex)].id!);
                  player.mediaData['BaseList'][episodeIndex] = dto?.copyWith(
                    userData: userDto?.copyWith(
                      isFavorite: true,
                    ),
                  );
                  favorited.value = true;
                  print('marked favorite, isFavorite: ${player.mediaData['BaseList'][episodeIndex].userData.isFavorite}');
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
        SettingsSheet(player: player,),
        MaterialFullscreenButton(), // fullscreen button
      ],
    );

    Widget _scaffold = Scaffold(
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
    );

    return _scaffold;
  }
}
