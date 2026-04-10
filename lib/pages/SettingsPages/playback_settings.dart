import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/main.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlaybackSettingsPage extends StatefulWidget {
  const PlaybackSettingsPage({super.key});

  @override
  State<PlaybackSettingsPage> createState() => _PlaybackSettingsPage();
}

class _PlaybackSettingsPage extends State<PlaybackSettingsPage> {
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
          title: Text('Playback Settings'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Text('Video Player', style: getTextStyling(2, context)),
                EasyTile(
                  title: Text('Preferred Playback Speed', style: getTextStyling(4, context),),
                  subtitle: Text('Setting an incorrect number will do nothing'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      onChanged: (value) async {
                        final newValue = double.tryParse(value);
                    
                        if (newValue != null) {
                          sets.settingsObj!.persistentPlaybackSpeed = newValue;
                          sets.notifyListeners();
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '${sets.settingsObj!.persistentPlaybackSpeed}',
                      ),
                    ),
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Use HLS', style: getTextStyling(4, context),),
                  subtitle: Text('Use HTTP Live Streaming for loading videos'),
                  trailing: SizedBox(
                    width: 100,
                    child: Switch(
                      value: sets.settingsObj!.useHLS,
                      onChanged: (val) async {
                        sets.settingsObj!.useHLS = val;
                        sets.notifyListeners();
                      },
                    ),
                  ),
                  context: context,
                ),
                EasyTile(
                  title: Text('Play Next Episode Automatically', style: getTextStyling(4, context),),
                  subtitle: Text('Applies only when watching shows'),
                  trailing: SizedBox(
                    width: 100,
                    child: Switch(
                      value: sets.settingsObj!.playNextEpisodeAuto,
                      onChanged: (val) async {
                        sets.settingsObj!.playNextEpisodeAuto = val;
                        sets.notifyListeners();
                      },
                    ),
                  ),
                  context: context,
                ),
                EasyTile(
                  title: Text('Show Skip Episode Dialog', style: getTextStyling(4, context),),
                  subtitle: Text('Show a dialog to skip episode when you have watched 90% of it'),
                  trailing: SizedBox(
                    width: 100,
                    child: Switch(
                      value: sets.settingsObj!.showSkipCreditsDialog,
                      onChanged: (val) async {
                        sets.settingsObj!.showSkipCreditsDialog = val;
                        sets.notifyListeners();
                      },
                    ),
                  ),
                  context: context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
