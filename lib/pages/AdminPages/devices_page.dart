import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/AdminPages/user_page.dart';
import 'package:jellyfin/pages/starting_page.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfin/pages/AdminPages/admin_page.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> with TickerProviderStateMixin {
  @override
  void initState() {
    adminCheck(context);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    TabController tabController = TabController(
      length: 2,
      vsync: this
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Devices'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.devices_sharp),
              text: 'Recent Devices',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          tabWrapper(
            child: Column(
              children: [
                SizedBox(height: 10),
                Text('Devices', style: getTextStyling(1, context)),
                SizedBox(height: 10),
                FutureBuilder(
                  future: ama.getDevices(),
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
                    if (asyncSnapshot.hasError) return Text("Failed getting devices due to error. \n Error: ${asyncSnapshot.error}");

                    List<DeviceInfoDto> devices = asyncSnapshot.data!;

                    return TableWidgets(
                      context: context,
                      leading: FilledButton.tonal(
                        onPressed: () {},
                        child: Text('lorem ipsum'),
                      ),
                      children: [
                        SizedBox(height: 5),
                        Row(
                          children: [
                            SizedBox(width: 5),
                            Text('Device, App Name, Last Active', style: getTextStyling(4, context)),
                            Spacer(),
                            Text('User', style: getTextStyling(4, context)),
                            SizedBox(width: 5),
                          ],
                        ),
                        SizedBox(height: 5),
                        for (DeviceInfoDto device in devices)
                          EasyTile(
                            title: Text('${device.name}', style: getTextStyling(4, context)),
                            subtitle: Text('${getDeviceTime(device.dateLastActivity!, context)}, ${device.appName}'),
                            trailing: Text('${device.lastUserName}', style: getTextStyling(4, context)),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => popUpDiag(
                                  title: '${device.name}',
                                  content: [
                                    Text("Delete device ${device.name}? It will reappear the next time a user signs in with it."),
                                  ],
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final result = await ama.deleteDevice(device.id!);

                                        if (result != null) {
                                          SimpleErrorDiag(
                                            title: 'Deletion Error',
                                            desc: 'Could not delete user. Error: ${result.error}',
                                            doublePop: true,
                                            context: context,
                                          );
                                          return;
                                        }
                                        setState(() {
                                          devices.remove(device);
                                        });
                                        Navigator.pop(context);
                                        showScaffold('Deleted user!', context);
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            context: context
                          )
                      ],
                    );
                  }
                ),
              ],
            )
          ),
          tabWrapper(
            child: Column(
              children: [],
            )
          ),
        ],
      ),
    );
  }
}
