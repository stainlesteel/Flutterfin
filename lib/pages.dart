import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'comps.dart';
import 'main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'dart:ui';

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
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 160,
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
                      SizedBox(height: 30),
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
              color: Colors.black.withOpacity(0.65),
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
            children: [
              Text('welcome, ${base?[ama.lastUser!] ?? 'nobody'}', style: getTextStyling(2 ,context)),
              Text('My Media', style: getTextStyling(1, context)),
              UserViews(context),            
              SizedBox(height: 10),
              Text('Continue Watching', style: getTextStyling(1, context)),
              ContinueWatching(context),
            ] 
        ),
      ), 
    );
  }
}

//end HomePage

//start MoviePage
class MoviePage extends StatefulWidget {
  final BaseItemDto viewData;

  const MoviePage({super.key, required this.viewData});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();
    BaseItemDto viewData = widget.viewData;
    print('${viewData!.imageTags}');

    Widget _scaffold = Scaffold(
      appBar: AppBar(
      ),
      body: Column(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Align(
                        alignment: Alignment(-5, -0),
                        child: FractionallySizedBox(
                          heightFactor: 0.8,
                          widthFactor: 1,
                          child: Container(
                              color: Colors.red,
                              child: CachedNetworkImage(
                                  imageUrl: '${ama.serverList[ama.lastUsedServer!].serverURL}/Items/${viewData!.id!}/Images/Primary?tag=${viewData!.imageTags?['Primary']}',
                              )
                            ), 
                        ),
                      ),
                    ),
                    Text('${viewData.name}', textAlign: TextAlign.left),
                  ],
                )
              ),            
            ),
          ),
        ], 
      ),
    );

    return _scaffold;
  }
}
