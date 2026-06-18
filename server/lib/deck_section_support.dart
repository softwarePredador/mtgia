String normalizeDeckSectionValue(Object value) {
  return value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[:：]+$'), '')
      .replaceAll(RegExp(r'[\s_\-]+'), '');
}

bool isUnsupportedDeckSectionValue(Object value) {
  return unsupportedDeckSectionValues
      .contains(normalizeDeckSectionValue(value));
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
