import 'package:postgres/postgres.dart';

import '../basic_land_utils.dart' as basic_lands;
import '../color_identity.dart';
import '../card_validation_service.dart';
import '../commander_mana_floor.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
import '../meta/meta_deck_reference_support.dart';
import 'cmc_safety.dart';
import 'edhrec_service.dart';
import 'optimize_complete_mana_support.dart';
import 'optimize_deck_support.dart';
import 'optimize_format_legality_support.dart';
import 'optimize_runtime_support.dart';
import 'optimize_route_recommendation_context_support.dart';
import 'optimize_route_request_support.dart';
import 'optimize_state_support.dart';
import 'otimizacao.dart';

export 'optimize_complete_mana_support.dart';

Map<String, dynamic> mapCompleteAiSuggestionCandidateRow(ResultRow row) {
  return {
    'card_id': row[0] as String,
    'name': row[1] as String,
    'type_line': row[2] as String? ?? '',
    'oracle_text': row[3] as String? ?? '',
    'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
    'color_identity': (row[5] as List?)?.cast<String>() ?? const <String>[],
    'mana_cost': (row[6] as String?) ?? '',
    'cmc': safeToDouble(row[7]),
    'functional_tags':
        (row[8] as List?)
            ?.map((entry) => entry.toString())
            .toList(growable: false) ??
        const <String>[],
    'semantic_tags_v2': row[9],
    'best_role_score': (row[10] as num?)?.toDouble() ?? 0.0,
  };
}

class CompleteBuildAccumulator {
  final List<Map<String, dynamic>> virtualDeck;
  final Map<String, int> virtualCountsById;
  final Map<String, int> virtualCountsByName;
  final Map<String, int> addedCountsById;
  final List<Map<String, dynamic>> blockedByBracketAll;
  final List<String> filteredByIdentityAll;
  final List<String> filteredByLegalityAll;
  final List<String> invalidAll;
  final Set<String> aiSuggestedNames;
  final Set<String> commanderMetaPriorityNames;
  final OptimizeRecommendationConstraintLedger recommendationLedger;
  String? commanderMetaEvidenceText;
  Map<String, dynamic>? commanderMetaEvidencePayload;
  int virtualTotal;
  int maxBasicAdditions = 999;
  int? commanderRecommendedLands;
  int? commanderMinimumLands;
  bool aiStageUsed = false;
  bool deterministicStageUsed = false;
  bool guaranteedBasicsStageUsed = false;
  bool competitiveModelStageUsed = false;
  bool commanderProfileStageUsed = false;
  bool averageDeckSeedStageUsed = false;
  int basicAddedDuringBuild = 0;
  int iterations = 0;

  CompleteBuildAccumulator._({
    required this.virtualDeck,
    required this.virtualCountsById,
    required this.virtualCountsByName,
    required this.virtualTotal,
    this.addedCountsById = const <String, int>{},
    this.blockedByBracketAll = const <Map<String, dynamic>>[],
    this.filteredByIdentityAll = const <String>[],
    this.filteredByLegalityAll = const <String>[],
    this.invalidAll = const <String>[],
    this.aiSuggestedNames = const <String>{},
    this.commanderMetaPriorityNames = const <String>{},
    OptimizeRecommendationConstraintLedger? recommendationLedger,
  }) : recommendationLedger =
           recommendationLedger ?? OptimizeRecommendationConstraintLedger();

  factory CompleteBuildAccumulator.fromDeck({
    required List<Map<String, dynamic>> allCardData,
    required Map<String, int> originalCountsById,
    required int currentTotalCards,
  }) {
    final virtualDeck = List<Map<String, dynamic>>.from(allCardData);
    final virtualCountsByName = <String, int>{};
    for (final card in virtualDeck) {
      final name = ((card['name'] as String?) ?? '').trim().toLowerCase();
      if (name.isEmpty) continue;
      final quantity = (card['quantity'] as int?) ?? 1;
      virtualCountsByName[name] = (virtualCountsByName[name] ?? 0) + quantity;
    }

    return CompleteBuildAccumulator._(
      virtualDeck: virtualDeck,
      virtualCountsById: Map<String, int>.from(originalCountsById),
      virtualCountsByName: virtualCountsByName,
      virtualTotal: currentTotalCards,
      addedCountsById: <String, int>{},
      blockedByBracketAll: <Map<String, dynamic>>[],
      filteredByIdentityAll: <String>[],
      filteredByLegalityAll: <String>[],
      invalidAll: <String>[],
      aiSuggestedNames: <String>{},
      commanderMetaPriorityNames: <String>{},
    );
  }
}

OptimizeRecommendationContext _completeRecommendationContext({
  required bool preferCollection,
  required int? budgetLimitBrl,
}) {
  return OptimizeRecommendationContext(
    rawWasPresent: preferCollection || budgetLimitBrl != null,
    rawWasMap: true,
    preferCollection: preferCollection,
    budgetLimitBrl: budgetLimitBrl,
    rebuildIntent: null,
    report: null,
    explainSwaps: null,
    includePriceRiskCurveBracket: null,
    unknownKeys: const <String>[],
  );
}

List<Map<String, dynamic>> dedupeCompleteRecommendationCandidatesForReservation(
  List<Map<String, dynamic>> candidates,
) {
  return dedupeCandidatesByName(candidates);
}

void _settleCompleteCandidateReservation({
  required CompleteBuildAccumulator state,
  required Map<String, dynamic> candidate,
  required bool accepted,
}) {
  settleOptimizeRecommendationReservation(
    ledger: state.recommendationLedger,
    candidate: candidate,
    accepted: accepted,
  );
}

void _releaseUnsettledCompleteCandidateReservations({
  required CompleteBuildAccumulator state,
  required Iterable<Map<String, dynamic>> candidates,
}) {
  releaseUnsettledOptimizeRecommendationReservations(
    ledger: state.recommendationLedger,
    candidates: candidates,
  );
}

