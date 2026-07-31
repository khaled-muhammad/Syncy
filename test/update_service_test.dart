import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/update_service.dart';

void main() {
  test('compares GitHub release versions semantically', () {
    expect(isVersionNewer('v1.1.0', '1.0.9'), isTrue);
    expect(isVersionNewer('v1.0.3', '1.0.3'), isFalse);
    expect(isVersionNewer('v1.0.2', '1.0.3'), isFalse);
    expect(isVersionNewer('v2.0.0', '1.99.99'), isTrue);
  });

  test('selects the platform release asset', () {
    final assets = [
      {
        'name': 'app-universal.apk',
        'browser_download_url': 'https://example.test/app.apk',
      },
      {
        'name': 'syncy-windows-release.zip',
        'browser_download_url': 'https://example.test/app.zip',
      },
    ];
    expect(
      selectReleaseAssetUrl(assets, windows: false),
      'https://example.test/app.apk',
    );
    expect(
      selectReleaseAssetUrl(assets, windows: true),
      'https://example.test/app.zip',
    );
  });
}
