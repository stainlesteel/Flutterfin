import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

class DownloadDialog extends StatefulWidget {
  final BaseItemDto viewData;

  DownloadDialog({super.key, required this.viewData});

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {

  @override
  void initState() {
    super.initState();
  }


  late List<MediaStream>? audioStreamList = widget.viewData.mediaSources!.first.mediaStreams!
  .where((MediaStream stream) => stream.type == MediaStreamType.audio)
  .toList();

  late Map<String, dynamic> streamParametersList = 
  {
    'MediaSourceId': widget.viewData.mediaSources!.first.id, 
    'Container': widget.viewData.mediaSources!.first.container, 
    'AudioStreamIndex': audioStreamList!.first.index, 
    'VideoBitrate': widget.viewData.mediaSources!.first.bitrate,
  };
  // for any null values, the getStreamUrl method will ignore it and not use it

  @override
  Widget build(BuildContext context) {
    bool readyToDownload = false;
    String? path;

    BaseItemDto viewData = widget.viewData;

    JellyfinAPI ama = context.watch<JellyfinAPI>();
    DownloaderManager dwm = context.watch<DownloaderManager>();

    return FloatingActionButton(
       heroTag: null,
       onPressed: 
       () async {
         showAnimatedSheet(
           context: context,
           child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Download ${viewData.name}', style: getTextStyling(1, context),),
                    SizedBox(height: 5),
                    Text('Path: ${path ?? 'Not Added'}'),
                    SizedBox(height: 5),
                    FilledButton(
                      onPressed: () async {
                        String? result = await FilePicker.getDirectoryPath(
                          dialogTitle: '$appTitle',
                        );
                        
                        setSheetState(() {
                          path = result;
                          readyToDownload = true;
                        });
                      },
                      child: Text('Select Path'),
                    ),
                    SizedBox(height: 5),
                    EasyTile(
                      title: Text('Video Track', style: getTextStyling(4, context)),
                      trailing: SizedBox(
                        width: MediaQuery.widthOf(context) * 0.3,
                        child: DropdownMenu(
                          initialSelection: '${viewData.mediaSources!.first.id}',
                          onSelected: (id) {
                            setSheetState(
                              () {
                                streamParametersList['MediaSourceId'] = id;
                              }
                            );
                          },
                          dropdownMenuEntries: [
                            for (MediaSourceInfo mediaSource in viewData.mediaSources ?? [])
                              DropdownMenuEntry(
                                value: mediaSource.id,
                                label: mediaSource.name ?? 'Unknown Track',
                              ),
                          ],
                        ),
                      ),
                      context: context
                    ),
                    SizedBox(height: 5),
                    EasyTile(
                      title: Text('Audio Tracks', style: getTextStyling(4, context)),
                      trailing: SizedBox(
                        width: MediaQuery.widthOf(context) * 0.3,
                        child: DropdownMenu(
                          initialSelection: audioStreamList!.first.index,
                          onSelected: (id) {
                            setSheetState(
                              () {
                                streamParametersList['AudioStreamIndex'] = id;
                              }
                            );
                          },
                          dropdownMenuEntries: [
                            for (MediaStream mediaStream in audioStreamList ?? [])
                              DropdownMenuEntry(
                                value: mediaStream.index,
                                label: mediaStream.displayTitle ?? 'Unknown Track',
                              ),
                          ],
                        ),
                      ),
                      context: context
                    ),
                    SizedBox(height: 5),
                    EasyTile(
                      title: Text('Container', style: getTextStyling(4, context)),
                      trailing: SizedBox(
                        width: MediaQuery.widthOf(context) * 0.3,
                        child: DropdownMenu(
                          initialSelection: '${viewData.mediaSources!.first.container}',
                          onSelected: (container) {
                            setSheetState(
                              () {
                                streamParametersList['Container'] = container;
                              }
                            );
                          },
                          dropdownMenuEntries: [
                            for (String container in [viewData.mediaSources!.first!.container ?? 'Original Unknown', 'webm', 'ogv', 'mp4', 'm4v', 'mkv', 'mpeg', 'avi', 'mov'])
                              DropdownMenuEntry(
                                value: container,
                                label: container,
                              ),
                          ],
                        ),
                      ),
                      context: context
                    ),
                    SizedBox(height: 5),
                    EasyTile(
                      title: Text('Video Quality', style: getTextStyling(4, context)),
                      subtitle: Text('Default will be used if not entered in manually'),
                      trailing: SizedBox(
                        width: MediaQuery.widthOf(context) * 0.3,
                        child: TextFormField(
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                        
                            if (intValue != null) {
                              setSheetState(
                                () {
                                  streamParametersList['VideoBitrate'] = intValue;
                                }
                              );
                            }
                          },
                          // fetch bitrate of mediasource that contains id stored above, else return first
                          initialValue: '${viewData.mediaSources!.firstWhere(
                            orElse: () {
                              return viewData.mediaSources!.first;
                            },
                          (source) => source.id == streamParametersList['MediaSourceId'])
                          .bitrate}',
                        ),
                      ),
                      context: context
                    ),
                    SizedBox(height: 5),
                    FilledButton.tonal(
                      onPressed: readyToDownload
                      ? () async {
                        DownloadTask task = DownloadTask(
                          url: ama.getStreamUrl(
                            dto: viewData,
                            mediaSourceId: streamParametersList['MediaSourceId'],
                            audioStreamIndex: streamParametersList['AudioStreamIndex'],
                            container: streamParametersList['Container'],
                            videoBitrate: streamParametersList['VideoBitrate'],
                          )!,
                          taskId: '${viewData.id}',
                          displayName: '${viewData.name}',
                          baseDirectory: BaseDirectory.root,
                          filename: '${viewData.name}.${streamParametersList['Container']}',
                          updates: Updates.statusAndProgress,
                          retries: 5,
                          allowPause: true,
                          metaData: '${viewData.name}',
                          directory: path!,
                        );

                        final result = await dwm.fileDownloader!.enqueue(task);

                        Navigator.pop(context);
                        showScaffold('Download started!', context);
                      }
                      : null,
                      child: Text('Download'),
                    ),
                  ],
                ),
              );
            },
           ),
         );
       },
       child: Icon(
         Icons.download
       ),
    );
  }
}

