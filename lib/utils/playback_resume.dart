import 'dart:math';

Duration resumePosition({required int positionMs, required int durationMs}) {
  if (positionMs < const Duration(seconds: 10).inMilliseconds) {
    return Duration.zero;
  }
  if (durationMs > 0) {
    final completionThreshold = min(
      (durationMs * .95).round(),
      durationMs - const Duration(seconds: 30).inMilliseconds,
    );
    if (positionMs >= completionThreshold) return Duration.zero;
    return Duration(milliseconds: positionMs.clamp(0, durationMs));
  }
  return Duration(milliseconds: max(0, positionMs));
}

String formatPlaybackPosition(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
