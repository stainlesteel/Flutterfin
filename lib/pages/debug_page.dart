import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jellyfin/comps/comps.dart';

class DebugPage extends StatefulWidget {
  final Box box;

  const DebugPage({super.key, required this.box});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Debug Page', style: getTextStyling(5, context),),
            Text('To leave, set debug (bool) in main.dart to false, and hot restart.'),
            SizedBox(height: 10,),
            FilledButton.tonal(
              onPressed: () async {
                await widget.box.clear();
                showScaffold('Deleted box data!', context);
              },
              child: Text('Clear Hive Box'),
            ),
          ],
        ),
      ),
    );
  }
}
