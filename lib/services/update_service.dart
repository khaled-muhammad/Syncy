import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const updateProtocolVersion = 1;
const updateManifestAssetName = 'syncy-update-v1.json';

enum UpdateTarget { android, windows }

enum UpdateInstallOutcome {
  launched,
  permissionRequested,
  browserOpened,
  cancelled,
  failed,
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    this.sha256,
  });

  final String name;
  final Uri downloadUrl;
  final int size;
  final String? sha256;

  bool get hasTrustedDigest =>
      sha256 != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256!);
}

class ReleaseUpdate {
  const ReleaseUpdate({
    required this.version,
    required this.releaseName,
    required this.notes,
    required this.releasePage,
    required this.asset,
    required this.protocolVerified,
  });

  final String version;
  final String releaseName;
  final String notes;
  final Uri releasePage;
  final ReleaseAsset asset;
  final bool protocolVerified;

  Uri get downloadUrl => asset.downloadUrl;
  bool get canInstallDirectly => protocolVerified && asset.hasTrustedDigest;
}

class UpdateProtocolException implements Exception {
  const UpdateProtocolException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateService extends GetxService {
  UpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  static const _latestReleaseApi =
      'https://api.github.com/repos/khaled-muhammad/Syncy/releases/latest';
  static const _lastCheckKey = 'github_update_last_checked_at';
  static const _updateChannel = MethodChannel('com.example.syncy/update');

  final availableUpdate = Rxn<ReleaseUpdate>();
  final isChecking = false.obs;
  final isUpdating = false.obs;
  final canCancelUpdate = false.obs;
  final downloadProgress = 0.0.obs;
  final currentVersion = '…'.obs;
  final statusMessage = ''.obs;

  late SharedPreferences _preferences;
  late PackageInfo _packageInfo;
  final Dio _dio;
  CancelToken? _downloadCancellation;

  Future<UpdateService> init() async {
    _preferences = await SharedPreferences.getInstance();
    _packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = _packageInfo.version;
    return this;
  }

  UpdateTarget? get target {
    if (Platform.isWindows) return UpdateTarget.windows;
    if (Platform.isAndroid) return UpdateTarget.android;
    return null;
  }

  bool get isEligiblePlatform {
    if (target == UpdateTarget.windows) return true;
    if (target != UpdateTarget.android) return false;
    const appStores = {
      'com.android.vending',
      'com.amazon.venezia',
      'com.sec.android.app.samsungapps',
      'com.huawei.appmarket',
      'com.xiaomi.mipicks',
      'com.oppo.market',
      'com.vivo.appstore',
    };
    return !appStores.contains(_packageInfo.installerStore);
  }

  Future<ReleaseUpdate?> check({bool force = false}) async {
    if (!isEligiblePlatform || isChecking.value) return availableUpdate.value;
    final previous = DateTime.tryParse(
      _preferences.getString(_lastCheckKey) ?? '',
    );
    if (!force &&
        previous != null &&
        DateTime.now().toUtc().difference(previous) <
            const Duration(hours: 12)) {
      return availableUpdate.value;
    }

    isChecking.value = true;
    statusMessage.value = 'Checking for updates…';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _latestReleaseApi,
        options: Options(headers: _githubHeaders),
      );
      await _preferences.setString(
        _lastCheckKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      final release = response.data;
      final tag = release?['tag_name']?.toString() ?? '';
      if (tag.isEmpty || !isVersionNewer(tag, _packageInfo.version)) {
        availableUpdate.value = null;
        statusMessage.value = 'You’re up to date';
        return null;
      }

      final manifestJson = await _fetchManifest(release?['assets']);
      final update = parseReleaseUpdate(
        release,
        manifestJson: manifestJson,
        target: target!,
      );
      availableUpdate.value = update;
      statusMessage.value = update.canInstallDirectly
          ? 'Version ${update.version} is ready to install'
          : 'Version ${update.version} is available on GitHub';
      return update;
    } on UpdateProtocolException catch (error) {
      statusMessage.value = error.message;
      return null;
    } catch (_) {
      statusMessage.value = 'Could not check for updates';
      return null;
    } finally {
      isChecking.value = false;
    }
  }

