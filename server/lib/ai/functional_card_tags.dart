import 'optimization_functional_roles.dart';

const functionalCardTagsSchemaVersion = 'functional_card_tags_v1_2026_05_18';
const semanticLayerV2SchemaVersion = 'semantic_layer_v2_2026_05_18';
const semanticLayerV2Source = 'deterministic_semantic_v2';

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
  'combo_piece',
  'wincon',
  'engine',
  'payoff',
  'enabler',
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
  'wincon',
  'engine',
  'payoff',
  'enabler',
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
    required this.sampleDetails,
    required this.cardRows,
    required this.cardCopies,
    required this.taggedRows,
    required this.taggedCopies,
    required this.otherRows,
    required this.otherCopies,
    this.persistedRows = 0,
    this.persistedCopies = 0,
    this.heuristicRows = 0,
    this.heuristicCopies = 0,
  });

  final Map<String, int> counts;
  final Map<String, List<String>> samples;
  final Map<String, List<Map<String, dynamic>>> sampleDetails;
  final int cardRows;
  final int cardCopies;
  final int taggedRows;
  final int taggedCopies;
  final int otherRows;
  final int otherCopies;
  final int persistedRows;
  final int persistedCopies;
  final int heuristicRows;
  final int heuristicCopies;

  int count(String tag) => counts[tag] ?? 0;

  Map<String, dynamic> toJson() => {
        'schema_version': functionalCardTagsSchemaVersion,
        'semantic_schema_version': semanticLayerV2SchemaVersion,
        'counts': counts,
        'samples': samples,
        'sample_details': sampleDetails,
        'coverage': {
          'card_rows': cardRows,
          'card_copies': cardCopies,
          'tagged_rows': taggedRows,
          'tagged_copies': taggedCopies,
          'other_rows': otherRows,
          'other_copies': otherCopies,
        },
        'source': {
          'priority': 'functional_tags_then_semantic_v2_then_heuristic',
          'persisted_rows': persistedRows,
          'persisted_copies': persistedCopies,
          'heuristic_rows': heuristicRows,
          'heuristic_copies': heuristicCopies,
        },
      };
}

class SemanticCardAnalysisV2 {
  const SemanticCardAnalysisV2({
    required this.tags,
    required this.speed,
    required this.manaEfficiency,
    required this.cardAdvantageType,
    required this.interactionScope,
    required this.comboPiece,
    required this.wincon,
    required this.engine,
    required this.payoff,
    required this.enabler,
    required this.protectionType,
    required this.recursionType,
    required this.roleConfidence,
    required this.explanationReason,
    this.source = semanticLayerV2Source,
  });

  final List<FunctionalCardTag> tags;
  final String speed;
  final String manaEfficiency;
  final String cardAdvantageType;
  final String interactionScope;
  final bool comboPiece;
  final bool wincon;
  final bool engine;
  final bool payoff;
  final bool enabler;
  final String protectionType;
  final String recursionType;
  final double roleConfidence;
  final String explanationReason;
  final String source;

