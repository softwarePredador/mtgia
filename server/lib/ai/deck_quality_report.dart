/// Deterministic MANA-CONSISTENCY scoring for Commander decks.
///
/// WHAT THIS MEASURES, AND WHAT IT DOES NOT. `consistency_score` comes from
/// `GoldfishSimulator` and is a function of opening-hand keepability, early
/// plays, mana screw and flood. It says nothing about interaction density,
/// card advantage, win conditions, synergy or power level. A deck of 36
/// Forest plus 64 identical vanilla two-drops scores 84 with zero issues --
/// tying the best real deck in the committed fixture. Treat this as a mana
/// foundation signal and a regression detector, never as a verdict on how
/// good a deck is. `deck_quality_report_limits_test.dart` pins that example
/// so the limitation cannot be forgotten.
///
/// Why this exists: deck generation had no quality measurement at all. The
/// `ai-eval` suite scores a response that is stored inside its own fixture,
/// so it passes regardless of what the generator produces. Without a score
/// that is a pure function of a real 100-card deck, no change to generation
/// -- and no future learning loop -- can be shown to help rather than hurt.
///
/// Design constraints, in order of importance:
///  1. DETERMINISTIC. `GoldfishSimulator` seeds itself from a stable deck
///     hash, so the same deck always yields the same score. That is what
///     makes a committed baseline meaningful instead of flaky.
///  2. PURE. No network, no LLM, no database. Input is a card list; output
///     is a report map.
///  3. STRUCTURED. Issues are emitted as stable codes, never prose, so a
///     baseline diff is machine-comparable and translatable.
///
/// This reuses existing engine code rather than reimplementing judgement:
/// `GoldfishSimulator` for the consistency score and curve, and
/// `commander_mana_floor.dart` for the land and colour-source floors.
library;

import '../basic_land_utils.dart' as basic_lands;
import '../commander_mana_floor.dart';
import 'cmc_safety.dart';
import 'goldfish_simulator.dart';

const deckQualityReportSchemaVersion = 'deck_quality_report_v1';

/// Colours in a fixed order so every emitted map is byte-stable.
const _colors = <String>['W', 'U', 'B', 'R', 'G'];

/// A single strict coloured pip, e.g. `{U}`. Hybrid (`{W/U}`), phyrexian
/// (`{U/P}`) and generic (`{2}`) are deliberately excluded: they do not
/// create the same colour pressure, and counting them as strict would
/// overstate how many sources a deck needs.
final _strictPipPattern = RegExp(r'\{([WUBRG])\}');

/// Any coloured symbol appearing in a cost, used to detect the flexible ones.
final _anySymbolPattern = RegExp(r'\{([^}]+)\}');

/// Colour symbols that a land actually ADDS. Scoped to an "Add ..." clause on
/// purpose: scanning the whole oracle text counted symbols from activation
/// costs, cycling costs and reminder text as if they were mana production.
/// That over-counts sources, which makes the report understate a broken mana
/// base -- the direction a gate must never fail in.
final _addClausePattern = RegExp(
  r'\badds?\b[^.;\n]*',
  caseSensitive: false,
);
final _oracleColorPattern = RegExp(r'\{([WUBRGwubrg])\}');

/// Phrases that make a land an any-colour source. Kept narrow on purpose --
/// a false positive here silently inflates fixing and hides a real problem.
final _anyColorPattern = RegExp(
  r'add\s+(one\s+mana\s+of\s+any\s+color'
  r'|mana\s+of\s+any\s+color'
  r'|one\s+mana\s+of\s+any\s+one\s+color)',
  caseSensitive: false,
);

/// Basic land SUBTYPES, matched against `type_line` -- never against the card
/// name. Name matching is unsafe: "Misty Rainforest" is a fetchland that
/// produces no mana at all, and "Cori Mountain Monastery" is a utility land;
/// both would otherwise be counted as coloured sources and would make the
/// report understate a broken mana base.
const _basicLandSubtypes = <String, String>{
  'plains': 'W',
  'island': 'U',
  'swamp': 'B',
  'mountain': 'R',
  'forest': 'G',
};

