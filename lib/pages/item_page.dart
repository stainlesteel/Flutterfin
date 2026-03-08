import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/comps/comps.dart';

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

  ValueNotifier<int?> episodesIndex = ValueNotifier(null);
  // episodesIndex will only appear if the viewData is a show, 
  // it is used to manage the current season index the user wants to look at

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    double runTime = widget.viewData.runTimeTicks! / 100000000;
    double? percentage = widget.viewData.userData?.playedPercentage;

    Widget _scaffold = Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                    Hero(
                      tag: widget.viewData,
                      child: CachedNetworkImage(
                        imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${widget.viewData!.id!}/Images/Primary?tag=${widget.viewData!.imageTags?['Primary']}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${widget.viewData!.id!}/Images/Logo?tag=${widget.viewData!.imageTags?['Logo']}',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, child) => Text(
                          '${widget.viewData.name}',
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
            if (widget.viewData.type == BaseItemKind.movie) SizedBox(height: 5),
            SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.viewData.type != BaseItemKind.series)
                    FilledButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerPage(viewData: widget.viewData),
                          ),
                        );
                        if (result != null) {
                          if (widget.viewData.type == BaseItemKind.episode && result['episodeIndex'] != widget.viewData.indexNumber) {
                          } else {
                            print(
                              'previous positionTicks: ${widget.viewData.userData?.playbackPositionTicks}',
                            );
                            try {
                              widget.viewData = widget.viewData.copyWith(
                                userData: widget.viewData.userData?.copyWith(
                                  playbackPositionTicks: result['positionTicks'],
                                  playedPercentage: result['positionTicks'] / widget.viewData.runTimeTicks * 100,
                                  isFavorite: result['isFavorite'],
                                ),
                              );
                              setState(() {
                                percentage = widget.viewData.userData?.playedPercentage;
                              });
                      
                              print(
                                'updated positionTicks: ${widget.viewData.userData?.playbackPositionTicks}\nNEW percentage: ${widget.viewData.userData?.playedPercentage}',
                              );
                            } catch (e) {
                              print('FAILED TO USE copyWith');
                            }
                            }
                        }
                      },
                      child: Text('Play'),
                    ),
                ],
              ),
            ),
            SizedBox(height: 7),
            if (widget.viewData.userData?.playedPercentage != null)
              LinearProgressIndicator(
                value: percentage! / 100,
              ),
            SizedBox(height: 7),
            if (widget.viewData.taglines?.isNotEmpty ?? false) ...[
              Text(
                '${widget.viewData.taglines?.firstOrNull ?? "Can't find taglines"}',
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
                    text: '${widget.viewData.productionYear ?? ''}',
                    context: context,
                  ),
                  SizedBox(width: 20),
                  detailCard(
                    text: '${getTime(runTime.round())}',
                    context: context,
                  ),
                  if (widget.viewData.officialRating != null) ...[
                    SizedBox(width: 20),
                    detailCard(
                      text:
                          '${widget.viewData.officialRating ?? 'Rating Unavailable'}',
                      context: context,
                    ),
                  ],
                  if (widget.viewData.criticRating != null) ...[
                    SizedBox(width: 20),
                    detailCard(
                      children: [
                        Icon(Icons.rate_review, color: Colors.red),
                        SizedBox(width: 5),
                        Text(
                          '${widget.viewData.criticRating?.round() ?? 'Unavailable'}',
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
                        '${widget.viewData?.communityRating ?? 'Unavailable'}',
                        style: getTextStyling(1, context),
                      ),
                    ],
                    context: context,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text('${widget.viewData?.overview ?? ''}', textAlign: TextAlign.center),
            if (widget.viewData?.tags?.isNotEmpty ?? false) ...[
              SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 12),
                    Text('Tags:'),
                    SizedBox(width: 5),
                    for (String tag in widget.viewData.tags ?? [])
                      detailCard(text: '$tag', context: context),
                  ],
                ),
              ),
            ],
            SizedBox(height: 30,),
            if (widget.viewData.type == BaseItemKind.episode) ...[
              Text('Other Episodes from Season ${widget.viewData.parentIndexNumber}', style: getTextStyling(1, context)),
              FutureBuilder(
                future: ama.getShowEpisodes(seriesId: widget.viewData.seriesId!, context: context), 
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snap.hasError) {
                    return Text('Failed to get other episodes.');
                  } else if (snap.hasData) {
                    final List<BaseItemDto>? data = snap.data;
      
                    snap.data?.removeAt(widget.viewData.indexNumber! - 1);
                    return SizedBox(
                      height: 200,
                      child: CarouselView(
                        scrollDirection: Axis.horizontal,
                        itemExtent: 200,
                        shrinkExtent: 100,
                        onTap: (index) async {
                          await goToItemPage(
                            index: index,
                            context: context,
                            data: data?[index] ?? BaseItemDto(),
                          );
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
              ),
            ]
            else if (widget.viewData.type == BaseItemKind.series && widget.viewData.id != null) ...[
              Text('Episodes from ${widget.viewData.name}', style: getTextStyling(1, context)),
              FutureBuilder(
                future: ama.getSeasons(widget.viewData.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Could not get season data for ${widget.viewData.name}');
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
                  return FutureBuilder(
                    future: ama.getShowEpisodes(seriesId: widget.viewData.id!, season: value, context: context),
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
                                index: index,
                                context: context,
                                data: data?[index] ?? BaseItemDto(),
                              );
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
          ],
        ),
      ),
    );

    return _scaffold;
  }
}
