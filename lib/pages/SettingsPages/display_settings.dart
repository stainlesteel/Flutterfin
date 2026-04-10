import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:jellyfin/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/main.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  List<ThemeMode> themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
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
      onPopInvokedWithResult: (_, __) async {
        await sets.saveData();
      },
      child: Scaffold(
        appBar: AppBar(
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
                    initialSelection: sets.settingsObj!.themeMode,
                    onSelected: (int? mode) async {
                      sets.settingsObj!.themeMode = mode!;
                      sets.notifyListeners();
                    },
                    dropdownMenuEntries: [
                      for (ThemeMode mode in themeModes)
                        DropdownMenuEntry(
                          value: ThemeMode.values.indexOf(mode),
                          label: mode.name,
                        ),
                    ],
                  ),
                  context: context
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Theme Style', style: getTextStyling(4, context),),
                  subtitle: Text("The design language of the content of the app, default is Google's Material"),
                  trailing: DropdownMenu<int>(
                    initialSelection: sets.settingsObj!.themeType,
                    onSelected: (index) async {
                      sets.settingsObj!.themeType = index!;
                        
                      sets.notifyListeners();
                    },
                    dropdownMenuEntries: [
                      DropdownMenuEntry<int>(
                        value: 0,
                        label: 'Material',
                      ),
                      DropdownMenuEntry<int>(
                        value: 1,
                        label: 'Yaru',
                      ),
                      DropdownMenuEntry<int>(
                        value: 2,
                        label: 'Adwaita',
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
                      trailing: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownMenu<HomepageCarousels>(
                          initialSelection: sets.settingsObj!.homepageCarousels[index],
                          onSelected: (HomepageCarousels? carousel) async {
                            if (carousel == null) {
                              return;
                            }
                            sets.settingsObj!.homepageCarousels[index] = carousel;
                              
                            await sets.saveData();
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
                      ),
                      context: context
                    );
                  },
                ),
                SizedBox(height: 5,),
                Text('Other', style: getTextStyling(2, context)),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Keep Screen Awake', style: getTextStyling(4, context),),
                  subtitle: Text("Stop OS from turning off screen by itself while using $appTitle. Some OS's may ignore this setting."),
                  trailing: Switch(
                    value: sets.settingsObj!.keepScreenAwake,
                    onChanged: (val) async {
                      sets.settingsObj!.keepScreenAwake = val;
                      WakelockPlus.toggle(enable: val);
      
                      sets.notifyListeners();
                    },
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Use Sliding Transition for Pages', style: getTextStyling(4, context),),
                  subtitle: Text("This will change only the transition for moving to or out of an Item, if selected the slide + fade transition is used"),
                  trailing: Switch(
                    value: sets.settingsObj!.useSlidingPageTransition,
                    onChanged: (val) async {
                      sets.settingsObj!.useSlidingPageTransition = val;
      
                      sets.notifyListeners();
                    },
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
