import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/utils/playback_resume.dart';

void main() {
  test('resumes meaningful unfinished progress', () {
    expect(
      resumePosition(positionMs: 125000, durationMs: 600000),
      const Duration(minutes: 2, seconds: 5),
    );
  });

  test('starts over near the beginning or after completion', () {
    expect(resumePosition(positionMs: 5000, durationMs: 600000), Duration.zero);
    expect(
      resumePosition(positionMs: 590000, durationMs: 600000),
      Duration.zero,
    );
  });
}
