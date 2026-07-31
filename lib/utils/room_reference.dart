final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final _joinCodePattern = RegExp(r'^[2-9A-HJ-NP-Z]{8}$');
final _inviteLinkPattern = RegExp(
  r'syncy://join/([0-9A-Z-]+)',
  caseSensitive: false,
);

String? normalizeRoomReference(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final linkMatch = _inviteLinkPattern.firstMatch(trimmed);
  final candidate = linkMatch?.group(1) ?? trimmed;
  if (_uuidPattern.hasMatch(candidate)) return candidate.toLowerCase();

  final code = candidate.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return _joinCodePattern.hasMatch(code) ? code : null;
}

String? roomReferenceFromUri(Uri uri) {
  if (uri.scheme.toLowerCase() != 'syncy' ||
      uri.host.toLowerCase() != 'join' ||
      uri.pathSegments.isEmpty) {
    return null;
  }
  return normalizeRoomReference(uri.pathSegments.first);
}
