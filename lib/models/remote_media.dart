/// A complete, privacy-safe view of a paired PC's media library.
class RemoteLibrary {
  const RemoteLibrary({required this.roots, required this.media});

  const RemoteLibrary.empty() : roots = const [], media = const [];

  final List<RemoteLibraryRoot> roots;
  final List<RemoteMedia> media;

  factory RemoteLibrary.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RemoteMedia.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
    final parsedRoots = (json['roots'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RemoteLibraryRoot.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);

    // Older PC builds did not return a roots array. Deriving it from the
    // media keeps a newly-updated phone compatible with those hosts.
    final rootsById = <String, RemoteLibraryRoot>{
      for (final root in parsedRoots) root.id: root,
    };
    for (final item in media) {
      rootsById.putIfAbsent(
        item.rootId,
        () => RemoteLibraryRoot(id: item.rootId, name: item.rootName),
      );
    }

    return RemoteLibrary(
      roots: rootsById.values.toList(growable: false),
      media: media,
    );
  }

  /// Immediate directories at [directoryKey]. The empty key is the library
  /// home and contains the PC's user-selected root folders.
  List<RemoteDirectory> childDirectories(String directoryKey) {
    if (directoryKey.isEmpty) {
      final counts = <String, int>{};
      for (final item in media) {
        counts[item.rootId] = (counts[item.rootId] ?? 0) + 1;
      }
      final result = <RemoteDirectory>[
        for (final root in roots)
          if ((counts[root.id] ?? 0) > 0)
            RemoteDirectory(
              key: root.id,
              name: root.name,
              mediaCount: counts[root.id]!,
            ),
      ];
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return result;
    }

    final keyParts = _segments(directoryKey);
    if (keyParts.isEmpty) return const [];
    final rootId = keyParts.first;
    final currentParts = keyParts.skip(1).toList(growable: false);
    final counts = <String, int>{};

    for (final item in media.where((item) => item.rootId == rootId)) {
      final folderParts = item.relativeFolderSegments;
      if (!_startsWith(folderParts, currentParts) ||
          folderParts.length <= currentParts.length) {
        continue;
      }
      final childName = folderParts[currentParts.length];
      counts[childName] = (counts[childName] ?? 0) + 1;
    }

    final result = counts.entries
        .map(
          (entry) => RemoteDirectory(
            key: [...keyParts, entry.key].join('/'),
            name: entry.key,
            mediaCount: entry.value,
          ),
        )
        .toList(growable: false);
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// Videos directly inside [directoryKey], or all matching videos when a
  /// search query is supplied.
  List<RemoteMedia> visibleMedia(
    String directoryKey, {
    String searchQuery = '',
  }) {
    final query = searchQuery.trim().toLowerCase();
    Iterable<RemoteMedia> result;
    if (query.isNotEmpty) {
      result = media.where(
        (item) =>
            item.name.toLowerCase().contains(query) ||
            item.displayFolder.toLowerCase().contains(query),
      );
    } else if (directoryKey.isEmpty) {
      result = const <RemoteMedia>[];
    } else {
      result = media.where((item) => item.directoryKey == directoryKey);
    }

    final sorted = result.toList(growable: false);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  List<RemoteBreadcrumb> breadcrumbs(String directoryKey) {
    final result = <RemoteBreadcrumb>[
      const RemoteBreadcrumb(key: '', label: 'Library'),
    ];
    final parts = _segments(directoryKey);
    if (parts.isEmpty) return result;

    final root = roots.where((item) => item.id == parts.first).firstOrNull;
    result.add(
      RemoteBreadcrumb(key: parts.first, label: root?.name ?? 'Library'),
    );
    for (var index = 1; index < parts.length; index++) {
      result.add(
        RemoteBreadcrumb(
          key: parts.take(index + 1).join('/'),
          label: parts[index],
        ),
      );
    }
    return result;
  }
}

class RemoteLibraryRoot {
  const RemoteLibraryRoot({required this.id, required this.name});

  final String id;
  final String name;

  factory RemoteLibraryRoot.fromJson(Map<String, dynamic> json) {
    return RemoteLibraryRoot(
      id: json['id']?.toString() ?? 'library',
      name: json['name']?.toString() ?? 'Library',
    );
  }
}

class RemoteDirectory {
  const RemoteDirectory({
    required this.key,
    required this.name,
    required this.mediaCount,
  });

  final String key;
  final String name;
  final int mediaCount;
}

class RemoteBreadcrumb {
  const RemoteBreadcrumb({required this.key, required this.label});

  final String key;
  final String label;
}

/// A video that lives on a paired PC, listed over the LAN.
///
/// The phone never has the file - it holds this lightweight descriptor and
/// streams the bytes on demand from the host's `/media/<id>` endpoint.
class RemoteMedia {
  const RemoteMedia({
    required this.id,
    required this.name,
    this.rootId = 'library',
    this.rootName = 'Library',
    this.relativeFolder = '',
    this.sizeBytes,
    this.hasThumbnail = false,
    this.hasSubtitles = false,
  });

  /// The host's Isar id for this media, used to build stream/thumbnail URLs.
  final int id;
  final String name;

  /// A virtual library path. It is relative to a user-selected root so the PC
  /// never exposes drive letters, usernames, or absolute filesystem paths.
  final String rootId;
  final String rootName;
  final String relativeFolder;
  final int? sizeBytes;
  final bool hasThumbnail;
  final bool hasSubtitles;

  List<String> get relativeFolderSegments => _segments(relativeFolder);

  String get directoryKey => [rootId, ...relativeFolderSegments].join('/');

  String get displayFolder => [rootName, ...relativeFolderSegments].join(' / ');

  factory RemoteMedia.fromJson(Map<String, dynamic> json) {
    // `folder` is the v1.0.8 immediate-parent field. Treat it as a root when
    // talking to an older PC so browsing and search still work.
    final legacyFolder = json['folder']?.toString();
    final rootName = json['rootName']?.toString() ?? legacyFolder ?? 'Library';
    final rootId = json['rootId']?.toString() ?? 'legacy:$rootName';
    return RemoteMedia(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Untitled',
      rootId: rootId,
      rootName: rootName,
      relativeFolder: _cleanRelativePath(
        json['relativeFolder']?.toString() ?? '',
      ),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      hasThumbnail: json['hasThumbnail'] == true,
      hasSubtitles: json['hasSubtitles'] == true,
    );
  }
}

String parentRemoteDirectory(String directoryKey) {
  final parts = _segments(directoryKey);
  if (parts.length <= 1) return '';
  return parts.take(parts.length - 1).join('/');
}

String _cleanRelativePath(String value) => _segments(value).join('/');

List<String> _segments(String value) => value
    .replaceAll('\\', '/')
    .split('/')
    .where((segment) => segment.isNotEmpty && segment != '.')
    .toList(growable: false);

bool _startsWith(List<String> value, List<String> prefix) {
  if (prefix.length > value.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (value[index] != prefix[index]) return false;
  }
  return true;
}
