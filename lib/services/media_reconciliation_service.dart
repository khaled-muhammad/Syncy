typedef MediaPathNormalizer = String Function(String path);

String _identityPath(String path) => path;

/// The paths added to and removed from a media library after discovery.
class MediaPathDiff {
  const MediaPathDiff({required this.addedPaths, required this.removedPaths});

  final List<String> addedPaths;
  final List<String> removedPaths;

  bool get isEmpty => addedPaths.isEmpty && removedPaths.isEmpty;
}

/// Calculates a library diff in O(known + discovered) time and memory.
///
/// Hash sets avoid the quadratic repeated-list searches that become visible
/// on libraries containing thousands of files. [normalizePath] lets Windows
/// callers compare case-insensitively without changing the stored path.
MediaPathDiff calculateMediaPathDiff({
  required Iterable<String> knownPaths,
  required Iterable<String> discoveredPaths,
  MediaPathNormalizer normalizePath = _identityPath,
}) {
  final known = knownPaths.toList(growable: false);
  final knownKeys = <String>{};
  for (final path in known) {
    knownKeys.add(normalizePath(path));
  }

  final discoveredKeys = <String>{};
  final added = <String>[];
  for (final path in discoveredPaths) {
    final key = normalizePath(path);
    if (!discoveredKeys.add(key)) continue;
    if (!knownKeys.contains(key)) added.add(path);
  }

  final removed = <String>[];
  for (final path in known) {
    if (!discoveredKeys.contains(normalizePath(path))) removed.add(path);
  }

  return MediaPathDiff(addedPaths: added, removedPaths: removed);
}