  Map<String, String> get _githubHeaders => {
    'accept': 'application/vnd.github+json',
    'x-github-api-version': '2022-11-28',
    'user-agent': 'Syncy/${_packageInfo.version}',
  };

  Future<Map<String, dynamic>?> _fetchManifest(dynamic rawAssets) async {
    final manifestUrl = selectNamedReleaseAssetUrl(
      rawAssets,
      updateManifestAssetName,
    );
    if (manifestUrl == null) return null;
    final response = await _dio.get<dynamic>(
      manifestUrl,
      options: Options(headers: _githubHeaders),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    if (data is List<int>) {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const UpdateProtocolException('The update manifest is invalid');
  }

  Future<UpdateInstallOutcome> install(ReleaseUpdate update) async {
    if (isUpdating.value) return UpdateInstallOutcome.failed;
    if (!update.canInstallDirectly || !kReleaseMode) {
      return await openDownload(update)
          ? UpdateInstallOutcome.browserOpened
          : UpdateInstallOutcome.failed;
    }

    isUpdating.value = true;
    canCancelUpdate.value = true;
    downloadProgress.value = 0;
    _downloadCancellation = CancelToken();
    try {
      statusMessage.value = 'Downloading Syncy ${update.version}…';
      var artifact = await _download(update.asset, _downloadCancellation!);
      canCancelUpdate.value = false;
      statusMessage.value = 'Verifying download…';
      try {
        await verifyUpdateArtifact(artifact, update.asset);
      } on UpdateProtocolException {
        if (await artifact.exists()) await artifact.delete();
        rethrow;
      }
      artifact = await _promoteVerifiedArtifact(artifact, update.asset.name);

      if (target == UpdateTarget.android) {
        statusMessage.value = 'Opening Android installer…';
        final response = await _updateChannel.invokeMethod<String>(
          'installApk',
          {'path': artifact.path},
        );
        if (response == 'permission_requested') {
          statusMessage.value = 'Allow installs, then Android will continue';
          return UpdateInstallOutcome.permissionRequested;
        }
        statusMessage.value = 'Complete the update in Android';
        return UpdateInstallOutcome.launched;
      }

      statusMessage.value = 'Preparing Windows update…';
      await _stageAndLaunchWindowsUpdate(artifact, update.version);
      return UpdateInstallOutcome.launched;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        statusMessage.value = 'Update cancelled';
        return UpdateInstallOutcome.cancelled;
      }
      statusMessage.value = 'Update download failed';
      return UpdateInstallOutcome.failed;
    } on UpdateProtocolException catch (error) {
      statusMessage.value = error.message;
      return UpdateInstallOutcome.failed;
    } catch (_) {
      statusMessage.value = 'Could not install the update';
      return UpdateInstallOutcome.failed;
    } finally {
      _downloadCancellation = null;
      canCancelUpdate.value = false;
      isUpdating.value = false;
    }
  }

  void cancelInstall() {
    if (canCancelUpdate.value) {
      _downloadCancellation?.cancel('Cancelled by user');
    }
  }

  bool directInstallEnabled(ReleaseUpdate update) =>
      update.canInstallDirectly && kReleaseMode;

  Future<File> _promoteVerifiedArtifact(File partial, String assetName) async {
    final verified = File(
      '${partial.parent.path}${Platform.pathSeparator}$assetName',
    );
    if (await verified.exists()) await verified.delete();
    return partial.rename(verified.path);
  }

  Future<File> _download(ReleaseAsset asset, CancelToken cancellation) async {
    final root = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}syncy-updates',
    );
    await root.create(recursive: true);
    final destination = File(
      '${root.path}${Platform.pathSeparator}${asset.name}.part',
    );
    var existing = await destination.exists() ? await destination.length() : 0;
    if (asset.size > 0 && existing > asset.size) {
      await destination.delete();
      existing = 0;
    }
    if (asset.size > 0 && existing == asset.size) {
      downloadProgress.value = 1;
      return destination;
    }

