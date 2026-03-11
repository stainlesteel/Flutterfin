import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    Widget scaffold = Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder(
                stream: ama.getFavoriteItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Could not get favorites.');
                  } else {
                    return Expanded(
                      child: GridView.builder(
                         shrinkWrap: true,
                         padding: EdgeInsets.all(15),
                         gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                           maxCrossAxisExtent: 200,
                           crossAxisSpacing: 20,
                           mainAxisSpacing: 20,
                         ),
                         scrollDirection: Axis.vertical,
                         itemCount: snapshot.data?.length,
                         itemBuilder: (context, index) {
                           final view = snapshot.data?[index];
                           return InkWell(
                             onTap: () async {
                               if (snapshot.data?[index] == null) {
                                 
                               } else {
                                 await Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ItemPage(viewData: snapshot.data![index]), 
                                   ),
                                 );
                               }
                             },
                             child: Column(
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
                             ),
                           );
                         },
                       ),
                    );
                  }
                }
              ),
            ],
          ),
        ),
      ),
    );

    return scaffold;
  }
}
