const _nonDeckCardTypeWords = <String>{
  'attraction',
  'conspiracy',
  'contraption',
  'dungeon',
  'emblem',
  'phenomenon',
  'plane',
  'scheme',
  'sticker',
  'stickers',
  'token',
  'vanguard',
};

const _nonDeckLayouts = <String>{
  'art_series',
  'double_faced_token',
  'emblem',
  'planar',
  'scheme',
  'token',
  'vanguard',
};

// Dedicated Mystery Booster playtest and unknown/playtest products can contain
// imported legality false positives. MB2 is intentionally not listed because
// Mystery Booster 2 mixes legitimate reprints with playtest/acorn cards; its
// ordinary reprints retain their existing format legality, while supplemental
// objects are rejected by type/layout and the remaining cards by legality.
// Unfinity is likewise not listed for the same type/layout + legality split.
const _playtestSetCodes = <String>{'cmb1', 'cmb2', 'unk'};

String? mainDeckCardIneligibilityReason({
  required String typeLine,
  String? setCode,
  String? layout,
}) {
  final normalizedTypeLine = typeLine.trim().toLowerCase();
  final typeWords = RegExp(
    r"[a-z]+",
  ).allMatches(normalizedTypeLine).map((match) => match.group(0)!);
  if (typeWords.any(_nonDeckCardTypeWords.contains)) {
    return 'supplemental_game_object';
  }

  final normalizedLayout = (layout ?? '').trim().toLowerCase();
  if (_nonDeckLayouts.contains(normalizedLayout)) {
    return 'non_deck_layout';
  }

  final normalizedSetCode = (setCode ?? '').trim().toLowerCase();
  if (_playtestSetCodes.contains(normalizedSetCode)) {
    return 'playtest_product';
  }
  return null;
}

bool isMainDeckCardEligible({
  required String typeLine,
  String? setCode,
  String? layout,
}) {
  return mainDeckCardIneligibilityReason(
        typeLine: typeLine,
        setCode: setCode,
        layout: layout,
      ) ==
      null;
}

String mainDeckCardEligibilitySql({String tableAlias = 'c'}) {
  if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(tableAlias)) {
    throw ArgumentError.value(tableAlias, 'tableAlias', 'Invalid SQL alias.');
  }
  final typeLine = "LOWER(COALESCE($tableAlias.type_line, ''))";
  final layout = "LOWER(COALESCE($tableAlias.layout, ''))";
  final setCode = "LOWER(COALESCE($tableAlias.set_code, ''))";
  const nonDeckTypePattern =
      r'(^|[^a-z])(attraction|conspiracy|contraption|dungeon|emblem|phenomenon|plane|scheme|sticker|stickers|token|vanguard)([^a-z]|$)';
  final layouts = _nonDeckLayouts.map((value) => "'$value'").join(', ');
  final setCodes = _playtestSetCodes.map((value) => "'$value'").join(', ');
  return '(NOT ($typeLine ~ \'$nonDeckTypePattern\')'
      ' AND $layout NOT IN ($layouts)'
      ' AND $setCode NOT IN ($setCodes))';
}

void validateMainDeckCardEligibility({
  required String name,
  required String typeLine,
  String? setCode,
  String? layout,
}) {
  final reason = mainDeckCardIneligibilityReason(
    typeLine: typeLine,
    setCode: setCode,
    layout: layout,
  );
  if (reason == null) return;
  throw MainDeckCardEligibilityException(
    'Regra violada: "$name" é um objeto de jogo suplementar ou uma carta de '
    'produto de teste e não pode entrar no deck principal.',
    reasonCode: reason,
  );
}

class MainDeckCardEligibilityException implements Exception {
  const MainDeckCardEligibilityException(
    this.message, {
    required this.reasonCode,
  });

  final String message;
  final String reasonCode;

  @override
  String toString() => message;
}
