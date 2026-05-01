import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';

class DownloaderManager extends ChangeNotifier {
  FileDownloader? fileDownloader;

  Future<void> init() async {
    fileDownloader = FileDownloader();

    await fileDownloader!.start(
      autoCleanDatabase: true,
      doTrackTasks: true,
      markDownloadedComplete: true,
    );
    
    fileDownloader!.configureNotification(
      running: TaskNotification('Downloading Media', 'Downloading {filename}'),
      complete: TaskNotification('Finished Downloading {filename}', '{filename} is available to watch'),
      error: TaskNotification('Download Error', 'Could not download {filename}'),
      progressBar: true,
    );
  }
}
