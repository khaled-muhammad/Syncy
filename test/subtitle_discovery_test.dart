import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/subtitle_discovery_service.dart';

void main() {
  test('LAN subtitle URLs preserve scoped stream authorization', () {
    final media = Uri.parse('http://192.168.1.8:8770/media/42?t=secret-token');

    expect(
      remoteSubtitleListUri(media).toString(),
      'http://192.168.1.8:8770/media/42/subtitles?t=secret-token',
    );
    expect(
      remoteSubtitleTrackUri(media, index: 1, extension: 'SRT').toString(),
      'http://192.168.1.8:8770/media/42/subtitles/1?t=secret-token&format=srt',
    );
  });

  test('discovers matching SRT and VTT language variants', () async {
    final directory = await Directory.systemTemp.createTemp('syncy-subtitles-');
    addTearDown(() => directory.delete(recursive: true));

    final video = File('${directory.path}${Platform.pathSeparator}Movie.mkv');
    await video.writeAsBytes(const [0]);
    await File(
      '${directory.path}${Platform.pathSeparator}Movie.en.srt',
    ).writeAsString('1\n00:00:00,000 --> 00:00:01,000\nHello\n');
    await File(
      '${directory.path}${Platform.pathSeparator}Movie.tr.vtt',
    ).writeAsString('WEBVTT\n\n00:00.000 --> 00:01.000\nMerhaba\n');
    await File(
      '${directory.path}${Platform.pathSeparator}Different.en.srt',
    ).writeAsString('unrelated');

    final tracks = discoverLocalSubtitlesSync(video.path);

    expect(tracks, hasLength(2));
    expect(
      tracks.map((track) => track.label),
      containsAll(['English', 'Turkish']),
    );
    expect(hasMatchingSubtitleSync(video.path), isTrue);
  });

  test('batch discovery matches videos across shared directories', () async {
    final directory = await Directory.systemTemp.createTemp(
      'syncy-subtitle-batch-',
    );
    addTearDown(() => directory.delete(recursive: true));

    String path(String name) =>
        '${directory.path}${Platform.pathSeparator}$name';
    final firstVideo = File(path('First Movie.mp4'));
    final secondVideo = File(path('Second Movie.mkv'));
    final thirdVideo = File(path('No Subtitles.webm'));
    await Future.wait([
      firstVideo.writeAsBytes(const [0]),
      secondVideo.writeAsBytes(const [0]),
      thirdVideo.writeAsBytes(const [0]),
      File(path('First Movie.en.srt')).writeAsString('subtitle'),
      File(path('Second Movie.vtt')).writeAsString('subtitle'),
      File(path('Unrelated.srt')).writeAsString('subtitle'),
    ]);

    final matches = await findVideoPathsWithMatchingSubtitles([
      firstVideo.path,
      secondVideo.path,
      thirdVideo.path,
    ]);

    expect(matches, {firstVideo.path, secondVideo.path});
  });
}
