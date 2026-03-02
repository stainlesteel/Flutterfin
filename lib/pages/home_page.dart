import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';

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
        leading: TextButton(
          child: Text('Back'),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => StartingPage()),
              (route) => false,
            );
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text(
                'welcome, ${base?[ama.lastUser!] ?? 'nobody'}',
                style: getTextStyling(2, context),
              ),
              Text('My Media', style: getTextStyling(1, context)),
              SizedBox(height: 10),
              SizedBox(height: 10),
              UserViews(context),
              SizedBox(height: 10),
              ContinueWatching(context),
            ],
          ),
        ),
      ),
    );
  }
}
