import 'package:flutter/material.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
