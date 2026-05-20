import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/starting_page.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/pages/AdminPages/admin_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void initState() {
    super.initState();
    adminCheck(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text('Users', style: getTextStyling(2, context)),
              SizedBox(height: 5),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserCreationPage(),
                    )
                  );
                },
                child: Text('Add User'),
              ),
              SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCreationPage extends StatefulWidget {
  const UserCreationPage({super.key});

  @override
  State<UserCreationPage> createState() => _UserCreationPageState();
}

class _UserCreationPageState extends State<UserCreationPage> {
  bool loaded = false;
  List<BaseItemDto>? userViews;

  @override
  void initState() {
    super.initState();
    getViews();
  }

  void getViews() async {
    final data = await Provider.of<JellyfinAPI>(context, listen: false).getUserViews();
    if (data == null) {
      showDialog(
        context: context,
        builder: (context) => popUpDiag(
          title: 'Libraries Error',
          content: [
            Text("We could not download the server's libraries, you can still make a user but you cannot select the available libraries unless you retry"),
          ],
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  loaded = true;
                });
              },
              child: Text('Continue'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        userViews = data;
        loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userName;
    String? userPwd;
    bool adminAccess = false;
    List<BaseItemDto> userViews = [];

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: loaded 
          ? Column(
            children: [
              Text('Add User', style: getTextStyling(2, context)),
              SizedBox(height: 5),
              EasyTextField(
                labelText: 'Name',
                onChanged: (String value) async {
                  userName = value;
                },
              ),
              SizedBox(height: 5),
              EasyTextField(
                labelText: 'Password',
                onChanged: (String value) async {
                  userPwd = value;
                },
              ),
              SizedBox(height: 5),
              Text('Library Access', style: getTextStyling(1, context)),
            ],
          )
          : CircularProgressIndicator(),
        ),
      ),
    );
  }
}
