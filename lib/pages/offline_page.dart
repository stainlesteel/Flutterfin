import 'package:flutter/material.dart';
import 'package:jellyfin/comps/wrappers.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('We are down!'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Text('Could not log in to last-used server', style: getTextStyling(2, context),),
            Text('You can try reconnecting, or going back to the main menu.')
            /* FilledButton.tonal(
              onPressed: () {
              },
            ),
            */
          ],
        ),
      ),
    );
  }
}


