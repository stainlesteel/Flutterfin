import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/starting_page.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PrimaryAdminPage extends StatefulWidget {
  const PrimaryAdminPage({super.key});

  @override
  State<PrimaryAdminPage> createState() => _PrimaryAdminPageState();
}

class _PrimaryAdminPageState extends State<PrimaryAdminPage> {

  @override
  void initState() {
    super.initState();
    adminCheck();
  }

  Future<void> adminCheck() async {
    UserDto? result = await Provider.of<JellyfinAPI>(context, listen: false).getCurrentUser();
    if (result?.policy?.isAdministrator == false) {
      Navigator.pop(context);
      showScaffold('User with normal privileges tried to access Admin Page', context);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    ServerObj serverObj = context.read<JellyfinAPI>().serverList[ama.lastUsedServer!];

    return Scaffold(
      appBar: AppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
            ),
          ],
        ),
      ),
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
                        adminCheck();
                    
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
                        adminCheck();

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
                        adminCheck();

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
                               Text('Last activity: ${session?.lastActivityDate?.year}:${session?.lastActivityDate?.month}:${session?.lastActivityDate?.day}, ${TimeOfDay.fromDateTime(session!.lastActivityDate!.toLocal()).format(context)}', style: getTextStyling(4, context)),
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
}
