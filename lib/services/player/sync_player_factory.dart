import 'dart:io';

import 'package:syncy/services/player/media_kit_backend.dart';
import 'package:syncy/services/player/sync_player.dart';
import 'package:syncy/services/player/video_player_backend.dart';
import 'package:syncy/utils/platform_utils.dart';

/// Builds a playback backend for a local [file], appropriate for the platform.
///
/// Only desktop constructs a media_kit [Player], which matters: the libmpv
/// native libraries are bundled for Windows only, so the media_kit code path
/// must never be entered on Android or iOS.
SyncPlayer createSyncPlayer(File file) {
  return isDesktop
      ? MediaKitBackend(file.path)
      : VideoPlayerBackend(file);
}

/// Builds a playback backend that streams from an `http(s)` [url] — used for
/// media hosted by a paired PC on the LAN, which the phone never has locally.
SyncPlayer createSyncPlayerFromUrl(String url) {
  return isDesktop
      ? MediaKitBackend.network(url)
      : VideoPlayerBackend.network(url);
}
