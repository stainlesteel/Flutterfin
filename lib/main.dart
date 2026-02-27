import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'pages.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'objects.dart';
import 'comps.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

final bool debug = false;
String appTitle = 'Flutterfin';

/* 
  main(): uses FSS to get (or make) encryption key for hive,
  uses path_provider to get support dir path to give a location for hive,
  uses hive to open encrypted Box
  runs flutter app
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final _fss = const FlutterSecureStorage();

  final libs = await getApplicationSupportDirectory(); // get support dir path
  String? _eKey = await _fss.read(key: 'encryptor'); // find encryptor
  dynamic _hiveKey = Hive.generateSecureKey(); // hive secure key

  dynamic _cipher = _eKey ?? _hiveKey;

  late Box jellyBox;

  if (_eKey == null) {
    await _fss.write(key: 'encryptor', value: '${base64Url.encode(_hiveKey)}');
  } else {
    _cipher = base64Url.decode(_eKey);
  }

  Hive.init(libs.path);
  Hive.registerAdapter(ServerObjAdapter());

  jellyBox = await Hive.openBox(
    'jellyBox',
    encryptionCipher: HiveAesCipher(_cipher),
    crashRecovery: true,
  ); // is fss key real? if yes use it, if not, use generated one and save it

  // nuke everything
  _eKey = null;
  _hiveKey = null;
  _cipher = null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<JellyfinAPI>(
          create: (_) => JellyfinAPI(jellyBox),
        ),
      ],
      child: MyApp(jellyfinBox: jellyBox),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Box jellyfinBox;
  const MyApp({super.key, required this.jellyfinBox});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainRedirector(box: jellyfinBox),
    );
  }
}

// main-redirector throws user to either server add, or home page depending on their config
class MainRedirector extends StatefulWidget {
  final Box box;
  const MainRedirector({super.key, required this.box});

  @override
  State<MainRedirector> createState() => _MainRedirectorState();
}

class _MainRedirectorState extends State<MainRedirector> {
  late Future<List<dynamic>> _ifLoggedIn;

  @override
  void initState() {
    super.initState();
    Provider.of<JellyfinAPI>(context, listen: false).loadAppData();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    Widget waitingWidget = Scaffold(
      appBar: AppBar(title: Text('Jellyfin'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      ),
    );

    // checks for network availbility
    if (debug == true) {
      return DebugPage(box: widget.box);
    } else {
      return FutureBuilder<ConnectivityResult>(
        future: checkNetwork(),
        builder: (context, snapshot) {
          // checks if network state is not none
          try {
            if (snapshot.data != ConnectivityResult.none) {
              if (ama.lastUsedServer != null) {
                var keyBase = ama.serverList[ama.lastUsedServer!].userMap!.keys.toList();
                var valueBase = ama.serverList[ama.lastUsedServer!].userMap!.values.toList();

                _ifLoggedIn = Future.wait([
                  Provider.of<JellyfinAPI>(
                    context,
                    listen: false,
                  ).makeClient(ama.lastUsedServer),
                  if (ama?.serverList[ama.lastUsedServer!].lastLogIsQC == true)
                    Provider.of<JellyfinAPI>(
                      context,
                      listen: false,
                    ).logInByQC(keyBase[ama.lastUser!], context)
                  else
                    Provider.of<JellyfinAPI>(context, listen: false).logInByName(
                      keyBase[ama.lastUser!],
                      valueBase[ama.lastUser!],
                      context,
                    ),
                ]);

                return FutureBuilder(
                  future: _ifLoggedIn,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return waitingWidget;
                    } else if (snapshot.hasError) {
                      return StartingPage();
                    } else {
                      return HomePage(index: ama.lastUsedServer);
                    }
                  },
                );
              } else {
                return StartingPage();
              }
            } else {
              return NoNetworkPage();
            }
          } on RangeError catch (e) {
            return StartingPage();
          }
        },
      );
    }
  }
}
