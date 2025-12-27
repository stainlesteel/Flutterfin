import 'package:flutter/material.dart';
import 'dart:math';

TextStyle getTextStyling(int index, BuildContext context) {
  if (index == 0) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 60);
  } else if (index == 1) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 20,);
  } else if (index == 2) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 30,);
  } else if (index == 3) {
    return TextStyle(fontSize: 20,);
  } else if (index == 4) {
    return TextStyle(fontWeight: FontWeight.bold);
  } else {
    return TextStyle();
  }
}


Widget popUpDiag({String title = '', List<Widget> content = const [], List<Widget> actions = const []}) {
  return AlertDialog(
    title: Text(title),
    content: content.isNotEmpty ? Column(
      mainAxisSize: MainAxisSize.min,
      children: content,
    ) : null,
    actions: actions.isNotEmpty ? actions : null,
  );
}

String randomString() {
  return String.fromCharCodes(List.generate(8, (index) => Random().nextInt(33) + 89));
}

void showScaffold(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}
