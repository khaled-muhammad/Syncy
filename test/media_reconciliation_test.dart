import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/media_reconciliation_service.dart';

void main() {
  test('finds additions and deletions in one reconciliation', () {
    final diff = calculateMediaPathDiff(
      knownPaths: const ['/media/kept.mp4', '/media/deleted.mkv'],
      discoveredPaths: const ['/media/kept.mp4', '/media/new.webm'],
    );

    expect(diff.addedPaths, ['/media/new.webm']);
    expect(diff.removedPaths, ['/media/deleted.mkv']);
  });

  test('deduplicates discovery and supports Windows path normalization', () {
    String windowsPath(String path) => path.replaceAll('\\', '/').toLowerCase();

    final diff = calculateMediaPathDiff(
      knownPaths: const [r'D:\Movies\Kept.mp4'],
      discoveredPaths: const [
        'd:/movies/kept.mp4',
        r'D:\MOVIES\KEPT.MP4',
        r'D:\Movies\New.mkv',
        'd:/movies/new.mkv',
      ],
      normalizePath: windowsPath,
    );

    expect(diff.addedPaths, [r'D:\Movies\New.mkv']);
    expect(diff.removedPaths, isEmpty);
  });
}
