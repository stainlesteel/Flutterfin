import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({super.key});

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPage();
}

class _DisplaySettingsPage extends State<DisplaySettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  List<AdaptiveThemeMode> themeModes = [AdaptiveThemeMode.light, AdaptiveThemeMode.dark, AdaptiveThemeMode.system];
  List<HomepageCarousels> baseCarousels = [
    HomepageCarousels.userViews,
    HomepageCarousels.continueWatching,
    HomepageCarousels.becauseYouWatched,
    HomepageCarousels.recentMovies,
    HomepageCarousels.recentShows,
    HomepageCarousels.nextUp,
    HomepageCarousels.none,
  ];

  @override
  Widget build(BuildContext context) {
    SettingsProvider sets = context.watch<SettingsProvider>();

    return PopScope(
      onPopInvokedWithResult: (boolean, object) async {
        await sets.saveData();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              await sets.saveData();
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
          title: Text('Display Settings'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Text('Theme', style: getTextStyling(2, context)),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Theme Mode', style: getTextStyling(4, context),),
                  subtitle: Text('The current theme mode (light, dark), Default is Light'),
                  trailing: DropdownMenu(
                    initialSelection: AdaptiveTheme.of(context).mode,
                    onSelected: (AdaptiveThemeMode? mode) {
                      if (mode == null) {
                        return;
                      }
                      AdaptiveTheme.of(context).setThemeMode(mode);
                    },
                    dropdownMenuEntries: [
                      for (AdaptiveThemeMode mode in themeModes)
                        DropdownMenuEntry(
                          value: mode,
                          label: mode.modeName,
                        ),
                    ],
                  ),
                  context: context
                ),
                Text('Home', style: getTextStyling(2, context)),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Show Username', style: getTextStyling(4, context),),
                  subtitle: Text("This shows the 'welcome, user' text on the Home Page"),
                  trailing: Switch(
                    value: sets.settingsObj!.showUsername,
                    onChanged: (val) async {
                      sets.settingsObj!.showUsername = val;
                      sets.notifyListeners();
                    },
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                SizedBox(height: 5,),
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return EasyTile(
                      title: Text('Home Screen Section ${index + 1}', style: getTextStyling(4, context),),
                      trailing: DropdownMenu<HomepageCarousels>(
                        initialSelection: sets.settingsObj!.homepageCarousels[index],
                        onSelected: (HomepageCarousels? carousel) async {
                          if (carousel == null) {
                            return;
                          }
                          sets.settingsObj!.homepageCarousels[index] = carousel;
      
                          sets.notifyListeners();
                        },
                        dropdownMenuEntries: [
                          for (HomepageCarousels carousels in baseCarousels)
                            DropdownMenuEntry(
                              value: carousels,
                              label: carousels.name,
                            ),
                        ],
                      ),
                      context: context
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
