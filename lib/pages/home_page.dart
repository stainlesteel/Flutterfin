import 'package:flutter/material.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

Widget UserViews(BuildContext context) {
  JellyfinAPI ama = context.read<JellyfinAPI>();
    
  return StreamCarousel(
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
  );
}

Widget ContinueWatching(BuildContext context) {
  JellyfinAPI ama = context.read<JellyfinAPI>();

  return StreamCarousel(
    context: context, 
    stream: ama.getContinueWatching(), 
    title: 'Continue Watching',
    onTap: (index, AsyncSnapshot snapshot) async {
      try {
        await goToItemPage(
          context: context,
          data: snapshot.data[index],
        );
      } catch (e) {
        await Future.delayed(Duration());
      }
    },
  );
}

Widget NextUp(BuildContext context) {
  JellyfinAPI ama = context.read<JellyfinAPI>();
  
  return StreamCarousel(
    context: context, 
    stream: ama.getNextUp(), 
    title: 'Next Up',
    onTap: (index, AsyncSnapshot snapshot) async {
      try {
        await goToItemPage(
          context: context,
          data: snapshot.data[index],
        );
      } catch (e) {
        await Future.delayed(Duration());
      }
    },
  );
}

Widget BecauseYouWatched(BuildContext context) {
  JellyfinAPI ama = context.watch<JellyfinAPI>();
  String? comparisonItemTitle;

  return StreamBuilder(
    stream: ama.getSimilarItems().asBroadcastStream(),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (snapshot.data?.isNotEmpty ?? false || snapshot.data != null) ...[
            Text('Because You Watched ${comparisonItemTitle ?? '...'} ', style: getTextStyling(1, context)),
            SizedBox(
              height: 200,
              child: secondWidget
            ),
          ] else
            SizedBox(height: 0, width: 0,)
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
        mainAxisSize: MainAxisSize.min,
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
  bool? userIsOk;

  Future<void> verifyUser() async {
    final data = await Provider.of<JellyfinAPI>(context, listen: false).getCurrentUser();
    setState(() {
      if (data == null) {
        userIsOk = false;
      } else {
        userIsOk = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Provider.of<JellyfinAPI>(context, listen: false).lastUsedServer = widget.index;
    verifyUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  int barIndex = 0;

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    SettingsProvider sets = context.watch<SettingsProvider>();

    Orientation orientation = MediaQuery.orientationOf(context);

    Widget errorPage = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Error', style: getTextStyling(5, context),),
        Text('Server: ${ama.serverList[ama.lastUsedServer!].serverName}'),
        Text("Please log in and out again, \nthe previous log in data isn't usable."),
        SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () async {
            await ama.logOut(widget.index!, context);
          },
          child: Text("Ok"),
        ),
      ],
    );

    Widget _actualPage(BuildContext context) {
      // the carousels list is for linking widget functions to enums under the same index
      Map<HomepageCarousels, Widget> carouselsList = {
        HomepageCarousels.userViews : UserViews(context),
        HomepageCarousels.continueWatching : ContinueWatching(context),
        HomepageCarousels.becauseYouWatched : BecauseYouWatched(context),
        HomepageCarousels.recentMovies : RecentlyAdded(
          context,
          [BaseItemKind.movie],
          'Recently Added Movies'
        ),
        HomepageCarousels.recentShows : RecentlyAdded(
          context,
          [BaseItemKind.series],
          'Recently Added Series',
        ),
        HomepageCarousels.nextUp : NextUp(context),
        HomepageCarousels.none : SizedBox(height: 0, width: 0,),
      };

      if (userIsOk == null) {
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
        return Scaffold(
        appBar: AppBar(
          title: Text('Jellyfin'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: userIsOk! ? Column(
              children: [
                if (sets.settingsObj!.showUsername == true)
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
                for (HomepageCarousels carousels in sets.settingsObj!.homepageCarousels)
                  carouselsList[carousels]!
              ],
            )
            : errorPage,
          ),
        ),
      );
    }

    List<Widget> barPages = [
      _actualPage(context), 
      FavoritesPage(), 
      SearchPage(),
      ProfilePage(),
    ];

    return Scaffold(
      bottomNavigationBar: (orientation == Orientation.portrait && userIsOk == true) 
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
          NavigationDestination(
            icon: SizedBox(
              height: 30,
              child: UserAvatar(ama: ama)
            ),
            label: 'Profile',
          ),
        ],
      )
      : null,
      body: Row(
        children: [
          if (orientation == Orientation.landscape && userIsOk == true) ...[
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
                NavigationRailDestination(
                  icon: SizedBox(
                    height: 30,
                    child: UserAvatar(ama: ama)
                  ),
                  label: Text('Profile'),
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