Future<List<Map<String, dynamic>>>
_reserveCompleteCandidatesByRecommendationContext({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required List<Map<String, dynamic>> candidates,
  required String? userId,
  required bool preferCollection,
  required int? budgetLimitBrl,
}) async {
  final uniqueCandidates = dedupeCompleteRecommendationCandidatesForReservation(
    candidates,
  );
  if (uniqueCandidates.isEmpty || !preferCollection && budgetLimitBrl == null) {
    return uniqueCandidates;
  }
  if (userId == null || userId.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }

  final names = uniqueCandidates
      .map((candidate) => candidate['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty) return const <Map<String, dynamic>>[];

  final constrained = await applyOptimizeRecommendationConstraints(
    pool: pool,
    userId: userId,
    validAdditions: names,
    context: _completeRecommendationContext(
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
    ),
    ledger: state.recommendationLedger,
  );
  final allowedCounts = <String, int>{};
  for (final name in constrained.additions) {
    final normalized = name.trim().toLowerCase();
    allowedCounts[normalized] = (allowedCounts[normalized] ?? 0) + 1;
  }

  final allowed = <Map<String, dynamic>>[];
  for (final candidate in uniqueCandidates) {
    final normalized = candidate['name']?.toString().trim().toLowerCase() ?? '';
    final remaining = allowedCounts[normalized] ?? 0;
    if (remaining <= 0) continue;
    allowedCounts[normalized] = remaining - 1;
    allowed.add(
      markOptimizeRecommendationReservation({
        ...candidate,
        ...?constrained.detailsByNameLower[normalized],
      }),
    );
  }
  return allowed;
}

Future<void> prepareCompleteCommanderSeed({
  required Pool pool,
  required List<String> commanders,
  required String deckFormat,
  required int maxTotal,
  required int currentTotalCards,
  required CompleteBuildAccumulator state,
  int? bracket,
}) async {
  final targetAdditionsForComplete = maxTotal - currentTotalCards;
  final normalizedDeckFormat = deckFormat.trim().toLowerCase();

  if (targetAdditionsForComplete >= 40) {
    state.maxBasicAdditions = calculateCompleteMaxBasicAdditions(
      null,
      deckFormat: normalizedDeckFormat,
    );
  }

  if (commanders.isEmpty) return;

  final commanderName = commanders.first.trim();
  if (commanderName.isEmpty) return;

  // Commander reference profiles and EDHREC are Commander-format evidence.
  // Brawl keeps its own 60-card mana policy and receives format-legal
  // candidates from the downstream loaders instead of inheriting a
  // Commander-only metagame.
  if (normalizedDeckFormat != 'commander') return;

  final commanderReferenceProfile =
      await loadCommanderReferenceProfileFromCache(
        pool: pool,
        commanderName: commanderName,
      );
  final landPolicy = extractLandPolicyFromProfile(commanderReferenceProfile);
  state.commanderRecommendedLands = landPolicy?.targetLandCount;
  state.commanderMinimumLands = landPolicy?.minimumLandCount;

  if (targetAdditionsForComplete >= 40) {
    state.maxBasicAdditions = calculateCompleteMaxBasicAdditions(
      state.commanderRecommendedLands,
      deckFormat: normalizedDeckFormat,
    );
  }

  final averageDeckSeedNames = extractAverageDeckSeedNamesFromProfile(
    commanderReferenceProfile,
    limit: 140,
  );
  if (averageDeckSeedNames.isNotEmpty) {
    state.averageDeckSeedStageUsed = true;
    state.aiSuggestedNames.addAll(
      averageDeckSeedNames.map((e) => e.toLowerCase()),
    );
  }

  final commanderMetaScope = resolveCommanderOptimizeMetaScope(
    deckFormat: deckFormat,
    bracket: bracket,
  );
  if (commanderMetaScope != null) {
    final metaReferenceSelection = await loadCommanderMetaReferenceSelection(
      pool: pool,
      commanderNames: commanders,
      limitDecks: 4,
      priorityCardLimit: 120,
      metaScope: commanderMetaScope,
      preferExternalCompetitive: true,
    );
    if (metaReferenceSelection.hasReferences) {
      state.commanderMetaEvidenceText = buildMetaDeckEvidenceText(
        metaReferenceSelection,
        maxPriorityCards: 14,
        maxReferences: 3,
      );
      state.commanderMetaEvidencePayload = buildMetaDeckEvidencePayload(
        metaReferenceSelection,
        maxPriorityCards: 14,
        maxReferences: 3,
      );
    }
    final priorityNames =
        metaReferenceSelection.priorityCardNames.isNotEmpty
            ? const <String>[]
            : await loadCommanderCompetitivePriorities(
              pool: pool,
              commanderName: commanderName,
              commanderNames: commanders.skip(1).toList(growable: false),
              limit: 120,
              metaScope: commanderMetaScope,
              preferExternalCompetitive: true,
            );
    final competitivePriorityNames =
        metaReferenceSelection.priorityCardNames.isNotEmpty
            ? metaReferenceSelection.priorityCardNames
            : priorityNames;
    if (competitivePriorityNames.isNotEmpty) {
      state.competitiveModelStageUsed = true;
      state.commanderMetaPriorityNames.addAll(competitivePriorityNames);
      state.aiSuggestedNames.addAll(
        competitivePriorityNames.map((e) => e.toLowerCase()),
      );
    }
  }

  if (state.aiSuggestedNames.isEmpty) {
    final profileTopNames = extractTopCardNamesFromProfile(
      commanderReferenceProfile,
      limit: 80,
    );
    if (profileTopNames.isNotEmpty) {
      state.aiSuggestedNames.addAll(
        profileTopNames.map((e) => e.toLowerCase()),
      );
      state.commanderProfileStageUsed = true;
    }
  }

  if (state.aiSuggestedNames.isEmpty) {
    try {
      final liveEdhrec = await EdhrecService().fetchCommanderData(
        commanderName,
      );
      if (liveEdhrec != null && liveEdhrec.topCards.isNotEmpty) {
        final liveNames =
            liveEdhrec.topCards
                .map((card) => card.name.trim().toLowerCase())
                .where((name) => name.isNotEmpty)
                .take(180)
                .toList();
        if (liveNames.isNotEmpty) {
          state.aiSuggestedNames.addAll(liveNames);
          state.averageDeckSeedStageUsed = true;
          Log.d(
            'Complete fallback: aiSuggestedNames alimentado via EDHREC live (${liveNames.length} cartas).',
          );
        }
      }
    } catch (e) {
      Log.w(
        'Falha ao carregar EDHREC live para fallback complete '
        'type=${e.runtimeType}',
      );
    }
  }
}

Future<void> _addBasicLandPlanToVirtualDeck({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required List<String> basicPlan,
}) async {
  if (basicPlan.isEmpty) return;
  final basicsWithIds = await loadBasicLandIds(
    pool,
    basicPlan.toSet().toList(),
  );
  if (basicsWithIds.isEmpty) return;

  for (final name in basicPlan) {
    final id = basicsWithIds[name];
    if (id == null) continue;
    final metadata = buildVirtualBasicLandMetadata(name);
    _addCardToVirtualDeck(
      state: state,
      id: id,
      name: name,
      typeLine: metadata['type_line'] as String,
      oracleText: metadata['oracle_text'] as String,
      colors: (metadata['colors'] as List).cast<String>(),
      colorIdentity: (metadata['color_identity'] as List).cast<String>(),
      isBasic: true,
    );
  }
}

Future<void> _addIdentitySafeNonBasicLands({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required int? bracket,
  required int limit,
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
}) async {
  if (limit <= 0) return;

  final excludeNames =
      state.virtualDeck
          .map((c) => ((c['name'] as String?) ?? '').trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
  final loadedFillers = await loadIdentitySafeNonBasicLandFillers(
    pool: pool,
    commanderColorIdentity: commanderColorIdentity,
    excludeNames: excludeNames,
    currentDeckCards: state.virtualDeck,
    bracket: bracket,
    limit: limit,
    deckFormat: deckFormat,
  );
  final fillers = await _reserveCompleteCandidatesByRecommendationContext(
    pool: pool,
    state: state,
    candidates: loadedFillers,
    userId: userId,
    preferCollection: preferCollection,
    budgetLimitBrl: budgetLimitBrl,
  );

  var added = 0;
  try {
    for (final filler in fillers) {
      if (added >= limit) break;
      final id = filler['id'] as String;
      final name = filler['name'] as String;
      final lowerName = name.toLowerCase();
      final maxCopies = maxCopiesForFormat(
        deckFormat: deckFormat,
        typeLine: filler['type_line'] as String? ?? '',
        name: name,
      );
      if ((state.virtualCountsByName[lowerName] ?? 0) >= maxCopies) continue;

      final wasAdded = _addCardToVirtualDeck(
        state: state,
        id: id,
        name: name,
        typeLine: filler['type_line'] as String? ?? '',
        oracleText: filler['oracle_text'] as String? ?? '',
        manaCost: filler['mana_cost']?.toString() ?? '',
        cmc: filler['cmc'],
        functionalTags: filler['functional_tags'],
        semanticTagsV2: filler['semantic_tags_v2'],
        bestRoleScore: filler['best_role_score'],
        colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
        colorIdentity: (filler['color_identity'] as List?)?.cast<String>(),
        bracket: bracket,
      );
      if (wasAdded) added += 1;
      _settleCompleteCandidateReservation(
        state: state,
        candidate: filler,
        accepted: wasAdded,
      );
    }
  } finally {
    _releaseUnsettledCompleteCandidateReservations(
      state: state,
      candidates: fillers,
    );
  }
}

Future<void> runCompleteAiSuggestionLoop({
  required Pool pool,
  DeckOptimizerService? optimizer,
  required List<String> commanders,
  required Set<String> deckColors,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String detectedTheme,
  required List<String> coreCards,
  required int maxTotal,
  required CompleteBuildAccumulator state,
  required String deckId,
  required String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
  int maxIterations = 4,
}) async {
  if (optimizer == null) {
    Log.i('Complete mode: IA desativada; pulando loop de sugestões.');
    return;
  }

  const sparseInputCardThreshold = 12;
  const sparseInputTargetAdditionsCap = 24;
  const sparseInputMaxIterations = 1;
  const sparseInputAiTimeout = Duration(seconds: 45);
  const defaultAiTimeout = Duration(seconds: 75);
  const sparseBootstrapMinAddedForAiSkip = 24;

  final isSparseInput = state.virtualTotal <= sparseInputCardThreshold;
  var sparseBootstrapAdded = 0;
  if (isSparseInput) {
    sparseBootstrapAdded = await _bootstrapSparseCompleteInput(
      pool: pool,
      state: state,
      commanders: commanders,
      commanderColorIdentity: commanderColorIdentity,
      deckFormat: deckFormat,
      targetArchetype: targetArchetype,
      keepTheme: keepTheme,
      detectedTheme: detectedTheme,
      coreCards: coreCards,
      bracket: bracket,
      maxTotal: maxTotal,
      userId: userId,
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
    );
  }
  final effectiveMaxIterations =
      isSparseInput ? sparseInputMaxIterations : maxIterations;
  final aiTimeout = isSparseInput ? sparseInputAiTimeout : defaultAiTimeout;

  if (isSparseInput) {
    Log.i(
      'Complete mode: sparse-input budget ativo '
      '(initial_total=${state.virtualTotal}, max_iterations=$effectiveMaxIterations, '
      'target_additions_cap=$sparseInputTargetAdditionsCap, timeout_s=${aiTimeout.inSeconds}).',
    );
    if (sparseBootstrapAdded >= sparseBootstrapMinAddedForAiSkip) {
      Log.i(
        'Complete mode: bootstrap determinístico já adicionou '
        '$sparseBootstrapAdded cartas não-terreno; pulando IA e seguindo para fill remainder.',
      );
      return;
    }
  }

  while (state.iterations < effectiveMaxIterations &&
      state.virtualTotal < maxTotal) {
    state.iterations++;
    final missingNow = maxTotal - state.virtualTotal;
    final requestedAdditions =
        isSparseInput && missingNow > sparseInputTargetAdditionsCap
            ? sparseInputTargetAdditionsCap
            : missingNow;

    Map<String, dynamic> iterResponse;
    try {
      iterResponse = await optimizer
          .completeDeck(
            deckData: {
              'cards': state.virtualDeck,
              'colors': deckColors.toList(),
            },
            commanders: commanders,
            targetArchetype: targetArchetype,
            targetAdditions: requestedAdditions,
            deckFormat: deckFormat,
            bracket: bracket,
            keepTheme: keepTheme,
            detectedTheme: detectedTheme,
            coreCards: coreCards,
            metaEvidenceContext: state.commanderMetaEvidenceText,
            userId: userId,
            deckId: deckId,
            preferCollection: preferCollection,
            budgetLimitBrl: budgetLimitBrl,
          )
          .timeout(aiTimeout);
    } catch (e) {
      Log.w(
        'Falha no completeDeck da IA; aplicando fallback determinístico. '
        'iteration=${state.iterations} missing=$missingNow requested=$requestedAdditions '
        'timeout_s=${aiTimeout.inSeconds} type=${e.runtimeType}',
      );
      break;
    }

    final rawAdditions =
        (iterResponse['additions'] as List?)?.cast<String>() ?? const [];
    if (rawAdditions.isEmpty) break;
    state.aiStageUsed = true;

    final sanitized =
        rawAdditions.map(CardValidationService.sanitizeCardName).toList();
    state.aiSuggestedNames.addAll(
      sanitized
          .where((name) => name.trim().isNotEmpty)
          .map((name) => name.trim().toLowerCase()),
    );

    final validationService = CardValidationService(pool);
    final validation = await validationService.validateCardNames(sanitized);
    state.invalidAll.addAll(
      (validation['invalid'] as List?)?.cast<String>() ?? const [],
    );

    final validList =
        (validation['valid'] as List).cast<Map<String, dynamic>>();
    var validNames = validList.map((v) => (v['name'] as String)).toList();
    final legalityFilter = await filterOptimizeCardNamesByKnownFormatLegality(
      pool: pool,
      names: validNames,
      deckFormat: deckFormat,
    );
    validNames = legalityFilter.allowed;
    state.filteredByLegalityAll.addAll(legalityFilter.blocked);
    if (validNames.isEmpty) break;

    final additionsInfoResult = await pool.execute(
      Sql.named('''
        SELECT
          c.id::text,
          c.name,
          c.type_line,
          c.oracle_text,
          c.colors,
          c.color_identity,
          c.mana_cost,
          c.cmc,
          ARRAY(
            SELECT DISTINCT value
            FROM unnest(
              COALESCE(cis.function_tags, ARRAY[]::text[]) ||
              COALESCE(cis.scored_roles, ARRAY[]::text[])
            ) AS role(value)
            WHERE value IS NOT NULL AND TRIM(value) <> ''
          ) AS functional_tags,
          COALESCE(cis.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2,
          COALESCE(cis.best_role_score, 0) AS best_role_score
        FROM cards c
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        WHERE c.name = ANY(@names)
      '''),
      parameters: {'names': validNames},
    );
    if (additionsInfoResult.isEmpty) break;

    final candidates = additionsInfoResult
        .map(mapCompleteAiSuggestionCandidateRow)
        .toList(growable: false);

    final identityAllowed = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      final identity = resolvedCardIdentity(candidate);
      final ok = isWithinCommanderIdentity(
        cardIdentity: identity,
        commanderIdentity: commanderColorIdentity,
      );
      if (!ok) {
        state.filteredByIdentityAll.add(candidate['name'] as String);
        continue;
      }
      identityAllowed.add(candidate);
    }
    if (identityAllowed.isEmpty) break;

    final bracketAllowed = <Map<String, dynamic>>[];
    if (bracket != null) {
      final decision = applyBracketPolicyToAdditions(
        bracket: bracket,
        currentDeckCards: state.virtualDeck,
        additionsCardsData: identityAllowed.map((c) {
          return {
            'name': c['name'],
            'type_line': c['type_line'],
            'oracle_text': c['oracle_text'],
            'quantity': 1,
          };
        }),
      );
      state.blockedByBracketAll.addAll(decision.blocked);
      final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
      for (final candidate in identityAllowed) {
        final lower = (candidate['name'] as String).toLowerCase();
        if (allowedSet.contains(lower)) bracketAllowed.add(candidate);
      }
    } else {
      bracketAllowed.addAll(identityAllowed);
    }
    if (bracketAllowed.isEmpty) break;
    final reservationCandidates = bracketAllowed
        .where((candidate) {
          final name = candidate['name']?.toString() ?? '';
          final nameLower = name.toLowerCase();
          final typeLine = candidate['type_line']?.toString() ?? '';
          final maxCopies = maxCopiesForFormat(
            deckFormat: deckFormat,
            typeLine: typeLine,
            name: name,
          );
          return (state.virtualCountsByName[nameLower] ?? 0) < maxCopies;
        })
        .take(maxTotal - state.virtualTotal)
        .toList(growable: false);
    final recommendationAllowed =
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: reservationCandidates,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        );
    if (recommendationAllowed.isEmpty) break;

    var addedThisIter = 0;
    try {
      for (final candidate in recommendationAllowed) {
        if (state.virtualTotal >= maxTotal) break;
        final id = candidate['card_id'] as String;
        final name = candidate['name'] as String;
        final typeLine = (candidate['type_line'] as String).toLowerCase();
        final isBasic = isBasicLandTypeLine(typeLine);
        final nameLower = name.toLowerCase();
        final maxCopies = maxCopiesForFormat(
          deckFormat: deckFormat,
          typeLine: typeLine,
          name: name,
        );

        if (!isBasic &&
            (state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) {
          continue;
        }

        if ((state.virtualCountsById[id] ?? 0) > 0 &&
            (state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) {
          continue;
        }

        final wasAdded = _addCardToVirtualDeck(
          state: state,
          id: id,
          name: name,
          typeLine: candidate['type_line'] as String? ?? '',
          oracleText: candidate['oracle_text'] as String? ?? '',
          manaCost: candidate['mana_cost']?.toString() ?? '',
          cmc: candidate['cmc'],
          functionalTags: candidate['functional_tags'],
          semanticTagsV2: candidate['semantic_tags_v2'],
          bestRoleScore: candidate['best_role_score'],
          colors: (candidate['colors'] as List?)?.cast<String>() ?? const [],
          colorIdentity: (candidate['color_identity'] as List?)?.cast<String>(),
          isBasic: isBasic,
          bracket: bracket,
        );
        if (wasAdded) addedThisIter += 1;
        _settleCompleteCandidateReservation(
          state: state,
          candidate: candidate,
          accepted: wasAdded,
        );
      }
    } finally {
      _releaseUnsettledCompleteCandidateReservations(
        state: state,
        candidates: recommendationAllowed,
      );
    }

    if (addedThisIter == 0) break;
  }
}

Future<int> _bootstrapSparseCompleteInput({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required String targetArchetype,
  required bool keepTheme,
  required String detectedTheme,
  required List<String> coreCards,
  required int? bracket,
  required int maxTotal,
  required String? userId,
  required bool preferCollection,
  required int? budgetLimitBrl,
}) async {
  final currentLands = _countCurrentLands(state.virtualDeck);
  final targetLands = resolveCompleteTargetLandCount(
    deckFormat: deckFormat,
    recommendedLandCount: state.commanderRecommendedLands,
  );
  final targetSpells = (maxTotal - targetLands).clamp(
    state.virtualTotal,
    maxTotal,
  );
  final spellSlotsToFill = (targetSpells - state.virtualTotal).clamp(0, 48);
  if (spellSlotsToFill <= 0) return 0;

  final existingNames =
      state.virtualDeck
          .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();

  final selected = <Map<String, dynamic>>[];
  try {
    final selectedNames = <String>{};
    List<Map<String, dynamic>> bracketSnapshot() => [
      ...state.virtualDeck,
      ...selected,
    ];

    void addUnique(Iterable<Map<String, dynamic>> items) {
      for (final item in items) {
        if (selected.length >= spellSlotsToFill) {
          _settleCompleteCandidateReservation(
            state: state,
            candidate: item,
            accepted: false,
          );
          continue;
        }
        if (basic_lands.isLandTypeLine(item['type_line']?.toString() ?? '')) {
          _settleCompleteCandidateReservation(
            state: state,
            candidate: item,
            accepted: false,
          );
          continue;
        }
        final lowerName =
            ((item['name'] as String?) ?? '').trim().toLowerCase();
        if (lowerName.isEmpty) {
          _settleCompleteCandidateReservation(
            state: state,
            candidate: item,
            accepted: false,
          );
          continue;
        }
        if (existingNames.contains(lowerName) ||
            selectedNames.contains(lowerName)) {
          _settleCompleteCandidateReservation(
            state: state,
            candidate: item,
            accepted: false,
          );
          continue;
        }
        selected.add(item);
        selectedNames.add(lowerName);
      }
    }

    final criticalNeeds = buildCommanderCriticalRoleFloorNeeds(
      cards: state.virtualDeck,
      targetArchetype: targetArchetype,
      limit: spellSlotsToFill,
      bracket: bracket,
    );
    final structuralNeeds = buildStructuralRecoveryFunctionalNeeds(
      allCardData: state.virtualDeck,
      targetArchetype: targetArchetype,
      limit: spellSlotsToFill,
    );
    final themedNeeds = _mergeCriticalCompleteFunctionalNeeds(
      criticalNeeds: criticalNeeds,
      plannedNeeds: structuralNeeds,
      limit: spellSlotsToFill,
    );
    final themedPool = await findSynergyReplacements(
      pool: pool,
      commanders: commanders,
      commanderColorIdentity: commanderColorIdentity,
      targetArchetype: targetArchetype,
      bracket: bracket,
      keepTheme: keepTheme,
      detectedTheme: detectedTheme,
      coreCards: coreCards,
      missingCount: spellSlotsToFill,
      removedCards: const [],
      functionalNeedsOverride: themedNeeds,
      excludeNames: existingNames,
      allCardData: state.virtualDeck,
      preferredNames: {
        ...state.aiSuggestedNames,
        ...state.commanderMetaPriorityNames,
      },
      userId: userId,
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
      deckFormat: deckFormat,
      recommendationLedger: state.recommendationLedger,
    );
    addUnique(themedPool);

    var structuredPool = const <Map<String, dynamic>>[];
    if (selected.length < spellSlotsToFill) {
      structuredPool = await loadGuaranteedNonBasicFillers(
        pool: pool,
        currentDeckCards: bracketSnapshot(),
        commanderColorIdentity: commanderColorIdentity,
        targetArchetype: targetArchetype,
        bracket: bracket,
        excludeNames: existingNames.union(selectedNames),
        preferredNames: {
          ...state.aiSuggestedNames,
          ...state.commanderMetaPriorityNames,
        },
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
    }
    addUnique(
      await _reserveCompleteCandidatesByRecommendationContext(
        pool: pool,
        state: state,
        candidates: structuredPool,
        userId: userId,
        preferCollection: preferCollection,
        budgetLimitBrl: budgetLimitBrl,
      ),
    );

    if (selected.length < spellSlotsToFill) {
      final foundationPool = await loadArchetypeCommanderFoundationFillers(
        pool: pool,
        commanderColorIdentity: commanderColorIdentity,
        targetArchetype: targetArchetype,
        detectedTheme: detectedTheme,
        excludeNames: existingNames.union(selectedNames),
        currentDeckCards: bracketSnapshot(),
        bracket: bracket,
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
      addUnique(
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: foundationPool,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        ),
      );
    }

    if (selected.length < spellSlotsToFill) {
      final universalPool = await loadUniversalCommanderFallbacks(
        pool: pool,
        excludeNames: existingNames.union(selectedNames),
        commanderColorIdentity: commanderColorIdentity,
        currentDeckCards: bracketSnapshot(),
        bracket: bracket,
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
      addUnique(
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: universalPool,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        ),
      );
    }

    if (selected.length < spellSlotsToFill) {
      final preferredPool = await loadPreferredNameFillers(
        pool: pool,
        preferredNames: state.aiSuggestedNames,
        commanderColorIdentity: commanderColorIdentity,
        excludeNames: existingNames.union(selectedNames),
        currentDeckCards: bracketSnapshot(),
        bracket: bracket,
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
      addUnique(
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: preferredPool,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        ),
      );
    }

    if (selected.length < spellSlotsToFill) {
      final broadPool = await loadBroadCommanderNonLandFillers(
        pool: pool,
        currentDeckCards: bracketSnapshot(),
        commanderColorIdentity: commanderColorIdentity,
        excludeNames: existingNames.union(selectedNames),
        bracket: bracket,
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
      addUnique(
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: broadPool,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        ),
      );
    }

    if (selected.length < spellSlotsToFill) {
      final identitySafePool = await loadIdentitySafeNonLandFillers(
        pool: pool,
        commanderColorIdentity: commanderColorIdentity,
        excludeNames: existingNames.union(selectedNames),
        currentDeckCards: bracketSnapshot(),
        bracket: bracket,
        limit: spellSlotsToFill - selected.length,
        deckFormat: deckFormat,
      );
      addUnique(
        await _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: identitySafePool,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        ),
      );
    }

    var added = 0;
    for (final candidate in selected) {
      if (state.virtualTotal >= maxTotal) break;
      final id = candidate['id'] as String;
      final name = candidate['name'] as String;
      final typeLine = candidate['type_line'] as String? ?? '';
      final oracleText = candidate['oracle_text'] as String? ?? '';
      final colors = (candidate['colors'] as List?)?.cast<String>() ?? const [];
      final colorIdentity =
          (candidate['color_identity'] as List?)?.cast<String>();
      final nameLower = name.toLowerCase();
      final maxCopies = maxCopiesForFormat(
        deckFormat: deckFormat,
        typeLine: typeLine,
        name: name,
      );

      if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) continue;

      final wasAdded = _addCardToVirtualDeck(
        state: state,
        id: id,
        name: name,
        typeLine: typeLine,
        oracleText: oracleText,
        manaCost: candidate['mana_cost']?.toString() ?? '',
        cmc: candidate['cmc'],
        functionalTags: candidate['functional_tags'],
        semanticTagsV2: candidate['semantic_tags_v2'],
        bestRoleScore: candidate['best_role_score'],
        colors: colors,
        colorIdentity: colorIdentity,
        bracket: bracket,
      );
      if (wasAdded) added += 1;
      _settleCompleteCandidateReservation(
        state: state,
        candidate: candidate,
        accepted: wasAdded,
      );
    }

    if (added > 0) {
      state.deterministicStageUsed = true;
      Log.i(
        'Complete sparse bootstrap: current_lands=$currentLands target_lands=$targetLands '
        'spell_slots=$spellSlotsToFill added=$added '
        'themed_pool=${themedPool.length} structured_pool=${structuredPool.length}',
      );
    }

    return added;
  } finally {
    _releaseUnsettledCompleteCandidateReservations(
      state: state,
      candidates: selected,
    );
  }
}

int completeOutstandingLandDeficit({
  required CompleteBuildAccumulator state,
  required String deckFormat,
}) {
  final currentLands = _countCurrentLands(state.virtualDeck);
  final avgCmc = calculateCompleteAverageNonLandCmc(state.virtualDeck);
  final idealLands = resolveCompleteTargetLandCount(
    deckFormat: deckFormat,
    recommendedLandCount: state.commanderRecommendedLands,
    averageNonLandCmc: avgCmc,
  );
  return (idealLands - currentLands).clamp(0, idealLands);
}

void rebalanceCompleteDeckForLandDeficit({
  required CompleteBuildAccumulator state,
  required int maxTotal,
  required String deckFormat,
  required String targetArchetype,
  int? bracket,
}) {
  final landDeficit = completeOutstandingLandDeficit(
    state: state,
    deckFormat: deckFormat,
  );
  final slotsAvailable = maxTotal - state.virtualTotal;

  if (landDeficit <= slotsAvailable || landDeficit <= 0) {
    return;
  }

  final slotsToFree = landDeficit - slotsAvailable;
  Log.d(
    'Land rebalancing: deficit=$landDeficit, available=$slotsAvailable, freeing=$slotsToFree slots',
  );

  final structuralMinimumCounts =
      deckFormat.trim().toLowerCase() == 'commander'
          ? commanderFunctionalRoleMinimumCounts(
            targetArchetype: targetArchetype,
            bracket: bracket,
          )
          : const <String, int>{};
  final structuralActualCounts = <String, int>{
    for (final role in structuralMinimumCounts.keys)
      role: countOptimizationFunctionalRole(state.virtualDeck, role: role),
  };

  var freed = 0;
  for (
    var i = state.virtualDeck.length - 1;
    i >= 0 && freed < slotsToFree;
    i--
  ) {
    final card = state.virtualDeck[i];
    final cardId = card['card_id'] as String?;
    if (cardId == null) continue;
    if (!state.addedCountsById.containsKey(cardId)) continue;

    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) continue;
    if (card['is_commander'] == true) continue;

    final qty = (card['quantity'] as int?) ?? 1;
    final addedQty = state.addedCountsById[cardId] ?? 0;
    if (addedQty <= 0) continue;
    final unitCard = <String, dynamic>{...card, 'quantity': 1};
    final structuralContributions = <String, int>{
      for (final role in structuralMinimumCounts.keys)
        role: countOptimizationFunctionalRole([unitCard], role: role),
    };
    final wouldReduceCriticalCoverage = structuralContributions.entries.any(
      (entry) =>
          entry.value > 0 &&
          (structuralActualCounts[entry.key] ?? 0) <=
              (structuralMinimumCounts[entry.key] ?? 0),
    );
    if (wouldReduceCriticalCoverage) continue;

    if (_removeOneAddedCardFromVirtualDeck(
      state: state,
      cardIndex: i,
      cardId: cardId,
      card: card,
      quantity: qty,
      addedQuantity: addedQty,
    )) {
      freed += 1;
      for (final entry in structuralContributions.entries) {
        structuralActualCounts[entry.key] =
            (structuralActualCounts[entry.key] ?? 0) - entry.value;
      }
    }
  }

  Log.d('Land rebalancing: freed $freed slots for lands');
}

int rebalanceCompleteDeckForFunctionalRoleDeficits({
  required CompleteBuildAccumulator state,
  required int maxTotal,
  required String deckFormat,
  required String targetArchetype,
  int? bracket,
}) {
  if (deckFormat.trim().toLowerCase() != 'commander') return 0;

  final needs = buildCommanderCriticalRoleFloorNeeds(
    cards: state.virtualDeck,
    targetArchetype: targetArchetype,
    limit: maxTotal,
    bracket: bracket,
  );
  final slotsAvailable = (maxTotal - state.virtualTotal).clamp(0, maxTotal);
  final outstandingLandDeficit = completeOutstandingLandDeficit(
    state: state,
    deckFormat: deckFormat,
  );
  final functionalSlotsAvailable = (slotsAvailable - outstandingLandDeficit)
      .clamp(0, maxTotal);
  final slotsToFree = (needs.length - functionalSlotsAvailable).clamp(
    0,
    maxTotal,
  );
  if (slotsToFree <= 0) return 0;

  final roleTargets = buildRoleTargetProfile(targetArchetype);
  final roleCounts = <String, int>{};
  for (final card in state.virtualDeck) {
    final role = inferFunctionalRoleForCard(card);
    final quantity = (card['quantity'] as num?)?.toInt() ?? 1;
    roleCounts[role] = (roleCounts[role] ?? 0) + quantity;
  }
  final structuralMinimumCounts = commanderFunctionalRoleMinimumCounts(
    targetArchetype: targetArchetype,
    bracket: bracket,
  );
  final structuralActualCounts = <String, int>{
    for (final role in structuralMinimumCounts.keys)
      role: countOptimizationFunctionalRole(state.virtualDeck, role: role),
  };

  final removable = <MapEntry<int, Map<String, dynamic>>>[];
  for (var index = 0; index < state.virtualDeck.length; index++) {
    final card = state.virtualDeck[index];
    final cardId = card['card_id']?.toString() ?? '';
    if (cardId.isEmpty || (state.addedCountsById[cardId] ?? 0) <= 0) continue;
    if (card['is_commander'] == true) continue;
    if (basic_lands.isLandTypeLine(card['type_line']?.toString() ?? '')) {
      continue;
    }
    removable.add(MapEntry(index, card));
  }
  removable.sort((a, b) {
    int removalPriority(Map<String, dynamic> card) {
      final role = inferFunctionalRoleForCard(card);
      final surplus = (roleCounts[role] ?? 0) - (roleTargets[role] ?? 0);
      final cmc = (card['cmc'] as num?)?.toDouble() ?? 0;
      return (surplus.clamp(0, 99) * 1000 + cmc * 10).round();
    }

    final byPriority = removalPriority(
      b.value,
    ).compareTo(removalPriority(a.value));
    if (byPriority != 0) return byPriority;
    return (b.value['name']?.toString() ?? '').compareTo(
      a.value['name']?.toString() ?? '',
    );
  });

  var freed = 0;
  for (final candidate in removable) {
    if (freed >= slotsToFree) break;
    final currentIndex = state.virtualDeck.indexWhere(
      (card) => identical(card, candidate.value),
    );
    if (currentIndex < 0) continue;
    final card = state.virtualDeck[currentIndex];
    final cardId = card['card_id']?.toString() ?? '';
    final quantity = (card['quantity'] as num?)?.toInt() ?? 1;
    final addedQuantity = state.addedCountsById[cardId] ?? 0;
    if (addedQuantity <= 0) continue;
    final unitCard = <String, dynamic>{...card, 'quantity': 1};
    final structuralContributions = <String, int>{
      for (final role in structuralMinimumCounts.keys)
        role: countOptimizationFunctionalRole([unitCard], role: role),
    };
    final wouldBreakStructuralFloor = structuralContributions.entries.any(
      (entry) =>
          entry.value > 0 &&
          (structuralActualCounts[entry.key] ?? 0) - entry.value <
              (structuralMinimumCounts[entry.key] ?? 0),
    );
    if (wouldBreakStructuralFloor) continue;
    if (_removeOneAddedCardFromVirtualDeck(
      state: state,
      cardIndex: currentIndex,
      cardId: cardId,
      card: card,
      quantity: quantity,
      addedQuantity: addedQuantity,
    )) {
      freed += 1;
      for (final entry in structuralContributions.entries) {
        structuralActualCounts[entry.key] =
            (structuralActualCounts[entry.key] ?? 0) - entry.value;
      }
      final primaryRole = inferFunctionalRoleForCard(card);
      roleCounts[primaryRole] = (roleCounts[primaryRole] ?? 0) - 1;
    }
  }

  if (freed > 0) {
    Log.i(
      'Complete role-floor rebalancing: freed=$freed '
      'required=${needs.length} roles=${needs.toSet().join(',')} '
      'open=$slotsAvailable land_reserved=$outstandingLandDeficit '
      'archetype=$targetArchetype bracket=${bracket ?? 2}',
    );
  }
  return freed;
}

Future<void> reconcileCompleteDeckFunctionalRoleFloors({
  required Pool pool,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String detectedTheme,
  required List<String> coreCards,
  required int maxTotal,
  required CompleteBuildAccumulator state,
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
}) async {
  if (deckFormat.trim().toLowerCase() != 'commander') return;

  for (var pass = 1; pass <= 3; pass++) {
    final before = assessCommanderFunctionalRoleFloors(
      cards: state.virtualDeck,
      targetArchetype: targetArchetype,
      bracket: bracket,
    );
    if (before.deficits.isEmpty) return;

    final freed = rebalanceCompleteDeckForFunctionalRoleDeficits(
      state: state,
      maxTotal: maxTotal,
      deckFormat: deckFormat,
      targetArchetype: targetArchetype,
      bracket: bracket,
    );
    if (state.virtualTotal >= maxTotal && freed == 0) {
      Log.w(
        'Complete role-floor reconciliation blocked: '
        'pass=$pass deficits=${before.deficits}',
      );
      return;
    }

    await fillCompleteDeckRemainder(
      pool: pool,
      commanders: commanders,
      commanderColorIdentity: commanderColorIdentity,
      deckFormat: deckFormat,
      targetArchetype: targetArchetype,
      bracket: bracket,
      keepTheme: keepTheme,
      detectedTheme: detectedTheme,
      coreCards: coreCards,
      maxTotal: maxTotal,
      state: state,
      userId: userId,
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
    );

    final after = assessCommanderFunctionalRoleFloors(
      cards: state.virtualDeck,
      targetArchetype: targetArchetype,
      bracket: bracket,
    );
    if (after.deficits.isEmpty) {
      state.deterministicStageUsed = true;
      Log.i('Complete role-floor reconciliation satisfied on pass=$pass.');
      return;
    }
    final improved = before.deficits.entries.any(
      (entry) => (after.deficits[entry.key] ?? 0) < entry.value,
    );
    if (!improved) {
      Log.w(
        'Complete role-floor reconciliation made no progress: '
        'pass=$pass before=${before.deficits} after=${after.deficits}',
      );
      return;
    }
  }
}

List<String> mergeCriticalCompleteFunctionalNeeds({
  required List<String> criticalNeeds,
  required List<String> plannedNeeds,
  required int limit,
}) {
  return _mergeCriticalCompleteFunctionalNeeds(
    criticalNeeds: criticalNeeds,
    plannedNeeds: plannedNeeds,
    limit: limit,
  );
}

List<String> _mergeCriticalCompleteFunctionalNeeds({
  required List<String> criticalNeeds,
  required List<String> plannedNeeds,
  required int limit,
}) {
  if (limit <= 0) return const [];
  final merged = <String>[...criticalNeeds.take(limit)];
  final duplicateBudget = <String, int>{};
  for (final need in criticalNeeds) {
    duplicateBudget[need] = (duplicateBudget[need] ?? 0) + 1;
  }
  for (final need in plannedNeeds) {
    if (merged.length >= limit) break;
    final duplicatesToSkip = duplicateBudget[need] ?? 0;
    if (duplicatesToSkip > 0) {
      duplicateBudget[need] = duplicatesToSkip - 1;
      continue;
    }
    merged.add(need);
  }
  return merged;
}

bool _removeOneAddedCardFromVirtualDeck({
  required CompleteBuildAccumulator state,
  required int cardIndex,
  required String cardId,
  required Map<String, dynamic> card,
  required int quantity,
  required int addedQuantity,
}) {
  if (addedQuantity <= 0 || quantity <= 0) return false;

  final nextAddedQuantity = addedQuantity - 1;
  if (nextAddedQuantity <= 0) {
    state.addedCountsById.remove(cardId);
  } else {
    state.addedCountsById[cardId] = nextAddedQuantity;
  }

  final nextIdQuantity = (state.virtualCountsById[cardId] ?? quantity) - 1;
  if (nextIdQuantity <= 0) {
    state.virtualCountsById.remove(cardId);
  } else {
    state.virtualCountsById[cardId] = nextIdQuantity;
  }

  final nameLower = (card['name']?.toString() ?? '').trim().toLowerCase();
  state.recommendationLedger.release(nameLower);
  final nextNameQuantity =
      (state.virtualCountsByName[nameLower] ?? quantity) - 1;
  if (nextNameQuantity <= 0) {
    state.virtualCountsByName.remove(nameLower);
  } else {
    state.virtualCountsByName[nameLower] = nextNameQuantity;
  }
  state.virtualTotal -= 1;

  if (quantity <= 1) {
    state.virtualDeck.removeAt(cardIndex);
  } else {
    state.virtualDeck[cardIndex] = {...card, 'quantity': quantity - 1};
  }
  return true;
}

Future<void> fillCompleteDeckRemainder({
  required Pool pool,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String detectedTheme,
  required List<String> coreCards,
  required int maxTotal,
  required CompleteBuildAccumulator state,
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
}) async {
  if (state.virtualTotal >= maxTotal) return;

  final missing = maxTotal - state.virtualTotal;
  var currentLands = _countCurrentLands(state.virtualDeck);
  final avgCmc = calculateCompleteAverageNonLandCmc(state.virtualDeck);
  final idealLands = resolveCompleteTargetLandCount(
    deckFormat: deckFormat,
    recommendedLandCount: state.commanderRecommendedLands,
    averageNonLandCmc: avgCmc,
  );
  final landsNeeded = (idealLands - currentLands).clamp(0, missing);
  final spellsNeeded = missing - landsNeeded;

  Log.d('Complete fallback inteligente:');
  Log.d(
    '  Cartas faltando: $missing | Lands atuais: $currentLands | Ideal: $idealLands',
  );
  Log.d(
    '  Lands a adicionar: $landsNeeded | Spells a adicionar: $spellsNeeded',
  );

  if (spellsNeeded > 0) {
    final selectedSpells = <Map<String, dynamic>>[];
    try {
      final existingNames =
          state.virtualDeck
              .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
              .toSet();
      final selectedSpellNames = <String>{};
      final criticalRoleNeeds = buildCommanderCriticalRoleFloorNeeds(
        cards: state.virtualDeck,
        targetArchetype: targetArchetype,
        limit: spellsNeeded,
        bracket: bracket,
      );
      List<Map<String, dynamic>> bracketSnapshot() => [
        ...state.virtualDeck,
        ...selectedSpells,
      ];
      Future<List<Map<String, dynamic>>> reserveIncoming(
        List<Map<String, dynamic>> incoming,
      ) {
        return _reserveCompleteCandidatesByRecommendationContext(
          pool: pool,
          state: state,
          candidates: incoming,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
        );
      }

      void mergeUniqueSpells(List<Map<String, dynamic>> incoming) {
        for (final item in incoming) {
          if (selectedSpells.length >= spellsNeeded) {
            _settleCompleteCandidateReservation(
              state: state,
              candidate: item,
              accepted: false,
            );
            continue;
          }
          if (basic_lands.isLandTypeLine(item['type_line']?.toString() ?? '')) {
            _settleCompleteCandidateReservation(
              state: state,
              candidate: item,
              accepted: false,
            );
            continue;
          }
          final lowerName =
              ((item['name'] as String?) ?? '').trim().toLowerCase();
          if (lowerName.isEmpty) {
            _settleCompleteCandidateReservation(
              state: state,
              candidate: item,
              accepted: false,
            );
            continue;
          }
          if (existingNames.contains(lowerName) ||
              selectedSpellNames.contains(lowerName)) {
            _settleCompleteCandidateReservation(
              state: state,
              candidate: item,
              accepted: false,
            );
            continue;
          }
          selectedSpells.add(item);
          selectedSpellNames.add(lowerName);
        }
      }

      final wipeFloorDeficit =
          criticalRoleNeeds.where((role) => role == 'wipe').length;
      if (wipeFloorDeficit > 0) {
        final wipeFloorCandidates = await loadCommanderWipeFloorCandidates(
          pool: pool,
          currentDeckCards: bracketSnapshot(),
          commanderColorIdentity: commanderColorIdentity,
          excludeNames: existingNames,
          bracket: bracket,
          limit: wipeFloorDeficit,
          deckFormat: deckFormat,
        );
        final reservedWipes = await reserveIncoming(wipeFloorCandidates);
        mergeUniqueSpells(reservedWipes);
        Log.d(
          '  Wipe floor lane: deficit=$wipeFloorDeficit selected=${reservedWipes.length}.',
        );
      }

      final remainingSynergySlots = spellsNeeded - selectedSpells.length;
      if (remainingSynergySlots > 0) {
        final refreshedCriticalNeeds = buildCommanderCriticalRoleFloorNeeds(
          cards: bracketSnapshot(),
          targetArchetype: targetArchetype,
          limit: remainingSynergySlots,
          bracket: bracket,
        );
        final refreshedStructuralNeeds = buildStructuralRecoveryFunctionalNeeds(
          allCardData: bracketSnapshot(),
          targetArchetype: targetArchetype,
          limit: remainingSynergySlots,
        );
        final functionalNeeds = _mergeCriticalCompleteFunctionalNeeds(
          criticalNeeds: refreshedCriticalNeeds,
          plannedNeeds: refreshedStructuralNeeds,
          limit: remainingSynergySlots,
        );
        final initialSynergySpells = await findSynergyReplacements(
          pool: pool,
          commanders: commanders,
          commanderColorIdentity: commanderColorIdentity,
          targetArchetype: targetArchetype,
          bracket: bracket,
          keepTheme: keepTheme,
          detectedTheme: detectedTheme,
          coreCards: coreCards,
          missingCount: remainingSynergySlots,
          removedCards: const [],
          functionalNeedsOverride: functionalNeeds,
          excludeNames: existingNames.union(selectedSpellNames),
          allCardData: bracketSnapshot(),
          preferredNames: state.aiSuggestedNames,
          userId: userId,
          preferCollection: preferCollection,
          budgetLimitBrl: budgetLimitBrl,
          deckFormat: deckFormat,
          recommendationLedger: state.recommendationLedger,
        );
        mergeUniqueSpells(initialSynergySpells);
      }

      if (selectedSpells.isEmpty) {
        final universalFallback = await loadUniversalCommanderFallbacks(
          pool: pool,
          excludeNames: existingNames,
          commanderColorIdentity: commanderColorIdentity,
          currentDeckCards: bracketSnapshot(),
          bracket: bracket,
          limit: spellsNeeded,
          deckFormat: deckFormat,
        );
        if (universalFallback.isNotEmpty) {
          Log.d(
            '  Synergy replacements vazios; aplicando fallback universal (${universalFallback.length} cartas).',
          );
          mergeUniqueSpells(await reserveIncoming(universalFallback));
        }
      }

      if (selectedSpells.length < spellsNeeded) {
        final foundationFallback =
            await loadArchetypeCommanderFoundationFillers(
              pool: pool,
              commanderColorIdentity: commanderColorIdentity,
              targetArchetype: targetArchetype,
              detectedTheme: detectedTheme,
              excludeNames: existingNames.union(selectedSpellNames),
              currentDeckCards: bracketSnapshot(),
              bracket: bracket,
              limit: spellsNeeded - selectedSpells.length,
              deckFormat: deckFormat,
            );
        if (foundationFallback.isNotEmpty) {
          Log.d(
            '  Fallback foundation aplicado (+${foundationFallback.length} cartas).',
          );
          mergeUniqueSpells(await reserveIncoming(foundationFallback));
        }
      }

      if (selectedSpells.length < spellsNeeded) {
        Log.d(
          '  Expansão de spells ativada: selected=${selectedSpells.length}, spellsNeeded=$spellsNeeded, identity=${commanderColorIdentity.join(',')}',
        );
        final preferredPool = await loadPreferredNameFillers(
          pool: pool,
          preferredNames: state.aiSuggestedNames,
          commanderColorIdentity: commanderColorIdentity,
          excludeNames: existingNames.union(selectedSpellNames),
          currentDeckCards: bracketSnapshot(),
          bracket: bracket,
          limit: spellsNeeded - selectedSpells.length,
          deckFormat: deckFormat,
        );
        if (preferredPool.isNotEmpty) {
          Log.d(
            '  Fallback preferred-name aplicado (+${preferredPool.length} cartas).',
          );
          mergeUniqueSpells(await reserveIncoming(preferredPool));
        }

        if (selectedSpells.length < spellsNeeded) {
          final broadPool = await loadBroadCommanderNonLandFillers(
            pool: pool,
            currentDeckCards: bracketSnapshot(),
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(selectedSpellNames),
            bracket: bracket,
            limit: spellsNeeded - selectedSpells.length,
            deckFormat: deckFormat,
          );
          Log.d('  Broad pool retornou: ${broadPool.length} cartas.');
          if (broadPool.isNotEmpty) {
            Log.d(
              '  Fallback broad pool aplicado (+${broadPool.length} cartas).',
            );
            mergeUniqueSpells(await reserveIncoming(broadPool));
          }
        }

        if (selectedSpells.length < spellsNeeded) {
          final emergencyIdentityPool = await loadIdentitySafeNonLandFillers(
            pool: pool,
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(selectedSpellNames),
            currentDeckCards: bracketSnapshot(),
            bracket: bracket,
            limit: spellsNeeded - selectedSpells.length,
            deckFormat: deckFormat,
          );
          if (emergencyIdentityPool.isNotEmpty) {
            Log.d(
              '  Fallback identity-safe aplicado (+${emergencyIdentityPool.length} cartas).',
            );
            mergeUniqueSpells(await reserveIncoming(emergencyIdentityPool));
          }
        }
      }

      var actuallyAddedSpells = 0;
      for (final spell in selectedSpells) {
        if (state.virtualTotal >= maxTotal) break;
        final id = spell['id'] as String;
        final name = spell['name'] as String;
        final nameLower = name.toLowerCase();
        final withinIdentity = isWithinCommanderIdentity(
          cardIdentity: resolvedCardIdentity(spell),
          commanderIdentity: commanderColorIdentity,
        );
        if (!withinIdentity) continue;

        final maxCopies = maxCopiesForFormat(
          deckFormat: deckFormat,
          typeLine: '',
          name: name,
        );
        if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) continue;

        final wasAdded = _addCardToVirtualDeck(
          state: state,
          id: id,
          name: name,
          typeLine: spell['type_line'] as String? ?? '',
          oracleText: spell['oracle_text'] as String? ?? '',
          manaCost: spell['mana_cost']?.toString() ?? '',
          cmc: spell['cmc'],
          functionalTags: spell['functional_tags'],
          semanticTagsV2: spell['semantic_tags_v2'],
          bestRoleScore: spell['best_role_score'],
          colors: (spell['colors'] as List?)?.cast<String>() ?? const [],
          colorIdentity: (spell['color_identity'] as List?)?.cast<String>(),
          bracket: bracket,
        );
        if (wasAdded) actuallyAddedSpells += 1;
        _settleCompleteCandidateReservation(
          state: state,
          candidate: spell,
          accepted: wasAdded,
        );
      }

      Log.d('  Spells não-terreno adicionadas: $actuallyAddedSpells');
    } catch (e) {
      Log.w('Falha ao buscar spells sinérgicas type=${e.runtimeType}');
    } finally {
      _releaseUnsettledCompleteCandidateReservations(
        state: state,
        candidates: selectedSpells,
      );
    }
  }

  if (state.virtualTotal < maxTotal) {
    currentLands = _countCurrentLands(state.virtualDeck);
    var landsToAdd = (idealLands - currentLands).clamp(
      0,
      maxTotal - state.virtualTotal,
    );
    final remainingBasicBudget =
        (state.maxBasicAdditions - state.basicAddedDuringBuild).clamp(0, 999);
    if (landsToAdd > 0) {
      final nonBasicLimit = landsToAdd > 8 ? 8 : landsToAdd;
      final beforeNonBasic = state.virtualTotal;
      await _addIdentitySafeNonBasicLands(
        pool: pool,
        state: state,
        commanderColorIdentity: commanderColorIdentity,
        deckFormat: deckFormat,
        bracket: bracket,
        limit: nonBasicLimit,
        userId: userId,
        preferCollection: preferCollection,
        budgetLimitBrl: budgetLimitBrl,
      );
      final addedNonBasicLands = state.virtualTotal - beforeNonBasic;
      landsToAdd -= addedNonBasicLands;
    }

    landsToAdd = landsToAdd.clamp(0, remainingBasicBudget);
    if (landsToAdd > 0) {
      final basicPlan = buildWeightedBasicLandPlan(
        currentDeck: state.virtualDeck,
        commanderColorIdentity: commanderColorIdentity,
        slotsToAdd: landsToAdd,
      );
      await _addBasicLandPlanToVirtualDeck(
        pool: pool,
        state: state,
        basicPlan: basicPlan,
      );
    }
  }

  if (state.virtualTotal < maxTotal) {
    final remaining = maxTotal - state.virtualTotal;
    final existingNames =
        state.virtualDeck
            .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
            .toSet();

    final loadedFillers = await loadGuaranteedNonBasicFillers(
      pool: pool,
      currentDeckCards: state.virtualDeck,
      targetArchetype: targetArchetype,
      commanderColorIdentity: commanderColorIdentity,
      bracket: bracket,
      excludeNames: existingNames,
      preferredNames: state.aiSuggestedNames,
      limit: remaining,
      deckFormat: deckFormat,
    );
    final fillers = await _reserveCompleteCandidatesByRecommendationContext(
      pool: pool,
      state: state,
      candidates: loadedFillers,
      userId: userId,
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
    );
    if (fillers.isNotEmpty) state.deterministicStageUsed = true;

    try {
      for (final filler in fillers) {
        if (state.virtualTotal >= maxTotal) break;
        final id = filler['id'] as String;
        final name = filler['name'] as String;
        final nameLower = name.toLowerCase();
        final maxCopies = maxCopiesForFormat(
          deckFormat: deckFormat,
          typeLine: filler['type_line'] as String? ?? '',
          name: name,
        );
        if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) continue;

        final wasAdded = _addCardToVirtualDeck(
          state: state,
          id: id,
          name: name,
          typeLine: filler['type_line'] as String? ?? '',
          oracleText: filler['oracle_text'] as String? ?? '',
          manaCost: filler['mana_cost']?.toString() ?? '',
          cmc: filler['cmc'],
          functionalTags: filler['functional_tags'],
          semanticTagsV2: filler['semantic_tags_v2'],
          bestRoleScore: filler['best_role_score'],
          colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
          colorIdentity: (filler['color_identity'] as List?)?.cast<String>(),
          bracket: bracket,
        );
        _settleCompleteCandidateReservation(
          state: state,
          candidate: filler,
          accepted: wasAdded,
        );
      }
    } finally {
      _releaseUnsettledCompleteCandidateReservations(
        state: state,
        candidates: fillers,
      );
    }

    if (state.virtualTotal < maxTotal) {
      final emergencyRemaining = maxTotal - state.virtualTotal;
      final loadedEmergencyFillers = await loadEmergencyNonBasicFillers(
        pool: pool,
        currentDeckCards: state.virtualDeck,
        commanderColorIdentity: commanderColorIdentity,
        excludeNames:
            state.virtualDeck
                .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
                .where((n) => n.isNotEmpty)
                .toSet(),
        bracket: bracket,
        limit: emergencyRemaining,
        deckFormat: deckFormat,
      );
      final emergencyFillers =
          await _reserveCompleteCandidatesByRecommendationContext(
            pool: pool,
            state: state,
            candidates: loadedEmergencyFillers,
            userId: userId,
            preferCollection: preferCollection,
            budgetLimitBrl: budgetLimitBrl,
          );
      if (emergencyFillers.isNotEmpty) state.deterministicStageUsed = true;

      try {
        for (final filler in emergencyFillers) {
          if (state.virtualTotal >= maxTotal) break;
          final id = filler['id'] as String;
          final name = filler['name'] as String;
          final nameLower = name.toLowerCase();
          final maxCopies = maxCopiesForFormat(
            deckFormat: deckFormat,
            typeLine: filler['type_line'] as String? ?? '',
            name: name,
          );
          if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) {
            continue;
          }

          final wasAdded = _addCardToVirtualDeck(
            state: state,
            id: id,
            name: name,
            typeLine: filler['type_line'] as String? ?? '',
            oracleText: filler['oracle_text'] as String? ?? '',
            manaCost: filler['mana_cost']?.toString() ?? '',
            cmc: filler['cmc'],
            functionalTags: filler['functional_tags'],
            semanticTagsV2: filler['semantic_tags_v2'],
            bestRoleScore: filler['best_role_score'],
            colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
            colorIdentity: (filler['color_identity'] as List?)?.cast<String>(),
            bracket: bracket,
          );
          _settleCompleteCandidateReservation(
            state: state,
            candidate: filler,
            accepted: wasAdded,
          );
        }
      } finally {
        _releaseUnsettledCompleteCandidateReservations(
          state: state,
          candidates: emergencyFillers,
        );
      }
    }
  }

  if (state.virtualTotal < maxTotal) {
    final remaining = maxTotal - state.virtualTotal;
    await _addIdentitySafeNonBasicLands(
      pool: pool,
      state: state,
      commanderColorIdentity: commanderColorIdentity,
      deckFormat: deckFormat,
      bracket: bracket,
      limit: remaining,
      userId: userId,
      preferCollection: preferCollection,
      budgetLimitBrl: budgetLimitBrl,
    );
  }

  if (state.virtualTotal < maxTotal) {
    final remainingBasicBudget =
        (state.maxBasicAdditions - state.basicAddedDuringBuild).clamp(0, 999);
    var slotsToAdd = maxTotal - state.virtualTotal;
    if (slotsToAdd > remainingBasicBudget) {
      slotsToAdd = remainingBasicBudget;
    }
    if (slotsToAdd > 0) {
      final basicPlan = buildWeightedBasicLandPlan(
        currentDeck: state.virtualDeck,
        commanderColorIdentity: commanderColorIdentity,
        slotsToAdd: slotsToAdd,
      );
      if (basicPlan.isNotEmpty) {
        state.guaranteedBasicsStageUsed = true;
        await _addBasicLandPlanToVirtualDeck(
          pool: pool,
          state: state,
          basicPlan: basicPlan,
        );
      }
    }
  }
}

