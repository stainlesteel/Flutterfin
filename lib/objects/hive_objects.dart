// contains hive objects and data enums
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

part 'hive_objects.g.dart';

@HiveType(typeId: 0)
class ServerObj extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? serverURL;

  @HiveField(2)
  String? serverName;

  @HiveField(3)
  String? version;

  @HiveField(4)
  UserData? userData;

  @HiveField(5)
  bool? lastLogIsQC;

  @HiveField(7)
  String? deviceId;

  @HiveField(8)
  DeviceProfile? profile;

  ServerObj({
    this.id,
    this.serverURL,
    this.serverName,
    this.version,
    this.userData,
    this.lastLogIsQC,
    this.profile,
  });
}

@HiveType(typeId: 1)
class UserData extends HiveObject {
  @HiveField(0)
  String? accessToken;

  @HiveField(1)
  String? userId;

  UserData({
    this.accessToken,
    this.userId
  });
}

@HiveType(typeId: 2)
class SettingsObj extends HiveObject {
  // display settings, theme is handled by adaptive_theme
  @HiveField(0)
  List<HomepageCarousels> homepageCarousels;

  @HiveField(1)
  bool showUsername;

  @HiveField(2)
  int themeType; // to avoid making a custom type, this is an index for the getTheme function used by main.dart

  @HiveField(3)
  int themeMode;

  @HiveField(4)
  bool keepScreenAwake;

  @HiveField(5)
  bool useSlidingPageTransition; // only for item pages
  // end display settings
  
  // start playback settings
  @HiveField(6)
  double persistentPlaybackSpeed;
  
  @HiveField(7)
  bool useHLS;

  @HiveField(8)
  bool playNextEpisodeAuto;

  @HiveField(9)
  bool showSkipCreditsDialog;

  // end playback settings

  SettingsObj({
    this.homepageCarousels = const [
      HomepageCarousels.userViews,
      HomepageCarousels.continueWatching,
      HomepageCarousels.becauseYouWatched,
      HomepageCarousels.recentMovies,
      HomepageCarousels.recentShows,
      HomepageCarousels.nextUp,
    ],
    this.showUsername = true,
    this.themeType = 0,
    this.themeMode = 0,
    this.keepScreenAwake = true,
    this.useSlidingPageTransition = true,
    this.persistentPlaybackSpeed = 1.00,
    this.useHLS = false,
    this.playNextEpisodeAuto = true,
    this.showSkipCreditsDialog = true,
  });
}

@HiveType(typeId: 3)
enum HomepageCarousels {
  @HiveField(0)
  userViews(name: 'My Media'),

  @HiveField(1)
  continueWatching(name: 'Continue Watching'),

  @HiveField(2)
  becauseYouWatched(name: 'Because you Watched'),

  @HiveField(3)
  recentMovies(name: 'Recently Added Movies'),

  @HiveField(4)
  recentShows(name: 'Recently Added Shows'),

  @HiveField(5)
  nextUp(name: 'Next Up'),

  @HiveField(6)
  none(name: 'None'),
  ;

  const HomepageCarousels({
    required this.name,
  });

  final String name;
}
