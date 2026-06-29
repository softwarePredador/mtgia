import 'commander_learned_deck_support.dart';
import 'commander_reference_card_stats_support.dart';
import 'commander_reference_deck_corpus_support.dart';
import 'commander_reference_generate_fallback_support.dart';
import 'commander_reference_profile_support.dart';
import 'deck_learning_event_support.dart';

const commanderDeckbuildingContractVersion =
    'commander_deckbuilding_contract_v2_2026-06-29';

const commanderDeckPlanningFlowVersion =
    'commander_deck_planning_flow_v1_2026-06-29';

const commanderDeckPlanningFlow = [
  'format_legality_and_power_bracket',
  'commander_intent_and_archetype',
  'primary_and_backup_win_plan',
  'mana_foundation_and_curve',
  'card_flow_and_resource_engine',
  'interaction_protection_and_resilience',
  'commander_specific_packages',
  'combo_synergy_and_finishers',
  'reference_corpus_and_learned_usage',
  'lane_balanced_cuts_and_anchor_protection',
  'goldfish_battle_replay_iteration',
];

const commanderDeckPlanningLaneOrder = [
  'legal_identity',
  'power_bracket',
  'commander_intent',
  'win_plan',
  'mana_base',
  'ramp',
  'curve',
  'card_draw_selection',
  'tutors_access',
  'interaction_removal',
  'protection_resilience',
  'board_wipes',
  'recursion_recovery',
  'commander_synergy_engine',
  'payoffs_finishers',
  'combo_lines',
  'meta_pressure_answers',
  'budget_collection_constraints',
  'same_lane_cuts',
  'battle_and_replay_validation',
];

const commanderDeckOverviewRequiredFields = [
  'commander_plan_sentence',
  'power_bracket_target',
  'primary_win_lines',
  'backup_win_lines',
  'role_counts_vs_targets',
  'mana_curve_and_sources',
  'package_lanes_with_key_cards',
  'source_provenance_by_anchor',
  'protected_anchors_and_cut_rules',
  'known_risks_and_validation_status',
];

