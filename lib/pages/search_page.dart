import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/pages/pages.dart';

Widget JellyfinSearch(JellyfinAPI ama, BuildContext context, ValueNotifier<List<BaseItemDto>> pageNotifier) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: SearchBar(
      onSubmitted: (String result) async {
        SearchHintResult? data = await ama.runSearch(result);

        var list = data?.searchHints;
        List<String> idList = [];

        for (SearchHint hint in list ?? []) {
          if (hint.id != null) {
            idList.add(hint.id!);
          }
        }

        List<BaseItemDto> dtoList = await ama.getItemsbyId(idList);

        pageNotifier.value = dtoList;

      },
    ),
  );
}

Widget getListView(List<BaseItemDto> list, JellyfinAPI ama) {
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
        itemCount: list.length,
        itemBuilder: (context, index) {
          final view = list[index];
          return InkWell(
            onTap: () async {
              if (list[index] == null) {
                
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemPage(viewData: list![index]), 
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
  }

  ValueNotifier<List<BaseItemDto>> searchResults = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Search'),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          child: Column(
            children: [
              JellyfinSearch(ama, context, searchResults),
              ValueListenableBuilder(
                valueListenable: searchResults,
                builder: (context, value, child) {
                  return getListView(value, ama);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

