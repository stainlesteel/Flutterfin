import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  bool loaded = false;
  List<UserDto>? users;
  late Stream stream;

  @override
  void initState() {
    super.initState();
    adminCheck(context);
    stream = Stream.fromFuture(
      Provider.of<JellyfinAPI>(context, listen: false).getUsers()
    );

    starter(firstTime: true);
  }

  Future<void> starter({required bool firstTime}) async {
    final data = await Provider.of<JellyfinAPI>(context, listen: false).getUsers();
    setState(() {
      users = data;
      if (firstTime) loaded = true;
    });
  }

  Future<void> pushToEditingPage({required int startingTab, required int userIndex}) async {
    final data = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEditingPage(
          dto: users![userIndex],
          startingTab: startingTab,
        )
      ),
    );
    if (data != null) await starter(firstTime: false);
  }

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: loaded 
          ? Column(
             children: [
               Text('Users', style: getTextStyling(2, context)),
               SizedBox(height: 5),
               FilledButton(
                 onPressed: () async {
                   final result = await Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => UserCreationPage(),
                     )
                   );
                   if (result != null) {
                     await starter(firstTime: false);
                   }
                 },
                 child: Text('Add User'),
               ),
               SizedBox(height: 10),
               if (users?.isNotEmpty ?? false)
                 GridView.builder(
                   shrinkWrap: true,
                   physics: NeverScrollableScrollPhysics(),
                   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                     maxCrossAxisExtent: 250,
                     mainAxisSpacing: 5,
                     crossAxisSpacing: 5,
                   ),
                   itemCount: users!.length,
                   itemBuilder: (context, index) {
                     return InkWell(
                       onTap: () {
                         showDialog(
                           context: context,
                           builder: (context) => popUpDiag(
                             title: users![index].name!,
                             content: [
                               ListTile(
                                 leading: Icon(Icons.draw),
                                 title: Text('Edit user'),
                                 onTap: () async{
                                   await pushToEditingPage(
                                     startingTab: 0, 
                                     userIndex: index
                                   );
                                 },
                               ),
                               SizedBox(height: 5),
                               ListTile(
                                 leading: Icon(Icons.lock),
                                 title: Text('Library access'),
                                 onTap: () async {
                                   await pushToEditingPage(
                                     startingTab: 1,
                                     userIndex: index
                                   );
                                 },
                               ),
                               SizedBox(height: 5),
                               ListTile(
                                 leading: Icon(Icons.person),
                                 title: Text('Parental control'),
                                 onTap: () async {
                                   await pushToEditingPage(
                                     startingTab: 2, 
                                     userIndex: index
                                   );
                                 },
                               ),
                               SizedBox(height: 5),
                               ListTile(
                                 leading: Icon(Icons.delete),
                                 title: Text('Delete'),
                                 onTap: () async {
                                   final DioException? e = await ama.deleteUser(userId: users![index].id!);
                                   if (e == null) {
                                     setState(() {
                                       users!.removeAt(index);
                                     });
                                     Navigator.pop(context);
                                   } else {
                                     showDialog(
                                       context: context,
                                       builder: (context) => popUpDiag(
                                         title: 'User Error',
                                         content: [
                                           Text('Failed to delete user: ${users![index].name}'),
                                           Text('HTTP Error Code: ${e.response?.statusCode ?? 'Unknown'}'),
                                           Text('Server Response: ${e.response}'),
                                         ],
                                       ),
                                     );
                                   }
                                 },
                               ),
                             ],
                             actions: [
                               TextButton(
                                 onPressed: () => Navigator.pop(context),
                                 child: Text('Cancel'),
                               ),
                             ],
                           ),
                         );
                       },
                       child: Container(
                         decoration: BoxDecoration(
                           color: Theme.of(context).focusColor,
                           borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
                         ),
                         child: Column(
                           children: [
                             Expanded(
                               child: UserAvatar(
                                 ama: ama,
                                 context: context,
                               ),
                             ),
                             Text(
                               '${users![index].name}', 
                               style: getTextStyling(3, context)
                             ),
                           ],
                         ),
                       ),
                     );
                   },
                 )
               else ...[
                 Text('Could not get user data, please try again.'),
               ],
             ],
          )
          : CircularProgressIndicator(),
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
  List<BaseItemDto> selectedViews = [];

  @override
  void initState() {
    super.initState();
    adminCheck(context);
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

  bool justAccessAllLibraries = false;
  String? userName;
  String? userPwd;

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

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
                  setState(() {
                    userName = value;
                  });
                },
              ),
              SizedBox(height: 10),
              EasyTextField(
                labelText: 'Password',
                onChanged: (String value) async {
                  setState(() {
                    userPwd = value;
                  });
                },
              ),
              SizedBox(height: 5),
              Text('Library Access', style: getTextStyling(1, context)),
              if (userViews != null && loaded) ... [
                EasyTile(
                  title: Text('Enable admin access for all libraries', style: getTextStyling(4, context)),
                  subtitle: Text('This user will have edit access to all folders via the Web UI.'),
                  trailing: Switch(
                    value: justAccessAllLibraries,
                    onChanged: (bool value) {
                      if (value == true) {
                        setState(() {
                          selectedViews = userViews!;
                          justAccessAllLibraries = true;
                        });
                      } else {
                        setState(() {
                          selectedViews = [];
                          justAccessAllLibraries = false;
                        });
                      }
                    },
                  ),
                  context: context,
                ),
                SizedBox(height: 5),
                if (!justAccessAllLibraries) ...[
                  Text('Libraries', style: getTextStyling(1, context)),
                  Text('Any folders selected will be able to be edited by this new user.'),
                  SizedBox(height: 5),
                  for (BaseItemDto dto in userViews ?? [])
                    EasyTile(
                      title: Text('${dto.name}', style: getTextStyling(4, context)),
                      trailing: Switch(
                        value: selectedViews.contains(dto),
                        onChanged: (bool value) {
                          if (value == true) {
                            setState(() {
                              selectedViews.add(dto);
                            });
                          } else {
                            setState(() {
                              selectedViews.remove(dto);
                            });
                          }
                        },
                      ),
                      context: context
                    )
                ],
                SizedBox(height: 5),
                FilledButton.tonal(
                  onPressed: () async {
                    if (userName == null) {
                      SimpleErrorDiag(
                        title: 'Wrong User Config', 
                        desc: 'The new user needs a name. : $userName', 
                        context: context
                      );
                      return;
                    }

                    await ama.makeUser(
                      name: userName!,
                      pwd: userPwd,
                      enableAllFolders: justAccessAllLibraries,
                      enabledFolderIds: selectedViews,
                    );

                    Navigator.pop(context, 'rebuild');

                    userName = null;
                    userPwd = null;
                  },
                  child: Text('Create'),
                ),
              ],
            ],
          )
          : CircularProgressIndicator(),
        ),
      ),
    );
  }
}

