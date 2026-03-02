export 'jellyfin_api.dart';
export 'player_manager.dart';

extension Ticks on Duration {
  int get inTicks => inMicroseconds * 10;
}

