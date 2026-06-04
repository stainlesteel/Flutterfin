import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/AdminPages/admin_page.dart';

class UserEditingPage extends StatefulWidget {
  UserDto? dto;
  final int startingTab;
  UserEditingPage({super.key, this.dto, this.startingTab = 0});

  @override
  State<UserEditingPage> createState() => _UserEditingPageState();
}

class _UserEditingPageState extends State<UserEditingPage> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  late UserDto dto = widget.dto!;
  late int startingTab = widget.startingTab;
  late TabController tabController = TabController(
    vsync: this,
    length: 4,
    initialIndex: startingTab,
  );

  Map<String, UnratedItem> unratedItems = {
    'Movies': UnratedItem.movie,
    'Trailers': UnratedItem.trailer,
    'Series': UnratedItem.series,
    'Music': UnratedItem.music,
    'Books': UnratedItem.book,
    'Channels': UnratedItem.channelContent,
    'Live TV': UnratedItem.liveTvChannel,
  };

  TextEditingController currentPasswordField = TextEditingController();
  TextEditingController newPasswordField = TextEditingController();
  TextEditingController newPasswordConfirmField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    Future<void> save() async {
      if (widget.dto == dto) {
        showScaffold('Nothing had changed, skipping unnecessary save.', context);
        return;
      }
      setState(() {
        widget.dto = dto;
      });

      await ama.updateUser(dto: dto, policy: dto.policy!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${dto.name!}'),
        leading: IconButton(
          onPressed: () {
            if (widget.dto != dto) {
              showDialog(
                context: context,
                builder: (context) => popUpDiag(
                  title: 'Are you Sure?',
                  content: [
                    Text('You have not saved current changes to the Jellyfin server. Continue?'),
                  ],
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Keep Editing'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'rebuild');
                        Navigator.pop(context);
                      },
                      child: Text('Exit without Saving'),
                    ),
                  ],
                ),
              );
              return;
            }
            Navigator.pop(context, 'rebuild');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          onTap: (int index) {
            setState(() {
              startingTab = index;
            });
          },
          tabs: [
            Tab(
              icon: Icon(Icons.person),
              text: 'Profile',
            ),
            Tab(
              icon: Icon(Icons.lock),
              text: 'Access',
            ),
            Tab(
              icon: Icon(Icons.supervised_user_circle),
              text: 'Parental Controls',
            ),
            Tab(
              icon: Icon(Icons.password),
              text: 'Password',
            ),
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          tabWrapper(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 5),
                EasyTextField(
                  labelText: 'Name',
                  initialValue: dto.name,
                  onChanged: (String value) {
                    setState(() {
                      dto = dto!.copyWith(
                        name: value,
                      );
                    });
                  }
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Allow remote connections to this server', style: getTextStyling(4, context)),
                  subtitle: Text('If unchecked, remote connections will be blocked by server.'),
                  trailing: Switch(
                    value: dto!.policy!.enableRemoteAccess!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            enableRemoteAccess: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Allow this user admin access to the server', style: getTextStyling(4, context)),
                  trailing: Switch(
                    value: dto!.policy!.isAdministrator!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            isAdministrator: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Allow this user to manage collections', style: getTextStyling(4, context)),
                  subtitle: Text('Regardless of permission, the user cannot manage collections on $appTitle'),
                  trailing: Switch(
                    value: dto!.policy!.enableCollectionManagement!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            enableCollectionManagement: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Allow the user to manage subtitles', style: getTextStyling(4, context)),
                  subtitle: Text('Regardless of permission, the user cannot manage subtitles on $appTitle'),
                  trailing: Switch(
                    value: dto!.policy!.enableSubtitleManagement!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            enableSubtitleManagement: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 10),
                EasyTile(
                  title: Text('Allow downloads from the user', style: getTextStyling(4, context)),
                  subtitle: Text('$appTitle does not support this restriction currently.'),
                  trailing: Switch(
                    value: dto!.policy!.enableContentDownloading!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            enableContentDownloading: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Disable this user', style: getTextStyling(4, context)),
                  subtitle: Text('Server will allow no connection from this user'),
                  trailing: Switch(
                    value: dto!.policy!.isDisabled!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            isDisabled: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 5),
                EasyTile(
                  title: Text('Hide this user from login screens', style: getTextStyling(4, context)),
                  subtitle: Text('If enabled, user will no longer show up on Jellyfin Web, $appTitle, and other clients.'),
                  trailing: Switch(
                    value: dto!.policy!.isHidden!,
                    onChanged: (bool value) {
                      setState(() {
                        dto = dto!.copyWith(
                          policy: dto!.policy!.copyWith(
                            isHidden: value,
                          ),
                        );
                      });
                    },
                  ),
                  context: context
                ),
                SizedBox(height: 20),
                EasyTextField(
                  labelText: 'Failed login tries before this user is locked out',
                  initialValue: dto.policy!.loginAttemptsBeforeLockout!.toString(),
                  onChanged: (String value) {
                    setState(() {
                      dto = dto!.copyWith(
                        policy: dto!.policy!.copyWith(
                          loginAttemptsBeforeLockout: int.parse(value),
                        ),
                      );
                    });
                  },
                ),
                SizedBox(height: 5),
                Text('If zero, default is applied (3 tries for non-admin, 5 tries for admin). If set to -1, user cannot be locked out.'),
                SizedBox(height: 15),
                EasyTextField(
                  labelText: 'Maximum number of user sessions at once',
                  initialValue: dto.policy!.maxActiveSessions!.toString(),
                  onChanged: (String value) {
                    int number = int.tryParse(value) ?? 0;
                    setState(() {
                      dto = dto!.copyWith(
                        policy: dto!.policy!.copyWith(
                          maxActiveSessions: number,
                        ),
                      );
                    });
                  },
                ),
                SizedBox(height: 5),
                Text('If set to 0, this user can have unlimited sessions at once'),
                SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () async => await save(),
                  child: Text('Save'),
                ),
              ],
            ),
          ),
          tabWrapper(
            child: FutureBuilder(
                future: Future.wait([
                  ama.getUserViews(),
                  ama.getDevices()
                ],
                eagerError: true,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Failed trying to fetch either libraries or devices.'),
                      Text('${snapshot.error}'),
                    ],
                  );
                }
            
                List<BaseItemDto> dtos = snapshot.data![0] as List<BaseItemDto>;
                List<DeviceInfoDto> devices = snapshot.data![1] as List<DeviceInfoDto>;
            
                return StatefulBuilder(
                  builder: (context, setPageState) => Column(
                    children: [
                      Text('Library Access', style: getTextStyling(1, context)),
                      if (dtos != null) ... [
                        EasyTile(
                          title: Text('Enable admin access for all libraries', style: getTextStyling(4, context)),
                          subtitle: Text('This user will have edit access to all folders via the Web UI.'),
                          trailing: Switch(
                            value: dto.policy!.enableAllFolders!,
                            onChanged: (bool value) {
                              setPageState(() {
                                dto = dto!.copyWith(
                                  policy: dto.policy!.copyWith(
                                    enableAllFolders: value,
                                  ),
                                );
                              });
                            },
                          ),
                          context: context,
                        ),
                        SizedBox(height: 5),
                        if (dto.policy!.enableAllFolders! == false) ...[
                          Text('Libraries', style: getTextStyling(1, context)),
                          Text('Any folders selected will be able to be edited by this new user.'),
                          SizedBox(height: 5),
                          for (BaseItemDto itemDto in  dtos ?? [])
                            EasyTile(
                              title: Text('${itemDto.name}', style: getTextStyling(4, context)),
                              trailing: Switch(
                                value: dto.policy!.enabledFolders!.contains(dto.id!),
                                onChanged: (bool value) {
                                  if (value == true) {
                                    setPageState(() {
                                      dto = dto!.copyWith(
                                        policy: dto.policy!.copyWith(
                                          enabledFolders: [...dto.policy!.enabledFolders!, dto.id!],
                                        ),
                                      );
                                    });
                                  } else {
                                    setPageState(() {
                                      dto = dto!.copyWith(
                                        policy: dto.policy!.copyWith(
                                          enabledFolders: List<String>.from
                                          (dto.policy!.enabledFolders!)..remove(dto.id!),
                                        ),
                                      );
                                    });
                                  }
                                },
                              ),
                              context: context
                            ),
                          ],
                        ],
                        if (devices != null) ...[
                          Text('Device Access', style: getTextStyling(1, context)),
                          EasyTile(
                            title: Text('Enable admin access for all devices', style: getTextStyling(4, context)),
                            subtitle: Text('This user can only log on via selected devices, unless all are enabled.'),
                            trailing: Switch(
                              value: dto.policy!.enableAllDevices!,
                              onChanged: (bool value) {
                                setPageState(() {
                                  dto = dto!.copyWith(
                                    policy: dto.policy!.copyWith(
                                      enableAllDevices: value,
                                    ),
                                  );
                                });
                              },
                            ),
                            context: context
                          ),
                          SizedBox(height: 5),
                          if (dto.policy!.enableAllDevices == false)
                            for (DeviceInfoDto device in devices)
                              EasyTile(
                                title: Text('${device.name} - ${device.appName}', style: getTextStyling(4, context)),
                                trailing: Switch(
                                  value: dto.policy!.enabledDevices!.contains(device.id!),
                                  onChanged: (bool value) {
                                    if (value == true) {
                                      setPageState(() {
                                        dto = dto!.copyWith(
                                          policy: dto.policy!.copyWith(
                                            enabledDevices: List<String>.from
                                            (dto.policy!.enabledDevices!)..add(device.id!),
                                          ),
                                        );
                                      });
                                    } else {
                                      setPageState(() {
                                        dto = dto!.copyWith(
                                          policy: dto.policy!.copyWith(
                                            enabledDevices: List<String>.from
                                            (dto.policy!.enabledDevices!)..remove( device.id!),
                                          ),
                                        );
                                      });
                                    }
                                  },
                                ),
                                context: context
                              ),
                      ],
                      SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: () async => await save(),
                        child: Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          tabWrapper(
            child: Column(
              children: [
                SizedBox(height: 5),
                Text('Parental Controls', style: getTextStyling(1, context)),
                SizedBox(height: 10),
                Text('Block items with no or unrated rating', style: getTextStyling(1, context)),
                SizedBox(height: 5),
                for (MapEntry<String, UnratedItem> item in unratedItems.entries)
                  EasyTile(
                    title: Text('${item.key}', style: getTextStyling(4, context)),
                    trailing: Switch(
                      value: dto.policy!.blockUnratedItems!.contains(item.value),
                      onChanged: (bool value) {
                        if (value == true) {
                          setState(() {
                            dto = dto!.copyWith(
                              policy: dto.policy!.copyWith(
                                blockUnratedItems: List<UnratedItem>.from
                                (dto.policy!.blockUnratedItems!)..add(item.value),
                              ),
                            );
                          });
                        } else {
                          setState(() {
                            dto = dto!.copyWith(
                              policy: dto.policy!.copyWith(
                                blockUnratedItems: List<UnratedItem>.from
                                (dto.policy!.blockUnratedItems!)..remove( item.value),
                              ),
                            );
                          });
                        }
                      },
                    ),
                    context: context
                  ),
                SizedBox(height: 10),
                Text('Allowed tags', style: getTextStyling(1, context)),
                Wrap(
                  children: [
                    if (dto.policy!.allowedTags?.isNotEmpty ?? false)
                      for (String string in dto.policy!.allowedTags!)
                        Chip(
                          label: Text(string),
                          deleteIcon: Icon(Icons.delete),
                          onDeleted: () {
                            setState(() {
                              dto = dto!.copyWith(
                                policy: dto.policy!.copyWith(
                                  allowedTags: List<String>.from
                                  (dto.policy!.allowedTags!)..remove(string),
                                ),
                              );
                            });
                          },
                        )
                    else
                      Text('No allowed tags yet.'),
                  ],
                ),
                SizedBox(height: 10),
                EasyTile(
                  title: Text('Add tag for allowed items', style: getTextStyling(4, context)),
                  subtitle: Text('When you add a tag, any items with it will be allowed for this user.'),
                  trailing: Icon(Icons.open_in_browser),
                  onTap: () async {
                    TextEditingController controller = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) => popUpDiag(
                        title: 'Add a Tag',
                        content: [
                          EasyTextField(
                            controller: controller,
                            labelText: 'Tag',
                          ),
                        ],
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                dto = dto!.copyWith(
                                  policy: dto.policy!.copyWith(
                                    allowedTags: List<String>.from
                                    (dto.policy!.allowedTags!)..add(controller.value.text),
                                  ),
                                );
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Continue'),
                          ),
                        ],
                      ),
                    );
                  },
                  context: context
                ),
                SizedBox(height: 10),
                Text('Blocked tags', style: getTextStyling(1, context)),
                Wrap(
                  children: [
                    if (dto.policy!.blockedTags?.isNotEmpty ?? false)
                      for (String string in dto.policy!.blockedTags!)
                        Chip(
                          label: Text(string),
                          deleteIcon: Icon(Icons.delete),
                          onDeleted: () {
                            setState(() {
                              dto = dto!.copyWith(
                                policy: dto.policy!.copyWith(
                                  blockedTags: List<String>.from
                                  (dto.policy!.blockedTags!)..remove(string),
                                ),
                              );
                            });
                          },
                        )
                    else
                      Text('No blocked tags yet.'),
                  ],
                ),
                SizedBox(height: 10),
                EasyTile(
                  title: Text('Add tag for blocked items', style: getTextStyling(4, context)),
                  subtitle: Text('When you add a tag, any items with it will be hidden for this user.'),
                  trailing: Icon(Icons.open_in_browser),
                  onTap: () async {
                    TextEditingController controller = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) => popUpDiag(
                        title: 'Add a Tag',
                        content: [
                          EasyTextField(
                            controller: controller,
                            labelText: 'Tag',
                          ),
                        ],
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                dto = dto!.copyWith(
                                  policy: dto.policy!.copyWith(
                                    blockedTags: List<String>.from
                                    (dto.policy!.blockedTags!)..add(controller.value.text),
                                  ),
                                );
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Continue'),
                          ),
                        ],
                      ),
                    );
                  },
                  context: context
                ),
                SizedBox(height: 10),
                FilledButton(
                  onPressed: () async => await save(),
                  child: Text('Save'),
                ),
              ],
            ),
          ),
          tabWrapper(
            child: Column(
              children: [
                SizedBox(height: 10),
                if (dto.hasPassword!) ...[
                  EasyTextField(
                    passwordSafe: true,
                    controller: currentPasswordField,
                    labelText: 'Current Password',
                  ),
                  SizedBox(height: 5),
                ],
                EasyTextField(
                  passwordSafe: true,
                  controller: newPasswordField,
                  labelText: 'New Password',
                ),
                SizedBox(height: 5),
                EasyTextField(
                  passwordSafe: true,
                  controller: newPasswordConfirmField,
                  labelText: 'New Password Confirm',
                ),
                SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (newPasswordField.text != newPasswordConfirmField.text) {
                      showScaffold('new Password needs to be the same in the 2 text fields.', context);
                      return;
                    }

                    if (currentPasswordField.text.isEmpty) {
                      showScaffold('You need to add your current Password.', context);
                      return;
                    }

                    final DioException? result = await ama.updateUserPassword(
                      currentPw: dto.hasPassword! ? currentPasswordField.text : null,
                      newPw: newPasswordField.text,
                      userId: dto.id!
                    );

                    if (result != null) {
                      SimpleErrorDiag(
                        title: 'Save Error', 
                        desc: "Could not save Password. \n HTTP Code: ${result.response?.statusCode ?? 'Unknown'}", 
                        context: context
                      );
                      return;
                    } else {
                      setState(() {
                        dto = dto!.copyWith(
                          hasPassword: true,
                        );
                      });
                      showScaffold('New password for ${dto.name!} saved!', context);
                    }

                  },
                  child: Text('Save Password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
