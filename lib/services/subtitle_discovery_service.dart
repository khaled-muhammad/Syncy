import 'dart:io';

import 'package:dio/dio.dart';
import 'package:syncy/models/subtitle_track.dart';

const _subtitleExtensions = {'srt', 'vtt'};

const _languageNames = <String, String>{
  'ar': 'Arabic',
  'ara': 'Arabic',
  'de': 'German',
  'deu': 'German',
  'ger': 'German',
  'en': 'English',
  'eng': 'English',
  'es': 'Spanish',
  'spa': 'Spanish',
  'fr': 'French',
  'fra': 'French',
  'fre': 'French',
  'hi': 'Hindi',
  'hin': 'Hindi',
  'it': 'Italian',
  'ita': 'Italian',
  'ja': 'Japanese',
  'jpn': 'Japanese',
  'ko': 'Korean',
  'kor': 'Korean',
  'pt': 'Portuguese',
  'por': 'Portuguese',
  'ru': 'Russian',
  'rus': 'Russian',
  'tr': 'Turkish',
  'tur': 'Turkish',
  'zh': 'Chinese',
  'zho': 'Chinese',
  'chi': 'Chinese',
};

class SubtitleDiscoveryService {
  SubtitleDiscoveryService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 6),
            ),
          );

  final Dio _dio;

  Future<List<SubtitleTrack>> discover(String mediaSource) async {
    final uri = Uri.tryParse(mediaSource);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _discoverRemote(uri);
    }
    return discoverLocalSubtitlesSync(mediaSource);
  }

  Future<List<SubtitleTrack>> _discoverRemote(Uri mediaUri) async {
    try {
      final listUri = remoteSubtitleListUri(mediaUri);
      final response = await _dio.getUri<dynamic>(listUri);
      final body = response.data;
      final values = body is Map ? body['subtitles'] : null;
      if (values is! List) return const [];

      return values
          .whereType<Map>()
          .map((raw) {
            final json = Map<String, dynamic>.from(raw);
            final index = (json['index'] as num?)?.toInt();
            final track = SubtitleTrack.fromJson(json);
            if (index == null) return track;
            final extension = track.fileName.split('.').last.toLowerCase();
            final source = remoteSubtitleTrackUri(
              mediaUri,
              index: index,
              extension: extension,
            );
            return track.copyWith(source: source.toString());
          })
          .where((track) => track.source.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

/// Builds LAN subtitle endpoints without dropping the media-scoped stream
/// token. Losing `?t=...` would make automatic subtitle loading fail with 401
/// on every phone except the one holding the full pairing credential.
Uri remoteSubtitleListUri(Uri mediaUri) =>
    mediaUri.replace(path: '${mediaUri.path}/subtitles');

Uri remoteSubtitleTrackUri(
  Uri mediaUri, {
  required int index,
  required String extension,
}) => mediaUri.replace(
  path: '${mediaUri.path}/subtitles/$index',
  queryParameters: {
    ...mediaUri.queryParameters,
    'format': extension.toLowerCase(),
  },
);

List<SubtitleTrack> discoverLocalSubtitlesSync(String videoPath) {
  final normalized = videoPath.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  final directoryPath = slash < 0 ? '.' : normalized.substring(0, slash);
  final videoFileName = slash < 0
      ? normalized
      : normalized.substring(slash + 1);
  final videoStem = _stem(videoFileName);
  if (videoStem.isEmpty) return const [];

  final directory = Directory(directoryPath);
  if (!directory.existsSync()) return const [];

  final tracks = <SubtitleTrack>[];
  try {
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final fileName = entity.path.replaceAll('\\', '/').split('/').last;
      final extension = _extension(fileName);
      if (!_subtitleExtensions.contains(extension)) continue;

      final subtitleStem = _stem(fileName);
      if (!_matchesVideoStem(videoStem, subtitleStem)) continue;
      tracks.add(_trackForFile(entity.path, fileName, videoStem, subtitleStem));
    }
  } on FileSystemException {
    return const [];
  }

  tracks.sort((a, b) {
    if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
  return tracks;
}

bool hasMatchingSubtitleSync(String videoPath) =>
    discoverLocalSubtitlesSync(videoPath).isNotEmpty;

/// Asynchronously finds videos with matching sidecar subtitles while listing
/// each parent directory only once.
///
/// Android can grant access to individual media files without allowing every
/// parent directory to be enumerated. Those directories are skipped because
/// subtitle badges are optional and must never prevent the video library from
/// loading.
Future<Set<String>> findVideoPathsWithMatchingSubtitles(
  List<String> videoPaths,
) async {
  final videosByDirectory = _groupVideoCandidatesByDirectory(videoPaths);
  final matches = <String>{};

  for (final entry in videosByDirectory.entries) {
    final subtitleStems = <String>[];
    try {
      await for (final entity in Directory(
        entry.key,
      ).list(followLinks: false)) {
        if (entity is! File) continue;
        final fileName = entity.path.replaceAll('\\', '/').split('/').last;
        if (!_subtitleExtensions.contains(_extension(fileName))) continue;
        subtitleStems.add(_stem(fileName));
      }
    } on FileSystemException {
      continue;
    }

    _addMatchingVideoPaths(matches, entry.value, subtitleStems);
    await Future<void>.delayed(Duration.zero);
  }
  return matches;
}

/// Finds every video that has a matching sidecar subtitle while listing each
/// parent directory only once.
///
/// A mobile library can contain thousands of videos in the same camera or
/// messaging folder. Calling [hasMatchingSubtitleSync] for each video turns
/// that into an O(videos * directory entries) scan on the caller's isolate.
/// This batched form keeps the work linear and is safe to run in a background
/// isolate.
Set<String> findVideoPathsWithMatchingSubtitlesSync(List<String> videoPaths) {
  final videosByDirectory = _groupVideoCandidatesByDirectory(videoPaths);
  final matches = <String>{};

  for (final entry in videosByDirectory.entries) {
    final directory = Directory(entry.key);
    if (!directory.existsSync()) continue;

    final subtitleStems = <String>[];
    try {
      for (final entity in directory.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final fileName = entity.path.replaceAll('\\', '/').split('/').last;
        if (!_subtitleExtensions.contains(_extension(fileName))) continue;
        subtitleStems.add(_stem(fileName));
      }
    } on FileSystemException {
      continue;
    }

    _addMatchingVideoPaths(matches, entry.value, subtitleStems);
  }
  return matches;
}

Map<String, List<_LocalVideoCandidate>> _groupVideoCandidatesByDirectory(
  List<String> videoPaths,
) {
  final videosByDirectory = <String, List<_LocalVideoCandidate>>{};
  for (final videoPath in videoPaths) {
    final normalized = videoPath.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    final directoryPath = slash < 0 ? '.' : normalized.substring(0, slash);
    final fileName = slash < 0 ? normalized : normalized.substring(slash + 1);
    final stem = _stem(fileName);
    if (stem.isEmpty) continue;
    videosByDirectory
        .putIfAbsent(directoryPath, () => <_LocalVideoCandidate>[])
        .add(_LocalVideoCandidate(videoPath, stem));
  }

  return videosByDirectory;
}

void _addMatchingVideoPaths(
  Set<String> matches,
  List<_LocalVideoCandidate> videos,
  List<String> subtitleStems,
) {
  if (subtitleStems.isEmpty) return;
  for (final video in videos) {
    if (subtitleStems.any(
      (subtitleStem) => _matchesVideoStem(video.stem, subtitleStem),
    )) {
      matches.add(video.path);
    }
  }
}

class _LocalVideoCandidate {
  const _LocalVideoCandidate(this.path, this.stem);

  final String path;
  final String stem;
}

bool _matchesVideoStem(String videoStem, String subtitleStem) {
  final video = videoStem.toLowerCase();
  final subtitle = subtitleStem.toLowerCase();
  if (subtitle == video) return true;
  if (!subtitle.startsWith(video) || subtitle.length == video.length) {
    return false;
  }
  return const {'.', '-', '_', ' '}.contains(subtitle[video.length]);
}

SubtitleTrack _trackForFile(
  String path,
  String fileName,
  String videoStem,
  String subtitleStem,
) {
  final suffix = subtitleStem
      .substring(videoStem.length)
      .replaceFirst(RegExp(r'^[._\-\s]+'), '');
  if (suffix.isEmpty) {
    return SubtitleTrack(
      source: path,
      fileName: fileName,
      languageCode: 'und',
      label: 'Default',
      isDefault: true,
    );
  }

  final parts = suffix
      .split(RegExp(r'[._\-\s]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  final code = parts.isEmpty ? 'und' : parts.first.toLowerCase();
  final language = _languageNames[code] ?? _titleCase(parts.first);
  final qualifiers = parts
      .skip(1)
      .map(_titleCase)
      .where((part) => part.isNotEmpty)
      .join(' · ');
  return SubtitleTrack(
    source: path,
    fileName: fileName,
    languageCode: code,
    label: qualifiers.isEmpty ? language : '$language · $qualifiers',
  );
}

String _stem(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}

String _extension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