Map<String, dynamic> buildCommanderDeckbuildingContractDiagnostics({
  required String format,
  required Map<String, dynamic> generatedDeck,
  required Map<String, dynamic> validationSummary,
  Map<String, dynamic>? referenceProfile,
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  List<String> unresolvedReferenceCards = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<Map<String, dynamic>> usageHotCards = const [],
  Map<String, dynamic>? referenceDeckEvaluation,
  Map<String, dynamic>? referenceDeckCorpusDiagnostics,
  Map<String, dynamic>? referenceDeterministicDeckDiagnostics,
  String? generationMode,
  bool battleGateRequired = true,
}) {
  final normalizedFormat = format.trim().toLowerCase();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';
  if (!isCommander) {
    return {
      'version': commanderDeckbuildingContractVersion,
      'status': 'not_applicable',
      'reason': 'format_not_commander',
    };
  }

  final commanderName = _commanderName(generatedDeck);
  final cards = _generatedCards(generatedDeck);
  final sourceSets = _buildSourceSets(
    referenceProfile: referenceProfile,
    referenceCardStats: referenceCardStats,
    referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
    activeLearnedDeck: activeLearnedDeck,
    usageHotCards: usageHotCards,
    commanderName: commanderName,
  );
  final sourceUsage = _sourceUsageForGeneratedCards(cards, sourceSets);
  final cardSourceSample = _cardSourceSample(cards, sourceSets);
  final validationIsValid = validationSummary['is_valid'] == true;
  final invalidCards = _listValue(validationSummary['invalid_cards']);
  final referenceProfileUsable = referenceProfile != null &&
      isReferenceProfileConfidenceUsable(referenceProfile['confidence']);
  final statsResolvedCount =
      referenceCardStats.where((stat) => !stat.unresolved).length;
  final corpusUsable = referenceDeckCorpusGuidance != null &&
      referenceDeckCorpusGuidance.isUsable;
  final hasReferenceLane = referenceProfileUsable ||
      statsResolvedCount > 0 ||
      corpusUsable ||
      activeLearnedDeck != null ||
      usageHotCards.isNotEmpty;
  final deterministicMainQuantity = _intFromPath(
    referenceDeterministicDeckDiagnostics,
    const ['main_deck_quantity'],
  );
  final deterministicDistinctCount = _intFromPath(
    referenceDeterministicDeckDiagnostics,
    const ['distinct_card_count'],
  );
  final deterministicFallbackReady =
      referenceDeterministicDeckDiagnostics == null ||
          (deterministicMainQuantity == 99 && deterministicDistinctCount >= 90);
  final coreCoverageRatio = _doubleFromPath(
    referenceDeckCorpusDiagnostics,
    const ['reference_deck_corpus_evaluation', 'core_package_coverage_ratio'],
  );

  final gates = <String, dynamic>{
    'commander_present': commanderName.isNotEmpty,
    'validation_valid': validationIsValid,
    'unresolved_cards_zero': invalidCards.isEmpty,
    'reference_profile_usable': referenceProfileUsable,
    'reference_card_stats_available': statsResolvedCount > 0,
    'reference_stats_unresolved_zero': unresolvedReferenceCards.isEmpty,
    'reference_corpus_usable': corpusUsable,
    'active_learned_deck_available': activeLearnedDeck != null,
    'usage_hot_cards_available': usageHotCards.isNotEmpty,
    'has_any_reference_lane': hasReferenceLane,
    'deterministic_reference_ready': deterministicFallbackReady,
    'battle_gate_required': battleGateRequired,
    'battle_gate_status': battleGateRequired ? 'pending' : 'not_required',
  };

  final blockers = <String>[];
  final warnings = <String>[];
  final nextActions = <String>[];
  void block(String code, String action) {
    blockers.add(code);
    nextActions.add(action);
  }

  if (commanderName.isEmpty) {
    block('commander_missing', 'Resolver comandante antes de montar o deck.');
  }
  if (!validationIsValid) {
    block(
      'validation_failed',
      'Corrigir legalidade, tamanho, singleton, identidade e resolucao.',
    );
  }
  if (invalidCards.isNotEmpty) {
    block(
      'unresolved_cards_present',
      'Resolver ou remover cartas nao encontradas antes de recomendar.',
    );
  }
  if (!hasReferenceLane) {
    block(
      'reference_lanes_missing',
      'Criar profile, stats, corpus, learned deck ou usage antes de chamar ideal.',
    );
  }
  if (!deterministicFallbackReady) {
    block(
      'deterministic_reference_not_ready',
      'Corrigir fallback deterministico para 99 cartas distintas e legais.',
    );
  }
  if (referenceProfile == null) warnings.add('reference_profile_missing');
  if (referenceProfile != null && !referenceProfileUsable) {
    warnings.add('reference_profile_below_confidence');
  }
  if (referenceCardStats.isEmpty) warnings.add('reference_card_stats_missing');
  if (unresolvedReferenceCards.isNotEmpty) {
    warnings.add('reference_card_stats_unresolved_present');
  }
  if (!corpusUsable) warnings.add('reference_corpus_missing_or_low');
  if (coreCoverageRatio != null && coreCoverageRatio < 0.35) {
    warnings.add('reference_core_package_low_coverage');
  }
  if (battleGateRequired) {
    nextActions.add(
      'Rodar battle gate igualado antes de promover mudanca estrutural.',
    );
  }

  final status = blockers.isNotEmpty
      ? 'blocked'
      : battleGateRequired
          ? 'ready_for_battle_gate'
          : 'ready';

  return {
    'version': commanderDeckbuildingContractVersion,
    'status': status,
    'commander_name': commanderName,
    if (generationMode != null) 'generation_mode': generationMode,
    'planning_flow_version': commanderDeckPlanningFlowVersion,
    'planning_flow': commanderDeckPlanningFlow,
    'lane_order': commanderDeckPlanningLaneOrder,
    'deck_overview_required_fields': commanderDeckOverviewRequiredFields,
    'source_hierarchy': const [
      'official_identity_legal_validation',
      'reference_profile',
      'reference_card_stats',
      'reference_corpus_packages',
      'active_learned_deck',
      'usage_hot_cards',
      'deterministic_fallback',
      'battle_gate',
    ],
    'source_lanes': {
      'reference_profile_used': referenceProfile != null,
      if (referenceProfile != null)
        'reference_profile_confidence': normalizeCommanderReferenceConfidence(
            referenceProfile['confidence']),
      'reference_card_stats_count': referenceCardStats.length,
      'reference_card_stats_resolved_count': statsResolvedCount,
      'reference_card_stats_unresolved_count': unresolvedReferenceCards.length,
      'reference_corpus_used': corpusUsable,
      if (referenceDeckCorpusGuidance != null) ...{
        'reference_corpus_accepted_deck_count':
            referenceDeckCorpusGuidance.acceptedDeckCount,
        'reference_corpus_core_package_count':
            referenceDeckCorpusGuidance.packages.corePackage.length,
      },
      'active_learned_deck_used': activeLearnedDeck != null,
      if (activeLearnedDeck != null)
        'active_learned_deck_source_ref': activeLearnedDeck.sourceRef,
      'usage_hot_cards_count': usageHotCards.length,
      'generated_card_source_usage': sourceUsage,
    },
    'gates': gates,
    'blockers': blockers.toSet().toList(growable: false)..sort(),
    'warnings': warnings.toSet().toList(growable: false)..sort(),
    'next_actions': nextActions.toSet().toList(growable: false)..sort(),
    'card_source_sample': cardSourceSample,
    if (referenceDeckEvaluation != null)
      'reference_deck_evaluation': referenceDeckEvaluation,
    if (referenceDeckCorpusDiagnostics != null)
      'reference_corpus_diagnostics': referenceDeckCorpusDiagnostics,
    if (referenceDeterministicDeckDiagnostics != null)
      'deterministic_reference_diagnostics':
          referenceDeterministicDeckDiagnostics,
  };
}

