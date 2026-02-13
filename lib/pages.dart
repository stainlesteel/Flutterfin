import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'comps.dart';
import 'main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
// media kit
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

String appTitle = 'Flutterfin';

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
        title: Text('$appTitle'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.question_mark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutPage(),
                ),
              );
            },
          ),
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
                  Text('Type in the full http(s) url for your server.\nDo not add a slash (/) at the end of your URL.'),
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
                children: [
                  for (var e in ama.serverList)
                    Card(
                      child: ListTile(
                        onTap: () async {
                          await ama.makeClient(e.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LogInPage(index: e.id)),
                          );
                        },
                        title: Text('${e.serverName}', style: getTextStyling(1 ,context)),
                        subtitle: Text('${e.serverURL}', style: getTextStyling(4, context)),
                        trailing: Text('${e.version}', style: getTextStyling(4, context)),
                      )
                    )
                ],             
              ),
          ],
        ),
      ),
    );
  }
}
// end StartingPage

// start NoNetworkPage
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
            Text('Please try connecting to WiFi/Mobile Data/Ethernet', style: getTextStyling(4, context)),
            SizedBox(height: 20),
            FloatingActionButton.extended(
              onPressed: () async {
                final networkData = await checkNetwork();

                if (networkData == ConnectivityResult.none) {
                  
                } else {
                  late var _widgetPage;

                   if (ama.lastUsedServer != null) {
                     var keyBase = ama.serverList[ama.lastUsedServer!].userMap!.keys!.toList();
                     var valueBase = ama.serverList[ama.lastUsedServer!].userMap!.values!.toList();

                     try {
                       Future.wait([
                         Provider.of<JellyfinAPI>(context, listen: false).makeClient(ama.lastUsedServer),
                         if (ama?.serverList[ama.lastUsedServer!].lastLogIsQC == true)
                           Provider.of<JellyfinAPI>(context, listen: false).logInByQC(keyBase[ama.lastUser!], context)
                         else
                           Provider.of<JellyfinAPI>(context, listen: false).logInByName(keyBase[ama.lastUser!], valueBase[ama.lastUser!], context)
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
              label: Text('Retry')
            ),
          ],
        ),
      ),
    );
  }
}
// end NoNetworkPage

// start AboutPage
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    Widget _scaffold = Scaffold(
      appBar: AppBar(
        title: Text('About $appTitle'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            ],
          ),
        ),
      ), 
    );

    return _scaffold;
  }
}
// end AboutPage

// start UserLogIn
class LogInPage extends StatefulWidget {
  final int? index;

