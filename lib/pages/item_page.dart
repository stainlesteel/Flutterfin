import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/comps/comps.dart';

class ItemPage extends StatefulWidget {
  BaseItemDto viewData;
  final int index; // 0: movie, 1: video/episode 

  ItemPage({super.key, required this.viewData, required this.index});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  @override
  void initState() {
    super.initState();
  }


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
                    Image(
                      fit: BoxFit.cover,
                      width: double.infinity,
                      image: CachedNetworkImageProvider(
                        '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${widget.viewData!.id!}/Images/Backdrop?tag=${widget.viewData!.imageTags?['Backdrop']}',
                      ),
                    ),
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
                    Center(
                      child: Image(
                        image: CachedNetworkImageProvider(
                          '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${widget.viewData!.id!}/Images/Logo?tag=${widget.viewData!.imageTags?['Logo']}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.index == 0) SizedBox(height: 5),
            SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () async {
                      int index = 0;
                      if (widget.viewData.seriesName != null) {
                        index = 1;
                      }
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(viewData: widget.viewData, index: index),
                        ),
                      );
                    
                      if (result != null) {
                        if (widget.index == 1 && result['episodeIndex'] != widget.viewData.indexNumber) {
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
            if (widget.index == 1) ...[
              Text('Other Episodes', style: getTextStyling(1, context)),
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
                          print('${data?.length}');
                          print('${data?[index]}');
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemPage(viewData: data?[index] ?? BaseItemDto(), index: 1),
                            ),
                          );
                        },
                        children: <Widget>[
                          for (BaseItemDto view in data ?? [])
                            if (view == widget.viewData) ...[
      
                            ]
                            else 
                              Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(0.5),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: LinearProgressIndicator(
                                        value: view.userData?.playedPercentage?.round().toDouble() ?? 0.01 / 100,
                                      ),
                                    ),
                                  ),
                                  if (view.seriesName != null) ...[
                                    Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        '${view.seriesName}',
                                        style: getTextStyling(4, context),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        'S${view.parentIndexNumber}:E${view.indexNumber}, ${view.name}',
                                      ),
                                    ),
                                  ] else
                                    Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        '${view.name}',
                                        style: getTextStyling(4, context),
                                      ),
                                    ),
                                ],
                              ),
                        ],
                      ),
                    );
                  } else {
                    return Text('Unknown Error when trying to get show episodes.');
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );

    return _scaffold;
  }
}
