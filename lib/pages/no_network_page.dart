import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';

class NoNetworkPage extends StatefulWidget {
  const NoNetworkPage({super.key});

  @override
  State<NoNetworkPage> createState() => _NoNetworkPageState();
}

class _NoNetworkPageState extends State<NoNetworkPage> {
  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 50,
              semanticLabel: 'no network available',
            ),
            Text('No Network Available', style: getTextStyling(2, context)),
            Text(
              'Please try connecting to WiFi/Mobile Data/Ethernet',
              style: getTextStyling(4, context),
            ),
            SizedBox(height: 20),
            FloatingActionButton.extended(
              onPressed: () async {
                final networkData = await checkNetwork();

                if (networkData == ConnectivityResult.none) {
                } else {
                  late var _widgetPage;

                  if (ama.lastUsedServer != null) {
                    var keyBase = ama
                        .serverList[ama.lastUsedServer!]
                        .userMap!
                        .keys!
                        .toList();
                    var valueBase = ama
                        .serverList[ama.lastUsedServer!]
                        .userMap!
                        .values!
                        .toList();

                    try {
                      Future.wait([
                        Provider.of<JellyfinAPI>(
                          context,
                          listen: false,
                        ).makeClient(ama.lastUsedServer),
                        if (ama?.serverList[ama.lastUsedServer!].lastLogIsQC ==
                            true)
                          Provider.of<JellyfinAPI>(
                            context,
                            listen: false,
                          ).logInByQC(keyBase[ama.lastUser!], context)
                        else
                          Provider.of<JellyfinAPI>(
                            context,
                            listen: false,
                          ).logInByName(
                            keyBase[ama.lastUser!],
                            valueBase[ama.lastUser!],
                            context,
                          ),
                      ]);
                      _widgetPage = HomePage(index: ama.lastUsedServer);
                    } catch (e) {
                      _widgetPage = StartingPage();
                    }
                  } else {
                    _widgetPage = StartingPage();
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => _widgetPage),
                    (route) => false,
                  );
                }
              },
              icon: Icon(Icons.autorenew),
              label: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
