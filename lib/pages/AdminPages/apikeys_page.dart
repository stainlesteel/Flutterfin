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

class ApikeysPage extends StatefulWidget {
  const ApikeysPage({super.key});

  @override
  State<ApikeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApikeysPage> {
  List<AuthenticationInfo>? apiKeys;
  bool loaded = false;

  @override
  void initState() {
    adminCheck(context);
    super.initState();
    starter();
  }

  Future<void> starter() async {
    final temp = await Provider.of<JellyfinAPI>(context, listen: false).getApiKeys();
    setState(() {
      apiKeys = temp;
      loaded = true;
    });
  }

  String? appName;

  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();

    return Scaffold(
      appBar: AppBar(
        title: Text('API Keys'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: loaded 
          ? Column(
            children: (apiKeys != null) 
            ? [
              Text(
          """
                External applications are required to have an API key
                in order to communicate with the server. Keys are issued
                by logging in with a normal user account or manually granting
                the application a key.
                """
              ),
              SizedBox(height: 5),
              TableWidgets(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: apiKeys!.length,
                    itemBuilder: (context, index) {
                      AuthenticationInfo auth = apiKeys![index];
                      return EasyTile(
                        title: Text('${auth.appName}', style: getTextStyling(4, context)),
                        subtitle: Text('${auth.accessToken}'),
                        trailing: Text('${getDeviceTime(auth.dateCreated!, context)}'),
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (context) => popUpDiag(
                              title: 'Delete ${auth.appName}?',
                              content: [
                                Text('Are you sure?')
                              ],
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final result = await ama.deleteApiKey(auth.accessToken!);
                                    Navigator.pop(context);

                                    if (result != null) {
                                      showScaffold('Could not delete key, HTTP error code: ${result.response!.statusCode}', context);
                                      return;
                                    }

                                    setState(() {
                                      apiKeys!.removeAt(index);
                                    });
                                  },
                                  child: Text('Continue'),
                                ),
                              ],
                            ),
                          );
                        },
                        context: context,
                      );
                    },
                  ),
                ],
                leading: FilledButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('New API Key'),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => popUpDiag(
                        title: 'New API Key',
                        content: [
                          EasyTextField(
                            labelText: 'App name',
                            onChanged: (String value) {
                              setState(() {
                                appName = value;
                              });
                            },
                          ),
                          SizedBox(height: 5),
                          Text('A human readable name for identifying API keys.'),
                          Text('An empty app name will result in a denied request.'),
                        ],
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (appName == null) {
                                Navigator.pop(context);
                                showScaffold('App name was empty, denied request.', context);
                                return;
                              }
                              final result = await ama.createApiKey(appName!);
                              if (result != null) {
                                Navigator.pop(context);
                                showScaffold('Error when making key: ${result.message}', context);
                                return;
                              }
                              Navigator.pop(context);
                              starter();
                            },
                            child: Text('Make'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                context: context,
              ),
            ]
            : [
              Text('Failed to get API key data, try again.'),
            ],
          )
          : CircularProgressIndicator(),
        ),
      ),
    );
  }
}
