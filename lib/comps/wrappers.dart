import 'package:flutter/material.dart';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';

/// getTextStyling(): custom Text Styling
/// index:
///   0: bold, size 60
///   1: bold, size 20
///   2: bold, size 30
///   3: size 20
///   4: bold
///   5: bold, size 40
///   6: size 30
TextStyle getTextStyling(int index, BuildContext context) {
  if (index == 0) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 60);
  } else if (index == 1) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  } else if (index == 2) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 30);
  } else if (index == 3) {
    return TextStyle(fontSize: 20);
  } else if (index == 4) {
    return TextStyle(fontWeight: FontWeight.bold);
  } else if (index == 5) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 40);
  } else if (index == 6) {
    return TextStyle(fontSize: 30);
  } else {
    return TextStyle();
  }
}

String randomString() {
  return String.fromCharCodes(
    List.generate(8, (index) => Random().nextInt(33) + 89),
  );
}

String getTime(int ticks) {
  Duration duration = Duration(microseconds: ticks * 10);

  return '${duration.inHours % 24}h ${duration.inMinutes % 60}m';
}

/*
  0: unlimited data (wifi, ethernet)
  1: limited data (mobile)
  2: no data (none)
*/
Future<ConnectivityResult> checkNetwork() async {
  final List<ConnectivityResult> result = await (Connectivity()
      .checkConnectivity());

  print("Network Connectivity State: ${result[0]}");
  return result[0];
}

void showScaffold(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
