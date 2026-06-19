import '../basic_land_utils.dart' as basic_lands;

const _basicLandColorByName = <String, String>{
  'plains': 'W',
  'snow covered plains': 'W',
  'island': 'U',
  'snow covered island': 'U',
  'swamp': 'B',
  'snow covered swamp': 'B',
  'mountain': 'R',
  'snow covered mountain': 'R',
  'forest': 'G',
  'snow covered forest': 'G',
  'wastes': 'C',
  'snow covered wastes': 'C',
};

bool isRebuildGuidedBasicLandName(String name) {
  return basic_lands.isBasicLandName(name);
}

bool rebuildGuidedBasicMatchesCommander(
  String name,
  Set<String> commanderColorIdentity,
) {
  final normalized = basic_lands.normalizeBasicLandName(name);
  final basicColor = _basicLandColorByName[normalized];
  if (basicColor == null) return false;
  if (commanderColorIdentity.isEmpty) return basicColor == 'C';
  return commanderColorIdentity.contains(basicColor);
}
