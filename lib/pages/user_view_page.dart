import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserViewPage extends StatefulWidget {
  final BaseItemDto userView;

  const UserViewPage({super.key, required this.userView});

  @override
  State<UserViewPage> createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    BaseItemDto userView = widget.userView;

    Widget scaffold = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_sharp),
        ),
      ),
      body: Center(
        child: StreamBuilder(
            stream: ama.getUserViewItems(parentId: widget.userView.id!), 
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); 
              } else if (snap.hasError) {
                return Text('Could not retrieve library data. \nTry re-entering this page.');
              } else if (snap.hasData) {
                final List<BaseItemDto>? data = snap.data;
                  return Column(
                    children: [
                      Text('${userView.name}', style: getTextStyling(2, context),),
                      Expanded(
                        child: GridView.builder(
                           shrinkWrap: true,
                           padding: EdgeInsets.all(15),
                           gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                             maxCrossAxisExtent: 200,
                             crossAxisSpacing: 20,
                             mainAxisSpacing: 20,
                           ),
                           scrollDirection: Axis.vertical,
                           itemCount: data?.length,
                           itemBuilder: (context, index) {
                             final view = data?[index];
                             return InkWell(
                               onTap: () async {
                                 await goToItemPage(
                                   data: view ?? BaseItemDto(),
                                   context: context,
                                 );
                               },
                               child: builderWidgets(context, view ?? BaseItemDto(), ama),
                             );
                           },
                         ),
                      ),
                    ],
                  );
              } else {
                return Text('Unknown Error.');
              }
            }
          ),
        ),
    );

    return scaffold;
  }
}