Map<String, Set<String>> _buildSourceSets({
  required Map<String, dynamic>? referenceProfile,
  required List<CommanderReferenceCardStat> referenceCardStats,
  required CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  required CommanderLearnedDeckInput? activeLearnedDeck,
  required List<Map<String, dynamic>> usageHotCards,
  required String commanderName,
}) {
  final sets = <String, Set<String>>{
    'profile_expected_packages': _profileExpectedPackageNames(referenceProfile),
    'reference_card_stats': referenceCardStats
        .where((stat) => !stat.unresolved)
        .map((stat) => stat.cardName)
        .map(_normalize)
        .where((name) => name.isNotEmpty)
        .toSet(),
    'reference_corpus_packages':
        _referenceCorpusPackageNames(referenceDeckCorpusGuidance),
    'active_learned_deck': activeLearnedDeck == null
        ? <String>{}
        : activeLearnedDeck.cards
            .map((card) => card.name)
            .map(_normalize)
            .where((name) => name.isNotEmpty)
            .toSet(),
    'usage_hot_cards': usageHotCardCanonicalNames(usageHotCards)
        .map(_normalize)
        .where((name) => name.isNotEmpty)
        .toSet(),
    'deterministic_fallback':
        isLoreholdCommanderReferenceCandidate(commanderName)
            ? loreholdDeterministicReferenceFallbackCards
                .map(_normalize)
                .where((name) => name.isNotEmpty)
                .toSet()
            : <String>{},
  };
  return sets;
}

Set<String> _profileExpectedPackageNames(Map<String, dynamic>? profile) {
  final packages = profile?['expected_packages'];
  if (packages is! Map) return <String>{};
  final names = <String>{};
  for (final value in packages.values) {
    if (value is! Iterable) continue;
    for (final raw in value) {
      final normalized = _normalize(raw);
      if (normalized.isNotEmpty) names.add(normalized);
    }
  }
  return names;
}

Set<String> _referenceCorpusPackageNames(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return <String>{};
  final packages = guidance.packages;
  return [
    ...packages.corePackage,
    ...packages.themePackage,
    ...packages.supportPackage,
    ...packages.optionalContextual,
  ]
      .map((card) => card['card_name'])
      .map(_normalize)
      .where((name) => name.isNotEmpty)
      .toSet();
}

Map<String, int> _sourceUsageForGeneratedCards(
  List<Map<String, dynamic>> cards,
  Map<String, Set<String>> sourceSets,
) {
  final usage = <String, int>{};
  for (final card in cards) {
    final name = _normalize(card['name']);
    if (name.isEmpty) continue;
    for (final entry in sourceSets.entries) {
      if (!entry.value.contains(name)) continue;
      usage[entry.key] = (usage[entry.key] ?? 0) + 1;
    }
  }
  return Map.fromEntries(
    usage.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

List<Map<String, dynamic>> _cardSourceSample(
  List<Map<String, dynamic>> cards,
  Map<String, Set<String>> sourceSets, {
  int limit = 20,
}) {
  final sample = <Map<String, dynamic>>[];
  for (final card in cards) {
    if (sample.length >= limit) break;
    final name = card['name']?.toString().trim() ?? '';
    final normalized = _normalize(name);
    if (name.isEmpty || normalized.isEmpty) continue;
    final sources = sourceSets.entries
        .where((entry) => entry.value.contains(normalized))
        .map((entry) => entry.key)
        .toList()
      ..sort();
    sample.add({
      'card_name': name,
      'quantity': _quantity(card['quantity']),
      'sources': sources,
      'source_count': sources.length,
    });
  }
  return sample;
}

String _commanderName(Map<String, dynamic> generatedDeck) {
  final commander = generatedDeck['commander'];
  if (commander is Map) return commander['name']?.toString().trim() ?? '';
  return commander?.toString().trim() ?? '';
}

List<Map<String, dynamic>> _generatedCards(Map<String, dynamic> generatedDeck) {
  final cards = generatedDeck['cards'];
  if (cards is! Iterable) return const [];
  return cards
      .whereType<Map>()
      .map((card) => card.cast<String, dynamic>())
      .toList(growable: false);
}

List<dynamic> _listValue(Object? value) {
  if (value is Iterable) return value.toList(growable: false);
  return const [];
}

int _quantity(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 1;
}

String _normalize(Object? value) =>
    normalizeCommanderReferenceName(value?.toString() ?? '');

int _intFromPath(Map<String, dynamic>? value, List<String> path) {
  Object? current = value;
  for (final key in path) {
    if (current is! Map) return 0;
    current = current[key];
  }
  if (current is int) return current;
  if (current is num) return current.round();
  return int.tryParse(current?.toString() ?? '') ?? 0;
}

double? _doubleFromPath(Map<String, dynamic>? value, List<String> path) {
  Object? current = value;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  if (current is num) return current.toDouble();
  return double.tryParse(current?.toString() ?? '');
}
