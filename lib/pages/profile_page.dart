import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';

Widget EasyTile({required BuildContext context, Widget? leading, Widget? trailing, Widget? title, Widget? subtitle, void Function()? onTap, EdgeInsets? padding}) {
  return Padding(
    padding: padding ?? EdgeInsets.all(10.0),
    child: Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: leading,
        trailing: trailing,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    ),
  );
}

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  UserAvatar(
                    ama: ama,
                    height: 50
                  ),
                  Text('${userDto!.name}', style: getTextStyling(5, context),),
                ],
              ),
              EasyTile(
                context: context,
                leading: Icon(
                  Icons.exit_to_app,
                  color: Colors.red,
                ),
                title: Text(
                  'Log Out',
                  style: getTextStyling(4, context),
                ),
                onTap: () async {
                  await ama.logOut(ama.lastUsedServer!, context);
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