/// Extracts the colours a basic land produces from its type line subtypes.
/// Returns empty for anything that is not a basic land.
Set<String> _basicLandColors(String typeLine) {
  if (!basic_lands.isBasicLandTypeLine(typeLine)) return const {};
  final normalized = typeLine.toLowerCase();
  return {
    for (final entry in _basicLandSubtypes.entries)
      if (normalized.contains(entry.key)) entry.value,
  };
}

int _quantityOf(Map<String, dynamic> card) {
  final raw = card['quantity'];
  final parsed =
      raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : 1;
}

String _textOf(Map<String, dynamic> card, String key) =>
    card[key]?.toString() ?? '';

bool _isLand(Map<String, dynamic> card) =>
    basic_lands.isLandTypeLine(_textOf(card, 'type_line'));

/// Counts strict coloured pips across all non-land cards, weighted by
/// quantity. Also reports how many flexible symbols were skipped, so a deck
/// built on hybrid mana is visibly different from one with no colour
/// requirements at all.
({Map<String, int> strict, int flexible}) _countPips(
  List<Map<String, dynamic>> cards,
) {
  final strict = <String, int>{for (final c in _colors) c: 0};
  var flexible = 0;

  for (final card in cards) {
    if (_isLand(card)) continue;
    final cost = _textOf(card, 'mana_cost');
    if (cost.isEmpty) continue;
    final quantity = _quantityOf(card);

    for (final match in _strictPipPattern.allMatches(cost)) {
      strict[match.group(1)!] = strict[match.group(1)!]! + quantity;
    }
    for (final match in _anySymbolPattern.allMatches(cost)) {
      final symbol = match.group(1)!.toUpperCase();
      final isStrict = symbol.length == 1 && _colors.contains(symbol);
      final isGeneric = int.tryParse(symbol) != null;
      if (!isStrict && !isGeneric && symbol.contains('/')) {
        flexible += quantity;
      }
    }
  }

  return (strict: strict, flexible: flexible);
}

/// Counts colour sources among lands. `Any` is tracked separately because it
/// satisfies every colour and must be added to each colour's total rather
/// than double-counted into one.
Map<String, int> _countColorSources(List<Map<String, dynamic>> cards) {
  final sources = <String, int>{for (final c in _colors) c: 0, 'Any': 0};

  for (final card in cards) {
    if (!_isLand(card)) continue;
    final quantity = _quantityOf(card);
    final oracle = _textOf(card, 'oracle_text');

    final basicColors = _basicLandColors(_textOf(card, 'type_line'));
    if (basicColors.isNotEmpty) {
      for (final color in basicColors) {
        sources[color] = sources[color]! + quantity;
      }
      continue;
    }

    if (_anyColorPattern.hasMatch(oracle)) {
      sources['Any'] = sources['Any']! + quantity;
      continue;
    }

    final produced = <String>{
      for (final clause in _addClausePattern.allMatches(oracle))
        for (final match in _oracleColorPattern.allMatches(clause.group(0)!))
          match.group(1)!.toUpperCase(),
    };
    for (final color in produced) {
      sources[color] = (sources[color] ?? 0) + quantity;
    }
  }

  return sources;
}

