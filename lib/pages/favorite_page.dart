import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

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
        physics: AlwaysScrollableScrollPhysics(),
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
                  } else if (snapshot.data!.isEmpty) {
                    return Center(child: Text('No Favorites.'));
                  } else {
                    return GridView.builder(
                       shrinkWrap: true,
                       physics: NeverScrollableScrollPhysics(),
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
                           child: builderWidgets(context, view ?? BaseItemDto(), ama),
                         );
                       },
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
