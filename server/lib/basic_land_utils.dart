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

bool isBasicLandCard({
  required String name,
  required String typeLine,
}) {
  return isBasicLandTypeLine(typeLine) || isBasicLandName(name);
}
