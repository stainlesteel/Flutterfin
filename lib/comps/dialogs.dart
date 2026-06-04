import 'package:flutter/material.dart';

Widget popUpDiag({
  String title = '',
  List<Widget> content = const [],
  List<Widget> actions = const [],
}) {
  return AlertDialog(
    scrollable: true,
    title: Text(title),
    content: Column(mainAxisSize: MainAxisSize.min, children: content),
    actions: actions,
  );
}

void ServerConnectErrorDiag(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "Connection Error",
      content: [
        Text(
          """
          We're unable to connect to the selected server right now. Please ensure it is running and try again.
          If you are seeing this in the Servers page, the last server you used cannot be connected to right now.
          """,
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}

void SimpleErrorDiag({
  required String title,
  required String desc,
  required BuildContext context,
  bool doublePop = false,
}) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "$title",
      content: [Text("$desc")],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (doublePop) Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}

void LogInErrorDiag(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => popUpDiag(
      title: "Log In Error",
      content: [
        Text(
          "Unable to login to the server with these credentials, please ensure they are correct and try again.",
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Ok'),
        ),
      ],
    ),
  );
}
