import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:syncy/utils/room_reference.dart';

class RoomLinkService extends GetxService {
  final pendingRoomReference = RxnString();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<RoomLinkService> init() async {
    // Instantiate this before runApp so the cold-start URI is not lost.
    _appLinks = AppLinks();
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {
        // An invalid operating-system activation should not interrupt startup.
      },
    );
    return this;
  }

  void _handleUri(Uri uri) {
    final reference = roomReferenceFromUri(uri);
    if (reference != null) pendingRoomReference.value = reference;
  }

  void consume(String reference) {
    if (pendingRoomReference.value == reference) {
      pendingRoomReference.value = null;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
