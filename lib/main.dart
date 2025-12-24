import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'pages.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data'; 
import 'dart:convert';

/* 
  main(): uses FSS to get (or make) encryption key for hive,
  uses path_provider to get support dir path to give a location for hive,
  uses hive to open encrypted Box
  runs flutter app
  force flutter error lines to a limit
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final _fss = const FlutterSecureStorage();

  final libs = await getApplicationSupportDirectory(); // get support dir path
  final _eKey = await _fss.read(key: 'encryptor'); // find encryptor
  final _hiveKey = Hive.generateSecureKey(); // hive secure key

  dynamic _cipher = _eKey ?? _hiveKey;

  late final jellyBox;

  if (_eKey == null) {
    await _fss.write(key : 'encryptor', value: '${base64Url.encode(_hiveKey)}');
  } else {
    _cipher = base64Url.decode(_eKey);
  }

  Hive.init(libs.path);

  while (true) {
    try {
      jellyBox = await Hive.openBox<Map<int, Map<String, dynamic>>>(
        'jellyBox',
        encryptionCipher: HiveAesCipher(_cipher),
        crashRecovery: false,
      ); // is fss key real? if yes use it, if not, use generated one and save it
      break;
    } catch (e) {
      print('box is broken, deleting and looping...');
      await Hive.deleteBoxFromDisk('jellyBox');
    }
  }

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
      home: MainRedirector(),
    );
  }
}

// main-redirector throws user to either server add, or home page depending on their config
class MainRedirector extends StatefulWidget {
  const MainRedirector({super.key});

  @override
  State<MainRedirector> createState() => _MainRedirectorState();
}

class _MainRedirectorState extends State<MainRedirector> {

  void initState() {
    super.initState();
    Provider.of<JellyfinAPI>(context, listen: false).loadAppData();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    return StartingPage();
  }
}
