/// Política determinística de EDH Brackets (1..4) para controlar power level.
///
/// Observação: isso NÃO substitui legalidade/identidade/limites de cópias.
/// É uma camada adicional para manter consistência entre "brackets".
library;

enum BracketCategory {
  fastMana,
  tutor,
  freeInteraction,
  extraTurns,
  infiniteCombo,
  boardWipe,
  cardAdvantage,
  stax,
  protection,
  valueEngine,
  gameChanger,
}

class BracketPolicy {
  BracketPolicy({
    required this.bracket,
    required this.maxCounts,
  });

  final int bracket;
  final Map<BracketCategory, int> maxCounts;

  static BracketPolicy forBracket(int bracket) {
    final b = bracket.clamp(1, 4);
    switch (b) {
      case 1:
        return BracketPolicy(
          bracket: 1,
          maxCounts: const {
            BracketCategory.fastMana: 1,
            BracketCategory.tutor: 1,
            BracketCategory.freeInteraction: 0,
            BracketCategory.extraTurns: 0,
            BracketCategory.infiniteCombo: 0,
            BracketCategory.boardWipe: 1,
            BracketCategory.cardAdvantage: 1,
            BracketCategory.stax: 0,
            BracketCategory.protection: 1,
            BracketCategory.valueEngine: 1,
            BracketCategory.gameChanger: 0,
          },
        );
      case 2:
        return BracketPolicy(
          bracket: 2,
          maxCounts: const {
            BracketCategory.fastMana: 3,
            BracketCategory.tutor: 3,
            BracketCategory.freeInteraction: 2,
            BracketCategory.extraTurns: 1,
            BracketCategory.infiniteCombo: 0,
            BracketCategory.boardWipe: 2,
            BracketCategory.cardAdvantage: 2,
            BracketCategory.stax: 1,
            BracketCategory.protection: 2,
            BracketCategory.valueEngine: 2,
            BracketCategory.gameChanger: 0,
          },
        );
      case 3:
        return BracketPolicy(
          bracket: 3,
          maxCounts: const {
            BracketCategory.fastMana: 6,
            BracketCategory.tutor: 6,
            BracketCategory.freeInteraction: 6,
            BracketCategory.extraTurns: 2,
            BracketCategory.infiniteCombo: 2,
            BracketCategory.boardWipe: 4,
            BracketCategory.cardAdvantage: 6,
            BracketCategory.stax: 3,
            BracketCategory.protection: 4,
            BracketCategory.valueEngine: 6,
            BracketCategory.gameChanger: 3,
          },
        );
      case 4:
      default:
        return BracketPolicy(
          bracket: 4,
          maxCounts: const {
            BracketCategory.fastMana: 99,
            BracketCategory.tutor: 99,
            BracketCategory.freeInteraction: 99,
            BracketCategory.extraTurns: 99,
            BracketCategory.infiniteCombo: 99,
            BracketCategory.boardWipe: 99,
            BracketCategory.cardAdvantage: 99,
            BracketCategory.stax: 99,
            BracketCategory.protection: 99,
            BracketCategory.valueEngine: 99,
            BracketCategory.gameChanger: 99,
          },
        );
    }
  }
}

class BracketTagResult {
  BracketTagResult(this.categories);
  final Set<BracketCategory> categories;
}