bool _addCardToVirtualDeck({
  required CompleteBuildAccumulator state,
  required String id,
  required String name,
  required String typeLine,
  required String oracleText,
  String manaCost = '',
  Object? cmc,
  Object? functionalTags,
  Object? semanticTagsV2,
  Object? bestRoleScore,
  required List<String> colors,
  required List<String>? colorIdentity,
  bool isBasic = false,
  int? bracket,
}) {
  if (bracket != null) {
    final decision = applyBracketPolicyToAdditions(
      bracket: bracket,
      currentDeckCards: state.virtualDeck,
      additionsCardsData: [
        {
          'name': name,
          'type_line': typeLine,
          'oracle_text': oracleText,
          'quantity': 1,
        },
      ],
    );
    if (decision.allowed.isEmpty) {
      state.blockedByBracketAll.addAll(decision.blocked);
      return false;
    }
  }

  final nameLower = name.toLowerCase();
  state.virtualCountsById[id] = (state.virtualCountsById[id] ?? 0) + 1;
  state.virtualCountsByName[nameLower] =
      (state.virtualCountsByName[nameLower] ?? 0) + 1;
  state.addedCountsById[id] = (state.addedCountsById[id] ?? 0) + 1;
  state.virtualTotal += 1;
  if (isBasic) {
    state.basicAddedDuringBuild += 1;
  }

  final existingIndex = state.virtualDeck.indexWhere(
    (e) => (e['card_id'] as String?) == id,
  );
  if (existingIndex == -1) {
    state.virtualDeck.add({
      'card_id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'mana_cost': manaCost,
      'cmc': switch (cmc) {
        num value => value.toDouble(),
        String value => double.tryParse(value.trim()) ?? 0.0,
        _ => 0.0,
      },
      if (functionalTags != null) 'functional_tags': functionalTags,
      if (semanticTagsV2 != null) 'semantic_tags_v2': semanticTagsV2,
      if (bestRoleScore != null) 'best_role_score': bestRoleScore,
      'colors': colors,
      'color_identity': colorIdentity,
      'quantity': 1,
      'is_commander': false,
    });
  } else {
    final existing = state.virtualDeck[existingIndex];
    state.virtualDeck[existingIndex] = {
      ...existing,
      'quantity': (existing['quantity'] as int? ?? 1) + 1,
    };
  }
  return true;
}

