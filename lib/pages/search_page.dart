import 'package:flutter/material.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/pages/pages.dart';

Widget JellyfinSearch(JellyfinAPI ama, BuildContext context, ValueNotifier<List<BaseItemDto>?> pageNotifier, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: SearchBar(
      controller: controller,
      onChanged: (String result) async {
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
      trailing: [
        ValueListenableBuilder(
          valueListenable: pageNotifier,
          builder: (context, value, child) {
            if (value == null) {
              return Text('');
            }
            return IconButton(
              onPressed: () {
                controller.clear();
                pageNotifier.value = null;
              },
              icon: Icon(Icons.cancel),
            );
          },
        ),
      ],
    ),
  );
}


Widget getListView(List<BaseItemDto>? list, JellyfinAPI ama) {
   return (list?.isNotEmpty ?? true)
   ? GridView.builder(
     shrinkWrap: true,
     padding: EdgeInsets.all(15),
     gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
       maxCrossAxisExtent: 200,
       crossAxisSpacing: 20,
       mainAxisSpacing: 20,
     ),
     scrollDirection: Axis.vertical,
     itemCount: list?.length ?? 0,
     itemBuilder: (context, index) {
       final view = list![index];
       return InkWell(
         onTap: () async {
           await Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => ItemPage(viewData: list![index]), 
             ),
           );
         },
         child: builderWidgets(context, view, ama),
       );
     },
   )
   : Text('Your search returned absolutely nothing!');
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  ValueNotifier<List<BaseItemDto>?> searchResults = ValueNotifier(null);
  TextEditingController barController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    barController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Search'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              JellyfinSearch(ama, context, searchResults, barController),
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