/// Heurística simples para taguear cartas por categoria.
/// - `fastMana` usa lista curada de nomes (mínimo viável).
/// - `tutor` e `extraTurns` usam oracle text.
/// - `freeInteraction` usa padrões de custo alternativo.
BracketTagResult tagCardForBracket({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  final categories = <BracketCategory>{};
  final n = name.toLowerCase().trim();
  final t = typeLine.toLowerCase();
  final o = oracleText.toLowerCase();

  if (_isOfficialGameChangerName(n)) {
    categories.add(BracketCategory.gameChanger);
  }

  if (_fastManaNames.contains(n)) {
    categories.add(BracketCategory.fastMana);
  }

  // Alguns terrenos “fast mana”
  if (t.contains('land') && _fastManaLandNames.contains(n)) {
    categories.add(BracketCategory.fastMana);
  }

  // Tutor real: land-ramp/fetch não deve consumir orçamento de tutor.
  if (_looksLikeBracketTutorText(o)) {
    categories.add(BracketCategory.tutor);
  }

  // Extra turns
  if (o.contains('extra turn')) {
    categories.add(BracketCategory.extraTurns);
  }

  // Free interaction / custo alternativo (heurística)
  final hasRather = o.contains('rather than pay');
  final hasExile = o.contains('exile a') ||
      o.contains('exile two') ||
      o.contains('exile one');
  final hasPayLife = o.contains('pay') && o.contains('life') && hasRather;
  final hasPitch = hasRather && (hasExile || hasPayLife);
  final hasFreeCast = o.contains('without paying');
  if (_knownFreeInteractionNames.contains(n) || hasPitch || hasFreeCast) {
    categories.add(BracketCategory.freeInteraction);
  }

  // Infinite combos: não dá pra inferir bem só do oracle text.
  // Começa com lista curada (pode evoluir depois).
  if (_knownInfiniteComboPieces.contains(n)) {
    categories.add(BracketCategory.infiniteCombo);
  }

  // Board wipe: destruicao/exilio/bounce em massa assimetrico ou unilateral
  if (_looksLikeGameChangerBoardWipe(n, o)) {
    categories.add(BracketCategory.boardWipe);
  }

  // Card advantage: draw repetitivo/passivo, tax effects, burst draw massivo
  if (_looksLikeGameChangerCardAdvantage(n, o)) {
    categories.add(BracketCategory.cardAdvantage);
  }

  // Stax: restringe acoes dos oponentes
  if (_looksLikeGameChangerStax(n, o)) {
    categories.add(BracketCategory.stax);
  }

  // Protection: protecao absoluta ou free protection spells
  if (_looksLikeGameChangerProtection(n, o)) {
    categories.add(BracketCategory.protection);
  }

  // Value engine: gera valor recorrente todo turno
  if (_isKnownValueEngineName(n)) {
    categories.add(BracketCategory.valueEngine);
  }

  return BracketTagResult(categories);
}

Map<BracketCategory, int> countBracketCategories(
  Iterable<Map<String, dynamic>> cards,
) {
  final counts = <BracketCategory, int>{
    BracketCategory.fastMana: 0,
    BracketCategory.tutor: 0,
    BracketCategory.freeInteraction: 0,
    BracketCategory.extraTurns: 0,
    BracketCategory.infiniteCombo: 0,
    BracketCategory.boardWipe: 0,
    BracketCategory.cardAdvantage: 0,
    BracketCategory.stax: 0,
    BracketCategory.protection: 0,
    BracketCategory.valueEngine: 0,
    BracketCategory.gameChanger: 0,
  };

  for (final c in cards) {
    final name = (c['name'] as String?) ?? '';
    final typeLine = (c['type_line'] as String?) ?? '';
    final oracle = (c['oracle_text'] as String?) ?? '';
    if (name.isEmpty) continue;

    final qty = (c['quantity'] as int?) ?? 1;
    final tags = tagCardForBracket(
      name: name,
      typeLine: typeLine,
      oracleText: oracle,
    );
    for (final cat in tags.categories) {
      counts[cat] = (counts[cat] ?? 0) + qty;
    }
  }

  return counts;
}

class BracketFilterDecision {
  BracketFilterDecision({
    required this.allowed,
    required this.blocked,
    required this.remainingBudget,
    required this.currentCounts,
    required this.policy,
  });

  final List<String> allowed;
  final List<Map<String, dynamic>> blocked; // {name, categories, reason}
  final Map<BracketCategory, int> remainingBudget;
  final Map<BracketCategory, int> currentCounts;
  final BracketPolicy policy;
}

BracketFilterDecision applyBracketPolicyToAdditions({
  required int bracket,
  required Iterable<Map<String, dynamic>> currentDeckCards,
  required Iterable<Map<String, dynamic>> additionsCardsData,
}) {
  final policy = BracketPolicy.forBracket(bracket);
  final counts = countBracketCategories(currentDeckCards);

  final remaining = <BracketCategory, int>{};
  for (final entry in policy.maxCounts.entries) {
    remaining[entry.key] =
        (entry.value - (counts[entry.key] ?? 0)).clamp(0, 999);
  }

  final allowed = <String>[];
  final blocked = <Map<String, dynamic>>[];

  for (final c in additionsCardsData) {
    final name = (c['name'] as String?) ?? '';
    final typeLine = (c['type_line'] as String?) ?? '';
    final oracle = (c['oracle_text'] as String?) ?? '';
    if (name.isEmpty) continue;

    final tags = tagCardForBracket(
      name: name,
      typeLine: typeLine,
      oracleText: oracle,
    );
    final categories = tags.categories.toList();

    var canAdd = true;
    for (final cat in tags.categories) {
      final budget = remaining[cat] ?? 0;
      if (budget <= 0) {
        canAdd = false;
        break;
      }
    }

    if (!canAdd) {
      blocked.add({
        'name': name,
        'categories': categories.map((e) => e.name).toList(),
        'reason': 'Excede o limite do bracket ${policy.bracket}.',
      });
      continue;
    }

    // Consome budget de cada categoria (intermediário: bloqueia o excedente,
    // mas não impede cartas “normais” de completar o deck).
    for (final cat in tags.categories) {
      remaining[cat] = ((remaining[cat] ?? 0) - 1).clamp(0, 999);
    }
    allowed.add(name);
  }

  return BracketFilterDecision(
    allowed: allowed,
    blocked: blocked,
    remainingBudget: remaining,
    currentCounts: counts,
    policy: policy,
  );
}

const _fastManaNames = <String>{
  // Staples comuns (lista inicial – pode ser refinada)
  'mana crypt',
  'jeweled lotus',
  'mana vault',
  'grim monolith',
  'chrome mox',
  'mox diamond',
  'lotus petal',
  'sol ring',
  'ancient tomb', // (land, mas mantém aqui também por segurança)
  'lion\'s eye diamond',
  'mana drain', // discutível, mas entra como “power spike”
};

const _fastManaLandNames = <String>{
  'ancient tomb',
  'city of traitors',
  'gaea\'s cradle',
  'mishra\'s workshop',
  'serra\'s sanctum',
};

const _knownFreeInteractionNames = <String>{
  'deadly rollick',
  'deflecting swat',
  'fierce guardianship',
  'flawless maneuver',
  'force of negation',
  'force of will',
  'mental misstep',
  'mindbreak trap',
  'pact of negation',
};

const _knownInfiniteComboPieces = <String>{
  'basalt monolith',
  'demonic consultation',
  'dramatic reversal',
  'grand architect',
  'power artifact',
  'sensei\'s divining top',
  'tainted pact',
  'thassa\'s oracle',
  'underworld breach',
};

// BEGIN GENERATED GAME CHANGERS
const officialGameChangerNamesForBracketPolicy = <String>{
  'ad nauseam',
  'ancient tomb',
  'aura shards',
  'biorhythm',
  'bolas\'s citadel',
  'braids, cabal minion',
  'chrome mox',
  'coalition victory',
  'consecrated sphinx',
  'crop rotation',
  'cyclonic rift',
  'demonic tutor',
  'drannith magistrate',
  'enlightened tutor',
  'farewell',
  'field of the dead',
  'fierce guardianship',
  'force of will',
  'gaea\'s cradle',
  'gamble',
  'gifts ungiven',
  'glacial chasm',
  'grand arbiter augustin iv',
  'grim monolith',
  'humility',
  'imperial seal',
  'intuition',
  'jeska\'s will',
  'lion\'s eye diamond',
  'mana vault',
  'mishra\'s workshop',
  'mox diamond',
  'mystical tutor',
  'narset, parter of veils',
  'natural order',
  'necropotence',
  'notion thief',
  'opposition agent',
  'orcish bowmasters',
  'panoptic mirror',
  'rhystic study',
  'seedborn muse',
  'serra\'s sanctum',
  'smothering tithe',
  'survival of the fittest',
  'teferi\'s protection',
  'tergrid, god of fright // tergrid\'s lantern',
  'thassa\'s oracle',
  'the one ring',
  'the tabernacle at pendrell vale',
  'underworld breach',
  'vampiric tutor',
  'worldly tutor',
};
// END GENERATED GAME CHANGERS

bool _isOfficialGameChangerName(String name) {
  final variants = _normalizedBracketNameVariants(name);
  for (final officialName in officialGameChangerNamesForBracketPolicy) {
    final officialVariants = _normalizedBracketNameVariants(officialName);
    if (variants.any(officialVariants.contains)) return true;
  }
  return false;
}

bool _isKnownValueEngineName(String name) {
  final variants = _normalizedBracketNameVariants(name);
  return variants.any(_knownValueEngineNames.contains);
}

Set<String> _normalizedBracketNameVariants(String name) {
  final normalized = name.toLowerCase().trim();
  if (normalized.isEmpty) return const <String>{};

  final variants = <String>{normalized};
  final splitIndex = normalized.indexOf('//');
  if (splitIndex != -1) {
    final firstFace = normalized.substring(0, splitIndex).trim();
    if (firstFace.isNotEmpty) variants.add(firstFace);
  }
  return variants;
}

bool _looksLikeBracketTutorText(String oracleLower) {
  if (!oracleLower.contains('search your library')) return false;
  return !_looksLikeBracketLandSearchText(oracleLower);
}

bool _looksLikeBracketLandSearchText(String oracleLower) {
  return oracleLower.contains('land card') ||
      oracleLower.contains('basic land') ||
      oracleLower.contains('plains card') ||
      oracleLower.contains('island card') ||
      oracleLower.contains('swamp card') ||
      oracleLower.contains('mountain card') ||
      oracleLower.contains('forest card') ||
      oracleLower.contains('wastes card');
}

bool _looksLikeGameChangerBoardWipe(String normalizedName, String oracleLower) {
  // Curated GC board wipes
  if (normalizedName == 'cyclonic rift' || normalizedName == 'farewell')
    return true;
  // Board wipes that are asymmetric (only opponents) or mass exile
  if (oracleLower.contains('exile all') &&
      oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('destroy all') &&
      oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('return all') &&
      oracleLower.contains('opponents control') &&
      oracleLower.contains('hand')) return true;
  return false;
}

bool _looksLikeGameChangerCardAdvantage(
    String normalizedName, String oracleLower) {
  // Curated GC card advantage engines
  if (normalizedName == 'rhystic study' ||
      normalizedName == 'mystic remora' ||
      normalizedName == 'the one ring' ||
      normalizedName == 'smothering tithe' ||
      normalizedName == 'necropotence' ||
      normalizedName == 'ad nauseam' ||
      normalizedName == 'consecrated sphinx') return true;
  // Tax-based draw: "unless that player pays"
  if (oracleLower.contains('unless') &&
      oracleLower.contains('pays') &&
      (oracleLower.contains('draw') || oracleLower.contains('create')))
    return true;
  // Necropotence-style: pay life for cards
  if (oracleLower.contains('pay') &&
      oracleLower.contains('life') &&
      oracleLower.contains('draw') &&
      oracleLower.contains('card') &&
      oracleLower.contains('skip your draw step')) return true;
  return false;
}

bool _looksLikeGameChangerStax(String normalizedName, String oracleLower) {
  // Curated GC stax pieces
  if (normalizedName == 'drannith magistrate' ||
      normalizedName == 'opposition agent' ||
      normalizedName == 'grand abolisher' ||
      normalizedName == 'grand arbiter augustin iv' ||
      normalizedName == 'narset, parter of veils' ||
      normalizedName == 'winter orb' ||
      normalizedName == 'static orb' ||
      normalizedName == 'torpor orb' ||
      normalizedName == 'rule of law' ||
      normalizedName == 'deafening silence') return true;
  if (normalizedName == 'eidolon of rhetoric' ||
      normalizedName == 'ethersworn canonist' ||
      normalizedName == 'archon of emeria') return true;
  // Spells-per-turn restrictions
  if (oracleLower.contains('cast') &&
          oracleLower.contains('more than one spell') ||
      oracleLower.contains('can\'t cast more than one spell')) return true;
  // Draw and tax restrictions.
  if (oracleLower.contains('can\'t draw more than one card')) return true;
  if (oracleLower.contains('spells your opponents cast cost')) return true;
  // ETB hate
  if (oracleLower.contains('creatures entering') &&
      oracleLower.contains('don\'t cause')) return true;
  // Search hate
  if (oracleLower.contains('search') &&
      oracleLower.contains('library') &&
      oracleLower.contains('control')) return true;
  return false;
}

bool _looksLikeGameChangerProtection(
    String normalizedName, String oracleLower) {
  // Curated GC protection
  if (normalizedName == 'teferi\'s protection' ||
      normalizedName == 'deflecting swat' ||
      normalizedName == 'fierce guardianship' ||
      normalizedName == 'heroic intervention' ||
      normalizedName == 'flawless maneuver' ||
      normalizedName == 'deadly rollick') return true;
  // Free protection spells
  if (oracleLower.contains('rather than pay') &&
      (oracleLower.contains('indestructible') ||
          oracleLower.contains('hexproof') ||
          oracleLower.contains('phase out') ||
          oracleLower.contains('protection from'))) return true;
  // Teferi's Protection pattern: phase out + protection from everything
  if (oracleLower.contains('phase out') &&
      oracleLower.contains('protection from everything')) return true;
  return false;
}

const _knownValueEngineNames = <String>{
  'seedborn muse',
  'tergrid, god of fright',
  'bolas\'s citadel',
  'sensei\'s divining top',
  'aetherflux reservoir',
  'consecrated sphinx',
  'field of the dead',
  'smothering tithe',
  'the one ring',
};
