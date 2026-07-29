import '../basic_land_utils.dart' as basic_lands;
import '../commander_mana_floor.dart';

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

bool rebuildUsesCommanderReferenceSources(String format) {
  final normalized = format.trim().toLowerCase();
  return normalized == 'commander' || normalized == 'edh';
}

int resolveRebuildGuidedLandTarget({
  required String format,
  required int derivedTarget,
  Map<String, dynamic>? recommendedStructure,
  Map<String, dynamic>? roleTargets,
}) {
  final minimum = strategicMinimumLandCountForFormat(format);
  if (minimum == null) return derivedTarget;

  final maximum = strategicMaximumAutomaticLandFloorForFormat(format);
  final profilePolicy = resolveOptimizationProfileLandPolicy(
    format: format,
    recommendedStructure: recommendedStructure,
    roleTargets: roleTargets,
  );
  return (profilePolicy?.targetLandCount ?? derivedTarget).clamp(
    minimum,
    maximum,
  );
}

List<Map<String, dynamic>> trimRebuildGuidedDeckToTarget({
  required Iterable<Map<String, dynamic>> cards,
  required int targetTotal,
  required int minimumLandCount,
}) {
  final mutable = cards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: true);
  var landCount = _rebuildPhysicalLandCount(mutable);

  mutable.sort((a, b) {
    final commanderA = a['is_commander'] == true ? 1 : 0;
    final commanderB = b['is_commander'] == true ? 1 : 0;
    final byCommander = commanderA.compareTo(commanderB);
    if (byCommander != 0) return byCommander;

    final landA = _isRebuildLand(a) ? 1 : 0;
    final landB = _isRebuildLand(b) ? 1 : 0;
    final byLand = landA.compareTo(landB);
    if (byLand != 0) return byLand;

    return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
  });

  while (_rebuildPhysicalCardCount(mutable) > targetTotal) {
    final index = mutable.indexWhere((card) {
      if (card['is_commander'] == true || _rebuildQuantity(card) <= 0) {
        return false;
      }
      return !_isRebuildLand(card) || landCount > minimumLandCount;
    });
    if (index == -1) {
      throw StateError(
        'Rebuild cannot reach $targetTotal cards without reducing the mana '
        'foundation below $minimumLandCount lands.',
      );
    }

    final card = mutable[index];
    final isLand = _isRebuildLand(card);
    final quantity = _rebuildQuantity(card);
    if (quantity <= 1) {
      mutable.removeAt(index);
    } else {
      card['quantity'] = quantity - 1;
    }
    if (isLand) landCount -= 1;
  }

  if (_rebuildPhysicalCardCount(mutable) != targetTotal) {
    throw StateError(
      'Rebuild produced ${_rebuildPhysicalCardCount(mutable)} cards instead '
      'of $targetTotal.',
    );
  }
  return mutable;
}

int _rebuildPhysicalCardCount(Iterable<Map<String, dynamic>> cards) {
  return cards.fold<int>(0, (sum, card) => sum + _rebuildQuantity(card));
}

int _rebuildPhysicalLandCount(Iterable<Map<String, dynamic>> cards) {
  return cards.fold<int>(
    0,
    (sum, card) => sum + (_isRebuildLand(card) ? _rebuildQuantity(card) : 0),
  );
}

int _rebuildQuantity(Map<String, dynamic> card) {
  final value = card['quantity'];
  final parsed = switch (value) {
    num() => value.toInt(),
    String() => int.tryParse(value.trim()),
    _ => null,
  };
  return parsed != null && parsed > 0 ? parsed : 1;
}

bool _isRebuildLand(Map<String, dynamic> card) {
  return basic_lands.isLandTypeLine(card['type_line']?.toString() ?? '');
}
