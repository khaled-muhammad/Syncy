import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseUpdate {
  final String version;
  final String releaseName;
  final String notes;
  final Uri releasePage;
  final Uri downloadUrl;

  const ReleaseUpdate({
    required this.version,
    required this.releaseName,
    required this.notes,
    required this.releasePage,
    required this.downloadUrl,
  });
}

class UpdateService extends GetxService {
  static const _latestReleaseApi =
      'https://api.github.com/repos/khaled-muhammad/Syncy/releases/latest';
  static const _lastCheckKey = 'github_update_last_checked_at';

  final availableUpdate = Rxn<ReleaseUpdate>();
  final isChecking = false.obs;
  final currentVersion = '…'.obs;
  final statusMessage = ''.obs;

  late SharedPreferences _preferences;
  late PackageInfo _packageInfo;
  final Dio _dio = Dio();

  Future<UpdateService> init() async {
    _preferences = await SharedPreferences.getInstance();
    _packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = _packageInfo.version;
    return this;
  }

  bool get isEligiblePlatform {
    if (Platform.isWindows) return true;
    if (!Platform.isAndroid) return false;
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
    statusMessage.value = 'Checking GitHub…';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _latestReleaseApi,
        options: Options(
          headers: {
            'accept': 'application/vnd.github+json',
            'x-github-api-version': '2022-11-28',
            'user-agent': 'Syncy/${_packageInfo.version}',
          },
        ),
      );
      await _preferences.setString(
        _lastCheckKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      final json = response.data;
      final tag = json?['tag_name']?.toString() ?? '';
      if (tag.isEmpty || !isVersionNewer(tag, _packageInfo.version)) {
        availableUpdate.value = null;
        statusMessage.value = 'You’re up to date';
        return null;
      }

      final releasePage = Uri.tryParse(json?['html_url']?.toString() ?? '');
      if (releasePage == null) throw const FormatException('Invalid release');
      final assetUrl = selectReleaseAssetUrl(
        json?['assets'],
        windows: Platform.isWindows,
      );
      final update = ReleaseUpdate(
        version: normalizeVersion(tag),
        releaseName: json?['name']?.toString().trim().isNotEmpty == true
            ? json!['name'].toString()
            : tag,
        notes: json?['body']?.toString() ?? '',
        releasePage: releasePage,
        downloadUrl: Uri.tryParse(assetUrl ?? '') ?? releasePage,
      );
      availableUpdate.value = update;
      statusMessage.value = 'Version ${update.version} is available';
      return update;
    } catch (_) {
      statusMessage.value = 'Could not check for updates';
      return null;
    } finally {
      isChecking.value = false;
    }
  }

  Future<bool> openDownload(ReleaseUpdate update) {
    return launchUrl(update.downloadUrl, mode: LaunchMode.externalApplication);
  }
}

String normalizeVersion(String value) {
  return value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
}

bool isVersionNewer(String candidate, String current) {
  final candidateVersion = _ParsedVersion.parse(candidate);
  final currentVersion = _ParsedVersion.parse(current);
  if (candidateVersion == null || currentVersion == null) return false;
  for (var index = 0; index < 3; index++) {
    final comparison = candidateVersion.parts[index].compareTo(
      currentVersion.parts[index],
    );
    if (comparison != 0) return comparison > 0;
  }
  if (candidateVersion.prerelease == currentVersion.prerelease) return false;
  if (candidateVersion.prerelease == null) return true;
  if (currentVersion.prerelease == null) return false;
  return candidateVersion.prerelease!.compareTo(currentVersion.prerelease!) > 0;
}

String? selectReleaseAssetUrl(dynamic rawAssets, {required bool windows}) {
  if (rawAssets is! List) return null;
  final preferredName = windows
      ? 'syncy-windows-release.zip'
      : 'app-universal.apk';
  for (final raw in rawAssets.whereType<Map>()) {
    if (raw['name']?.toString().toLowerCase() == preferredName) {
      return raw['browser_download_url']?.toString();
    }
  }
  return null;
}

class _ParsedVersion {
  final List<int> parts;
  final String? prerelease;

  const _ParsedVersion(this.parts, this.prerelease);

  static _ParsedVersion? parse(String value) {
    final normalized = normalizeVersion(value);
    final separator = normalized.indexOf('-');
    final numericPart = separator < 0
        ? normalized
        : normalized.substring(0, separator);
    final prerelease = separator < 0
        ? null
        : normalized.substring(separator + 1);
    final numeric = numericPart.split('.');
    if (numeric.isEmpty || numeric.length > 3) return null;
    final parts = <int>[];
    for (final item in numeric) {
      final parsed = int.tryParse(item);
      if (parsed == null) return null;
      parts.add(parsed);
    }
    while (parts.length < 3) {
      parts.add(0);
    }
    return _ParsedVersion(parts, prerelease);
  }
}
