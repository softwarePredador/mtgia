import 'optimization_functional_roles.dart';

const functionalCardTagsSchemaVersion = 'functional_card_tags_v1_2026_05_18';

const functionalCardTagsV1 = <String>{
  'land',
  'ramp',
  'ritual',
  'draw',
  'loot',
  'tutor',
  'removal',
  'board_wipe',
  'protection',
  'recursion',
  'token_maker',
  'sacrifice_outlet',
  'aristocrat_payoff',
  'lifegain',
  'drain',
  'spellslinger',
  'artifact_synergy',
  'enchantment_synergy',
  'graveyard_synergy',
  'etb',
  'blink',
  'big_spell',
  'exile_value',
};

const deckAnalysisMainFunctionalBuckets = <String>{
  'land',
  'ramp',
  'draw',
  'tutor',
  'removal',
  'board_wipe',
  'protection',
  'recursion',
  'token_maker',
  'sacrifice_outlet',
  'aristocrat_payoff',
  'lifegain',
  'drain',
  'spellslinger',
};

class FunctionalCardTag {
  const FunctionalCardTag({
    required this.tag,
    required this.confidence,
    required this.evidence,
  });

  final String tag;
  final double confidence;
  final String evidence;

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'confidence': double.parse(confidence.toStringAsFixed(3)),
        'evidence': evidence,
      };
}

class FunctionalDeckSummary {
  const FunctionalDeckSummary({
    required this.counts,
    required this.samples,
    required this.cardRows,
    required this.cardCopies,
    required this.taggedRows,
    required this.taggedCopies,
    required this.otherRows,
    required this.otherCopies,
  });

  final Map<String, int> counts;
  final Map<String, List<String>> samples;
  final int cardRows;
  final int cardCopies;
  final int taggedRows;
  final int taggedCopies;
  final int otherRows;
  final int otherCopies;

  int count(String tag) => counts[tag] ?? 0;

  Map<String, dynamic> toJson() => {
        'schema_version': functionalCardTagsSchemaVersion,
        'counts': counts,
        'samples': samples,
        'coverage': {
          'card_rows': cardRows,
          'card_copies': cardCopies,
          'tagged_rows': taggedRows,
          'tagged_copies': taggedCopies,
          'other_rows': otherRows,
          'other_copies': otherCopies,
        },
      };
}

