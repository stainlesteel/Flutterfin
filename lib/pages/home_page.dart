import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

Widget UserViews(BuildContext context) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();
  return SizedBox(
    height: 200,
    child: StreamBuilder(
      stream: ama.userViewsStream(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          print('${snapshot.error}');
          return Text('Failed to download libraries.');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          final List<BaseItemDto>? data = snapshot.data;
          if (data != null) {
            return CarouselView(
              scrollDirection: Axis.horizontal,
              itemExtent: 230,
              shrinkExtent: 100,
              onTap: (index) async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserViewPage(userView: data[index]),
                  ),
                );
              },
              children: <Widget>[
                for (BaseItemDto view in data)
                  Column(
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                          errorWidget: (context, url, object) {
                            return Icon(Icons.question_mark);
                          },
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          view.name!,
                          style: getTextStyling(4, context),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          } else {
            return Text('could not download user views');
          }
        }
      },
    ),
  );
}

Widget ContinueWatching(BuildContext context) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();

  return SizedBox(
    height: 200,
    child: StreamBuilder(
      stream: ama.getContinueWatching(),
      builder: (context, snapshot) {
        late Widget secondWidget;
        if (snapshot.data == null) {
          secondWidget = Text('Failed to download library playlist.');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          secondWidget = CircularProgressIndicator();
        } else if (snapshot.hasData) {
          final List<BaseItemDto>? data = snapshot.data;
          if (data != null) {
            secondWidget = CarouselView(
              scrollDirection: Axis.horizontal,
              itemExtent: 200,
              shrinkExtent: 100,
              onTap: (index) async {
                print('${data.length}');
                print('${data[index]}');
                if (data[index] == null) {
                } else if (data[index].seriesName == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(viewData: data[index]),
                    ),
                  );
                } else if (data[index].seriesName != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(viewData: data[index]),
                    ),
                  );
                } else {}
              },
              children: <Widget>[
                for (BaseItemDto view in data)
                  Column(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: view as Object,
                          child: CachedNetworkImage(
                            imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                            errorWidget: (context, url, object) {
                              return Icon(Icons.question_mark);
                            },
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      LinearProgressIndicator(
                        value: view.userData!.playedPercentage!.round().toDouble() / 100,
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
            );
          } else {
            secondWidget = Text('could not download user views');
          }
        }
        List<BaseItemDto>? data = snapshot.data;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (data?.isNotEmpty ?? false) ...[
              Text('Continue Watching', style: getTextStyling(1, context)),
              Expanded(child: secondWidget),
            ] else
              Text(''),
          ],
        );
      },
    ),
  );
}

Widget BecauseYouWatched(BuildContext context) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();
  String? comparisonItemTitle;

  return SizedBox(
    height: 200,
    child: StreamBuilder(
      stream: ama.getSimilarItems(),
      builder: (context, snapshot) {
        late Widget secondWidget;
        if (snapshot.data == null) {
          secondWidget = Text('Failed to download similar items');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          secondWidget = CircularProgressIndicator();
        } else if (snapshot.hasData) {
          final List<BaseItemDto>? data = snapshot.data?.values.toList()[0];
          comparisonItemTitle = snapshot.data?.keys.toList()[0];
          if (data != null) {
            secondWidget = CarouselView(
              scrollDirection: Axis.horizontal,
              itemExtent: 200,
              shrinkExtent: 100,
              onTap: (index) async {
                print('${data.length}');
                print('${data[index]}');
                if (data[index] == null) {
                } else if (data[index].seriesName == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(viewData: data[index]),
                    ),
                  );
                } else if (data[index].seriesName != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(viewData: data[index]),
                    ),
                  );
                } else {}
              },
              children: <Widget>[
                for (BaseItemDto view in data)
                  Column(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: view as Object,
                          child: CachedNetworkImage(
                            imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                            errorWidget: (context, url, object) {
                              return Icon(Icons.question_mark);
                            },
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      LinearProgressIndicator(
                        value: view.userData!.playedPercentage!.round().toDouble() / 100,
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
            );
          } else {
            secondWidget = Text('could not get similar items');
          }
        }
        List<BaseItemDto>? data = snapshot.data?[0];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (snapshot.data?.isNotEmpty ?? false)
              Text('Because You Watched $comparisonItemTitle ', style: getTextStyling(1, context)),
              Expanded(child: secondWidget),
          ],
        );
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  final int? index;

  const HomePage({super.key, required this.index});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    final base = ama.serverList[widget.index!];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Jellyfin'),
        leading: TextButton(
          child: Text('Back'),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => StartingPage()),
              (route) => false,
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              FutureBuilder(
                future: ama.getCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error getting user name.');
                  } else {
                    return Text(
                      'welcome, ${snapshot.data?.name}',
                      style: getTextStyling(2, context),
                    );
                  }
                }
              ),
              Text('My Media', style: getTextStyling(1, context)),
              SizedBox(height: 10),
              SizedBox(height: 10),
              UserViews(context),
              SizedBox(height: 10),
              ContinueWatching(context),
              SizedBox(height: 10),
              BecauseYouWatched(context),
            ],
          ),
        ),
      ),
    );
  }
}
