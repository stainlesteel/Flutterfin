import 'package:flutter/material.dart';
import 'package:jellyfin/providers/settings_provider.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// this is for carouselView
Future<void> goToItemPage({required BaseItemDto data, required BuildContext context}) async {
  SettingsProvider sets = context.read<SettingsProvider>();

  await Navigator.push(
    context,
    sets.settingsObj!.useSlidingPageTransition
    ? PageRouteBuilder(
      pageBuilder: (context, __, ___) => ItemPage(viewData: data),
      transitionsBuilder: (context, animation, animation2, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    )
    : MaterialPageRoute(
      builder: (context) => ItemPage(viewData: data)
    ),
  );
}

Future<void> goToURL(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $url');
  }
}
