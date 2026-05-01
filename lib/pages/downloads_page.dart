import 'package:flutter/material.dart';
import 'package:jellyfin/providers/downloader_manager.dart';
import 'package:provider/provider.dart';
import 'package:background_downloader/background_downloader.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  @override
  Widget build(BuildContext context) {
    DownloaderManager dwm = context.watch<DownloaderManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Downloads'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              StreamBuilder(
                stream: dwm.fileDownloader!.database.updates,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Received an error.\nError: ${snapshot.error}");
                  } else {
                    return Text('unfinished');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
