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
            BracketCategory.gameChanger: 3,
          },
        );
      case 4:
      default:
        // cEDH: sem limite (mantém números altos só para não “filtrar” na prática)
        return BracketPolicy(
          bracket: 4,
          maxCounts: const {
            BracketCategory.fastMana: 99,
            BracketCategory.tutor: 99,
            BracketCategory.freeInteraction: 99,
            BracketCategory.extraTurns: 99,
            BracketCategory.infiniteCombo: 99,
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

  // Game Changers oficiais consomem apenas o budget de Game Changer.
  // Eles nao devem consumir tambem fast mana/tutor/free interaction/etc.
  if (_isOfficialGameChangerName(n)) {
    return BracketTagResult({BracketCategory.gameChanger});
  }

  if (_fastManaNames.contains(n)) {
    categories.add(BracketCategory.fastMana);
  }

  // Alguns terrenos “fast mana”
  if (t.contains('land') && _fastManaLandNames.contains(n)) {
    categories.add(BracketCategory.fastMana);
  }

  // Tutor: heurística direta
  if (o.contains('search your library')) {
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
  if (hasPitch) {
    categories.add(BracketCategory.freeInteraction);
  }

  // Free interaction: 'without paying' (covers Fierce Guardianship, Deflecting Swat)
  if (o.contains('without paying')) {
    categories.add(BracketCategory.freeInteraction);
  }

  // Infinite combos: não dá pra inferir bem só do oracle text.
  // Começa com lista curada (pode evoluir depois).
  if (_knownInfiniteComboPieces.contains(n)) {
    categories.add(BracketCategory.infiniteCombo);
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
    BracketCategory.gameChanger: 0,
  };

  for (final c in cards) {
    final name = (c['name'] as String?) ?? '';
    final typeLine = (c['type_line'] as String?) ?? '';
    final oracle = (c['oracle_text'] as String?) ?? '';
    if (name.isEmpty) continue;

    final qty = (c['quantity'] as int?) ?? 1;
    final tags =
        tagCardForBracket(name: name, typeLine: typeLine, oracleText: oracle);
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

    final tags =
        tagCardForBracket(name: name, typeLine: typeLine, oracleText: oracle);
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
};

const _knownInfiniteComboPieces = <String>{
  // Placeholder inicial (lista curada evolui depois)
  'thassa\'s oracle',
  'demonic consultation',
  'tainted pact',
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

const _gameChangerNames = officialGameChangerNamesForBracketPolicy;

bool _isOfficialGameChangerName(String name) {
  final variants = _normalizedBracketNameVariants(name);
  for (final officialName in _gameChangerNames) {
    final officialVariants = _normalizedBracketNameVariants(officialName);
    if (variants.any(officialVariants.contains)) return true;
  }
  return false;
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