int _countCurrentLands(List<Map<String, dynamic>> cards) {
  return cards.fold<int>(0, (sum, card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) {
      return sum + ((card['quantity'] as int?) ?? 1);
    }
    return sum;
  });
}

double calculateCompleteAverageNonLandCmc(List<Map<String, dynamic>> cards) {
  var weightedCmc = 0.0;
  var nonLandQuantity = 0;
  for (final card in cards) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (basic_lands.isLandTypeLine(typeLine)) continue;

    final quantity = ((card['quantity'] as num?)?.toInt() ?? 1).clamp(
      0,
      1 << 20,
    );
    if (quantity <= 0) continue;
    weightedCmc +=
        safeCmcForOptimization(card, unknownNonLandFallback: 4) * quantity;
    nonLandQuantity += quantity;
  }

  // A lista ainda pode conter somente o comandante/terrenos durante uma
  // reconstrução ampla. Um valor neutro impede que metadata ausente seja
  // interpretada como curva zero e reduza artificialmente a base de mana.
  if (nonLandQuantity == 0) return 3.5;
  return weightedCmc / nonLandQuantity;
}

Map<String, dynamic> _buildCompleteFunctionalRoleFloorError({
  required CommanderFunctionalRoleFloorAssessment assessment,
  required bool finalValidation,
}) {
  final deficits = assessment.deficits;
  final singleDeficit = deficits.length == 1 ? deficits.entries.first : null;
  final stage =
      finalValidation
          ? 'na validação final: a lista resolvida'
          : 'porque a lista final';
  return {
    'code': 'COMPLETE_QUALITY_ROLE_FLOOR',
    'message':
        'Complete bloqueado $stage não cobre os pisos estruturais de '
        'ramp, compra, interação e wipes.',
    'functional_role_policy': assessment.toJson(),
    'deficits': deficits,
    if (singleDeficit != null) ...{
      // Compatibilidade com consumidores que já exibem um único déficit.
      'role': singleDeficit.key,
      'actual': assessment.actualCounts[singleDeficit.key] ?? 0,
      'minimum': assessment.minimumCounts[singleDeficit.key] ?? 0,
    },
  };
}

