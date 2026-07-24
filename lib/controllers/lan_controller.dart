import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/services/lan/lan_client_service.dart';
import 'package:syncy/services/lan/pairing_store.dart';

/// Phone-side state for connecting to and browsing a PC on the LAN.
class LanController extends GetxController {
  LanClientService? _client;

  final devices = <LanDevice>[].obs;
  final isScanning = false.obs;
  final ready = false.obs;

  final selectedPc = Rxn<LanDevice>();
  final remoteLibrary = <RemoteMedia>[].obs;
  final isLoadingLibrary = false.obs;
  final libraryError = RxnString();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final store = await PairingStore.open();
    _client = LanClientService(store);
    ready.value = true;
    await refresh();
  }

  /// Discovers PCs on the network and merges them with previously-paired ones.
  Future<void> refresh() async {
    final client = _client;
    if (client == null) return;
    isScanning.value = true;
    try {
      devices.value = await client.knownAndDiscovered();
    } catch (_) {
      // Discovery is best-effort; leave whatever list we had.
    } finally {
      isScanning.value = false;
    }
  }

  /// Confirms a manually-typed address points at a Syncy host.
  Future<LanDevice?> probe(String host, int port) =>
      _client?.probe(host, port) ?? Future.value(null);

  /// Pairs with [device] using the one-time [code]. Throws [LanUnauthorized]
  /// on a wrong/expired code.
  Future<LanDevice> pair(LanDevice device, String code) async {
    final paired = await _client!.pair(device, code);
    final index = devices.indexWhere((d) => d.deviceId == paired.deviceId);
    if (index == -1) {
      devices.add(paired);
    } else {
      devices[index] = paired;
    }
    return paired;
  }

  Future<void> unpair(LanDevice device) async {
    await _client?.unpair(device.deviceId);
    await refresh();
  }

  /// Loads [pc]'s library into [remoteLibrary].
  Future<void> openLibrary(LanDevice pc) async {
    selectedPc.value = pc;
    remoteLibrary.clear();
    libraryError.value = null;
    isLoadingLibrary.value = true;
    try {
      remoteLibrary.value = await _client!.fetchLibrary(pc);
    } on LanUnauthorized {
      libraryError.value = 'This PC no longer trusts this phone. Pair again.';
    } catch (_) {
      libraryError.value = "Couldn't reach this PC. Check you're on its Wi-Fi.";
    } finally {
      isLoadingLibrary.value = false;
    }
  }

  String? thumbnailUrl(RemoteMedia media) {
    final pc = selectedPc.value;
    if (pc == null || !media.hasThumbnail) return null;
    return _client!.thumbnailUrl(pc, media);
  }

  Map<String, String> authHeader() {
    final pc = selectedPc.value;
    return pc == null ? const {} : _client!.authHeader(pc);
  }

  /// Case A: creates a room whose media is streamed from the PC. Returns an
  /// error message on failure, or null on success (navigation happens in
  /// RoomController).
  Future<String?> createRoomFromRemote(
    RemoteMedia media,
    String roomName,
    RoomMode mode,
  ) async {
    final pc = selectedPc.value;
    if (pc == null) return 'No PC selected';
    try {
      final url = await _client!.streamUrlFor(pc, media);
      await Get.find<RoomController>().createRoom(
        roomName,
        streamUrl: url,
        streamTitle: media.name,
        mode: mode,
      );
      return null;
    } on LanUnauthorized {
      return 'This PC no longer trusts this phone. Pair again.';
    } catch (_) {
      return 'Could not start the stream from this PC.';
    }
  }
}
