class SubtitleTrack {
  final String source;
  final String fileName;
  final String languageCode;
  final String label;
  final bool isDefault;

  const SubtitleTrack({
    required this.source,
    required this.fileName,
    required this.languageCode,
    required this.label,
    this.isDefault = false,
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      source: json['source']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Subtitle',
      languageCode: json['languageCode']?.toString() ?? 'und',
      label: json['label']?.toString() ?? 'Subtitle',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'fileName': fileName,
    'languageCode': languageCode,
    'label': label,
    'isDefault': isDefault,
  };

  SubtitleTrack copyWith({String? source}) {
    return SubtitleTrack(
      source: source ?? this.source,
      fileName: fileName,
      languageCode: languageCode,
      label: label,
      isDefault: isDefault,
    );
  }
}
