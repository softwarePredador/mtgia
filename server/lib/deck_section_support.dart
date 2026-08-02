String normalizeDeckSectionValue(Object value) {
  var normalized = value.toString().trim().toLowerCase();
  normalized = normalized.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
  normalized = normalized.replaceFirst(RegExp(r'[:：]+$'), '').trim();
  if (normalized.startsWith('[') && normalized.endsWith(']')) {
    normalized = normalized.substring(1, normalized.length - 1).trim();
  }

  return normalized.replaceAll(RegExp(r'[\s_\-]+'), '');
}

bool isUnsupportedDeckSectionValue(Object value) {
  return unsupportedDeckSectionValues.contains(
    normalizeDeckSectionValue(value),
  );
}

const unsupportedDeckSectionValues = {
  'side',
  'sideboard',
  'sideboards',
  'wish',
  'wishboard',
  'wishboards',
  'maybe',
  'maybeboard',
  'maybeboards',
  'considering',
  'outside',
  'outsidegame',
  'outsidethegame',
  'outsideboard',
};
