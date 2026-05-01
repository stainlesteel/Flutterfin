import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/providers/downloader_manager.dart';
import 'package:jellyfin/providers/jellyfin_api.dart';
import 'package:jellyfin/providers/provider_extensions/jellyfin_api/jellyfin_api.dart';
import 'package:jellyfin/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/main.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StorageSettings extends StatefulWidget {
  const StorageSettings({super.key});

  @override
  State<StorageSettings> createState() => _StorageSettings();
}

class _StorageSettings extends State<StorageSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider sets = context.watch<SettingsProvider>();

    return PopScope(
      onPopInvokedWithResult: (_, __) async {
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Storage Settings'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                EasyTile(
                  leading: Icon(
                    Icons.image
                  ),
                  title: Text(
                    'Clear Image Cache',
                    style: getTextStyling(4, context),
                  ),
                  onTap: () async {
                    CachedNetworkImageProvider.defaultCacheManager.emptyCache();
                    PaintingBinding.instance.imageCache.clear();
                    PaintingBinding.instance.imageCache.clearLiveImages();

                    showScaffold('Cleared image cache!', context);
                  },
                  context: context,
                ),
                SizedBox(height: 5),
                EasyTile(
                  leading: Icon(
                    Icons.file_present
                  ),
                  title: Text(
                    'Clear All Saved Storage',
                    style: getTextStyling(4, context),
                  ),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StartingPage(),
                      ),
                      result: (route) => false,
                    );
                    Provider.of<JellyfinAPI>(context, listen: false).wipeItAll();
                    sets.wipeItAll();
                    sets.notifyListeners();
                  },
                  context: context,
                ),
                SizedBox(height: 5),
                EasyTile(
                  leading: Icon(
                    Icons.settings
                  ),
                  title: Text(
                    'Revert to Default Settings',
                    style: getTextStyling(4, context),
                  ),
                  onTap: () async {
                    sets.settingsObj = SettingsObj();
                    await sets.box.put('settings', sets.settingsObj!);

                    await Future.delayed(Durations.medium1);
                    sets.notifyListeners();
                  },
                  context: context,
                ),
                SizedBox(height: 5),
                EasyTile(
                  leading: Icon(
                    Icons.download
                  ),
                  title: Text(
                    'Delete Downloads Data',
                    style: getTextStyling(4, context),
                  ),
                  subtitle: Text('This cannot delete the actual video files, only the records stored by the app.'),
                  onTap: () async {
                    await Provider.of<DownloaderManager>(context, listen: false).fileDownloader!.database.deleteAllRecords();
                  },
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
