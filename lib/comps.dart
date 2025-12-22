import 'package:flutter/material.dart';

TextStyle getTextStyling(int index, BuildContext context) {
  if (index == 0) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 60);
  } else if (index == 1) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 20,);
  } else if (index == 2) {
    return TextStyle(fontWeight: FontWeight.bold, fontSize: 30,);
  } else if (index == 3) {
    return TextStyle(fontSize: 20,);
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