  Map<String, dynamic> toJson() => {
        'schema_version': semanticLayerV2SchemaVersion,
        'source': source,
        'tags': tags.map((tag) => tag.toJson()).toList(growable: false),
        'speed': speed,
        'mana_efficiency': manaEfficiency,
        'card_advantage_type': cardAdvantageType,
        'interaction_scope': interactionScope,
        'combo_piece': comboPiece,
        'wincon': wincon,
        'engine': engine,
        'payoff': payoff,
        'enabler': enabler,
        'protection_type': protectionType,
        'recursion_type': recursionType,
        'role_confidence': double.parse(roleConfidence.toStringAsFixed(3)),
        'explanation_reason': explanationReason,
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
  final strategicRoles = resolveCardFunctionalRoles(
    oracleText: oracleText,
    typeLine: typeLine,
    name: name,
    manaCost: manaCost,
    cmc: cmc,
  ).roles;
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

  if (strategicRoles.contains('wincon')) {
    add('wincon', 0.78, 'explicit_win_or_finisher_text');
  }

  if (strategicRoles.contains('combo_piece')) {
    // Heurística propositalmente abaixo do limiar operacional (0.65):
    // combo_piece de alta confiança vem de card_function_tags persistido pelo
    // Commander Spellbook (sync_combos.dart), reduzindo falso positivo textual.
    add('combo_piece', 0.60, 'combo_pattern_text_or_known_name');
  }

  if (strategicRoles.contains('engine')) {
    add('engine', 0.7, 'repeatable_value_engine_text');
  }

  if (strategicRoles.contains('payoff')) {
    add('payoff', 0.72, 'payoff_trigger_or_scaling_text');
  }

  if (strategicRoles.contains('enabler')) {
    add('enabler', 0.7, 'plan_enabler_or_setup_text');
  }

  final ordered = tags.values.toList()
    ..sort((a, b) {
      final byConfidence = b.confidence.compareTo(a.confidence);
      if (byConfidence != 0) return byConfidence;
      return a.tag.compareTo(b.tag);
    });
  return ordered;
}

SemanticCardAnalysisV2 inferSemanticCardAnalysisV2({
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
  final tags = inferFunctionalCardTags(
    name: name,
    typeLine: typeLine,
    oracleText: oracleText,
    manaCost: manaCost,
    cmc: cmc,
  );
  final tagNames = tags.map((tag) => tag.tag).toSet();
  final roleConfidence = tags.isEmpty
      ? 0.0
      : tags
          .map((tag) => tag.confidence)
          .reduce((value, element) => value > element ? value : element);

  return SemanticCardAnalysisV2(
    tags: tags,
    speed: _inferSpeed(type, oracle),
    manaEfficiency: _inferManaEfficiency(estimatedCmc),
    cardAdvantageType: _inferCardAdvantageType(tagNames, oracle),
    interactionScope: _inferInteractionScope(tagNames, oracle),
    comboPiece: tagNames.contains('combo_piece'),
    wincon: tagNames.contains('wincon'),
    engine: tagNames.contains('engine'),
    payoff: tagNames.contains('payoff') ||
        tagNames.contains('aristocrat_payoff') ||
        tagNames.contains('spellslinger'),
    enabler: tagNames.contains('enabler') ||
        tagNames.contains('ramp') ||
        tagNames.contains('loot') ||
        tagNames.contains('tutor'),
    protectionType: _inferProtectionType(
      oracle: oracle,
      normalizedName: normalizedName,
      tagNames: tagNames,
    ),
    recursionType: _inferRecursionType(oracle, tagNames),
    roleConfidence: roleConfidence,
    explanationReason: _buildSemanticExplanationReason(tagNames),
  );
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
  final sampleDetails = <String, List<Map<String, dynamic>>>{
    for (final tag in countedTags) tag: <Map<String, dynamic>>[],
  };

  var cardRows = 0;
  var cardCopies = 0;
  var taggedRows = 0;
  var taggedCopies = 0;
  var otherRows = 0;
  var otherCopies = 0;
  var persistedRows = 0;
  var persistedCopies = 0;
  var heuristicRows = 0;
  var heuristicCopies = 0;

  for (final card in cards) {
    cardRows++;
    final name = ((card['name'] as String?) ?? '').trim();
    final qty = ((card['quantity'] as int?) ?? 1).clamp(0, 999).toInt();
    cardCopies += qty;
    final persistedTags = _readPersistedFunctionalTags(
      card['functional_tags'],
      countedTags: countedTags,
      minConfidence: minConfidence,
    );
    final persistedSemanticV2 =
        _readPersistedSemanticV2(card['semantic_tags_v2']);
    final semanticV2 = persistedSemanticV2 ??
        inferSemanticCardAnalysisV2(
          name: name,
          typeLine: (card['type_line'] as String?) ?? '',
          oracleText: (card['oracle_text'] as String?) ?? '',
          manaCost: card['mana_cost'] as String?,
          cmc: card['cmc'],
        );
    final inferredTags = inferFunctionalCardTags(
      name: name,
      typeLine: (card['type_line'] as String?) ?? '',
      oracleText: (card['oracle_text'] as String?) ?? '',
      manaCost: card['mana_cost'] as String?,
      cmc: card['cmc'],
    )
        .where((tag) =>
            countedTags.contains(tag.tag) && tag.confidence >= minConfidence)
        .toList(growable: false);
    final semanticV2Tags = persistedSemanticV2?.tags
            .where((tag) =>
                countedTags.contains(tag.tag) &&
                tag.confidence >= minConfidence)
            .toList(growable: false) ??
        const <FunctionalCardTag>[];
    final tagObjects = persistedTags.isNotEmpty
        ? persistedTags
            .map((tag) => FunctionalCardTag(
                  tag: tag,
                  confidence: semanticV2.roleConfidence > 0
                      ? semanticV2.roleConfidence
                      : 0.75,
                  evidence: semanticV2.explanationReason,
                ))
            .toList(growable: false)
        : semanticV2Tags.isNotEmpty
            ? semanticV2Tags
            : inferredTags;
    final tags = tagObjects.map((tag) => tag.tag).toSet();

    if (persistedTags.isNotEmpty || semanticV2Tags.isNotEmpty) {
      persistedRows++;
      persistedCopies += qty;
    } else {
      heuristicRows++;
      heuristicCopies += qty;
    }

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
        final details = sampleDetails[tag] ?? <Map<String, dynamic>>[];
        if (details.length < sampleLimit) {
          final tagObject = tagObjects.firstWhere(
            (candidate) => candidate.tag == tag,
            orElse: () => FunctionalCardTag(
              tag: tag,
              confidence: semanticV2.roleConfidence,
              evidence: semanticV2.explanationReason,
            ),
          );
          details.add(_buildFunctionalSampleDetail(
            name: name,
            tag: tagObject,
            semantic: semanticV2,
          ));
          sampleDetails[tag] = details;
        }
      }
    }
  }

