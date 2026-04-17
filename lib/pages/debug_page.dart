import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:overlayment/overlayment.dart';

class DebugPage extends StatefulWidget {

  const DebugPage({super.key});

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
                await Hive.deleteBoxFromDisk('jellyBox');
                showScaffold('Deleted box data!', context);
              },
              child: Text('Clear Hive Box'),
            ),
            FilledButton.tonal(
              onPressed: () async {
                await Hive.deleteFromDisk();
                showScaffold('cleared all Hive data!', context);
              },
              child: Text('Clear All Data'),
            ),
            FilledButton.tonal(
              onPressed: () {
                Overlayment.show(
                  OverWindow(
                    alignment: Alignment.center,
                    child: Text('Flutter && git sucks'),
                  ),
                );
              },
              child: Text('Show OverWindow'),
            ),
          ],
        ),
      ),
    );
  }
}
