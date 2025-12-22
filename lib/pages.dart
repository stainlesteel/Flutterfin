import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'comps.dart';
import 'main.dart';

// start default page (no server found)
class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State<StartingPage> createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  @override
  Widget build(BuildContext context) {

    var ama = context.watch<JellyfinAPI>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutterfin'),
        centerTitle: true,
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
                  Text('Type in the full http(s) url for your server.'),
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
                        final bool result = await amd.verifyServer(conts.text, context);
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
          }
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
              ListView(
                padding: const EdgeInsets.all(6.7),
                shrinkWrap: true,
                children: ama.serverList.entries.map<Widget>((e) {
                  return IntrinsicWidth(
                    child: Card(
                      child: ListTile(
                        title: Text('${e.key}', style: getTextStyling(1 ,context))
                      ),
                    )
                  );
                }
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
