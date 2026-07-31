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
  SubtitleDiscoveryService({Dio? dio}) : _dio = dio ?? Dio();

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
      final listUri = mediaUri.replace(path: '${mediaUri.path}/subtitles');
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
            final source = mediaUri.replace(
              path: '${mediaUri.path}/subtitles/$index',
              queryParameters: {
                ...mediaUri.queryParameters,
                'format': extension,
              },
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