List<FunctionalCardTag> inferFunctionalCardTags({
  required String name,
  required String typeLine,
  required String oracleText,
  String? manaCost,
  Object? cmc,
}) {
  final normalizedName = normalizeFunctionalCardName(name);
  final type = typeLine.toLowerCase();
  final oracle = oracleText.toLowerCase();
  final estimatedCmc = _safeDouble(cmc, _estimateManaValue(manaCost ?? ''));
  final tags = <String, FunctionalCardTag>{};

  void add(String tag, double confidence, String evidence) {
    if (!functionalCardTagsV1.contains(tag)) return;
    final current = tags[tag];
    if (current == null || confidence > current.confidence) {
      tags[tag] = FunctionalCardTag(
        tag: tag,
        confidence: confidence.clamp(0, 1).toDouble(),
        evidence: evidence,
      );
    }
  }

  final isLand = type.contains('land');
  if (isLand) {
    add('land', 1, 'type_line_land');
  }

  final isBasicLand = type.contains('basic land');
  if (!isBasicLand &&
      (looksLikeOptimizationRampText(oracleText) ||
          normalizedName.contains('signet') ||
          normalizedName.contains('talisman') ||
          normalizedName == 'sol ring' ||
          normalizedName == 'arcane signet')) {
    add('ramp', 0.88, 'mana_or_land_ramp_text');
  }

  if (_looksLikeRitual(oracle, normalizedName)) {
    add('ritual', 0.82, 'temporary_mana_burst_text');
  }

  if (_looksLikeDraw(oracle)) {
    add('draw', 0.84, 'card_draw_text');
  }

  if (_looksLikeLoot(oracle)) {
    add('loot', 0.8, 'draw_discard_selection_text');
  }

  if (_looksLikeTutor(oracle)) {
    add('tutor', 0.86, 'non_land_library_search');
  }

  if (_looksLikeTargetedRemoval(oracle)) {
    add('removal', 0.83, 'targeted_interaction_text');
  }

  if (oracle.contains('counter target')) {
    add('removal', 0.72, 'counterspell_is_interaction');
    add('protection', 0.62, 'counterspell_can_protect_plan');
  }

  if (looksLikeOptimizationBoardWipeText(oracleText)) {
    add('board_wipe', 0.9, 'mass_removal_text');
  }

  if (_looksLikeProtection(oracle, normalizedName)) {
    add('protection', 0.82, 'protection_keyword_or_effect');
  }

  if (_looksLikeRecursion(oracle)) {
    add('recursion', 0.86, 'graveyard_return_text');
  }

  if (_looksLikeGraveyardSynergy(oracle)) {
    add('graveyard_synergy', 0.72, 'graveyard_payoff_or_setup_text');
  }

  if (_looksLikeTokenMaker(oracle)) {
    add('token_maker', 0.82, 'token_creation_text');
  }

  if (_looksLikeSacrificeOutlet(oracle)) {
    add('sacrifice_outlet', 0.8, 'repeatable_sacrifice_outlet_text');
  }

  if (_looksLikeAristocratPayoff(oracle, normalizedName)) {
    add('aristocrat_payoff', 0.84, 'death_trigger_payoff_text');
  }

  if (_looksLikeLifegain(oracle)) {
    add('lifegain', 0.76, 'life_gain_text');
  }

  if (_looksLikeDrain(oracle, normalizedName)) {
    add('drain', 0.82, 'life_loss_payoff_text');
  }

  if (_looksLikeSpellslinger(oracle)) {
    add('spellslinger', 0.84, 'instant_sorcery_cast_payoff_text');
  }

  if (_looksLikeArtifactSynergy(oracle)) {
    add('artifact_synergy', 0.74, 'artifact_payoff_text');
  }

  if (_looksLikeEnchantmentSynergy(oracle)) {
    add('enchantment_synergy', 0.74, 'enchantment_payoff_text');
  }

  if (_looksLikeEtb(oracle)) {
    add('etb', 0.7, 'enters_the_battlefield_text');
  }

  if (_looksLikeBlink(oracle, normalizedName)) {
    add('blink', 0.86, 'exile_then_return_text');
    add('protection', 0.68, 'blink_can_protect_permanent');
  }

  if (estimatedCmc >= 6 || _looksLikeBigSpellPayoff(oracle, normalizedName)) {
    add('big_spell', 0.72, 'high_mana_value_or_big_turn_text');
  }

  if (_looksLikeExileValue(oracle)) {
    add('exile_value', 0.84, 'exile_play_or_cast_value_text');
  }

  final ordered = tags.values.toList()
    ..sort((a, b) {
      final byConfidence = b.confidence.compareTo(a.confidence);
      if (byConfidence != 0) return byConfidence;
      return a.tag.compareTo(b.tag);
    });
  return ordered;
}

FunctionalDeckSummary summarizeFunctionalTagsForDeck(
  Iterable<Map<String, dynamic>> cards, {
  int sampleLimit = 5,
  double minConfidence = 0.65,
  Set<String> countedTags = deckAnalysisMainFunctionalBuckets,
}) {
  final counts = <String, int>{
    for (final tag in countedTags) tag: 0,
  };
  final samples = <String, List<String>>{
    for (final tag in countedTags) tag: <String>[],
  };

  var cardRows = 0;
  var cardCopies = 0;
  var taggedRows = 0;
  var taggedCopies = 0;
  var otherRows = 0;
  var otherCopies = 0;

  for (final card in cards) {
    cardRows++;
    final name = ((card['name'] as String?) ?? '').trim();
    final qty = ((card['quantity'] as int?) ?? 1).clamp(0, 999).toInt();
    cardCopies += qty;
    final tags = inferFunctionalCardTags(
      name: name,
      typeLine: (card['type_line'] as String?) ?? '',
      oracleText: (card['oracle_text'] as String?) ?? '',
      manaCost: card['mana_cost'] as String?,
      cmc: card['cmc'],
    )
        .where((tag) =>
            countedTags.contains(tag.tag) && tag.confidence >= minConfidence)
        .map((tag) => tag.tag)
        .toSet();

    if (tags.isEmpty) {
      otherRows++;
      otherCopies += qty;
      continue;
    }

    taggedRows++;
    taggedCopies += qty;
    for (final tag in tags) {
      counts[tag] = (counts[tag] ?? 0) + qty;
      final tagSamples = samples[tag] ?? <String>[];
      if (name.isNotEmpty &&
          tagSamples.length < sampleLimit &&
          !tagSamples.contains(name)) {
        tagSamples.add(name);
        samples[tag] = tagSamples;
      }
    }
  }

  return FunctionalDeckSummary(
    counts: counts,
    samples: samples,
    cardRows: cardRows,
    cardCopies: cardCopies,
    taggedRows: taggedRows,
    taggedCopies: taggedCopies,
    otherRows: otherRows,
    otherCopies: otherCopies,
  );
}

