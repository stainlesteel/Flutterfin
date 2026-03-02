import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';

/// simpleTile(): A simpler version of ListTile
/// args:
/// Widget? leading
/// String? title
/// Widget? trailing
/// Widget? subtitle
Widget simpleTile({
  Widget? leading = null,
  String? title = null,
  Widget? trailing = null,
  Widget? subtitle = null,
  void Function()? onTap = null,
  double padding = 10,
}) {
  return Padding(
    padding: EdgeInsets.only(left: padding, right: padding),
    child: Card(
      child: ListTile(
        leading: leading,
        subtitle: subtitle,
        title: Text('$title'),
        trailing: trailing,
        onTap: onTap,
      ),
    ),
  );
}

Widget detailCard({
  String? text = '',
  List<Widget>? children = null,
  required BuildContext context,
}) {
  if (children != null) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Row(children: children),
      ),
    );
  } else {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Text(text!, style: getTextStyling(1, context)),
      ),
    );
  }
}


Widget PlayerText(String text) {
  return Text(
    text,
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );
}

// starts jellyfin api widgets
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
                      builder: (context) => ItemPage(viewData: data[index], index: 0),
                    ),
                  );
                } else if (data[index].seriesName != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(viewData: data[index], index: 1),
                    ),
                  );
                } else {}
              },
              children: <Widget>[
                for (BaseItemDto view in data)
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
                            value:
                                view.userData!.playedPercentage!.round().toDouble() / 100,
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

// end jellyfin api widgets
