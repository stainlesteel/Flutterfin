import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as dev;

TextStyle getTextStyling(int index, BuildContext context) {
  if (index == 0) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 60);
  } else if (index == 1) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 20,);
  } else if (index == 2) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 30,);
  } else if (index == 3) {
    return TextStyle(fontSize: 20,);
  } else if (index == 4) {
    return TextStyle(fontWeight: FontWeight.bold);
  } else {
    return TextStyle();
  }
}


Widget popUpDiag({String title = '', List<Widget> content = const [], List<Widget> actions = const []}) {
  return AlertDialog(
    title: Text(title),
    content: content.isNotEmpty ? Column(
      mainAxisSize: MainAxisSize.min,
      children: content,
    ) : null,
    actions: actions.isNotEmpty ? actions : null,
  );
}

String randomString() {
  return String.fromCharCodes(List.generate(8, (index) => Random().nextInt(33) + 89));
}

String getTime(int val) {
  int h = val ~/ 60;
  int m = val % 60;

  return '${h.toString().padLeft(2)}h ${m.toString().padLeft(2, "0")}m';
}

Widget detailCard({String? text = '', List<Widget>? children = null, required BuildContext context}) {
  if (children != null) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Row(
          children: children,
        ),
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

void showScaffold(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
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
           if (snapshot.hasError) {
             dev.log('${snapshot.error}');
             return Text('\$');
           } else  if (snapshot.connectionState == ConnectionState.waiting) {
             return CircularProgressIndicator();
           } else {
             final List<BaseItemDto>? data = snapshot.data;
             if (data != null) {
               return CarouselView(
                 scrollDirection: Axis.horizontal,
                 itemExtent: 230,
                 shrinkExtent: 100,
                 children: <Widget>[
                   for (BaseItemDto view in data)
                     Column(
                       children: [
                         Expanded(
                           child:  Container(
                             alignment: Alignment.center,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(0.5),
                               image: DecorationImage(
                                 image: NetworkImage(
                                   '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${view!.id!}/Images/Primary?tag=${view!.imageTags?['Primary']}',
                                 ),
                                 fit: BoxFit.cover,
                               ),
                             ),
                           ),
                         ),
                         Padding(
                           padding: EdgeInsets.only(top: 5),
                           child: Text(view.name!, style: getTextStyling(4, context)),
                         ),
                       ],
                     )
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
        if (snapshot.hasError) {
          return Text('Failed to download library playlist.');
        } else  if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          final List<BaseItemDto>? data = snapshot.data;
          if (data != null) {
            return CarouselView(
              scrollDirection: Axis.horizontal,
              itemExtent: 230,
              shrinkExtent: 100,
              onTap: (index) async {
                print('${data.length}');
                print('${data[index]}');
                if (data[index] == null) {
                  
                } else if (data[index].seriesName == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MoviePage(viewData: data[index]), 
                    ),
                  );
                } else {

                }
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
                            value: view.userData!.playedPercentage!.round().toDouble() / 100,
                          ),
                        ),
                      ),
                      if (view.seriesName != null) ...[
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text('${view.seriesName}', style: getTextStyling(4, context
                          )),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text('S${view.parentIndexNumber}:E${view.indexNumber}, ${view.name}'),
                        )
                      ]
                      else
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text('${view.name}', style: getTextStyling(4, context
                          )),
                        )
                    ],
                  )
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
// end jellyfin api widgets
