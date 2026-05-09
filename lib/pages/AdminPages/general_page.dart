import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    ServerObj obj = ama.serverList[ama.lastUsedServer!];

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text('Settings', style: getTextStyling(2, context)),
              SizedBox(height: 5),
              EasyTextField(
                labelText: 'Server Name',
                initialValue: '${obj.serverName}'
              ),
            ],
          ),
        ),
      ),
    );
  }
}
