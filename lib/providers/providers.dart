import 'package:dio/dio.dart';

export 'jellyfin_api.dart';
export 'player_manager.dart';
export 'package:jellyfin/providers/provider_extensions/jellyfin_api/jellyfin_api.dart';

extension Ticks on Duration {
  int get inTicks => inMicroseconds * 10;
}