  return FunctionalDeckSummary(
    counts: counts,
    samples: samples,
    sampleDetails: sampleDetails,
    cardRows: cardRows,
    cardCopies: cardCopies,
    taggedRows: taggedRows,
    taggedCopies: taggedCopies,
    otherRows: otherRows,
    otherCopies: otherCopies,
    persistedRows: persistedRows,
    persistedCopies: persistedCopies,
    heuristicRows: heuristicRows,
    heuristicCopies: heuristicCopies,
  );
}

Set<String> _readPersistedFunctionalTags(
  Object? value, {
  required Set<String> countedTags,
  required double minConfidence,
}) {
  if (value is! Iterable) return const <String>{};
  final tags = <String>{};
  for (final raw in value) {
    if (raw is String) {
      if (countedTags.contains(raw)) tags.add(raw);
      continue;
    }
    if (raw is! Map) continue;
    final tag = (raw['tag'] as String?)?.trim();
    if (tag == null || !countedTags.contains(tag)) continue;
    final confidence = _safeDouble(raw['confidence'], 1);
    if (confidence >= minConfidence) tags.add(tag);
  }
  return tags;
}

SemanticCardAnalysisV2? _readPersistedSemanticV2(Object? value) {
  if (value is! Iterable) return null;
  Map? selected;
  for (final raw in value) {
    if (raw is! Map) continue;
    final confidence = _safeDouble(raw['role_confidence'], 0);
    final currentConfidence =
        selected == null ? -1.0 : _safeDouble(selected['role_confidence'], 0);
    if (confidence > currentConfidence) selected = raw;
  }
  if (selected == null) return null;

  final rawTags = selected['tags'];
  final tags = <FunctionalCardTag>[];
  if (rawTags is Iterable) {
    for (final rawTag in rawTags) {
      if (rawTag is String && functionalCardTagsV1.contains(rawTag)) {
        tags.add(FunctionalCardTag(
          tag: rawTag,
          confidence: _safeDouble(selected['role_confidence'], 0.75),
          evidence: selected['explanation_reason']?.toString() ??
              'persisted_semantic_v2',
        ));
      } else if (rawTag is Map) {
        final tag = rawTag['tag']?.toString().trim();
        if (tag == null || !functionalCardTagsV1.contains(tag)) continue;
        tags.add(FunctionalCardTag(
          tag: tag,
          confidence: _safeDouble(rawTag['confidence'],
              _safeDouble(selected['role_confidence'], 0.75)),
          evidence: rawTag['evidence']?.toString() ??
              selected['explanation_reason']?.toString() ??
              'persisted_semantic_v2',
        ));
      }
    }
  }

  return SemanticCardAnalysisV2(
    tags: tags,
    speed: selected['speed']?.toString() ?? 'unknown',
    manaEfficiency: selected['mana_efficiency']?.toString() ?? 'unknown',
    cardAdvantageType: selected['card_advantage_type']?.toString() ?? 'none',
    interactionScope: selected['interaction_scope']?.toString() ?? 'none',
    comboPiece: selected['combo_piece'] == true,
    wincon: selected['wincon'] == true,
    engine: selected['engine'] == true,
    payoff: selected['payoff'] == true,
    enabler: selected['enabler'] == true,
    protectionType: selected['protection_type']?.toString() ?? 'none',
    recursionType: selected['recursion_type']?.toString() ?? 'none',
    roleConfidence: _safeDouble(selected['role_confidence'], 0),
    explanationReason:
        selected['explanation_reason']?.toString() ?? 'persisted_semantic_v2',
    source: selected['source']?.toString() ?? semanticLayerV2Source,
  );
}