class ItemPage extends StatefulWidget {
  BaseItemDto viewData;

  ItemPage({super.key, required this.viewData});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {

  @override
  void initState() {
    super.initState();
  }

  Future<void> gotoVideoPlayerPage({bool resume = true}) async {
    final ama = context.read<JellyfinAPI>();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(viewData: viewData, resume: resume,),
      ),
    );
    if (result != null) {
      List<BaseItemDto> newViewData = await ama.getItemsbyId(
         [viewData.id!],
      );
      setState(
        () {
          print('Updating ITEMPAGE');
          viewData = newViewData[0];
        },
      );
    }
  }

  Future<void> rebuildPage() async {
    BaseItemDto? newViewData = await Provider.of<JellyfinAPI>(context, listen: (false)).getItem(widget.viewData.id!);

    setState(() {
      print('updating ITEMPAGE');
      viewData = newViewData!;
    });
  }

  ValueNotifier<int?> episodesIndex = ValueNotifier(null);
  // episodesIndex will only appear if the viewData is a show, 
  // it is used to manage the current season index the user wants to look at
  
  late BaseItemDto viewData = widget.viewData;

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    double runTime = viewData.runTimeTicks! / 100000000;
    double? percentage = viewData.userData?.playedPercentage;

    Widget _scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back),
          ),
        ),
        actions: [
          if (viewData.userData?.played ?? false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Icon(
                  Icons.check
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                    CachedNetworkImage(
                      imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${viewData!.id!}/Images/Primary?tag=${viewData!.imageTags?['Primary']}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${viewData!.id!}/Images/Logo?tag=${viewData!.imageTags?['Logo']}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, child) => Text(
                          '${viewData.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (viewData.type != BaseItemKind.series) ...[
                    FloatingActionButton.extended(
                      heroTag: null,
                      onPressed: gotoVideoPlayerPage,
                      icon: Icon(Icons.replay_10_rounded),
                      label: Text('Resume'),
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () async {
                        await gotoVideoPlayerPage(resume: false);
                      },
                      child: Icon(Icons.play_arrow),
                    ),
                    DownloadDialog(viewData: viewData),
                  ],
                  FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      if (viewData.userData?.isFavorite == false) {
                        await ama.markFavorite(viewData.id!);
                        print('favorited item');
                      } else {
                        await ama.unmarkFavorite(viewData.id!);
                        print('UNfavorited item');
                      }

                      await rebuildPage();
                    },
                    child: (viewData.userData?.isFavorite ?? false)
                    ? Icon(Icons.favorite, color: Colors.red,)
                    : Icon(Icons.favorite),
                  ),
                  FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      if (viewData.userData?.played == false) {
                        await ama.markPlayed(viewData.id!);
                        print('ItemPage(): Marked item PLAYED');
                      } else {
                        await ama.markunPlayed(viewData.id!);
                        print('ItemPage(): Marked item PLAYED');
                      }


                      await rebuildPage();
                    },
                    child: (viewData.userData?.played ?? false)
                    ? Icon(Icons.check, color: Colors.red,)
                    : Icon(Icons.check),
                  ),
                  if (widget.viewData.remoteTrailers?.isNotEmpty ?? false)
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () async {
                        print(widget.viewData.remoteTrailers![0].url!);
                        await goToURL(widget.viewData.remoteTrailers![0].url!);
                      },
                      child: Icon(Icons.dvr_rounded),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
            if (viewData.userData?.playedPercentage != null)
              LinearProgressIndicator(
                value: percentage! / 100,
              ),
            SizedBox(height: 7),
            if (viewData.taglines?.isNotEmpty ?? false) ...[
              Text(
                '${viewData.taglines?.firstOrNull ?? "Can't find taglines"}',
                textAlign: TextAlign.center,
                style: getTextStyling(1, context),
              ),
              SizedBox(height: 10),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 15),
                  detailCard(
                    text: '${viewData.productionYear ?? ''}',
                    context: context,
                  ),
                  SizedBox(width: 20),
                  detailCard(
                    text: '${getTime(runTime.round())}',
                    context: context,
                  ),
                  if (viewData.officialRating != null) ...[
                    SizedBox(width: 20),
                    detailCard(
                      text:
                          '${viewData.officialRating ?? 'Rating Unavailable'}',
                      context: context,
                    ),
                  ],
                  if (viewData.criticRating != null) ...[
                    SizedBox(width: 20),
                    detailCard(
                      children: [
                        Icon(Icons.rate_review, color: Colors.red),
                        SizedBox(width: 5),
                        Text(
                          '${viewData.criticRating?.round() ?? 'Unavailable'}',
                          style: getTextStyling(1, context),
                        ),
                      ],
                      context: context,
                    ),
                  ],
                  SizedBox(width: 20),
                  detailCard(
                    children: [
                      Icon(Icons.star, color: Colors.yellow),
                      SizedBox(width: 5),
                      Text(
                        '${viewData?.communityRating ?? 'Unavailable'}',
                        style: getTextStyling(1, context),
                      ),
                    ],
                    context: context,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text('${viewData?.overview ?? ''}', textAlign: TextAlign.center),
            if (viewData?.tags?.isNotEmpty ?? false) ...[
              SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 12),
                    Text('Tags:'),
                    SizedBox(width: 5),
                    for (String tag in viewData.tags ?? [])
                      detailCard(text: '$tag', context: context),
                  ],
                ),
              ),
            ],
            SizedBox(height: 30,),
            if (viewData.type == BaseItemKind.episode) ...[
              Card(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: CachedNetworkImage(
                          imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${viewData!.seriesId!}/Images/Primary?tag=${viewData.seriesPrimaryImageTag}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Colors.black.withOpacity(0.5)
                        ),
                      ),
                    ),
                    ListTile(
                      title: PlayerText(
                        'Series Page: ${viewData.seriesName}',
                      ),
                      onTap: () async {
                        BaseItemDto? seriesData = await ama.getItem(
                          viewData.seriesId!,
                        );

                        await goToItemPage(
                          context: context,
                          data: seriesData ?? BaseItemDto(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Text('Other Episodes from Season ${viewData.parentIndexNumber}', style: getTextStyling(1, context)),
              FutureBuilder(
                future: ama.getShowEpisodes(seriesId: viewData.seriesId!, context: context), 
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snap.hasError) {
                    return Text('Failed to get other episodes.');
                  } else if (snap.hasData) {
                    final List<BaseItemDto>? data = snap.data;
      
                    snap.data?.removeAt(viewData.indexNumber! - 1);
                    return SizedBox(
                      height: 200,
                      child: CarouselView(
                        scrollDirection: Axis.horizontal,
                        itemExtent: 200,
                        shrinkExtent: 100,
                        onTap: (index) async {
                          await goToItemPage(
                            context: context,
                            data: data?[index] ?? BaseItemDto(),
                          );
                        },
                        children: carouselWidgets(
                          context,
                          data ?? [],
                          ama,
                        ),
                      ),
                    );
                  } else {
                    return Text('Unknown Error when trying to get show episodes.');
                  }
                },
              ),
            ]
            else if (viewData.type == BaseItemKind.series && viewData.id != null) ...[
              Text('Episodes from ${viewData.name}', style: getTextStyling(1, context)),
              FutureBuilder(
                future: ama.getSeasons(viewData.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Could not get season data for ${viewData.name}');
                  } else {
                    List<BaseItemDto> data = snapshot.data!;
                    episodesIndex.value == 0;
                    return Wrap(
                      spacing: 5,
                      children: List<Widget>.generate(
                        data.length,
                        (int index) {
                          late bool selection;
                          if (index == 0) {
                            selection = true;
                          } else {
                            selection = false;
                          }
                          return ChoiceChip(
                            label: Text('Season ${index + 1}'),
                            selected: selection,
                            onSelected: (bool selected) {
                              episodesIndex.value == index;
                            },
                          );
                        }
                      ).toList(),
                    );
                  }
                },
              ),
              
              ValueListenableBuilder(
                valueListenable: episodesIndex,
                builder: (context, value, child) {
                  return StreamBuilder(
                    stream: ama.showEpisodesStream(seriesId: viewData.id!, season: value, context: context),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snap.hasError) {
                        return Text('Failed to get season episodes.');
                      } else if (snap.hasData) {
                        final List<BaseItemDto>? data = snap.data;
      
                        return SizedBox(
                          height: 200,
                          child: CarouselView(
                            scrollDirection: Axis.horizontal,
                            itemExtent: 200,
                            shrinkExtent: 100,
                            onTap: (index) async {
                              await goToItemPage(
                                context: context,
                                data: data?[index] ?? BaseItemDto(),
                              );

                              await rebuildPage();
                            },
                            children: carouselWidgets(
                              context,
                              data ?? [],
                              ama
                            ),
                          ),
                        );
                      } else {
                        return Text('Unknown Error when trying to get show episodes.');
                      }
                    },
                  );
                }
              ),
            ],
            SizedBox(height: 10),
            if (viewData.people != null)
              Text('Cast', style: getTextStyling(1, context)),
              SizedBox(
                height: 200,
                child: CarouselView(
                  scrollDirection: Axis.horizontal,
                  itemExtent: 230,
                  shrinkExtent: 100,
                  onTap: (int index) {
                    BaseItemPerson person = viewData.people?[index] ?? BaseItemPerson();
                    showAnimatedSheet(
                      context: context,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 130,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)
                                ),
                                child: Stack(
                                  fit: StackFit.passthrough,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${person.id!}/Images/Primary?tag=${person.primaryImageTag}',
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, child) => Text(
                                        ''
                                      ),
                                    ),
                                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
                                    Center(
                                      child: Text(
                                        '${person.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Wrap(
                                children: [
                                  SizedBox(width: 15),
                                  detailCard(
                                    text: '${person.role}',
                                    context: context,
                                  ),
                                  SizedBox(width: 20),
                                  detailCard(
                                    text: person.type.toString().toUpperCase(),
                                    context: context,
                                  ),
                                  SizedBox(width: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  children: [
                    for (BaseItemPerson person in viewData.people ?? []) ...[
                      Column(
                        children: [
                          Expanded(
                            child: HeroMode(
                              child: CachedNetworkImage(
                                imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${person.id!}/Images/Primary?tag=${person.primaryImageTag}',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, child) {
                                  return Icon(Icons.question_mark);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              '${person.name}',
                              style: getTextStyling(4, context),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return _scaffold;
  }
}