  const LogInPage({super.key, required this.index});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {

  @override
  void initState() {
    super.initState();
  }

  TextEditingController userCont = TextEditingController();
  TextEditingController pwdCont = TextEditingController();

  var _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {

    var ama = context.watch<JellyfinAPI>();

    Widget _image = CachedNetworkImage(
       imageUrl: '${ama.serverList[widget.index!].serverURL}/Branding/SplashScreen',
       fit: BoxFit.cover,
     );

    TextStyle _textcolor = TextStyle(
      color: Colors.white,
    );

    Widget _scaffold = Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            '${ama.serverList[widget.index!].serverName}',
            style: _textcolor,           
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Log In', style: getTextStyling(2 ,context)),
                      SizedBox(height: 10),
                      Container(
                        width: MediaQuery.of(context).size.width - 100,
                        child: Card.filled(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: userCont,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username cannot be empty.';
                                }
                                return null;
                              },
                              style: TextStyle(
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Username',
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: MediaQuery.of(context).size.width - 100,
                        child: Card.filled(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: pwdCont,
                              validator: (String? value) {
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      OrientationBuilder(
                        builder: (context, unusedValue) {
                          final orientation = MediaQuery.of(context).orientation;

                          int buttonRowSubtract = (orientation == Orientation.portrait) ? 269 : 450;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width - buttonRowSubtract,
                                child: FilledButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final response = await ama.logInByName(userCont.text, pwdCont.text, context);
                                      if (response) {
                                        print('logged in!');
                                        await ama.saveUser(userCont.text, pwdCont.text, widget.index);
                                        await ama.goToHome(widget.index, context);
                                      } else {
                                        print('failure!');
                                      }
                                    }
                                  },
                                  child: Text('Log In'),
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width - buttonRowSubtract,
                                child: FilledButton(
                                  onPressed: () async {
                                    final res = await ama.makeQCRequest(context);
                                    if (res == null) {
                                      
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return popUpDiag(
                                            title: 'Quick Connect',
                                            content: <Widget>[
                                              Text(
                                                'Code is: ${res.code}',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      );

                                      late final sSub;

                                      sSub = ama.getQCState(res.secret!).listen(
                                        (data) async {
                                          print('$data');
                                          if (data?.authenticated == true) {
                                            sSub.cancel();
                                            final response = await ama.logInByQC(data!.secret!, context);
                                            if (response == true) {
                                              print('logged in!');
                                              final username = await ama.getCurrentUser();
                                              await ama.saveUser(username!.name!, data!.secret!, widget.index);
                                              await ama.goToHome(widget.index, context);
                                            } else {
                                              print('failure!');
                                            }
                                          }
                                        },
                                        onError: (error) => print('$error'),
                                        onDone: () => print('done'),
                                      );

                                    }
                                  },
                                  child: Text('Quick Connect'),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll<Color>(
                                      Theme.of(context).colorScheme.onTertiaryFixed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 120,
                        child: FilledButton(
                          onPressed: () async {
                            final users = await ama.getPublicUsers();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => popUpDiag(
                                title: 'Available Users',
                                content: <Widget>[
                                  Text('Includes users the server allows to see on the Log-In page.'),
                                  SizedBox(height: 5),
                                  for (UserDto user in users ?? [])
                                    Card(
                                      child: ListTile(
                                        title: Text('${user.name ?? ''}', style: getTextStyling(1, context)),
                                        subtitle: Text('${user.hasPassword! ? 'Requires Password' : 'No Password'}'),
                                        onTap: () async {
                                          if (user.hasPassword! == true) {
                                            setState(() {
                                              userCont.text = user.name!;
                                            });
                                            Navigator.pop(context);
                                          } else {
                                            final response = await ama.logInByName(user.name!, pwdCont.text, context);
                                            if (response) {
                                              print('logged in!');
                                              await ama.saveUser(user.name!, pwdCont.text, widget.index);
                                              await ama.goToHome(widget.index, context);
                                            } else {
                                              print('failure!');
                                            }
                                          }
                                        },
                                      )
                                    )
                                ],
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel')
                                  ),
                                ],
                              )
                            );
                          },
                          child: Text('Available Users'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll<Color>(
                              Theme.of(context).colorScheme.onPrimaryFixed,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50.0),
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Text('${ama.logInMsg ?? ''}'), 
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _image,         
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: Container(
              color: Colors.black.withOpacity(0.56),
            ),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          child: _scaffold,
        ),
      ],
    );
  }
}
// end UserLogIn

// start HomePage
class HomePage extends StatefulWidget {
  final int? index;

  const HomePage({super.key, required this.index});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    final base = ama.serverList[widget.index!].userMap?.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Jellyfin'),
        leading: TextButton(
          child: Text('Back'),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => StartingPage()),
              (route) => false,
            );
          }
        ), 
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text('welcome, ${base?[ama.lastUser!] ?? 'nobody'}', style: getTextStyling(2 ,context)),
              Text('My Media', style: getTextStyling(1, context)),
              SizedBox(height: 10),
              SizedBox(height: 10),
              UserViews(context),            
              SizedBox(height: 10),
              Text('Continue Watching', style: getTextStyling(1, context)),
              ContinueWatching(context),
            ] 
          ),
        ),
      ), 
    );
  }
}

//end HomePage

//start ItemPage
class ItemPage extends StatefulWidget {
  final BaseItemDto viewData;
  final int index; // 0: movie, 1: video

  const ItemPage({super.key, required this.viewData, required this.index});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    BaseItemDto viewData = widget.viewData;

    double runTime = viewData.runTimeTicks! / 100000000;

