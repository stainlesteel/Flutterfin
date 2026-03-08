import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:jellyfin/pages/pages.dart';

// this is for carouselView
Future<void> goToItemPage({required int index, required BaseItemDto data, required BuildContext context}) async {
  print('${data}');
  if (data == null) {
  } else {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemPage(viewData: data),
      ),
    );
  }
}
