import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';

export 'primary_page.dart';
export 'general_page.dart';
export 'branding_page.dart';
export 'user_page.dart';
export 'user_editing_page.dart';
export 'devices_page.dart';

Widget tabWrapper({required Widget child}) {
  return SingleChildScrollView(
    child: Center(
      child: child
    ),
  );
}

Future<void> adminCheck(BuildContext context) async {
  UserDto? result = await Provider.of<JellyfinAPI>(context, listen: false).getCurrentUser();
  if (result?.policy?.isAdministrator == false) {
    Navigator.pop(context);
    showScaffold('User with normal privileges tried to access Admin Page', context);
  }
}

String getDeviceTime(DateTime obj, BuildContext context) {
  return '${obj.year}:${obj.month}:${obj.day}, ${TimeOfDay.fromDateTime(obj.toLocal()).format(context)}';
}
