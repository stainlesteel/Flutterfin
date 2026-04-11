import 'package:provider/provider.dart';
import 'package:jellyfin/providers/providers.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:flutter/material.dart';

class SubtitleSettings extends StatefulWidget {
  const SubtitleSettings({super.key});

  @override
  State<SubtitleSettings> createState() => _SubtitleSettingsState();
}

class _SubtitleSettingsState extends State<SubtitleSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider sets = context.watch<SettingsProvider>();

    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        await sets.saveData();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Subtitle Settings'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                EasyTile(

                  context: context
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
