import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/controllers/lan_controller.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/models/remote_media.dart';

void main() {
  const pc = LanDevice(
    deviceId: 'pc-1',
    name: 'Living room PC',
    host: '192.168.1.8',
    port: 8770,
    token: 'paired',
  );

  RemoteLibrary library(int mediaId) => RemoteLibrary(
    roots: const [RemoteLibraryRoot(id: '1', name: 'Movies')],
    media: [
      RemoteMedia(
        id: mediaId,
        name: 'Movie $mediaId.mkv',
        rootId: '1',
        rootName: 'Movies',
      ),
    ],
  );

  test('a newer refresh cancels and supersedes a stale library load', () async {
    final first = Completer<RemoteLibrary>();
    final second = Completer<RemoteLibrary>();
    CancelToken? firstToken;
    var callCount = 0;

    Future<RemoteLibrary> loader(LanDevice _, {CancelToken? cancelToken}) {
      callCount++;
      if (callCount == 1) {
        firstToken = cancelToken;
        return first.future;
      }
      return second.future;
    }

    final controller = LanController(libraryLoader: loader)..onInit();
    addTearDown(controller.onClose);

    final staleLoad = controller.openLibrary(pc);
    expect(controller.isInitialLibraryLoad, isTrue);

    final latestLoad = controller.openLibrary(pc);
    expect(firstToken?.isCancelled, isTrue);
    expect(controller.isInitialLibraryLoad, isTrue);

    second.complete(library(2));
    await latestLoad;
    expect(controller.libraryLoadState.value, LanLibraryLoadState.loaded);
    expect(controller.remoteLibrary.single.id, 2);

    // A slow response from the cancelled request must not overwrite the latest
    // library or put the UI back into a stale loading state.
    first.complete(library(1));
    await staleLoad;
    expect(controller.libraryLoadState.value, LanLibraryLoadState.loaded);
    expect(controller.remoteLibrary.single.id, 2);
  });

  test('refresh preserves visible media while the replacement loads', () async {
    final refresh = Completer<RemoteLibrary>();
    var callCount = 0;

    Future<RemoteLibrary> loader(LanDevice _, {CancelToken? cancelToken}) {
      callCount++;
      return callCount == 1 ? Future.value(library(1)) : refresh.future;
    }

    final controller = LanController(libraryLoader: loader)..onInit();
    addTearDown(controller.onClose);
    await controller.openLibrary(pc);

    final refreshing = controller.openLibrary(pc);
    expect(controller.isRefreshingLibrary, isTrue);
    expect(controller.remoteLibrary.single.id, 1);

    refresh.complete(library(2));
    await refreshing;
    expect(controller.isRefreshingLibrary, isFalse);
    expect(controller.remoteLibrary.single.id, 2);
  });

  test('direct playback resolves a stream without creating a room', () async {
    LanDevice? requestedPc;
    RemoteMedia? requestedMedia;
    final controller = LanController(
      libraryLoader: (pc, {cancelToken}) => Future.value(library(7)),
      streamUrlLoader: (pc, media) async {
        requestedPc = pc;
        requestedMedia = media;
        return 'http://${pc.host}:${pc.port}/media/${media.id}?t=scoped';
      },
    )..onInit();
    addTearDown(controller.onClose);

    await controller.openLibrary(pc);
    final media = controller.remoteLibrary.single;
    final url = await controller.streamUrlForRemote(media);

    expect(requestedPc, pc);
    expect(requestedMedia, media);
    expect(url, 'http://192.168.1.8:8770/media/7?t=scoped');
  });
}