    Future<dynamic> download({required bool resume}) {
      final offset = resume ? existing : 0;
      return _dio.download(
        asset.downloadUrl.toString(),
        destination.path,
        cancelToken: cancellation,
        deleteOnError: false,
        fileAccessMode: resume ? FileAccessMode.append : FileAccessMode.write,
        options: Options(
          headers: {..._githubHeaders, if (resume) 'range': 'bytes=$offset-'},
        ),
        onReceiveProgress: (received, total) {
          final transferred = offset + received;
          final expected = asset.size > 0
              ? asset.size
              : (total > 0 ? offset + total : 0);
          if (expected > 0) {
            downloadProgress.value = (transferred / expected).clamp(0, 1);
          }
        },
      );
    }

    if (existing > 0) {
      final response = await download(resume: true);
      if (response.statusCode != HttpStatus.partialContent) {
        await destination.delete();
        existing = 0;
        await download(resume: false);
      }
    } else {
      await download(resume: false);
    }
    return destination;
  }

  Future<void> _stageAndLaunchWindowsUpdate(
    File archive,
    String version,
  ) async {
    final executable = File(Platform.resolvedExecutable);
    final target = executable.parent;
    if (!await executable.exists() || target.path == target.parent.path) {
      throw const UpdateProtocolException('Unsafe Windows install location');
    }

    final tempRoot = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final staging = Directory(
      '${tempRoot.path}${Platform.pathSeparator}syncy-stage-$stamp',
    );
    await staging.create(recursive: true);
    await extractFileToDisk(archive.path, staging.path);

    final stagedExe = File(
      '${staging.path}${Platform.pathSeparator}${executable.uri.pathSegments.last}',
    );
    final stagedAssets = Directory(
      '${staging.path}${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets',
    );
    if (!await stagedExe.exists() || !await stagedAssets.exists()) {
      throw const UpdateProtocolException(
        'The Windows update package is incomplete',
      );
    }

    final script = File(
      '${tempRoot.path}${Platform.pathSeparator}syncy-update-$stamp.ps1',
    );
    final backup = '${target.path}.syncy-backup-$stamp';
    final failed = '${target.path}.syncy-failed-$stamp';
    await script.writeAsString(
      windowsUpdateScript(
        processId: pid,
        sourcePath: staging.path,
        targetPath: target.path,
        backupPath: backup,
        failedPath: failed,
        executableName: executable.uri.pathSegments.last,
        archivePath: archive.path,
        version: version,
      ),
      flush: true,
    );

    await Process.start('powershell.exe', [
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
    ], mode: ProcessStartMode.detached);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    exit(0);
  }

  Future<bool> openDownload(ReleaseUpdate update) {
    return launchUrl(
      update.asset.downloadUrl,
      mode: LaunchMode.externalApplication,
    );
  }
}

