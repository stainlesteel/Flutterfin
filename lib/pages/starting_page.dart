import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin/pages/pages.dart';
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
                  SizedBox(height: 5,),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(), 
                    ),
                    controller: conts
                  ),
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
                      if (ama.isVerifyingServer == true) {
                      } else {
                        final bool result = await ama.verifyServer(
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Servers', style: getTextStyling(2, context)),
              if (ama.serverList.isEmpty)
                Text('No servers Available', style: getTextStyling(1, context)),
              if (ama.serverList.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(6.7),
                  itemCount: ama.serverList.length,
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
                                await ama.makeClient(e.id, context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LogInPage(index: e.id),
                                  )
                                );
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
      ),
    );
  }
}
