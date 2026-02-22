import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';

/// getTextStyling(): custom Text Styling
/// index: 
///   0: bold, size 60
///   1: bold, size 20
///   2: bold, size 30
///   3: size 20
///   4: bold
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
    title: Text(
      title,
      style: TextStyle(
        color: Colors.black,
      ),
    ),
    content: content.isNotEmpty ? Column(
      mainAxisSize: MainAxisSize.min,
      children: content,
    ) : null,
    actions: actions.isNotEmpty ? actions : null,
  );
}

void ServerConnectErrorDiag(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "Connection Error",
      content: [
        Text(
          "We're unable to connect to the selected server right now. Please ensure it is running and try again.", 
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}

void SimpleErrorDiag({required String title, required String desc, required BuildContext context}) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "$title",
      content: [
        Text(
          "$title", 
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}

void LogInErrorDiag(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "Log In Error",
      content: [
        Text(
          "Unable to login to the server with these credentials, please ensure they are correct and try again.", 
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}

String randomString() {
  return String.fromCharCodes(List.generate(8, (index) => Random().nextInt(33) + 89));
}

String getTime(int ticks) {
  Duration duration = Duration(microseconds: ticks * 10);

  return '${duration.inHours % 24}h ${duration.inMinutes % 60}m';
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

/*
  0: unlimited data (wifi, ethernet)
  1: limited data (mobile)
  2: no data (none)
*/
Future<ConnectivityResult> checkNetwork() async {
  final List<ConnectivityResult> result = await (Connectivity().checkConnectivity());

  print("Network Connectivity State: ${result[0]}");
  return result[0];
} 

void showScaffold(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

Widget PlayerText(String text) {
  return Text(
    text, 
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
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
           if (snapshot.data == null) {
             dev.log('${snapshot.error}');
             return Text('Failed to download libraries.');
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
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserViewPage(userView: data[index]),
                    )
                   );
                 },
                 children: <Widget>[
                   for (BaseItemDto view in data)
                     Column(
                       children: [
                         Expanded(
                           child: Container(
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
        late Widget secondWidget;
        if (snapshot.data == null) {
          secondWidget = Text('Failed to download library playlist.');
        } else  if (snapshot.connectionState == ConnectionState.waiting) {
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
                          child: Text('${view.name}', style: getTextStyling(4, context)),
                        )
                    ],
                  )
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
              Expanded(
                child: secondWidget,
              ),
            ]
            else 
              Text('')
          ],
        );
      },
    ),
  );
}
// end jellyfin api widgets
