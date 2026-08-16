import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/update_service.dart';

void main() {
  test('compares GitHub release versions semantically', () {
    expect(isVersionNewer('v1.1.0', '1.0.9'), isTrue);
    expect(isVersionNewer('v1.0.3', '1.0.3'), isFalse);
    expect(isVersionNewer('v1.0.2', '1.0.3'), isFalse);
    expect(isVersionNewer('v2.0.0', '1.99.99'), isTrue);
    expect(isVersionNewer('1.1.0-beta.10', '1.1.0-beta.2'), isTrue);
    expect(isVersionNewer('1.1.0-beta.2', '1.1.0-beta.10'), isFalse);
    expect(isVersionNewer('1.1.0', '1.1.0-rc.9'), isTrue);
    expect(isVersionNewer('1.01.0', '1.0.0'), isFalse);
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

  test('accepts an exact platform manifest and checksum', () {
    final update = parseReleaseUpdate(
      releaseJson(size: 123),
      target: UpdateTarget.android,
      manifestJson: manifestJson(androidSize: 123),
    );

    expect(update.version, '1.2.0');
    expect(update.asset.name, 'app-universal.apk');
    expect(update.asset.sha256, repeated('a', 64));
    expect(update.canInstallDirectly, isTrue);
  });

  test('a stale manifest cannot authorize a different artifact', () {
    final release = releaseJson(size: 124);
    (release['assets'] as List).first['digest'] = 'sha256:${repeated('c', 64)}';
    final update = parseReleaseUpdate(
      release,
      target: UpdateTarget.android,
      manifestJson: manifestJson(androidSize: 123),
    );

    expect(update.canInstallDirectly, isFalse);
    expect(update.asset.sha256, isNull);
  });

  test('rejects a release that omits the current platform', () {
    final release = releaseJson(size: 123);
    (release['assets'] as List).removeAt(0);
    expect(
      () => parseReleaseUpdate(
        release,
        target: UpdateTarget.android,
        manifestJson: manifestJson(androidSize: 123),
      ),
      throwsA(isA<UpdateProtocolException>()),
    );
  });

  test('verifies artifact length and sha256 before install', () async {
    final directory = await Directory.systemTemp.createTemp('syncy-update-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.apk')..writeAsStringSync('syncy');
    final digest = sha256.convert(file.readAsBytesSync()).toString();
    final asset = ReleaseAsset(
      name: 'app-universal.apk',
      downloadUrl: Uri.parse('https://example.test/app.apk'),
      size: 5,
      sha256: digest,
    );

    await expectLater(verifyUpdateArtifact(file, asset), completes);
    await expectLater(
      verifyUpdateArtifact(
        file,
        ReleaseAsset(
          name: asset.name,
          downloadUrl: asset.downloadUrl,
          size: asset.size,
          sha256: repeated('0', 64),
        ),
      ),
      throwsA(isA<UpdateProtocolException>()),
    );
  });

  test('Windows handoff script escapes paths and contains rollback', () {
    final script = windowsUpdateScript(
      processId: 42,
      sourcePath: r"C:\Temp\Khaled's update",
      targetPath: r'C:\Apps\Syncy',
      backupPath: r'C:\Apps\Syncy.backup',
      failedPath: r'C:\Apps\Syncy.failed',
      executableName: 'syncy.exe',
      archivePath: r'C:\Temp\syncy.zip',
      version: '1.2.0',
    );

    expect(script, contains(r"C:\Temp\Khaled''s update"));
    expect(script, contains('Wait-Process -Id 42'));
    expect(script, contains(r'Move-Item -LiteralPath $backup'));
    expect(script, contains(r'Start-Process -FilePath $newExe'));
  });

  test('Windows PowerShell accepts the generated handoff script', () async {
    if (!Platform.isWindows) return;
    final directory = await Directory.systemTemp.createTemp('syncy-script-');
    addTearDown(() => directory.delete(recursive: true));
    final scriptFile = File('${directory.path}/update.ps1');
    await scriptFile.writeAsString(
      windowsUpdateScript(
        processId: 42,
        sourcePath: r'C:\Temp\stage',
        targetPath: r'C:\Apps\Syncy',
        backupPath: r'C:\Apps\Syncy.backup',
        failedPath: r'C:\Apps\Syncy.failed',
        executableName: 'syncy.exe',
        archivePath: r'C:\Temp\syncy.zip',
        version: '1.2.0',
      ),
    );

    final escapedPath = scriptFile.path.replaceAll("'", "''");
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "[void][scriptblock]::Create((Get-Content -Raw -LiteralPath '$escapedPath'))",
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  });
}

Map<String, dynamic> releaseJson({required int size}) => {
  'tag_name': 'v1.2.0',
  'name': 'Syncy 1.2.0',
  'body': 'Safer updates',
  'html_url': 'https://example.test/releases/v1.2.0',
  'assets': [
    {
      'name': 'app-universal.apk',
      'size': size,
      'browser_download_url': 'https://example.test/app.apk',
    },
    {
      'name': 'syncy-windows-release.zip',
      'size': 456,
      'browser_download_url': 'https://example.test/app.zip',
    },
  ],
};

Map<String, dynamic> manifestJson({required int androidSize}) => {
  'protocol': 1,
  'version': '1.2.0',
  'platforms': {
    'android': {
      'asset': 'app-universal.apk',
      'size': androidSize,
      'sha256': repeated('a', 64),
    },
    'windows': {
      'asset': 'syncy-windows-release.zip',
      'size': 456,
      'sha256': repeated('b', 64),
    },
  },
};

String repeated(String value, int count) => List.filled(count, value).join();