Map<String, dynamic> buildCompleteIntermediatePayload({
  required CompleteBuildAccumulator state,
  required int maxTotal,
  required int currentTotalCards,
  required String targetArchetype,
  required String deckFormat,
  int? bracket,
}) {
  final additionsDetailed = <Map<String, dynamic>>[];
  for (final entry in state.addedCountsById.entries) {
    additionsDetailed.add({'card_id': entry.key, 'quantity': entry.value});
  }

  final addedTotal = additionsDetailed.fold<int>(
    0,
    (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
  );
  final targetTotal = maxTotal - currentTotalCards;
  var basicAdded = 0;

  for (final entry in additionsDetailed) {
    final cardId = entry['card_id']?.toString() ?? '';
    final quantity = (entry['quantity'] as int?) ?? 0;
    final virtualMatch = state.virtualDeck.firstWhere(
      (card) => (card['card_id'] as String?) == cardId,
      orElse: () => const <String, dynamic>{},
    );
    final name = (virtualMatch['name'] as String?)?.trim().toLowerCase() ?? '';
    if (name.isNotEmpty && isBasicLandName(name)) {
      basicAdded += quantity;
    }
  }

  final nonBasicAdded = addedTotal - basicAdded;
  final manaFloorAssessment = assessCommanderManaFloor(
    format: deckFormat,
    cards: state.virtualDeck,
    minimumLandCount: state.commanderMinimumLands,
  );
  final bracketAssessment =
      deckFormat.trim().toLowerCase() == 'commander' && bracket != null
          ? assessDeckAgainstBracketPolicy(
            bracket: bracket,
            cards: state.virtualDeck,
          )
          : null;
  final functionalRoleAssessment =
      deckFormat.trim().toLowerCase() == 'commander' && targetTotal > 0
          ? assessCommanderFunctionalRoleFloors(
            cards: state.virtualDeck,
            targetArchetype: targetArchetype,
            bracket: bracket,
          )
          : null;
  final requiredWipes = functionalRoleAssessment?.minimumCounts['wipe'] ?? 0;
  final wipeCount = functionalRoleAssessment?.actualCounts['wipe'] ?? 0;
  Map<String, dynamic>? qualityError;

  if (addedTotal < targetTotal) {
    qualityError = {
      'code': 'COMPLETE_QUALITY_PARTIAL',
      'message':
          'Não foi possível completar o deck com qualidade mínima: adições insuficientes.',
      'target_additions': targetTotal,
      'added_total': addedTotal,
      'basic_added': basicAdded,
      'non_basic_added': nonBasicAdded,
    };
  } else if (bracketAssessment != null && !bracketAssessment.hardCompliant) {
    qualityError = {
      'code': 'COMPLETE_QUALITY_BRACKET_VIOLATION',
      'message':
          'Complete bloqueado: a lista final contém Game Changers '
          'incompatíveis com o Bracket ${bracketAssessment.policy.bracket}.',
      'bracket_policy': bracketAssessment.toJson(),
    };
  } else if (functionalRoleAssessment != null &&
      !functionalRoleAssessment.satisfied) {
    qualityError = _buildCompleteFunctionalRoleFloorError(
      assessment: functionalRoleAssessment,
      finalValidation: false,
    );
  } else if (!manaFloorAssessment.meetsMinimum) {
    qualityError = manaFloorAssessment.toQualityError(
      code: 'COMPLETE_QUALITY_LAND_FLOOR',
      message:
          'Complete bloqueado: a lista final teria apenas '
          '${manaFloorAssessment.landCount} terrenos; o piso seguro de '
          '${manaFoundationFormatLabel(deckFormat)} é '
          '${manaFloorAssessment.minimumLandCount}.',
    );
  } else if (manaFloorAssessment.hasSevereExcess) {
    qualityError = manaFloorAssessment.toQualityError(
      code: 'COMPLETE_QUALITY_LAND_EXCESS',
      message:
          'Complete bloqueado: a lista final teria '
          '${manaFloorAssessment.landCount} terrenos e precisa de rebuild '
          'estrutural antes de qualquer preenchimento automático.',
    );
  } else if (targetTotal >= 40 && basicAdded > state.maxBasicAdditions) {
    qualityError = {
      'code': 'COMPLETE_QUALITY_BASIC_OVERFLOW',
      'message':
          'Complete com excesso de terrenos básicos para montagem competitiva.',
      'target_additions': targetTotal,
      'added_total': addedTotal,
      'basic_added': basicAdded,
      'wipe_count': wipeCount,
      'minimum_wipe_count': requiredWipes,
      'non_basic_added': nonBasicAdded,
    };
  } else if (targetTotal >= 40 && nonBasicAdded == 0) {
    qualityError = {
      'code': 'COMPLETE_QUALITY_DEGENERATE',
      'message':
          'Complete degenerado: apenas terrenos básicos foram sugeridos para preencher o deck.',
      'target_additions': targetTotal,
      'added_total': addedTotal,
      'basic_added': basicAdded,
      'non_basic_added': nonBasicAdded,
    };
  }

  return normalizeOptimizePayload({
    'mode': 'complete',
    'mana_foundation_satisfied': manaFloorAssessment.satisfied,
    if (bracketAssessment != null) 'bracket_policy': bracketAssessment.toJson(),
    if (functionalRoleAssessment != null)
      'functional_role_policy': functionalRoleAssessment.toJson(),
    'target_additions': targetTotal,
    'iterations': state.iterations,
    'additions_detailed': additionsDetailed,
    'reasoning':
        (state.virtualTotal >= maxTotal)
            ? 'Deck completado com cartas sinérgicas ao arquétipo $targetArchetype, priorizando sinergia com o Commander e a proporção ideal de terrenos/spells.'
            : 'Deck parcialmente completado; algumas sugestões foram bloqueadas/filtradas.',
    'warnings': {
      if (state.invalidAll.isNotEmpty) 'invalid_cards': state.invalidAll,
      if (state.filteredByIdentityAll.isNotEmpty)
        'filtered_by_color_identity': {
          'removed_additions': state.filteredByIdentityAll,
        },
      if (state.filteredByLegalityAll.isNotEmpty)
        'filtered_by_format_legality': {
          'format': deckFormat,
          'removed_additions': state.filteredByLegalityAll,
        },
      if (state.blockedByBracketAll.isNotEmpty)
        'blocked_by_bracket': {'blocked_additions': state.blockedByBracketAll},
    },
    'consistency_slo': {
      'completed_target': addedTotal >= targetTotal,
      'mana_foundation_satisfied': manaFloorAssessment.satisfied,
      if (functionalRoleAssessment != null)
        'functional_role_floor_satisfied': functionalRoleAssessment.satisfied,
      if (bracketAssessment != null) ...{
        'bracket_hard_compliant': bracketAssessment.hardCompliant,
        'game_changer_count':
            bracketAssessment.counts[BracketCategory.gameChanger] ?? 0,
        'game_changer_cap': commanderBracketNumericGameChangerCap(
          bracketAssessment.policy.bracket,
        ),
        'numeric_game_changer_cap_applies':
            bracketAssessment.policy.bracket <= 3,
      },
      'ai_stage_used': state.aiStageUsed,
      'competitive_model_stage_used': state.competitiveModelStageUsed,
      'commander_profile_stage_used': state.commanderProfileStageUsed,
      'average_deck_seed_stage_used': state.averageDeckSeedStageUsed,
      'deterministic_stage_used': state.deterministicStageUsed,
      'guaranteed_basics_stage_used': state.guaranteedBasicsStageUsed,
      'added_total': addedTotal,
      'target_total': targetTotal,
      'non_basic_added': nonBasicAdded,
      'basic_added': basicAdded,
      if (manaFloorAssessment.applies) ...{
        'land_count': manaFloorAssessment.landCount,
        'minimum_land_count': manaFloorAssessment.minimumLandCount,
        'land_floor_satisfied': manaFloorAssessment.satisfied,
      },
    },
    if (state.commanderMetaEvidencePayload != null &&
        state.commanderMetaEvidencePayload!.isNotEmpty)
      'meta_reference_context': state.commanderMetaEvidencePayload,
    if (qualityError != null) 'quality_error': qualityError,
  }, defaultMode: 'optimize');
}

Future<Map<String, dynamic>> buildCompleteFinalResponse({
  required Pool pool,
  required String deckFormat,
  required List<Map<String, dynamic>> originalDeck,
  required Set<String> deckColors,
  required bool keepTheme,
  required Map<String, dynamic> theme,
  required int? bracket,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic> jsonResponse,
  required String targetArchetype,
  required String intensity,
}) async {
  final rawAdditionsDetailed =
      (jsonResponse['additions_detailed'] as List)
          .whereType<Map>()
          .map((m) {
            final mm = m.cast<String, dynamic>();
            return {
              'card_id': mm['card_id']?.toString(),
              'quantity': mm['quantity'] as int? ?? 1,
            };
          })
          .where((m) => (m['card_id'] as String?)?.isNotEmpty ?? false)
          .toList();

  final ids = rawAdditionsDetailed.map((e) => e['card_id'] as String).toList();
  final cardInfoById = <String, Map<String, dynamic>>{};
  var additionsDetailed = <Map<String, dynamic>>[];
  var resolvedAdditionsForFloor = <Map<String, dynamic>>[];
  Map<String, dynamic>? postAnalysisComplete;

  if (ids.isNotEmpty) {
    final namesAndTypes = await pool.execute(
      Sql.named('''
        SELECT
          c.id::text,
          c.name,
          c.type_line,
          c.oracle_text,
          c.mana_cost,
          c.cmc,
          ARRAY(
            SELECT DISTINCT value
            FROM unnest(
              COALESCE(cis.function_tags, ARRAY[]::text[]) ||
              COALESCE(cis.scored_roles, ARRAY[]::text[])
            ) AS role(value)
            WHERE value IS NOT NULL AND TRIM(value) <> ''
          ) AS functional_tags,
          COALESCE(cis.semantic_tags_v2, '[]'::jsonb) AS semantic_tags_v2,
          COALESCE(cis.best_role_score, 0) AS best_role_score
        FROM cards c
        LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
        WHERE c.id = ANY(@ids)
      '''),
      parameters: {'ids': ids},
    );
    for (final row in namesAndTypes) {
      cardInfoById[row[0] as String] = {
        'name': row[1] as String,
        'type_line': (row[2] as String?) ?? '',
        'oracle_text': (row[3] as String?) ?? '',
        'mana_cost': (row[4] as String?) ?? '',
        'cmc': safeToDouble(row[5]),
        'functional_tags':
            (row[6] as List?)
                ?.map((entry) => entry.toString())
                .toList(growable: false) ??
            const <String>[],
        'semantic_tags_v2': row[7],
        'best_role_score': (row[8] as num?)?.toDouble() ?? 0.0,
      };
    }

    final aggregatedByName = <String, Map<String, dynamic>>{};
    for (final entry in rawAdditionsDetailed) {
      final cardId = entry['card_id'] as String;
      final cardInfo = cardInfoById[cardId];
      if (cardInfo == null) continue;

      final name = cardInfo['name']?.toString() ?? '';
      final typeLine = cardInfo['type_line']?.toString() ?? '';
      if (name.trim().isEmpty) continue;

      final maxCopies = maxCopiesForFormat(
        deckFormat: deckFormat,
        typeLine: typeLine,
        name: name,
      );

      final existing = aggregatedByName[name.toLowerCase()];
      final currentQty = (existing?['quantity'] as int?) ?? 0;
      final incomingQty = (entry['quantity'] as int?) ?? 1;
      final allowedToAdd = (maxCopies - currentQty).clamp(0, incomingQty);
      if (allowedToAdd <= 0) continue;

      if (existing == null) {
        aggregatedByName[name.toLowerCase()] = {
          'card_id': cardId,
          'quantity': allowedToAdd,
          'name': name,
          'type_line': typeLine,
          'oracle_text': cardInfo['oracle_text'] ?? '',
          'mana_cost': cardInfo['mana_cost'] ?? '',
          'cmc': cardInfo['cmc'] ?? 0.0,
          'functional_tags': cardInfo['functional_tags'] ?? const <String>[],
          'semantic_tags_v2':
              cardInfo['semantic_tags_v2'] ?? const <Map<String, dynamic>>[],
          'best_role_score': cardInfo['best_role_score'] ?? 0.0,
        };
      } else {
        aggregatedByName[name.toLowerCase()] = {
          ...existing,
          'quantity': currentQty + allowedToAdd,
        };
      }
    }

    resolvedAdditionsForFloor = aggregatedByName.values
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    additionsDetailed =
        resolvedAdditionsForFloor
            .map(
              (e) => {
                'card_id': e['card_id'],
                'quantity': e['quantity'],
                'name': e['name'],
                'is_basic_land': isBasicLandName(
                  ((e['name'] as String?) ?? '').trim(),
                ),
              },
            )
            .toList();

    try {
      final additionsDataResult = await pool.execute(
        Sql.named('''
          SELECT name, type_line, mana_cost, colors, 
                 COALESCE(
                   (SELECT SUM(
                     CASE 
                       WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                       WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                       WHEN m[1] = 'X' THEN 0
                       ELSE 1
                     END
                   ) FROM regexp_matches(mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
                   0
                 ) as cmc,
                 oracle_text
          FROM cards 
          WHERE id = ANY(@ids)
        '''),
        parameters: {'ids': ids},
      );

      final additionsData =
          additionsDataResult
              .map(
                (row) => {
                  'name': (row[0] as String?) ?? '',
                  'type_line': (row[1] as String?) ?? '',
                  'mana_cost': (row[2] as String?) ?? '',
                  'colors': (row[3] as List?)?.cast<String>() ?? [],
                  'cmc': (row[4] as num?)?.toDouble() ?? 0.0,
                  'oracle_text': (row[5] as String?) ?? '',
                },
              )
              .toList();

      final additionsForAnalysis =
          additionsDetailed.map((add) {
            final data = additionsData.firstWhere(
              (d) =>
                  (d['name'] as String).toLowerCase() ==
                  ((add['name'] as String?) ?? '').toLowerCase(),
              orElse:
                  () => {
                    'name': add['name'] ?? '',
                    'type_line': '',
                    'mana_cost': '',
                    'colors': <String>[],
                    'cmc': 0.0,
                    'oracle_text': '',
                  },
            );
            return {...data, 'quantity': (add['quantity'] as int?) ?? 1};
          }).toList();

      final virtualDeck = buildVirtualDeckForAnalysis(
        originalDeck: originalDeck,
        additions: additionsForAnalysis,
      );
      final postAnalyzer = DeckArchetypeAnalyzerCore(
        virtualDeck,
        deckColors.toList(),
        deckFormat: deckFormat,
      );
      postAnalysisComplete = postAnalyzer.generateAnalysis();
    } catch (e) {
      Log.w(
        'Falha ao gerar post_analysis para modo complete '
        'type=${e.runtimeType}',
      );
    }
  }

  final intermediateConsistency =
      jsonResponse['consistency_slo'] is Map
          ? (jsonResponse['consistency_slo'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  final intermediateMinimumLandCount =
      switch (intermediateConsistency['minimum_land_count']) {
        num value => value.toInt(),
        String value => int.tryParse(value.trim()),
        _ => null,
      };
  final finalManaFloorAssessment = assessCommanderManaFloor(
    format: deckFormat,
    cards: [...originalDeck, ...resolvedAdditionsForFloor],
    minimumLandCount: intermediateMinimumLandCount,
  );
  final finalBracketAssessment =
      deckFormat.trim().toLowerCase() == 'commander' && bracket != null
          ? assessDeckAgainstBracketPolicy(
            bracket: bracket,
            cards: [...originalDeck, ...resolvedAdditionsForFloor],
          )
          : null;
  final targetAdditionCount = switch (jsonResponse['target_additions']) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()) ?? 0,
    _ => 0,
  };
  final finalFunctionalRoleAssessment =
      deckFormat.trim().toLowerCase() == 'commander' && targetAdditionCount > 0
          ? assessCommanderFunctionalRoleFloors(
            cards: [...originalDeck, ...resolvedAdditionsForFloor],
            targetArchetype: targetArchetype,
            bracket: bracket,
          )
          : null;
  final responseBody = <String, dynamic>{
    'mode': 'complete',
    'mana_foundation_satisfied': finalManaFloorAssessment.satisfied,
    'constraints': {'keep_theme': keepTheme},
    'theme': theme,
    'bracket': bracket,
    if (finalBracketAssessment != null)
      'bracket_policy': finalBracketAssessment.toJson(),
    if (finalFunctionalRoleAssessment != null)
      'functional_role_policy': finalFunctionalRoleAssessment.toJson(),
    'target_additions': jsonResponse['target_additions'],
    'iterations': jsonResponse['iterations'],
    'additions':
        additionsDetailed.map((e) => e['name'] ?? e['card_id']).toList(),
    'additions_detailed':
        additionsDetailed
            .map(
              (e) => {
                'card_id': e['card_id'],
                'quantity': e['quantity'],
                'name': e['name'],
                'is_basic_land':
                    e['is_basic_land'] ??
                    isBasicLandName(((e['name'] as String?) ?? '').trim()),
              },
            )
            .toList(),
    'removals': const <String>[],
    'removals_detailed': const <Map<String, dynamic>>[],
    'reasoning': jsonResponse['reasoning'] ?? '',
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysisComplete,
    'validation_warnings': const <String>[],
  };
  if (finalBracketAssessment != null && !finalBracketAssessment.hardCompliant) {
    responseBody
      ..['quality_error'] = {
        'code': 'COMPLETE_QUALITY_BRACKET_VIOLATION',
        'message':
            'Complete bloqueado na validação final: a lista resolvida contém '
            'Game Changers incompatíveis com o Bracket '
            '${finalBracketAssessment.policy.bracket}.',
        'bracket_policy': finalBracketAssessment.toJson(),
      }
      ..['can_apply'] = false
      ..['learning_eligible'] = false
      ..['apply_blockers'] = ['commander_bracket_policy_violation'];
  } else if (finalFunctionalRoleAssessment != null &&
      !finalFunctionalRoleAssessment.satisfied) {
    responseBody
      ..['quality_error'] = _buildCompleteFunctionalRoleFloorError(
        assessment: finalFunctionalRoleAssessment,
        finalValidation: true,
      )
      ..['can_apply'] = false
      ..['learning_eligible'] = false
      ..['apply_blockers'] = ['commander_functional_role_floor_not_met'];
  } else if (!finalManaFloorAssessment.satisfied) {
    final excessive = finalManaFloorAssessment.hasSevereExcess;
    responseBody
      ..['quality_error'] = finalManaFloorAssessment.toQualityError(
        code:
            excessive
                ? 'COMPLETE_QUALITY_LAND_EXCESS'
                : 'COMPLETE_QUALITY_LAND_FLOOR',
        message:
            excessive
                ? 'Complete bloqueado na validação final: a lista resolvida '
                    'teria ${finalManaFloorAssessment.landCount} terrenos e '
                    'exige rebuild estrutural.'
                : 'Complete bloqueado na validação final: a lista resolvida '
                    'teria ${finalManaFloorAssessment.landCount} terrenos; o '
                    'piso seguro é '
                    '${finalManaFloorAssessment.minimumLandCount}.',
      )
      ..['can_apply'] = false
      ..['learning_eligible'] = false
      ..['apply_blockers'] = [
        excessive
            ? 'commander_land_excess_requires_rebuild'
            : 'commander_land_floor_not_met',
      ];
  }

  responseBody['optimization_contract'] = {
    ...buildOptimizeDecisionContract(
      mode: 'complete',
      targetArchetype: targetArchetype,
      intensity: intensity,
      keepTheme: keepTheme,
      additionCount: additionsDetailed.fold<int>(
        0,
        (sum, entry) => sum + ((entry['quantity'] as int?) ?? 1),
      ),
      removalCount: 0,
    ),
    'mana_foundation': buildOptimizationManaFoundationContract(
      format: deckFormat,
      minimumLandCount: finalManaFloorAssessment.minimumLandCount,
      landCount: finalManaFloorAssessment.landCount,
      satisfied: finalManaFloorAssessment.satisfied,
    ),
    if (finalFunctionalRoleAssessment != null)
      'functional_role_policy': finalFunctionalRoleAssessment.toJson(),
  };
  responseBody['battle_validation'] =
      (responseBody['optimization_contract'] as Map)['battle_validation'];

  final warnings =
      (jsonResponse['warnings'] is Map)
          ? (jsonResponse['warnings'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  if (warnings.isNotEmpty) {
    responseBody['warnings'] = warnings;
  }

  final qualityWarning = jsonResponse['quality_warning'];
  if (qualityWarning is Map) {
    responseBody['quality_warning'] = qualityWarning.cast<String, dynamic>();
  }

  final consistencySlo = jsonResponse['consistency_slo'];
  if (consistencySlo is Map) {
    responseBody['consistency_slo'] = consistencySlo.cast<String, dynamic>();
  }
  if (finalManaFloorAssessment.applies) {
    responseBody['consistency_slo'] = {
      ...?responseBody['consistency_slo'] as Map<String, dynamic>?,
      'mana_foundation_satisfied': finalManaFloorAssessment.satisfied,
      'land_count': finalManaFloorAssessment.landCount,
      'minimum_land_count': finalManaFloorAssessment.minimumLandCount,
      'land_floor_satisfied': finalManaFloorAssessment.satisfied,
      if (finalFunctionalRoleAssessment != null) ...{
        'functional_role_floor_satisfied':
            finalFunctionalRoleAssessment.satisfied,
        'wipe_count': finalFunctionalRoleAssessment.actualCounts['wipe'] ?? 0,
        'minimum_wipe_count':
            finalFunctionalRoleAssessment.minimumCounts['wipe'] ?? 0,
      },
      if (finalBracketAssessment != null) ...{
        'bracket_hard_compliant': finalBracketAssessment.hardCompliant,
        'game_changer_count':
            finalBracketAssessment.counts[BracketCategory.gameChanger] ?? 0,
        'game_changer_cap': commanderBracketNumericGameChangerCap(
          finalBracketAssessment.policy.bracket,
        ),
        'numeric_game_changer_cap_applies':
            finalBracketAssessment.policy.bracket <= 3,
      },
    };
  }

  final metaReferenceContext = jsonResponse['meta_reference_context'];
  if (metaReferenceContext is Map) {
    responseBody['meta_reference_context'] =
        augmentMetaDeckEvidencePayloadWithOutputMatches(
          metaReferenceContext.cast<String, dynamic>(),
          outputCardNames: additionsDetailed.map(
            (entry) => '${entry['name'] ?? ''}',
          ),
        );
  }

  return responseBody;
}