ReleaseUpdate parseReleaseUpdate(
  Map<String, dynamic>? release, {
  required Map<String, dynamic>? manifestJson,
  required UpdateTarget target,
}) {
  if (release == null) {
    throw const UpdateProtocolException('The release response is empty');
  }
  final tag = release['tag_name']?.toString() ?? '';
  final version = normalizeVersion(tag);
  final releasePage = Uri.tryParse(release['html_url']?.toString() ?? '');
  if (version.isEmpty || releasePage == null || !releasePage.hasScheme) {
    throw const UpdateProtocolException('The release metadata is invalid');
  }

  final expectedName = target == UpdateTarget.windows
      ? 'syncy-windows-release.zip'
      : 'app-universal.apk';
  final rawAsset = findNamedReleaseAsset(release['assets'], expectedName);
  if (rawAsset == null) {
    throw UpdateProtocolException(
      target == UpdateTarget.windows
          ? 'This release has no Windows package'
          : 'This release has no Android package',
    );
  }
  final assetUrl = Uri.tryParse(
    rawAsset['browser_download_url']?.toString() ?? '',
  );
  if (assetUrl == null || !assetUrl.hasScheme) {
    throw const UpdateProtocolException('The update download URL is invalid');
  }

  final manifest = parseUpdateManifest(manifestJson, version: version);
  final manifestAsset = manifest?.platforms[target.name];
  final rawSize = (rawAsset['size'] as num?)?.toInt() ?? 0;
  final manifestMatches =
      manifestAsset != null &&
      manifestAsset.name == expectedName &&
      manifestAsset.size == rawSize;
  final digest = manifestMatches ? manifestAsset.sha256 : null;

  return ReleaseUpdate(
    version: version,
    releaseName: release['name']?.toString().trim().isNotEmpty == true
        ? release['name'].toString()
        : tag,
    notes: release['body']?.toString() ?? '',
    releasePage: releasePage,
    asset: ReleaseAsset(
      name: expectedName,
      downloadUrl: assetUrl,
      size: rawSize,
      sha256: digest,
    ),
    protocolVerified: manifestMatches,
  );
}

class UpdateManifest {
  const UpdateManifest({
    required this.protocol,
    required this.version,
    required this.platforms,
  });

  final int protocol;
  final String version;
  final Map<String, ManifestAsset> platforms;
}

class ManifestAsset {
  const ManifestAsset({
    required this.name,
    required this.sha256,
    required this.size,
  });

  final String name;
  final String sha256;
  final int size;
}

UpdateManifest? parseUpdateManifest(
  Map<String, dynamic>? json, {
  required String version,
}) {
  if (json == null) return null;
  final protocol = (json['protocol'] as num?)?.toInt();
  final manifestVersion = normalizeVersion(json['version']?.toString() ?? '');
  if (protocol != updateProtocolVersion || manifestVersion != version) {
    return null;
  }
  final rawPlatforms = json['platforms'];
  if (rawPlatforms is! Map) return null;
  final platforms = <String, ManifestAsset>{};
  for (final key in const ['android', 'windows']) {
    final raw = rawPlatforms[key];
    if (raw is! Map) continue;
    final sha = normalizeSha256(raw['sha256']?.toString());
    final name = raw['asset']?.toString() ?? '';
    final size = (raw['size'] as num?)?.toInt() ?? 0;
    if (sha != null && name.isNotEmpty && size > 0) {
      platforms[key] = ManifestAsset(name: name, sha256: sha, size: size);
    }
  }
  return UpdateManifest(
    protocol: protocol!,
    version: manifestVersion,
    platforms: platforms,
  );
}

Future<void> verifyUpdateArtifact(File file, ReleaseAsset asset) async {
  if (!asset.hasTrustedDigest) {
    throw const UpdateProtocolException('No trusted checksum was published');
  }
  final length = await file.length();
  if (asset.size > 0 && length != asset.size) {
    throw const UpdateProtocolException('The update download is incomplete');
  }
  final digest = await sha256.bind(file.openRead()).first;
  if (digest.toString().toLowerCase() != asset.sha256) {
    throw const UpdateProtocolException('Update verification failed');
  }
}

String normalizeVersion(String value) {
  return value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
}

String? normalizeSha256(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase().replaceFirst(
    RegExp(r'^sha256:'),
    '',
  );
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized) ? normalized : null;
}

bool isVersionNewer(String candidate, String current) {
  final candidateVersion = _ParsedVersion.parse(candidate);
  final currentVersion = _ParsedVersion.parse(current);
  if (candidateVersion == null || currentVersion == null) return false;
  return candidateVersion.compareTo(currentVersion) > 0;
}

Map<dynamic, dynamic>? findNamedReleaseAsset(dynamic rawAssets, String name) {
  if (rawAssets is! List) return null;
  final normalizedName = name.toLowerCase();
  for (final asset in rawAssets.whereType<Map>()) {
    if (asset['name']?.toString().toLowerCase() == normalizedName) return asset;
  }
  return null;
}

