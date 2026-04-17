import 'package:flutter/material.dart';
import 'package:jellyfin/objects/objects.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  final Box box;

  SettingsProvider(this.box);

  SettingsObj? settingsObj;

  // list of custom settings lists
  List<TextAlign> textAlignments = [TextAlign.left, TextAlign.right, TextAlign.center];

  Future<void> loadSettingsData() async {
    final _data = box.get('settings');

    if (_data == null) {
      settingsObj = SettingsObj();
      await box.put('settings', settingsObj);

      notifyListeners();
      return;
    }

    settingsObj = _data;
    notifyListeners();
  }

  Future<void> saveData() async {
    await settingsObj!.save();
    await box.put('settings', settingsObj);
    print("saveData(): saved new object to box!, \n object showUsername: ${box.get('settings').showUsername}");
    notifyListeners();
  }

  // PLEASE don't use this until you have popped to StartingPage
  Future<void> wipeItAll() async {
    settingsObj = SettingsObj();
    await box.flush();
    await box.clear();
  }
}
