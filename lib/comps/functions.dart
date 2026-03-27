import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:url_launcher/url_launcher.dart';

// this is for carouselView
Future<void> goToItemPage({required BaseItemDto data, required BuildContext context}) async {
  print('${data}');
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ItemPage(viewData: data),
    ),
  );
}

Future<void> goToURL(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $url');
  }
}
