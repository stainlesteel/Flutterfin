import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:overlayment/overlayment.dart';

final bool debug = false;
String appTitle = 'Flutterfin';

// this is for adding drag support to mouses and trackpads
class CustomScrollBehaviour extends MaterialScrollBehavior {
  @override 
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
  };
}

/* 
  main(): uses FSS to get (or make) encryption key for hive,
  uses path_provider to get support dir path to give a location for hive,
  uses hive to open encrypted Box
  runs flutter app
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final _fss = const FlutterSecureStorage();


  String? _eKey = await _fss.read(key: 'encryptor'); // find encryptor
  dynamic _hiveKey = Hive.generateSecureKey(); // hive secure key

  dynamic _cipher = _eKey ?? _hiveKey;

  late Box jellyBox;

  if (_eKey == null) {
    await _fss.write(key: 'encryptor', value: '${base64Url.encode(_hiveKey)}');
  } else {
    _cipher = base64Url.decode(_eKey);
  }

  try {
    dynamic libs = await getApplicationDocumentsDirectory();
    Hive.init(libs.path);
  } catch (e) {
    Hive.initFlutter();
  }

  Hive.registerAdapter(ServerObjAdapter());
  Hive.registerAdapter(UserDataAdapter());

  jellyBox = await Hive.openBox(
    'jellyBox',
    encryptionCipher: HiveAesCipher(_cipher),
    crashRecovery: true,
  ); // is fss key real? if yes use it, if not, use generated one and save it

  // nuke everything
  _eKey = null;
  _hiveKey = null;
  _cipher = null;

  // in case an 'antoher exception' appears
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

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
    final navgatorKey = GlobalKey<NavigatorState>();
    Overlayment.navigationKey = navgatorKey;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      scrollBehavior: CustomScrollBehaviour(),
      navigatorKey: navgatorKey,
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
  late Future<void> future;
  Widget? page;

  @override
  void initState() {
    super.initState();
    Provider.of<JellyfinAPI>(context, listen: false).loadAppData();
    future = starter();
  }

  Future<void> starter() async {
    final ama = Provider.of<JellyfinAPI>(context, listen: false);
    final networkStatus = await checkNetwork();

    if (debug == true) {
      page = DebugPage(box: widget.box);
    } else {
      if (networkStatus != ConnectivityResult.none) {
        if (ama.lastUsedServer != null) {
          var userData = ama.serverList[ama.lastUsedServer!].userData;

          try {
            await Provider.of<JellyfinAPI>(context, listen: false,).makeClient(ama.lastUsedServer);
            await Provider.of<JellyfinAPI>(context, listen: false).setUser(userData!);
            page = HomePage(index: ama.lastUsedServer);
          } catch (e) {
            page = StartingPage();
          }

        } else {
          page = StartingPage();
        }
      } else {
        page = NoNetworkPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('${snapshot.error}');
          return Scaffold(
            appBar: AppBar(
              title: Text('unknown error'),
              centerTitle: true,
            ),
            body: Center(
              child: Text('${snapshot.error}'),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          return page!;
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(appTitle),
              centerTitle: true,
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    );
  }
}
