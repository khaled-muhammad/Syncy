/// A video that lives on a paired PC, listed over the LAN.
///
/// The phone never has the file — it holds this lightweight descriptor and
/// streams the bytes on demand from the host's `/media/<id>` endpoint.
class RemoteMedia {
  const RemoteMedia({
    required this.id,
    required this.name,
    this.folder,
    this.sizeBytes,
    this.hasThumbnail = false,
    this.hasSubtitles = false,
  });

  /// The host's Isar id for this media, used to build stream/thumbnail URLs.
  final int id;
  final String name;
  final String? folder;
  final int? sizeBytes;
  final bool hasThumbnail;
  final bool hasSubtitles;

  factory RemoteMedia.fromJson(Map<String, dynamic> json) {
    return RemoteMedia(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Untitled',
      folder: json['folder']?.toString(),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      hasThumbnail: json['hasThumbnail'] == true,
      hasSubtitles: json['hasSubtitles'] == true,
    );
  }
}
