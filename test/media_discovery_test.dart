import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/media_discovery_service.dart';

void main() {
  test('complete folder scans may reconcile missing paths', () async {
    final directory = await Directory.systemTemp.createTemp(
      'syncy-media-discovery-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final video = File('${directory.path}${Platform.pathSeparator}movie.mp4');
    await video.writeAsBytes(const [0]);

    final result = await MediaDiscoveryService().scanDirectoryWithResult(
      directory.path,
    );

    expect(result.isComplete, isTrue);
    expect(result.paths, [video.path]);
  });

  test(
    'an unavailable root never authorizes destructive reconciliation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'syncy-missing-media-root-',
      );
      await directory.delete();

      final result = await MediaDiscoveryService().scanDirectoryWithResult(
        directory.path,
      );

      expect(result.paths, isEmpty);
      expect(result.isComplete, isFalse);
    },
  );
}
