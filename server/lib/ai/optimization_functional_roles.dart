bool looksLikeOptimizationBoardWipeText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  final ownBoardOnly = oracle.contains('all creatures you control') ||
      oracle.contains('each creature you control');
  final combatDamageAssignment = oracle.contains('assigns combat damage');

  if (ownBoardOnly || combatDamageAssignment) return false;

  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('all creatures get -') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      oracle.contains('damage to each creature') ||
      oracle.contains('deals') &&
          oracle.contains('damage') &&
          oracle.contains('to each creature');
}

bool looksLikeOptimizationRampText(String oracleText) {
  final oracle = oracleText.toLowerCase();

  if (oracle.contains('add {') || oracle.contains('mana of any')) {
    return true;
  }

  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle)) {
    return true;
  }

  return oracle.contains('additional land this turn') ||
      oracle.contains('additional land on each of your turns') ||
      oracle.contains('put a land card from your hand onto the battlefield') ||
      oracle.contains('put up to') && oracle.contains('land cards') ||
      oracle.contains('create a treasure token') ||
      oracle.contains('create two treasure tokens') ||
      oracle.contains('create three treasure tokens');
}

bool looksLikeOptimizationLandSearchText(String oracleText) {
  final oracle = oracleText.toLowerCase();
  return oracle.contains('land card') ||
      oracle.contains('basic land') ||
      oracle.contains('forest card') ||
      oracle.contains('plains card') ||
      oracle.contains('island card') ||
      oracle.contains('swamp card') ||
      oracle.contains('mountain card');
}

String classifyOptimizationFunctionalRole(Map<String, dynamic> card) {
  final semanticRole =
      _classifySemanticV2FunctionalRole(card['semantic_tags_v2']);
  if (semanticRole != null) return semanticRole;

  final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
  final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();

  if (typeLine.contains('land')) return 'land';

  if (oracle.contains('draw') ||
      oracle.contains('look at the top') ||
      (oracle.contains('scry') && oracle.contains('draw'))) {
    return 'draw';
  }

  if (oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('counter target') ||
      (oracle.contains('return target') && oracle.contains('to its owner')) ||
      (oracle.contains('deals') &&
          oracle.contains('damage') &&
          (oracle.contains('target creature') ||
              oracle.contains('target planeswalker') ||
              oracle.contains('any target')))) {
    return 'removal';
  }

  if (looksLikeOptimizationBoardWipeText(oracle)) {
    return 'wipe';
  }

  if (looksLikeOptimizationRampText(oracle) ||
      (typeLine.contains('artifact') && oracle.contains('add'))) {
    return 'ramp';
  }

  if (oracle.contains('search your library') && !oracle.contains('land')) {
    return 'tutor';
  }

  if (oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('shroud') ||
      oracle.contains('ward')) {
    return 'protection';
  }

  if (typeLine.contains('creature')) return 'creature';
  if (typeLine.contains('artifact')) return 'artifact';
  if (typeLine.contains('enchantment')) return 'enchantment';
  if (typeLine.contains('planeswalker')) return 'planeswalker';

  return 'utility';
}

String? _classifySemanticV2FunctionalRole(Object? rawSemanticTags) {
  if (rawSemanticTags is! Iterable) return null;
  Map? best;
  for (final raw in rawSemanticTags) {
    if (raw is! Map) continue;
    final confidence = _safeSemanticConfidence(raw['role_confidence']);
    final currentConfidence =
        best == null ? -1.0 : _safeSemanticConfidence(best['role_confidence']);
    if (confidence > currentConfidence) best = raw;
  }
  if (best == null || _safeSemanticConfidence(best['role_confidence']) < 0.65) {
    return null;
  }

  final tags = <String>{};
  final rawTags = best['tags'];
  if (rawTags is Iterable) {
    for (final item in rawTags) {
      if (item is String) {
        tags.add(item.trim().toLowerCase());
      } else if (item is Map) {
        final tag = item['tag']?.toString().trim().toLowerCase();
        if (tag != null && tag.isNotEmpty) tags.add(tag);
      }
    }
  }

  if (tags.contains('board_wipe')) return 'wipe';
  for (final role in const [
    'draw',
    'removal',
    'ramp',
    'tutor',
    'protection',
    'recursion',
    'wincon',
    'combo_piece',
  ]) {
    if (tags.contains(role)) return role;
  }
  if (best['wincon'] == true) return 'wincon';
  if (best['combo_piece'] == true) return 'combo_piece';
  if (best['engine'] == true) return 'engine';
  if (best['payoff'] == true) return 'payoff';
  if (best['enabler'] == true) return 'enabler';
  return null;
}

double _safeSemanticConfidence(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