String normalizeFunctionalCardName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _looksLikeDraw(String oracle) {
  if (oracle.contains('target opponent draws') ||
      oracle.contains('an opponent draws') ||
      oracle.contains('each opponent draws')) {
    return false;
  }
  return oracle.contains('draw a card') ||
      oracle.contains('draw two cards') ||
      oracle.contains('draw three cards') ||
      oracle.contains('draw cards') ||
      oracle.contains('draw x cards') ||
      oracle.contains('draw that many cards') ||
      oracle.contains('draw equal to') ||
      oracle.contains('whenever') && oracle.contains('draw a card') ||
      oracle.contains('reveal') &&
          oracle.contains('put') &&
          oracle.contains('into your hand');
}

bool _looksLikeLoot(String oracle) {
  return oracle.contains('draw') &&
          (oracle.contains('discard a card') ||
              oracle.contains('discard that many') ||
              oracle.contains('then discard')) ||
      oracle.contains('discard') && oracle.contains('then draw');
}

bool _looksLikeTutor(String oracle) {
  return oracle.contains('search your library') &&
      !oracle.contains('basic land') &&
      !oracle.contains('land card') &&
      (oracle.contains('put') ||
          oracle.contains('reveal') ||
          oracle.contains('card'));
}

bool _looksLikeTargetedRemoval(String oracle) {
  final targetsOwnPermanent = oracle.contains('target creature you control') ||
      oracle.contains('target permanent you control') ||
      oracle.contains('target artifact you control') ||
      oracle.contains('target enchantment you control');
  if (targetsOwnPermanent) return false;

  return oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('return target') && oracle.contains('to its owner') ||
      oracle.contains('target') &&
          oracle.contains('gets -') &&
          oracle.contains('/-') ||
      oracle.contains('deals') &&
          oracle.contains('damage') &&
          (oracle.contains('target creature') ||
              oracle.contains('target planeswalker') ||
              oracle.contains('any target') ||
              oracle.contains('damage to target'));
}

bool _looksLikeProtection(String oracle, String normalizedName) {
  return oracle.contains('hexproof') ||
      oracle.contains('indestructible') ||
      oracle.contains('protection from') ||
      oracle.contains('shroud') ||
      oracle.contains('phase out') ||
      oracle.contains('gain protection') ||
      normalizedName.contains('teferi\'s protection') ||
      normalizedName.contains('heroic intervention') ||
      normalizedName.contains('swiftfoot boots') ||
      normalizedName.contains('lightning greaves');
}

bool _looksLikeRecursion(String oracle) {
  return (oracle.contains('from your graveyard') ||
          oracle.contains('from a graveyard') ||
          oracle.contains('from graveyard')) &&
      (oracle.contains('return') ||
          oracle.contains('put target') ||
          oracle.contains('cast') ||
          oracle.contains('onto the battlefield') ||
          oracle.contains('to your hand'));
}

bool _looksLikeGraveyardSynergy(String oracle) {
  return oracle.contains('graveyard') ||
      oracle.contains('mill') ||
      oracle.contains('escape') ||
      oracle.contains('disturb') ||
      oracle.contains('dredge') ||
      oracle.contains('flashback');
}

bool _looksLikeTokenMaker(String oracle) {
  return oracle.contains('create') && oracle.contains('token') ||
      oracle.contains('populate');
}

bool _looksLikeSacrificeOutlet(String oracle) {
  return oracle.contains('sacrifice another') ||
      oracle.contains('sacrifice a creature:') ||
      oracle.contains('sacrifice a permanent:') ||
      oracle.contains('sacrifice an artifact:') ||
      oracle.contains('sacrifice a token:') ||
      oracle.contains('{t}, sacrifice');
}