Map<String, dynamic> _buildFunctionalSampleDetail({
  required String name,
  required FunctionalCardTag tag,
  required SemanticCardAnalysisV2 semantic,
}) {
  return {
    'name': name,
    'tag': tag.tag,
    'role': tag.tag,
    'reason': _friendlyFunctionalTagReason(tag.tag, semantic),
    'evidence': tag.evidence,
    'confidence': double.parse(tag.confidence.toStringAsFixed(3)),
    'semantic_schema_version': semanticLayerV2SchemaVersion,
    'speed': semantic.speed,
    'mana_efficiency': semantic.manaEfficiency,
    if (semantic.cardAdvantageType != 'none')
      'card_advantage_type': semantic.cardAdvantageType,
    if (semantic.interactionScope != 'none')
      'interaction_scope': semantic.interactionScope,
    if (semantic.protectionType != 'none')
      'protection_type': semantic.protectionType,
    if (semantic.recursionType != 'none')
      'recursion_type': semantic.recursionType,
  };
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
      RegExp(
        r'\bdraw (?:one|two|three|four|five|six|seven|eight|nine|ten|\d+) cards\b',
      ).hasMatch(oracle) ||
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
      !looksLikeOptimizationLandSearchText(oracle) &&
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
      oracle.contains('ward') ||
      oracle.contains('phase out') ||
      oracle.contains('gain protection') ||
      oracle.contains("can't be the target") ||
      oracle.contains('cannot be the target') ||
      oracle.contains('prevent all damage') ||
      oracle.contains('regenerate target') ||
      oracle.contains('gains hexproof') ||
      oracle.contains('gains indestructible') ||
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
  if (oracle.contains("can't gain life") ||
      oracle.contains('cannot gain life') ||
      oracle.contains('players can\'t gain life') ||
      oracle.contains('opponents can\'t gain life')) {
    return false;
  }
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

String _inferSpeed(String typeLine, String oracle) {
  if (typeLine.contains('instant') || oracle.contains('flash')) {
    return 'instant_speed';
  }
  if (typeLine.contains('land')) return 'land_drop';
  if (typeLine.contains('sorcery')) return 'sorcery_speed';
  if (oracle.contains('whenever') || oracle.contains('at the beginning')) {
    return 'triggered_engine';
  }
  return 'board_speed';
}

String _inferManaEfficiency(double cmc) {
  if (cmc <= 0) return 'free_or_land';
  if (cmc <= 1) return 'one_mana';
  if (cmc <= 2) return 'cheap';
  if (cmc <= 3) return 'efficient';
  if (cmc <= 5) return 'fair';
  return 'expensive';
}

String _inferCardAdvantageType(Set<String> tags, String oracle) {
  if (tags.contains('draw')) return 'draw';
  if (tags.contains('loot')) return 'selection';
  if (tags.contains('tutor')) return 'tutor';
  if (tags.contains('exile_value')) return 'impulse';
  if (tags.contains('recursion')) return 'recursion';
  if (tags.contains('token_maker')) return 'board_material';
  if (oracle.contains('investigate') || oracle.contains('connive')) {
    return 'selection';
  }
  return 'none';
}

String _inferInteractionScope(Set<String> tags, String oracle) {
  if (tags.contains('board_wipe')) return 'mass';
  if (oracle.contains('counter target')) return 'counterspell';
  if (tags.contains('removal')) return 'targeted';
  return 'none';
}

String _inferProtectionType({
  required String oracle,
  required String normalizedName,
  required Set<String> tagNames,
}) {
  if (!tagNames.contains('protection')) return 'none';
  if (oracle.contains('hexproof')) return 'hexproof';
  if (oracle.contains('indestructible')) return 'indestructible';
  if (oracle.contains('ward')) return 'ward';
  if (oracle.contains('prevent all damage')) return 'damage_prevention';
  if (oracle.contains('counter target')) return 'counterspell';
  if (tagNames.contains('blink')) return 'blink';
  if (normalizedName.contains('greaves') || normalizedName.contains('boots')) {
    return 'equipment';
  }
  return 'generic';
}

String _inferRecursionType(String oracle, Set<String> tagNames) {
  if (!tagNames.contains('recursion')) return 'none';
  if (oracle.contains('onto the battlefield'))
    return 'graveyard_to_battlefield';
  if (oracle.contains('to your hand')) return 'graveyard_to_hand';
  if (oracle.contains('cast')) return 'cast_from_graveyard';
  return 'generic';
}

String _buildSemanticExplanationReason(Set<String> tags) {
  if (tags.contains('ramp')) return 'mana_acceleration_or_land_search';
  if (tags.contains('draw')) return 'adds_cards_or_refills_hand';
  if (tags.contains('loot')) return 'filters_hand_quality';
  if (tags.contains('tutor')) return 'searches_library_for_nonland_card';
  if (tags.contains('removal')) return 'answers_targeted_threats';
  if (tags.contains('board_wipe')) return 'answers_multiple_threats';
  if (tags.contains('protection')) return 'protects_plan_or_permanents';
  if (tags.contains('recursion')) return 'returns_resources_from_graveyard';
  if (tags.contains('wincon')) return 'can_close_or_win_the_game';
  if (tags.contains('combo_piece')) return 'matches_known_combo_pattern';
  if (tags.contains('engine')) return 'creates_repeatable_value';
  if (tags.contains('payoff')) return 'rewards_the_deck_plan';
  if (tags.contains('enabler')) return 'sets_up_the_deck_plan';
  return 'no_primary_function_detected';
}

String _friendlyFunctionalTagReason(
  String tag,
  SemanticCardAnalysisV2 semantic,
) {
  return switch (tag) {
    'ramp' => 'Conta como ramp porque acelera mana ou busca terrenos.',
    'draw' => 'Conta como compra porque repõe cartas ou gera vantagem de mão.',
    'loot' => 'Conta como seleção porque compra e filtra/descarte cartas.',
    'tutor' => 'Conta como tutor porque busca carta não-terreno no grimório.',
    'removal' =>
      'Conta como remoção porque interage com uma ameaça específica.',
    'board_wipe' =>
      'Conta como wipe porque afeta múltiplas criaturas ou permanentes.',
    'protection' =>
      'Conta como proteção (${semantic.protectionType}) porque protege o plano ou permanentes.',
    'recursion' =>
      'Conta como recursão (${semantic.recursionType}) porque recupera recursos do cemitério.',
    'wincon' => 'Conta como condição de vitória porque pode fechar o jogo.',
    'combo_piece' =>
      'Conta como peça de combo por padrão conhecido ou texto de combo.',
    'engine' => 'Conta como engine porque gera valor repetível.',
    'payoff' => 'Conta como payoff porque recompensa o plano do deck.',
    'enabler' => 'Conta como enabler porque ajuda a configurar o plano.',
    _ =>
      'Classificada por heurística semântica segura (${semantic.explanationReason}).',
  };
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
