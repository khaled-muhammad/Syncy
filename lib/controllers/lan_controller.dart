import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/services/lan/lan_client_service.dart';
import 'package:syncy/services/lan/pairing_store.dart';

enum LanLibraryLoadState { idle, loading, refreshing, loaded, error }

typedef RemoteLibraryLoader =
    Future<RemoteLibrary> Function(LanDevice pc, {CancelToken? cancelToken});
typedef RemoteStreamUrlLoader =
    Future<String> Function(LanDevice pc, RemoteMedia media);

/// Phone-side state for connecting to and browsing a PC on the LAN.
class LanController extends GetxController {
  LanController({
    RemoteLibraryLoader? libraryLoader,
    RemoteStreamUrlLoader? streamUrlLoader,
  }) : _libraryLoader = libraryLoader,
       _streamUrlLoader = streamUrlLoader;

  LanClientService? _client;
  final RemoteLibraryLoader? _libraryLoader;
  final RemoteStreamUrlLoader? _streamUrlLoader;

  final devices = <LanDevice>[].obs;
  final isScanning = false.obs;
  final ready = false.obs;

  final selectedPc = Rxn<LanDevice>();
  final remoteLibrary = <RemoteMedia>[].obs;
  final remoteRoots = <RemoteLibraryRoot>[].obs;
  final currentDirectory = ''.obs;
  final librarySearchQuery = ''.obs;
  final libraryLoadState = LanLibraryLoadState.idle.obs;
  final libraryError = RxnString();

  final Completer<void> _clientReady = Completer<void>();
  CancelToken? _libraryCancelToken;
  Object? _clientInitializationError;
  int _libraryRequestId = 0;

  bool get isInitialLibraryLoad =>
      libraryLoadState.value == LanLibraryLoadState.loading;

  bool get isRefreshingLibrary =>
      libraryLoadState.value == LanLibraryLoadState.refreshing;

  RemoteLibrary get _librarySnapshot => RemoteLibrary(
    roots: remoteRoots.toList(growable: false),
    media: remoteLibrary.toList(growable: false),
  );

  List<RemoteDirectory> get childDirectories =>
      librarySearchQuery.value.trim().isNotEmpty
      ? const []
      : _librarySnapshot.childDirectories(currentDirectory.value);

  List<RemoteMedia> get visibleRemoteMedia => _librarySnapshot.visibleMedia(
    currentDirectory.value,
    searchQuery: librarySearchQuery.value,
  );

  List<RemoteBreadcrumb> get libraryBreadcrumbs =>
      _librarySnapshot.breadcrumbs(currentDirectory.value);

  bool get isSearching => librarySearchQuery.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    if (_libraryLoader != null) {
      ready.value = true;
      _clientReady.complete();
    } else {
      unawaited(_init());
    }
  }

  Future<void> _init() async {
    try {
      final store = await PairingStore.open();
      _client = LanClientService(store);
    } catch (error) {
      _clientInitializationError = error;
    } finally {
      ready.value = true;
      if (!_clientReady.isCompleted) _clientReady.complete();
    }
    if (_client != null) await refresh();
  }

  /// Discovers PCs on the network and merges them with previously-paired ones.
  @override
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
    final requestId = ++_libraryRequestId;
    _libraryCancelToken?.cancel('A newer library load started');
    final cancelToken = CancelToken();
    _libraryCancelToken = cancelToken;

    final samePc = selectedPc.value?.deviceId == pc.deviceId;
    final keepCurrentLibrary = samePc && remoteLibrary.isNotEmpty;
    selectedPc.value = pc;
    if (!keepCurrentLibrary) {
      remoteLibrary.clear();
      remoteRoots.clear();
      currentDirectory.value = '';
      librarySearchQuery.value = '';
    }
    libraryError.value = null;
    libraryLoadState.value = keepCurrentLibrary
        ? LanLibraryLoadState.refreshing
        : LanLibraryLoadState.loading;

    try {
      final RemoteLibrary library;
      final injectedLoader = _libraryLoader;
      if (injectedLoader != null) {
        library = await injectedLoader(pc, cancelToken: cancelToken);
      } else {
        await _clientReady.future;
        if (requestId != _libraryRequestId) return;
        final client = _client;
        if (client == null) {
          throw StateError(
            'LAN client unavailable: $_clientInitializationError',
          );
        }
        library = await client.fetchLibrary(pc, cancelToken: cancelToken);
      }
      if (requestId != _libraryRequestId) return;
      remoteRoots.assignAll(library.roots);
      remoteLibrary.assignAll(library.media);
      libraryLoadState.value = LanLibraryLoadState.loaded;
    } on LanUnauthorized {
      if (requestId != _libraryRequestId) return;
      libraryError.value = 'This PC no longer trusts this phone. Pair again.';
      libraryLoadState.value = LanLibraryLoadState.error;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || requestId != _libraryRequestId) return;
      _finishLibraryLoadWithNetworkError(keepCurrentLibrary);
    } catch (_) {
      if (requestId != _libraryRequestId) return;
      _finishLibraryLoadWithNetworkError(keepCurrentLibrary);
    }
  }

  void _finishLibraryLoadWithNetworkError(bool keptCurrentLibrary) {
    const message = "Couldn't reach this PC. Check you're on its Wi-Fi.";
    if (keptCurrentLibrary) {
      libraryLoadState.value = LanLibraryLoadState.loaded;
      Get.snackbar('Refresh failed', message, snackPosition: SnackPosition.TOP);
    } else {
      libraryError.value = message;
      libraryLoadState.value = LanLibraryLoadState.error;
    }
  }

  void openDirectory(String key) {
    currentDirectory.value = key;
    librarySearchQuery.value = '';
  }

  void navigateToParentDirectory() {
    currentDirectory.value = parentRemoteDirectory(currentDirectory.value);
  }

  void searchLibrary(String value) {
    librarySearchQuery.value = value;
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

  /// Resolves a short-lived, media-scoped URL for playback on this phone.
  /// This is intentionally independent of rooms: the PC serves the bytes
  /// directly over the LAN and no backend or WebSocket session is created.
  Future<String> streamUrlForRemote(RemoteMedia media) async {
    final pc = selectedPc.value;
    if (pc == null) throw StateError('No PC selected');
    final injectedLoader = _streamUrlLoader;
    if (injectedLoader != null) return injectedLoader(pc, media);
    await _clientReady.future;
    final client = _client;
    if (client == null) {
      throw StateError('LAN client unavailable: $_clientInitializationError');
    }
    return client.streamUrlFor(pc, media);
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
      final url = await streamUrlForRemote(media);
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

  @override
  void onClose() {
    _libraryRequestId++;
    _libraryCancelToken?.cancel('LAN controller closed');
    super.onClose();
  }
}