bool _looksLikeAristocratPayoff(String oracle, String normalizedName) {
  return normalizedName == 'blood artist' ||
      normalizedName == 'zulaport cutthroat' ||
      oracle.contains('whenever') &&
          oracle.contains('creature') &&
          oracle.contains('dies') &&
          (oracle.contains('loses') ||
              oracle.contains('gain') ||
              oracle.contains('drain')) ||
      oracle.contains('whenever you sacrifice') &&
          (oracle.contains('loses') || oracle.contains('gain'));
}

bool _looksLikeLifegain(String oracle) {
  return oracle.contains('you gain') && oracle.contains('life') ||
      oracle.contains('gain life') ||
      oracle.contains('gains you') && oracle.contains('life');
}

bool _looksLikeDrain(String oracle, String normalizedName) {
  return normalizedName == 'blood artist' ||
      oracle.contains('loses') && oracle.contains('you gain') ||
      oracle.contains('each opponent loses') ||
      oracle.contains('target player loses');
}

bool _looksLikeSpellslinger(String oracle) {
  return oracle.contains('instant or sorcery') ||
      oracle.contains('magecraft') ||
      oracle.contains('whenever you cast or copy') ||
      oracle.contains('whenever you cast') &&
          (oracle.contains('instant') || oracle.contains('sorcery'));
}

bool _looksLikeArtifactSynergy(String oracle) {
  if (!oracle.contains('artifact')) return false;
  return oracle.contains('whenever') ||
      oracle.contains('for each artifact') ||
      oracle.contains('artifacts you control') ||
      oracle.contains('artifact enters') ||
      oracle.contains('sacrifice an artifact');
}

bool _looksLikeEnchantmentSynergy(String oracle) {
  if (!oracle.contains('enchantment')) return false;
  return oracle.contains('whenever') ||
      oracle.contains('for each enchantment') ||
      oracle.contains('enchantments you control') ||
      oracle.contains('enchantment enters');
}

bool _looksLikeEtb(String oracle) {
  if (!oracle.contains('enters the battlefield')) return false;
  if (oracle.contains("don't cause abilities to trigger") ||
      oracle.contains('abilities don\'t trigger')) {
    return false;
  }
  return oracle.contains('when ') ||
      oracle.contains('whenever ') ||
      oracle.contains('as ') ||
      oracle.contains('enters the battlefield,');
}

bool _looksLikeBlink(String oracle, String normalizedName) {
  return normalizedName == 'ephemerate' ||
      oracle.contains('exile target') &&
          oracle.contains('return') &&
          oracle.contains('battlefield') ||
      oracle.contains('exile another target') &&
          oracle.contains('return') &&
          oracle.contains('battlefield') ||
      oracle.contains('flicker');
}

bool _looksLikeBigSpellPayoff(String oracle, String normalizedName) {
  return normalizedName == 'jeska\'s will' ||
      oracle.contains('if you control a commander') ||
      oracle.contains('without paying its mana cost') ||
      oracle.contains('copy target spell') ||
      oracle.contains('copy it') && oracle.contains('spell');
}

bool _looksLikeExileValue(String oracle) {
  return oracle.contains('exile') &&
      (oracle.contains('may play') ||
          oracle.contains('may cast') ||
          oracle.contains('until the end of your next turn') ||
          oracle.contains('until end of turn'));
}

bool _looksLikeRitual(String oracle, String normalizedName) {
  return normalizedName == 'jeska\'s will' ||
      oracle.contains('add {') &&
          (oracle.contains('until end of turn') ||
              oracle.contains('for each') ||
              oracle.contains('for every') ||
              oracle.contains('your mana pool'));
}

double _estimateManaValue(String manaCost) {
  if (manaCost.trim().isEmpty) return 0;
  var total = 0.0;
  for (final match in RegExp(r'\{([^}]+)\}').allMatches(manaCost)) {
    final symbol = (match.group(1) ?? '').trim().toUpperCase();
    if (symbol.isEmpty || symbol == 'X') continue;
    final numeric = int.tryParse(symbol);
    if (numeric != null) {
      total += numeric;
      continue;
    }
    if (symbol.contains('/')) {
      final parts = symbol.split('/');
      var hybrid = 1.0;
      for (final part in parts) {
        final parsed = int.tryParse(part);
        if (parsed != null && parsed > hybrid) hybrid = parsed.toDouble();
      }
      total += hybrid;
      continue;
    }
    total += 1;
  }
  return total;
}

double _safeDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