    Widget _scaffold = Scaffold(
      appBar: AppBar(
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(width: 20),
                  Container(
                    width: MediaQuery.sizeOf(context).width * 0.30,
                    height: MediaQuery.sizeOf(context).height * 0.30,
                    child: Image(
                      image: CachedNetworkImageProvider('${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${viewData!.id!}/Images/Primary?tag=${viewData!.imageTags?['Primary']}'),
                    )
                  ),
                  SizedBox(width: 15),
                  Flexible(
                    child: Column(
                      children: [
                        if (viewData.seriesName != null) ...[
                          Text('${viewData.seriesName}',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                          Text('S${viewData.parentIndexNumber}:E${viewData.indexNumber}, ${viewData.name}',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                        ] 
                        else ...[
                          Text('${viewData.name}',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.index == 0)
                SizedBox(height: 5),
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      int index = 0;
                      if (viewData.seriesName != null) {
                        index = 1;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(viewData: viewData, index: index),
                        )
                      );
                    },
                    child: Text('Play'),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 7),
              if (viewData.taglines?.isNotEmpty ?? false) ...[
                Text(
                  '${viewData.taglines?.firstOrNull ?? "Can't find taglines"}', 
                  textAlign: TextAlign.center,
                  style: getTextStyling(1 ,context),
                ),
                SizedBox(height: 10),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 15),
                    detailCard(text: '${viewData.productionYear ?? ''}', context: context),
                    SizedBox(width: 20),
                    detailCard(text: '${getTime(runTime.round())}', context: context),
                    if (viewData.officialRating != null) ...[
                      SizedBox(width: 20),
                      detailCard(text: '${viewData.officialRating ?? 'Rating Unavailable'}', context: context)
                    ],
                    if (viewData.criticRating != null) ...[
                      SizedBox(width: 20),
                      detailCard(
                        children: [
                          Icon(
                            Icons.rate_review,
                            color: Colors.red,
                          ),
                          SizedBox(width: 5),
                          Text('${viewData.criticRating?.round() ?? 'Unavailable'}', style: getTextStyling(1, context)),
                        ], 
                        context: context
                      ),
                    ],
                    SizedBox(width: 20),
                    detailCard(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                        ),
                        SizedBox(width: 5),
                        Text('${viewData?.communityRating ?? 'Unavailable'}', style: getTextStyling(1, context)),
                      ], 
                      context: context
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text('${viewData?.overview ?? ''}', textAlign: TextAlign.center),
              if (viewData?.tags?.isNotEmpty ?? false) ...[
                SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Text('Tags:'),
                      SizedBox(width: 5,),
                      for (String tag in viewData.tags ?? [])
                        detailCard(text: '$tag', context: context)
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ), 
    );

    return _scaffold;
  }
}
// end ItemPage

// start VideoPlayerPage
class VideoPlayerPage extends StatefulWidget {
  final BaseItemDto viewData;
  final int index; // 0: movie, 1: video

  const VideoPlayerPage({super.key, required this.viewData, required this.index});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late var player;
  late dynamic playbackReport;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    player = PlayerManager();
    starter();

    playbackReport = player.reportPlaybackStream(context).listen(
      (event) {
        print('reported Playback Session!');
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> starter() async {
    final url = Provider.of<JellyfinAPI>(context, listen: false).getStreamUrl(widget.viewData!.id!);
    print('Stream Url: $url');
    if (widget.index == 0) {
      await player.addMovie(url!);
      await player.playMovie();
    } else {
      await player.addShow(widget.viewData, context);
      await player.playShow();
    }
    await Provider.of<JellyfinAPI>(context, listen: false).startPlayback(widget.viewData);
  }

  ValueNotifier<String> playerTitle = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    VideoController videoConts = VideoController(player.player);

    int episodeIndex = widget.viewData.indexNumber ?? 0; // the number for skip buttons to use as the base (skip previous: skipInt - 1) (skip next: skipInt + 1)
    // if null, video is probably a movie, in that case, this isn't going to be used
    

    List<Widget> skipButtonList = [
      IconButton( // skip previous
        icon: Icon(
          Icons.skip_previous,
          color: Colors.white,
        ),
        onPressed: () async {
          try {
            episodeIndex--;
            await player.skipPrevious();
            await Future.delayed(Duration(seconds: 1));

            playerTitle.value = '${widget.viewData.seriesName} - ${player.player.state.playlist.medias![episodeIndex].extras!['name']}';
          } on RangeError catch (e) {
            print('VideoPlayerPage: Episode limit reached!');
          }
        },
      ),
      IconButton( // skip next
        icon: Icon(
          Icons.skip_next,
          color: Colors.white,
        ),
        onPressed: () async {
          try {
            episodeIndex++;
            await player.skipNext();
            await Future.delayed(Duration(seconds: 1));

            playerTitle.value = '${widget.viewData.seriesName} - ${player.player.state.playlist.medias![episodeIndex].extras!['name']}';
          } on RangeError catch (e) {
            print('VideoPlayerPage: Episode limit reached!');
          }
        },
      ),
    ];

    if (widget.viewData.seriesName != null) {
      playerTitle.value = '${widget.viewData.seriesName} - ${widget.viewData.name}';
    } else {
      playerTitle.value = '${widget.viewData.name}';
    }

    // player theme for both normal and fullscreen
    MaterialVideoControlsThemeData themeData = MaterialVideoControlsThemeData(
      topButtonBar: [
        IconButton(
          onPressed: () async {
            await player.pause();
            await player.disposePlayer();

            await ama.stopPlayback(widget.viewData);

            await Future.delayed(Duration(seconds: 1));
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: playerTitle,
          builder: (context, value, child) {
            return Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        ),
      ],
      primaryButtonBar: [
        if (widget.viewData.seriesName != null)
          skipButtonList[0],
        SizedBox(width: 100),
        MaterialPlayOrPauseButton(),
        SizedBox(width: 100),
        if (widget.viewData.seriesName != null)
          skipButtonList[1],
      ],
      bottomButtonBar: [
        MaterialPlayOrPauseButton(), // play pause
        if (widget.viewData.seriesName != null)
          ...skipButtonList,
        MaterialPositionIndicator(), // position indicator
        TextButton(
          onPressed: () async {
            final data = await ama.getSessionInfo();
            print('$data');
          },
          child: Text('der riese'),
        ),
      ],
    );

    Widget _scaffold = Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: MaterialVideoControlsTheme(
                normal: themeData,
                fullscreen: themeData,
                child: Video(
                  controller: videoConts,
                ),
              ),
            ),
          ],
        ),
      ), 
    );

    return _scaffold;
  }
}
// end VideoPlayerPage
