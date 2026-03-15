import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';


Widget BecauseYouWatched(BuildContext context) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();
  String? comparisonItemTitle;

  return StreamBuilder(
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
            itemExtent: 230,
            shrinkExtent: 100,
            onTap: (index) async {
              print('${data.length}');
              print('${data[index]}');
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemPage(viewData: data[index]),
                  ),
                );
            },
            children: carouselWidgets(context, data, ama),
          );
        } else {
          secondWidget = Text('could not get similar items');
        }
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (snapshot.data?.isNotEmpty ?? false || snapshot.data != null) ...[
            Text('Because You Watched ${comparisonItemTitle ?? '...'} ', style: getTextStyling(1, context)),
            SizedBox(
              height: 200,
              child: secondWidget
            ),
          ] else
            Text('')
        ],
      );
    },
  );
}

Widget RecentlyAdded(BuildContext context, List<BaseItemKind>? includeItemTypes, String title) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();

  return FutureBuilder(
    future: ama.getRecentlyAddedItems(
      sortBy: SortOrder.descending,
      limit: 15,
      includeItemTypes: includeItemTypes,
    ),
    builder: (context, snapshot) {
      late Widget secondWidget;
      if (snapshot.data == null) {
        secondWidget = Text('');
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        secondWidget = CircularProgressIndicator();
      } else if (snapshot.hasData) {
        final data = snapshot.data;
        if (data != null) {
          secondWidget = CarouselView(
            scrollDirection: Axis.horizontal,
            itemExtent: 230,
            shrinkExtent: 100,
            onTap: (index) async {
              print('${data.length}');
              print('${data[index]}');
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemPage(viewData: data[index]),
                  ),
                );
            },
            children: carouselWidgets(context, data, ama),
          );
        } else {
          secondWidget = Text('could not get similar items');
        }
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (snapshot.data?.isNotEmpty ?? false)
            Text(title, style: getTextStyling(1, context)),
            SizedBox(
              height: 200,
              child: secondWidget
            ),
        ],
      );
    },
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

   int barIndex = 0;

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    final base = ama.serverList[widget.index!];

    Orientation orientation = MediaQuery.orientationOf(context);

    Widget _actualPage(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
          title: Text('Jellyfin'),
          centerTitle: true,
          leading: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StartingPage(),
                ));
            },
            child: Text('Back'),
          ),
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
                SizedBox(height: 10),
                StreamCarousel(
                  context: context, 
                  stream: ama.userViewsStream(), 
                  title: 'My Media',
                  onTap: (int index, AsyncSnapshot snapshot) async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserViewPage(userView: snapshot.data[index]),
                      ),
                    );
                  }
                ),
                SizedBox(height: 10),
                StreamCarousel(
                  context: context, 
                  stream: ama.getContinueWatching(), 
                  title: 'Continue Watching',
                  onTap: (index, AsyncSnapshot snapshot) async {
                    try {
                      await goToItemPage(
                        index: index,
                        context: context,
                        data: snapshot.data[index],
                      );
                    } catch (e) {
                      await Future.delayed(Duration());
                    }
                  },
                ),
                SizedBox(height: 10),
                BecauseYouWatched(context),
                SizedBox(height: 10),
                RecentlyAdded(
                  context,
                  [BaseItemKind.movie],
                  'Recently Added Movies'
                ),
                SizedBox(height: 10),
                RecentlyAdded(
                  context,
                  [BaseItemKind.series],
                  'Recently Added Series',
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> barPages = [_actualPage(context), FavoritesPage(), SearchPage()];

    return Scaffold(
      bottomNavigationBar: (orientation == Orientation.portrait) 
      ? NavigationBar(
        selectedIndex: barIndex,
        onDestinationSelected: (int index) {
          setState(
            () {
              barIndex = index;
            }
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      )
      : null,
      body: Row(
        children: [
          if (orientation == Orientation.landscape) ...[
            NavigationRail(
              extended: (MediaQuery.heightOf(context) >= 700),
              selectedIndex: barIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  barIndex = index;
                });
              },
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
              ],
            ),
            VerticalDivider()
          ],
          Expanded(
            child: barPages[barIndex]
          ),
        ],
      ),
    );
  }
}
