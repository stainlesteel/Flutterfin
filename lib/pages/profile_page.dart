import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/pages/SettingsPages/settings_pages.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserDto? userDto; 

  @override
  void initState() {
    super.initState();
    starter();
  }

  Future<void> starter() async {
    userDto = await Provider.of<JellyfinAPI>(context, listen: false).getCurrentUser();
    setState(() {
      userDto = userDto;
    });
  }

  final qcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: (userDto != null)
        ? SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Wrap(
                spacing: 5,
                children: [
                  UserAvatar(
                    ama: ama,
                    height: 50
                  ),
                  Text('${userDto!.name}', style: getTextStyling(0, context),),
                ],
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 15,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      showAnimatedSheet(
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Quick Connect', style: getTextStyling(2, context),),
                              SizedBox(height: 5,),
                              Text('Enter the code displayed on your device'),
                              SizedBox(height: 5,),
                              SizedBox(
                                width: MediaQuery.widthOf(context) * 0.75,
                                child: TextFormField(
                                  controller: qcController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    hintText: 'Type the number here',
                                  ),
                                ),
                              ),
                              SizedBox(height: 5,),
                              SizedBox(
                                width: MediaQuery.widthOf(context) * 0.75,
                                child: FilledButton.tonal(
                                  onPressed: () async {
                                    final response = await ama.authQC(qcController.text);
                                    Navigator.pop(context);
                                    if (response == true) {
                                      showScaffold('Other device logged in via Quick Connect', context);
                                    } else {
                                      showScaffold('Other device failed to log in', context);
                                    }
                                  },
                                  child: Text('Connect'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        context: context
                      );
                    },
                    child: Text('Quick Connect'),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await ama.logOut(ama.lastUsedServer!, context);
                    },
                    child: Text('Log Out'),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              EasyTile(
                context: context,
                leading: Icon(
                  Icons.tv,
                ),
                title: Text(
                  'Display',
                  style: getTextStyling(4, context),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplaySettingsPage(),
                    ),
                  );
                } 
              ),
              SizedBox(height: 5,),
              EasyTile(
                leading: Icon(
                  Icons.play_circle
                ),
                title: Text(
                  'Playback',
                  style: getTextStyling(4, context),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaybackSettingsPage()
                    )
                  );
                },
                context: context
              ),
              SizedBox(height: 15),
              EasyTile(
                context: context,
                leading: Icon(
                  Icons.question_mark,
                ),
                title: Text(
                  'About $appTitle',
                  style: getTextStyling(4, context),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AboutPage(),
                    ),
                  );
                } 
              ),
            ],
          ),
        )
        : CircularProgressIndicator()
      ),
    );
  }
}
