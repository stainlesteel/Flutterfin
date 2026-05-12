import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/AdminPages/admin_page.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {

  @override
  void initState() {
    super.initState();
    adminCheck(context);
  }

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    ServerObj obj = ama.serverList[ama.lastUsedServer!];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('Settings', style: getTextStyling(2, context)),
            SizedBox(height: 5),
            EasyTextField(
              onChanged: (String value) async {
                ServerConfiguration newConfig = ama.serverConfiguration!.copyWith(
                  serverName: value,
                );

                await ama.updateConfiguration(
                  newConfig
                );

                ama.serverList[ama.lastUsedServer!].serverName = value;
                ama.serverConfiguration = newConfig;

                ama.notifyListeners();
              },
              labelText: 'Server Name',
              initialValue: '${ama.serverConfiguration!.serverName}'
            ),
            Text('The name of your Jellyfin server, default is the server hostname.'),
            SizedBox(height: 5),
            EasyTile(
              title: Text('Enable Quick Connect on this server', style: getTextStyling(4, context)),
              trailing: Switch(
                value: ama.serverConfiguration!.quickConnectAvailable!,
                onChanged: (bool) async {
                  ServerConfiguration newConfig = ama.serverConfiguration!.copyWith(
                    quickConnectAvailable: bool,
                  );

                  await ama.updateConfiguration(
                    newConfig
                  );

                  ama.serverConfiguration = newConfig;
                  ama.notifyListeners();
                },
              ),
              context: context
            ),
            SizedBox(height: 8),
            EasyTextField(
              onChanged: (String value) async {
                final int? integer = int.tryParse(value);

                if (integer == null) return;

                ServerConfiguration newConfig = ama.serverConfiguration!.copyWith(
                  libraryScanFanoutConcurrency: integer,
                );

                await ama.updateConfiguration(
                  newConfig
                );

                ama.serverConfiguration = newConfig;

                ama.notifyListeners();
              },
              labelText: 'Parallel library scan tasks limit',
              initialValue: (ama.serverConfiguration!.libraryScanFanoutConcurrency != 0) 
              ? '${ama.serverConfiguration!.libraryScanFanoutConcurrency ?? ''}'
              : ''
            ),
            SizedBox(
              width: MediaQuery.widthOf(context) * 0.95,
              child: Text('Maximum number of parallel tasks during library scans, if empty, a limit is automatically decided. WARNING: If set too high, this will cause performance issues. Anything not a number will not be used.')
            ),
            SizedBox(height: 8),
            EasyTextField(
              onChanged: (String value) async {
                final int? integer = int.tryParse(value);

                if (integer == null) return;

                ServerConfiguration newConfig = ama.serverConfiguration!.copyWith(
                  parallelImageEncodingLimit: integer,
                );

                await ama.updateConfiguration(
                  newConfig
                );

                ama.serverConfiguration = newConfig;

                ama.notifyListeners();
              },
              labelText: 'Parallel image encoding limit',
              initialValue: (ama.serverConfiguration!.parallelImageEncodingLimit != 0) 
              ? '${ama.serverConfiguration!.parallelImageEncodingLimit ?? ''}'
              : ''
            ),
            SizedBox(
              width: MediaQuery.widthOf(context) * 0.95,
              child: Text('Maximum number of image encodings allowed to run in parallel. If empty, a limit is automatically decided.')
            ),
          ],
        ),
      )
    );
  }
}
