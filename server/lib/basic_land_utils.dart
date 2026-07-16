const regularBasicLandNames = <String>{
  'plains',
  'island',
  'swamp',
  'mountain',
  'forest',
  'wastes',
};

const snowBasicLandNames = <String>{
  'snow covered plains',
  'snow covered island',
  'snow covered swamp',
  'snow covered mountain',
  'snow covered forest',
  'snow covered wastes',
};

const basicLandNames = <String>{
  ...regularBasicLandNames,
  ...snowBasicLandNames,
};

String normalizeBasicLandName(String name) {
  return name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[‐‑‒–—−-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool isBasicLandName(String name) {
  final normalized = normalizeBasicLandName(name);
  return basicLandNames.contains(normalized);
}

bool isBasicLandTypeLine(String typeLine) {
  final normalized = typeLine
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[‐‑‒–—−-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return RegExp(r'\bbasic\s+(snow\s+)?land\b').hasMatch(normalized);
}

/// Returns whether [typeLine] contains the standalone Magic card type `Land`.
///
/// A substring check is not sufficient here: creature subtypes and names such
/// as `Lander` must not be treated as lands, while `Basic Land — Island`,
/// `Legendary Land`, and multi-face type lines still need to match.
bool isLandTypeLine(String typeLine) {
  return RegExp(
    r'(^|[^a-z])land([^a-z]|$)',
    caseSensitive: false,
  ).hasMatch(typeLine);
}

bool isBasicLandCard({required String name, required String typeLine}) {
  return isBasicLandTypeLine(typeLine) || isBasicLandName(name);
}
