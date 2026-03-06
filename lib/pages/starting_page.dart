import 'package:flutter/material.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';

// start default page (no server found)
class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State<StartingPage> createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  @override
  Widget build(BuildContext context) {
    MenuController menuConts = MenuController();

    var ama = context.watch<JellyfinAPI>();

    return Scaffold(
      appBar: AppBar(
        title: Text('$appTitle'),
        centerTitle: true,
        actions: [
          MenuAnchor(
            controller: menuConts,
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  );
                },
                child: Text('About'),
              ),
            ],
            builder: (context, menuConts, child) => IconButton(
              onPressed: () {
                if (menuConts.isOpen) {
                  menuConts.close();
                } else {
                  menuConts.open();
                }
              },
              icon: Icon(Icons.settings),
            ),
          ),
          SizedBox(width: 9),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final amd = context.read<JellyfinAPI>();
          final conts = TextEditingController();

          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return popUpDiag(
                title: 'Add Server',
                content: [
                  Text(
                    'Type in the full http(s) url for your server.\nDo not add a slash (/) at the end of your URL.',
                  ),
                  TextField(controller: conts),
                ],
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (amd.isVerifyingServer == true) {
                      } else {
                        final bool result = await amd.verifyServer(
                          conts.text,
                          context,
                        );
                        print('$result');
                        if (result == true) {
                          print('Server is real! Name: ${conts.text}');
                        }
                      }
                    },
                    child: Text('Ok'),
                  ),
                ],
              );
            },
          );
        },
        label: Text('Add Server'),
        icon: Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Servers', style: getTextStyling(2, context)),
            if (ama.serverList.isEmpty)
              Text('No servers Available', style: getTextStyling(1, context)),
            if (ama.serverList.isNotEmpty)
              ListView.builder(
                padding: const EdgeInsets.all(6.7),
                itemCount: ama.serverList.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  ServerObj e = ama.serverList[index];
                  return Dismissible(
                      background: Container(
                        color: Colors.redAccent,
                        child: Text('Remove'),
                      ),
                      key: ValueKey<ServerObj>(ama.serverList[index]),
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) {
                        ama.removeAtServerList(index);
                      },
                      child: Card(
                        child: ListTile(
                          onTap: () async {
                            try {
                              await ama.makeClient(e.id);
                              await Future.delayed(Duration(seconds: 1));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LogInPage(index: e.id),
                                ),
                              );
                            } catch (e) {
                              SimpleErrorDiag(
                                title: 'Connection Error', 
                                desc: 'Could not establish any connection to the server.\n This most likely happened because the server is completely down (host inaccessible).', 
                                context: context,
                              );
                            }

                          },
                          title: Text(
                            '${e.serverName}',
                            style: getTextStyling(1, context),
                          ),
                          subtitle: Text(
                            '${e.serverURL}',
                            style: getTextStyling(4, context),
                          ),
                          trailing: Text(
                            '${e.version}',
                            style: getTextStyling(4, context),
                          ),
                        ),
                      ),
                    );
                },
              ),
          ],
        ),
      ),
    );
  }
}
