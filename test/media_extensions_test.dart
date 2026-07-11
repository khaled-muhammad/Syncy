import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/utils/files.dart';

void main() {
  test('recognizes extended video containers case-insensitively', () {
    for (final extension in [
      'mp4',
      'm4v',
      'mkv',
      '3gp',
      'm2ts',
      'mpeg',
      'vob',
      'ogv',
      'flv',
      'wmv',
      'rmvb',
    ]) {
      expect(videoExtensions, contains(extension));
      expect(isVideo('/media/MOVIE.${extension.toUpperCase()}'), isTrue);
    }
  });

  test('valid media check rejects unrelated files', () async {
    expect(await isValidMediaFile('/media/movie.m4v'), isTrue);
    expect(await isValidMediaFile('/media/notes.txt'), isFalse);
  });

  test('filesystem entity extension is normalized', () {
    expect(getFileSystemEntityExtension(File('/media/movie.M2TS')), 'm2ts');
  });
}
