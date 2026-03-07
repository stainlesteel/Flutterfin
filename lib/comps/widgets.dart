import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:jellyfin/pages/pages.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';

/// simpleTile(): A simpler version of ListTile
/// args:
/// Widget? leading
/// String? title
/// Widget? trailing
/// Widget? subtitle
Widget simpleTile({
  Widget? leading = null,
  String? title = null,
  Widget? trailing = null,
  Widget? subtitle = null,
  void Function()? onTap = null,
  double padding = 10,
}) {
  return Padding(
    padding: EdgeInsets.only(left: padding, right: padding),
    child: Card(
      child: ListTile(
        leading: leading,
        subtitle: subtitle,
        title: Text('$title'),
        trailing: trailing,
        onTap: onTap,
      ),
    ),
  );
}

Widget detailCard({
  String? text = '',
  List<Widget>? children = null,
  required BuildContext context,
}) {
  if (children != null) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Row(children: children),
      ),
    );
  } else {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Text(text!, style: getTextStyling(1, context)),
      ),
    );
  }
}

Widget PlayerText(String text) {
  return Text(
    text,
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );
}

