import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/AdminPages/user_page.dart';
import 'package:jellyfin/pages/starting_page.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/pages/AdminPages/admin_page.dart';

Widget actualPage(ServerObj serverObj, JellyfinAPI ama, BuildContext context) {
  return Scaffold(
    appBar: null,
    body: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Column(
          children: [
            Text('${serverObj.serverName}', style: getTextStyling(2, context)),
            SizedBox(height: 5),
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Server Info', style: getTextStyling(4, context)),
                    SizedBox(height: 5),
                    Text('Server name: ${serverObj.serverName}'),
                    Text('Server version: ${serverObj.version}'),
                    Text('Server URL: ${serverObj.serverURL}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            SingleChildScrollView(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      adminCheck(context);
                  
                      final DioException? result = await ama.scanLibrary();
                      if (result == null) {
                        showScaffold('Successfully scanned library', context);
                        return;
                      }
                  
                      if (result != null) {
                        Navigator.pop(context);
                        showScaffold('${
                          (result.response?.statusCode == 401)
                          ? 'You do not have access to perform this task or access the Admin Page'
                          : 'Error when trying to scan library, HTTP Error Code: ${result.response?.statusCode}'
                        }', context);
                      }
                    },
                    child: Text('Scan Library', style: getTextStyling(4, context)),
                  ),
                  SizedBox(width: 5),
                  FilledButton.tonal(
                    onPressed: () async {
                      adminCheck(context);

                      final DioException? result = await ama.restartServer();
                      if (result == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StartingPage(),
                          ),
                          result: (route) => false,
                        );
                        showScaffold('Successfully restarted server', context);
                        return;
                      }
                  
                      if (result != null) {
                        Navigator.pop(context);
                        showScaffold('${
                          (result.response?.statusCode == 401)
                          ? 'You do not have access to perform this task or access the Admin Page'
                          : 'Error when trying to restart server, HTTP Error Code: ${result.response?.statusCode}'
                        }', context);
                      }
                    },
                    child: Text('Restart', style: getTextStyling(4, context)),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                    ),
                  ),
                  SizedBox(width: 5),
                  FilledButton.tonal(
                    onPressed: () async {
                      adminCheck(context);

                      final DioException? result = await ama.shutDownServer();
                      if (result == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StartingPage(),
                          ),
                          result: (route) => false,
                        );
                        showScaffold('Successfully shut down server', context);
                        return;
                      }
                  
                      if (result != null) {
                        Navigator.pop(context);
                        showScaffold('${
                          (result.response?.statusCode == 401)
                          ? 'You do not have access to perform this task or access the Admin Page'
                          : 'Error when trying to shut down server, HTTP Error Code: ${result.response?.statusCode}'
                        }', context);
                      }
                    },
                    child: Text('Shut Down', style: getTextStyling(4, context)),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('Devices', style: getTextStyling(1, context)),
            StreamBuilder(
              stream: ama.getSessionsStream().asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Faced an error trying to get devices, error: ${snapshot.error}');
                } else if (snapshot.hasData) {
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
                       final SessionInfoDto? session = snapshot.data?[index];
                       return Card.filled(
                         child: Column(
                           children: [
                             Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 CircleAvatar(
                                   radius: 0.5,
                                   child: CachedNetworkImage(
                                     imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/UserImage?userId=${ama.userID}',
                                     fit: BoxFit.cover,
                                     errorWidget: (context, url, child) => Text(''),
                                   ),
                                 ),
                                 SizedBox(height: 5),
                                 Text('${session?.userName ?? 'Unknown Name'}', style: getTextStyling(5, context)),
                               ],
                             ),
                             SizedBox(height: 5),
                             Text('${session?.deviceName}', style: getTextStyling(4, context)),
                             SizedBox(height: 5),
                             Text('Version ${session?.applicationVersion}', style: getTextStyling(4, context)),
                             SizedBox(height: 5),
                             Text('Last activity: ${getDeviceTime(session!.lastActivityDate!, context)}', style: getTextStyling(4, context)),
                           ],
                         ),
                       );
                     },
                  );
                } else {
                  return Text('Unknown error.');
                }
              },
            ),
            SizedBox(height: 10),
            Text('Activity', style: getTextStyling(1, context)),
            StreamBuilder(
              stream: ama.getActivityStream().asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Faced an error trying to get activity, error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return ListView.builder(
                     shrinkWrap: true,
                     physics: NeverScrollableScrollPhysics(),
                     padding: EdgeInsets.all(15),
                     itemCount: snapshot.data?.length,
                     itemBuilder: (context, index) {
                       final ActivityLogEntry? log = snapshot.data?[index];
                       return EasyTile(
                         title: Text('${log?.name}', style: getTextStyling(4, context)),
                         subtitle: Text('At: ${log?.date?.year}:${log?.date?.month}:${log?.date?.day}, ${TimeOfDay.fromDateTime(log!.date!.toLocal()).format(context)}'),
                         context: context,
                       );
                     },
                  );
                } else {
                  return Text('Unknown error.');
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

enum DrawerPages {
  actualPage(name: 'Dashboard', icon: Icons.home),
  generalPage(name: 'General', icon: Icons.settings),
  brandingPage(name: 'Branding', icon: Icons.image),
  userPage(name: 'Users', icon: Icons.supervised_user_circle),
  devicesPage(name: 'Devices', icon: Icons.devices_sharp),
  ;

  const DrawerPages({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

class PrimaryAdminPage extends StatefulWidget {
  const PrimaryAdminPage({super.key});

  @override
  State<PrimaryAdminPage> createState() => _PrimaryAdminPageState();
}

class _PrimaryAdminPageState extends State<PrimaryAdminPage> {
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    adminCheck(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    ServerObj serverObj = context.read<JellyfinAPI>().serverList[ama.lastUsedServer!];

    GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();
    Size size = MediaQuery.sizeOf(context);

    List<Widget> drawerPages = [
      actualPage(serverObj, ama, context),
      GeneralPage(),
      BrandingPage(),
      UserPage(),
      DevicesPage(),
    ];

    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        leadingWidth: 100,
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (size.width <= 700)
              IconButton(
                onPressed: () {
                  globalKey.currentState!.openDrawer();
                },
                icon: Icon(Icons.list),
              ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
            ),
          ],
        ),
      ),
      drawer: (size.width <= 700) 
      ? NavigationDrawer(
        header: Text('${serverObj.serverName}', style: getTextStyling(2, context)),
        selectedIndex: pageIndex,
        onDestinationSelected: (int newIndex) {
          setState(() {
            globalKey.currentState!.closeDrawer();
            pageIndex = newIndex;
          });
        },
        children: [
          Center(
            child: Text('Server', style: getTextStyling(4, context))
          ),
          for (var page in DrawerPages.values)
            NavigationDrawerDestination(
              icon: Icon(page.icon),
              label: Text(page.name),
            ),
        ],
      )
      : null,
      body: (size.width <= 700)
      ? drawerPages[pageIndex]
      : Row(
        children: [
          if (size.width <= 700) ...[
            NavigationRail(
              leading: Text('${serverObj.serverName}', style: getTextStyling(2, context)),
              extended: (MediaQuery.heightOf(context) >= 400),
              selectedIndex: pageIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  pageIndex = index;
                });
              },
              destinations: [
                for (var page in DrawerPages.values)
                  NavigationRailDestination(
                    icon: Icon(page.icon),
                    label: Text(page.name),
                  ),
              ],
            ),
            VerticalDivider()
          ],
          Expanded(
            child: drawerPages[pageIndex],
          ),
        ],
      ),
    );
  }
}
