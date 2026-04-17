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
                  title: Text('Subtitle Text Height', style: getTextStyling(4, context),),
                  subtitle: Text('Setting an incorrect number will do nothing'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      onChanged: (value) async {
                        final newValue = double.tryParse(value);
                    
                        if (newValue != null) {
                          sets.settingsObj!.subtitleHeight = newValue;
                          sets.notifyListeners();
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '${sets.settingsObj!.subtitleHeight}',
                      ),
                    ),
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Subtitle Font Size', style: getTextStyling(4, context),),
                  subtitle: Text('Controls the font size of your subtitles'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      onChanged: (value) async {
                        final newValue = double.tryParse(value);
                    
                        if (newValue != null) {
                          sets.settingsObj!.subtitleFontSize = newValue;
                          sets.notifyListeners();
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '${sets.settingsObj!.subtitleFontSize}',
                      ),
                    ),
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Subtitle Word Spacing', style: getTextStyling(4, context),),
                  subtitle: Text('The padding in between words in subtitles'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      onChanged: (value) async {
                        final newValue = double.tryParse(value);
                    
                        if (newValue != null) {
                          sets.settingsObj!.subtitleFontSize = newValue;
                          sets.notifyListeners();
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: '${sets.settingsObj!.subtitleWordSpacing}',
                      ),
                    ),
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Use Bold Font', style: getTextStyling(4, context),),
                  subtitle: Text('Use a bold font for your subtitles'),
                  trailing: Switch(
                    value: sets.settingsObj!.fontIsBold,
                    onChanged: (value) async {
                      sets.settingsObj!.fontIsBold = value;
                      sets.notifyListeners();
                    },
                  ),
                  context: context,
                ),
                SizedBox(height: 5,),
                EasyTile(
                  title: Text('Subtitle Alignment', style: getTextStyling(4, context),),
                  subtitle: Text('Where the subtitles are aligned on the screen while watching'),
                  trailing: DropdownMenu(
                    initialSelection: sets.settingsObj!.subtitleAlignIndex,
                    onSelected: (index) async {
                      sets.settingsObj!.subtitleAlignIndex = index!;
                      sets.notifyListeners();
                    },
                    dropdownMenuEntries: [
                      for (TextAlign align in sets.textAlignments)
                        DropdownMenuEntry(
                          value: align.index,
                          label: align.name,
                        ),
                    ],
                  ),
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