String? selectNamedReleaseAssetUrl(dynamic rawAssets, String name) =>
    findNamedReleaseAsset(rawAssets, name)?['browser_download_url']?.toString();

String? selectReleaseAssetUrl(dynamic rawAssets, {required bool windows}) =>
    selectNamedReleaseAssetUrl(
      rawAssets,
      windows ? 'syncy-windows-release.zip' : 'app-universal.apk',
    );

String windowsUpdateScript({
  required int processId,
  required String sourcePath,
  required String targetPath,
  required String backupPath,
  required String failedPath,
  required String executableName,
  required String archivePath,
  required String version,
}) {
  String quote(String value) => "'${value.replaceAll("'", "''")}'";
  return '''
\$ErrorActionPreference = 'Stop'
\$source = ${quote(sourcePath)}
\$target = ${quote(targetPath)}
\$backup = ${quote(backupPath)}
\$failed = ${quote(failedPath)}
\$exeName = ${quote(executableName)}
\$archive = ${quote(archivePath)}
\$version = ${quote(version)}

try {
  Wait-Process -Id $processId -ErrorAction SilentlyContinue
  if (-not (Test-Path -LiteralPath (Join-Path \$source \$exeName) -PathType Leaf)) {
    throw 'Staged executable is missing.'
  }
  Move-Item -LiteralPath \$target -Destination \$backup
  Move-Item -LiteralPath \$source -Destination \$target
  \$newExe = Join-Path \$target \$exeName
  \$newProcess = Start-Process -FilePath \$newExe -PassThru
  Start-Sleep -Seconds 5
  if (\$newProcess.HasExited) { throw "Syncy \$version exited during startup." }
  Remove-Item -LiteralPath \$backup -Recurse -Force
  Remove-Item -LiteralPath \$archive -Force -ErrorAction SilentlyContinue
} catch {
  if (Test-Path -LiteralPath \$target) {
    Move-Item -LiteralPath \$target -Destination \$failed -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath \$backup) {
    Move-Item -LiteralPath \$backup -Destination \$target
    Start-Process -FilePath (Join-Path \$target \$exeName)
  }
}
Remove-Item -LiteralPath \$MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
''';
}

class _ParsedVersion implements Comparable<_ParsedVersion> {
  const _ParsedVersion(this.parts, this.prerelease);

  final List<int> parts;
  final List<String>? prerelease;

  static _ParsedVersion? parse(String value) {
    final normalized = normalizeVersion(value);
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?$',
    ).firstMatch(normalized);
    if (match == null) return null;
    final prereleaseValue = match.group(4);
    final prerelease = prereleaseValue?.split('.');
    if (prerelease?.any((item) => item.isEmpty) == true) return null;
    return _ParsedVersion([
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ], prerelease);
  }

  @override
  int compareTo(_ParsedVersion other) {
    for (var index = 0; index < 3; index++) {
      final comparison = parts[index].compareTo(other.parts[index]);
      if (comparison != 0) return comparison;
    }
    if (prerelease == null && other.prerelease == null) return 0;
    if (prerelease == null) return 1;
    if (other.prerelease == null) return -1;
    final limit = prerelease!.length < other.prerelease!.length
        ? prerelease!.length
        : other.prerelease!.length;
    for (var index = 0; index < limit; index++) {
      final left = prerelease![index];
      final right = other.prerelease![index];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      int comparison;
      if (leftNumber != null && rightNumber != null) {
        comparison = leftNumber.compareTo(rightNumber);
      } else if (leftNumber != null) {
        comparison = -1;
      } else if (rightNumber != null) {
        comparison = 1;
      } else {
        comparison = left.compareTo(right);
      }
      if (comparison != 0) return comparison;
    }
    return prerelease!.length.compareTo(other.prerelease!.length);
  }
}
