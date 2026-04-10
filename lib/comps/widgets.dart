import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';

import 'package:overlayment/overlayment.dart';

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

List<Widget> carouselWidgets(BuildContext context, List<BaseItemDto> data, JellyfinAPI ama) {
  return <Widget>[
    for (BaseItemDto view in data)
      Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, child) {
                    return Icon(Icons.question_mark);
                  },
                ),
              ),
              if (view.userData?.playedPercentage != null)
                LinearProgressIndicator(
                  value: (view.userData?.playedPercentage != null) 
                  ? view.userData!.playedPercentage!.round().toDouble() / 100
                  : 0,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          if (view.userData?.played ?? false)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Icon(
                    Icons.check
                  ),
                ),
              ),
            ),
        ],
      ),
  ];
}

Widget builderWidgets(BuildContext context, BaseItemDto view, JellyfinAPI ama) {
  return Stack(
    children: [
      Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: LinearProgressIndicator(
                value: (view.userData?.playedPercentage != null) 
                ? view.userData!.playedPercentage!.round().toDouble() / 100
                : 0,
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
      if (view.userData?.played ?? false)
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Icon(
                Icons.check
              ),
            ),
          ),
        ),
    ],
  );
}

Widget StreamCarousel({required BuildContext context, required Stream stream, required String title, required Function(int index, AsyncSnapshot snapshot) onTap}) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();
  return StreamBuilder(
    stream: stream.asBroadcastStream(),
    builder: (context, snapshot) {
      late Widget secondWidget;
  
      if (snapshot.data == null) {
        print('${snapshot.error}');
        secondWidget = Text('Failed to download libraries.');
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        secondWidget = CircularProgressIndicator();
      } else {
        final List<BaseItemDto>? data = snapshot.data;
        if (data != null) {
          secondWidget = CarouselView(
            scrollDirection: Axis.horizontal,
            itemExtent: 230,
            shrinkExtent: 100,
            onTap: (int index) {
              onTap(index, snapshot);
            },
            children: carouselWidgets(context, data, ama),
          );
        } else {
          secondWidget = Text('could not download user views');
        }
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (snapshot.data?.isNotEmpty ?? false) ...[
            SizedBox(height: 10),
            Text(title, style: getTextStyling(1, context)),
            SizedBox(
              height: 200,
              child: secondWidget
            ),
          ]
        ],
      );
    },
  );
}

Widget UserAvatar({required JellyfinAPI ama, double? height}) {
  return CircleAvatar(
    backgroundColor: Colors.black,
    radius: height,
    child: CachedNetworkImage(
      imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/UserImage?userId=${ama.userID}',
      fit: BoxFit.cover,
      errorWidget: (context, url, child) => Text(''),
    ),
  );
}

Widget EasyTile({required BuildContext context, Widget? leading, Widget? trailing, Widget? title, Widget? subtitle, void Function()? onTap, EdgeInsets? padding}) {
  return Padding(
    padding: padding ?? EdgeInsets.symmetric(horizontal: 10),
    child: Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: leading,
        trailing: trailing,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    ),
  );
}
