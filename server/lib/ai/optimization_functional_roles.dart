bool looksLikeOptimizationBoardWipeText(String oracleText) {
  final oracle = oracleText.toLowerCase();

  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('all creatures get') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      (oracle.contains('each creature') && oracle.contains('damage'));
}

bool looksLikeOptimizationRampText(String oracleText) {
  final oracle = oracleText.toLowerCase();

  if (oracle.contains('add {') || oracle.contains('mana of any')) {
    return true;
  }

  if (oracle.contains('search your library') &&
      (oracle.contains('land card') ||
          oracle.contains('basic land') ||
          oracle.contains('forest card') ||
          oracle.contains('plains card') ||
          oracle.contains('island card') ||
          oracle.contains('swamp card') ||
          oracle.contains('mountain card'))) {
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

String classifyOptimizationFunctionalRole(Map<String, dynamic> card) {
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
