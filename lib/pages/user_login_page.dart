import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var ama = context.watch<JellyfinAPI>();

    Widget _image;

    _image = CachedNetworkImage(
      imageUrl: '${ama.serverList[widget.index!].serverURL}/Branding/SplashScreen',
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        return ColoredBox(color: Colors.black);
      },
    );

    TextStyle _textcolor = TextStyle(color: Colors.white);

    Widget _scaffold = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '${ama.serverList[widget.index!].serverName}',
          style: _textcolor,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
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
                    Text('Log In', style: getTextStyling(2, context)),
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
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(labelText: 'Username'),
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
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(labelText: 'Password'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: MediaQuery.widthOf(context) - 120, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: FilledButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final response = await ama.logInByName(
                                      userCont.text,
                                      pwdCont.text,
                                      context,
                                      widget.index!,
                                    );
                                    if (response) {
                                      print('logged in!');
                                      await ama.goToHome(widget.index, context);
                                    } else {
                                      print('failure!');
                                    }
                                  }
                                },
                                child: Text('Log In', style: _textcolor,),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
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
                                      },
                                    );
                                                  
                                    late final sSub;
                                                  
                                    sSub = ama
                                    .getQCState(res.secret!)
                                    .listen(
                                      (QuickConnectResult? data) async {
                                        print('$data');
                                        if (data?.authenticated == true) {
                                          sSub.cancel();
                                          final response = await ama
                                              .logInByQC(
                                                data!.secret!,
                                                context,
                                                widget.index!,
                                              );
                                          if (response == true) {
                                            print('logged in!');
                                            final username = await ama.getCurrentUser();
                                            ama.lastUsedServer = widget.index;
                                            await ama.goToHome(
                                              widget.index,
                                              context,
                                            );
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
                                child: Text('Quick Connect', style: _textcolor,),
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStatePropertyAll<Color>(
                                        Theme.of(
                                          context,
                                        ).colorScheme.onTertiaryFixed,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                Text(
                                  'Includes users the server allows to see on the Log-In page.',
                                ),
                                SizedBox(height: 5),
                                for (UserDto user in users ?? [])
                                  Card(
                                    child: ListTile(
                                      title: Text(
                                        '${user.name ?? ''}',
                                        style: getTextStyling(1, context),
                                      ),
                                      subtitle: Text(
                                        '${user.hasPassword! ? 'Requires Password' : 'No Password'}',
                                      ),
                                      onTap: () async {
                                        if (user.hasPassword! == true) {
                                          setState(() {
                                            userCont.text = user.name!;
                                          });
                                          Navigator.pop(context);
                                        } else {
                                          final response = await ama
                                              .logInByName(
                                                user.name!,
                                                pwdCont.text,
                                                context,
                                                widget.index!
                                              );
                                          if (response) {
                                            print('logged in!');
                                            await ama.goToHome(
                                              widget.index,
                                              context,
                                            );
                                          } else {
                                            print('failure!');
                                          }
                                        }
                                      },
                                    ),
                                  ),
                              ],
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('Available Users', style: _textcolor,),
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
        Positioned.fill(child: _image),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),
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