/// Builds a deterministic quality report for one Commander deck.
///
/// [cards] must be the full 100-card list, each entry carrying at least
/// `name`, `quantity` and `type_line`; `mana_cost`, `cmc` and `oracle_text`
/// sharpen the result and their absence degrades gracefully (and is
/// reported via `data_quality`).
Map<String, dynamic> buildDeckQualityReport({
  required List<Map<String, dynamic>> cards,
  String format = 'commander',
  int simulations = 1000,
}) {
  // GoldfishSimulator reads quantity with a hard cast (`as int?`), so a deck
  // carrying `36.0` would crash it with a TypeError. A gate that crashes is
  // worse than one that fails: the exit code and message stop being readable.
  // Normalise first, and count the coercions so bad input stays visible
  // instead of being silently laundered.
  var coercedQuantities = 0;
  final normalized = <Map<String, dynamic>>[];
  for (final card in cards) {
    final raw = card['quantity'];
    if (raw is int || raw == null) {
      normalized.add(card);
      continue;
    }
    coercedQuantities++;
    normalized.add({...card, 'quantity': _quantityOf(card)});
  }

  final simulation =
      GoldfishSimulator(normalized, simulations: simulations).simulate();
  final floor = assessCommanderManaFloor(format: format, cards: normalized);

  final pips = _countPips(normalized);
  final sources = _countColorSources(normalized);
  final totalPips = pips.strict.values.fold<int>(0, (a, b) => a + b);

  final dominantFloor = dominantColorSourceFloorForFormat(format);
  final secondaryFloor = secondaryColorSourceFloorForFormat(format);
  final anySources = sources['Any'] ?? 0;

  // Modal double-faced cards whose BACK face is a land (Emeria's Call //
  // Emeria, Shattered Skyclave) arrive with only their front-face type line,
  // because neither deck_cards nor card_oracle_cache stores the back face.
  // They are therefore counted as spells and the land count is understated.
  // The data to fix this does not exist locally, so the uncertainty is
  // surfaced rather than hidden: a land_count_below_minimum on a deck with a
  // non-zero count here may be an artifact.
  final possibleBackFaceLands = normalized
      .where((card) => _textOf(card, 'name').contains('//') && !_isLand(card))
      .fold<int>(0, (sum, card) => sum + _quantityOf(card));

  // Stable, machine-comparable issue codes. Prose belongs in the UI layer.
  final issues = <Map<String, dynamic>>[];

  if (!floor.meetsMinimum) {
    issues.add({
      'code': 'land_count_below_minimum',
      'land_count': floor.landCount,
      'minimum': floor.minimumLandCount,
      'possible_back_face_lands': possibleBackFaceLands,
    });
  }
  if (floor.hasSevereExcess) {
    issues.add({
      'code': 'land_count_severe_excess',
      'land_count': floor.landCount,
      'threshold': floor.severeExcessLandCount,
    });
  }

  final colorRequirements = <Map<String, dynamic>>[];
  for (final color in _colors) {
    final pipCount = pips.strict[color]!;
    if (pipCount <= 0) continue;
    final share = totalPips == 0 ? 0.0 : pipCount / totalPips;
    final available = (sources[color] ?? 0) + anySources;
    // Thresholds mirror deck_state_analysis.dart: a colour carrying more
    // than 30% of the pips is dominant and needs the higher floor.
    final required = share > 0.30 ? dominantFloor : (share > 0.10 ? secondaryFloor : 0);

    colorRequirements.add({
      'color': color,
      'pips': pipCount,
      'pip_share': double.parse(share.toStringAsFixed(4)),
      'sources': sources[color] ?? 0,
      'sources_with_any': available,
      'required_sources': required,
      'satisfied': available >= required,
    });

    if (required > 0 && available < required) {
      issues.add({
        'code': 'insufficient_color_sources',
        'color': color,
        'pip_share': double.parse(share.toStringAsFixed(4)),
        'sources_with_any': available,
        'required_sources': required,
      });
    }
  }

  // Data-quality signals: a deck can score well simply because the input was
  // too thin to reveal a problem. Surface that instead of hiding it.
  final nonLands = normalized.where((c) => !_isLand(c)).toList();
  final missingManaCost =
      nonLands.where((c) => _textOf(c, 'mana_cost').isEmpty).length;
  final suspiciousCmc = nonLands.where(hasSuspiciousNonLandCmc).length;

  return {
    'schema_version': deckQualityReportSchemaVersion,
    'format': format,
    'card_count': floor.totalCardCount,
    'consistency_score': simulation.consistencyScore,
    'mana_foundation': {
      'land_count': floor.landCount,
      'minimum_land_count': floor.minimumLandCount,
      'severe_excess_land_count': floor.severeExcessLandCount,
      'satisfied': floor.satisfied,
    },
    'color_requirements': colorRequirements,
    'total_strict_pips': totalPips,
    'flexible_pips': pips.flexible,
    'any_color_sources': anySources,
    'simulation': simulation.toJson(),
    'issues': issues,
    'issue_codes': [for (final issue in issues) issue['code'] as String]..sort(),
    'data_quality': {
      'nonland_cards': nonLands.length,
      'nonland_missing_mana_cost': missingManaCost,
      'nonland_suspicious_cmc': suspiciousCmc,
      'coerced_quantities': coercedQuantities,
      'possible_back_face_lands': possibleBackFaceLands,
    },
  };
}
