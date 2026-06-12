import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:file_picker/file_picker.dart';

Widget logPage(BuildContext context, String name, String data) {
  return Scaffold(
    appBar: AppBar(
      title: Text(name),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: data));
            showScaffold('Copied data to clipboard!', context);
          },
          icon: Icon(Icons.copy),
        ),
        IconButton(
          onPressed: () async {
            String? result = await FilePicker.saveFile(
              dialogTitle: 'Where to save ${name}?',
              fileName: name,
              bytes: Uint8List.fromList(data.codeUnits),
            );

            if (result != null) {
              showScaffold('Saved log file.', context);
            }
          },
          icon: Icon(Icons.download),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Card(
              child: Text(data),
            ),
          ],
        ),
      ),
    ),
  );
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Logs'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: FutureBuilder(
            future: ama.getServerLogs(),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
              if (asyncSnapshot.hasError) return Text('Could not get logs.');

              List<LogFile> logs = asyncSnapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return EasyTile(
                    context: context,
                    title: Text('${logs[index].name}', style: getTextStyling(4, context)),
                    subtitle: Text('${getDeviceTime(logs[index].dateCreated!, context)}'),
                    onTap: () async {
                      Uint8List? data = await ama.getLogFile(logs[index].name!);
                      if (data == null) {
                        showScaffold('Could not get log file data.', context);
                        return;
                      }

                      String textData = String.fromCharCodes(data);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => logPage(context, logs[index].name!, textData),
                        ),
                      );
                    },
                  );
                },
              );
            }
          ),
        ),
      ),
    );
  }
}
