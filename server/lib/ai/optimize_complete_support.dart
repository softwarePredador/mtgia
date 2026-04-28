import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../card_validation_service.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
import '../meta/meta_deck_reference_support.dart';
import 'edhrec_service.dart';
import 'optimize_deck_support.dart';
import 'optimize_runtime_support.dart';
import 'optimize_state_support.dart';
import 'otimizacao.dart';

class CompleteBuildAccumulator {
  final List<Map<String, dynamic>> virtualDeck;
  final Map<String, int> virtualCountsById;
  final Map<String, int> virtualCountsByName;
  final Map<String, int> addedCountsById;
  final List<Map<String, dynamic>> blockedByBracketAll;
  final List<String> filteredByIdentityAll;
  final List<String> invalidAll;
  final Set<String> aiSuggestedNames;
  final Set<String> commanderMetaPriorityNames;
  String? commanderMetaEvidenceText;
  Map<String, dynamic>? commanderMetaEvidencePayload;
  int virtualTotal;
  int maxBasicAdditions = 999;
  int? commanderRecommendedLands;
  bool aiStageUsed = false;
  bool deterministicStageUsed = false;
  bool guaranteedBasicsStageUsed = false;
  bool competitiveModelStageUsed = false;
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
    this.invalidAll = const <String>[],
    this.aiSuggestedNames = const <String>{},
    this.commanderMetaPriorityNames = const <String>{},
  });

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
      invalidAll: <String>[],
      aiSuggestedNames: <String>{},
      commanderMetaPriorityNames: <String>{},
    );
  }
}

Future<void> prepareCompleteCommanderSeed({
  required Pool pool,
  required List<String> commanders,
  required int maxTotal,
  required int currentTotalCards,
  required CompleteBuildAccumulator state,
  int? bracket,
}) async {
  final targetAdditionsForComplete = maxTotal - currentTotalCards;
  if (commanders.isEmpty) return;

  final commanderName = commanders.first.trim();
  if (commanderName.isEmpty) return;

  final commanderReferenceProfile =
      await loadCommanderReferenceProfileFromCache(
    pool: pool,
    commanderName: commanderName,
  );
  state.commanderRecommendedLands =
      extractRecommendedLandsFromProfile(commanderReferenceProfile);

  if (targetAdditionsForComplete >= 40) {
    state.maxBasicAdditions = calculateCompleteMaxBasicAdditions(
      state.commanderRecommendedLands,
    );
  }

  final averageDeckSeedNames = extractAverageDeckSeedNamesFromProfile(
    commanderReferenceProfile,
    limit: 140,
  );
  if (averageDeckSeedNames.isNotEmpty) {
    state.averageDeckSeedStageUsed = true;
    state.aiSuggestedNames
        .addAll(averageDeckSeedNames.map((e) => e.toLowerCase()));
  }

  final commanderMetaScope = resolveCommanderOptimizeMetaScope(
    deckFormat: 'commander',
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
    final priorityNames = metaReferenceSelection.priorityCardNames.isNotEmpty
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
      state.aiSuggestedNames
          .addAll(competitivePriorityNames.map((e) => e.toLowerCase()));
    }
  }

  if (state.aiSuggestedNames.isEmpty) {
    final profileTopNames = extractTopCardNamesFromProfile(
      commanderReferenceProfile,
      limit: 80,
    );
    if (profileTopNames.isNotEmpty) {
      state.aiSuggestedNames
          .addAll(profileTopNames.map((e) => e.toLowerCase()));
      state.competitiveModelStageUsed = true;
    }
  }

  if (state.aiSuggestedNames.isEmpty) {
    try {
      final liveEdhrec =
          await EdhrecService().fetchCommanderData(commanderName);
      if (liveEdhrec != null && liveEdhrec.topCards.isNotEmpty) {
        final liveNames = liveEdhrec.topCards
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
      Log.w('Falha ao carregar EDHREC live para fallback complete: $e');
    }
  }
}

int calculateCompleteMaxBasicAdditions(int? commanderRecommendedLands) {
  final recommended = (commanderRecommendedLands ?? 38).clamp(28, 42);
  final buffered = recommended + 4;
  return buffered > 40 ? 40 : buffered;
}

Map<String, int> _buildColorDemandMap({
  required List<Map<String, dynamic>> currentDeck,
  required Set<String> commanderColorIdentity,
}) {
  final demand = <String, int>{};
  for (final color in commanderColorIdentity) {
    demand[color] = 0;
  }

  for (final card in currentDeck) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) continue;

    final quantity = (card['quantity'] as int?) ?? 1;
    final manaCost = (card['mana_cost'] as String?) ?? '';
    final explicitSymbols = <String, int>{};
    for (final color in commanderColorIdentity) {
      final symbolCount = RegExp(
        '\\{${color.toLowerCase()}\\}',
        caseSensitive: false,
      ).allMatches(manaCost).length;
      if (symbolCount > 0) {
        explicitSymbols[color] = symbolCount * quantity;
      }
    }

    if (explicitSymbols.isNotEmpty) {
      for (final entry in explicitSymbols.entries) {
        demand[entry.key] = (demand[entry.key] ?? 0) + entry.value;
      }
      continue;
    }

    final fallbackIdentity = resolvedCardIdentity(card)
        .where(commanderColorIdentity.contains)
        .toSet();
    if (fallbackIdentity.isEmpty) continue;

    final fallbackWeight =
        fallbackIdentity.length == 1 ? 2 * quantity : quantity;
    for (final color in fallbackIdentity) {
      demand[color] = (demand[color] ?? 0) + fallbackWeight;
    }
  }

  return demand;
}

List<String> buildWeightedBasicLandPlan({
  required List<Map<String, dynamic>> currentDeck,
  required Set<String> commanderColorIdentity,
  required int slotsToAdd,
}) {
  if (slotsToAdd <= 0) return const [];
  if (commanderColorIdentity.isEmpty) {
    return List<String>.filled(slotsToAdd, 'Wastes');
  }

  final colors = commanderColorIdentity.toList()..sort();
  final analyzer = DeckArchetypeAnalyzerCore(currentDeck, colors);
  final manaBase = analyzer.analyzeManaBase();
  final rawSymbols = _buildColorDemandMap(
    currentDeck: currentDeck,
    commanderColorIdentity: commanderColorIdentity,
  );
  final rawSources = (manaBase['sources'] as Map?)?.cast<String, int>() ??
      const <String, int>{};
  final projectedSources = <String, int>{};
  for (final color in colors) {
    projectedSources[color] = rawSources[color] ?? 0;
  }
  final anySource = rawSources['Any'] ?? 0;
  final totalSymbols = colors.fold<int>(
    0,
    (sum, color) => sum + (rawSymbols[color] ?? 0),
  );
  final plan = <String>[];

  for (var i = 0; i < slotsToAdd; i++) {
    String? bestColor;
    var bestScore = -1 << 30;

    for (final color in colors) {
      final symbolCount = rawSymbols[color] ?? 0;
      final sourceCount = (projectedSources[color] ?? 0) + anySource;
      final percent = totalSymbols > 0 ? symbolCount / totalSymbols : 0.0;
      final targetSources = symbolCount <= 0
          ? 6
          : percent > 0.30
              ? 15
              : percent > 0.10
                  ? 10
                  : 8;
      final deficit = targetSources - sourceCount;
      final score = (deficit * 100) + (symbolCount * 3) - sourceCount;
      if (bestColor == null || score > bestScore) {
        bestColor = color;
        bestScore = score;
      }
    }

    final chosenColor = bestColor ?? colors.first;
    plan.add(basicLandNameForColor(chosenColor));
    projectedSources[chosenColor] = (projectedSources[chosenColor] ?? 0) + 1;
  }

  return plan;
}

Future<void> _addBasicLandPlanToVirtualDeck({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required List<String> basicPlan,
}) async {
  if (basicPlan.isEmpty) return;
  final basicsWithIds =
      await loadBasicLandIds(pool, basicPlan.toSet().toList());
  if (basicsWithIds.isEmpty) return;

  for (final name in basicPlan) {
    final id = basicsWithIds[name];
    if (id == null) continue;
    _addCardToVirtualDeck(
      state: state,
      id: id,
      name: name,
      typeLine: 'Basic Land',
      oracleText: '',
      colors: const <String>[],
      colorIdentity: const <String>[],
      isBasic: true,
    );
  }
}

Future<void> _addIdentitySafeNonBasicLands({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required int limit,
}) async {
  if (limit <= 0) return;

  final excludeNames = state.virtualDeck
      .map((c) => ((c['name'] as String?) ?? '').trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();
  final fillers = await loadIdentitySafeNonBasicLandFillers(
    pool: pool,
    commanderColorIdentity: commanderColorIdentity,
    excludeNames: excludeNames,
    limit: limit,
  );

  var added = 0;
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

    _addCardToVirtualDeck(
      state: state,
      id: id,
      name: name,
      typeLine: filler['type_line'] as String? ?? '',
      oracleText: filler['oracle_text'] as String? ?? '',
      colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
      colorIdentity:
          (filler['color_identity'] as List?)?.cast<String>() ?? const [],
    );
    added += 1;
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
      commanderColorIdentity: commanderColorIdentity,
      deckFormat: deckFormat,
      targetArchetype: targetArchetype,
      detectedTheme: detectedTheme,
      bracket: bracket,
      maxTotal: maxTotal,
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
      iterResponse = await optimizer.completeDeck(
        deckData: {
          'cards': state.virtualDeck,
          'colors': deckColors.toList(),
        },
        commanders: commanders,
        targetArchetype: targetArchetype,
        targetAdditions: requestedAdditions,
        bracket: bracket,
        keepTheme: keepTheme,
        detectedTheme: detectedTheme,
        coreCards: coreCards,
        metaEvidenceContext: state.commanderMetaEvidenceText,
      ).timeout(aiTimeout);
    } catch (e) {
      Log.w(
        'Falha no completeDeck da IA; aplicando fallback determinístico. '
        'iteration=${state.iterations} missing=$missingNow requested=$requestedAdditions '
        'timeout_s=${aiTimeout.inSeconds} error=$e',
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
    state.invalidAll
        .addAll((validation['invalid'] as List?)?.cast<String>() ?? const []);

    final validList =
        (validation['valid'] as List).cast<Map<String, dynamic>>();
    final validNames = validList.map((v) => (v['name'] as String)).toList();
    if (validNames.isEmpty) break;

    final additionsInfoResult = await pool.execute(
      Sql.named('''
        SELECT id::text, name, type_line, oracle_text, colors, color_identity
        FROM cards
        WHERE name = ANY(@names)
      '''),
      parameters: {'names': validNames},
    );
    if (additionsInfoResult.isEmpty) break;

    final candidates = additionsInfoResult.map((r) {
      final id = r[0] as String;
      final name = r[1] as String;
      final typeLine = r[2] as String? ?? '';
      final oracle = r[3] as String? ?? '';
      final colors = (r[4] as List?)?.cast<String>() ?? const <String>[];
      final identity = (r[5] as List?)?.cast<String>() ?? const <String>[];
      return {
        'card_id': id,
        'name': name,
        'type_line': typeLine,
        'oracle_text': oracle,
        'colors': colors,
        'color_identity': identity,
      };
    }).toList();

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

    var addedThisIter = 0;
    for (final candidate in bracketAllowed) {
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

      _addCardToVirtualDeck(
        state: state,
        id: id,
        name: name,
        typeLine: candidate['type_line'] as String? ?? '',
        oracleText: candidate['oracle_text'] as String? ?? '',
        colors: (candidate['colors'] as List?)?.cast<String>() ?? const [],
        colorIdentity:
            (candidate['color_identity'] as List?)?.cast<String>() ?? const [],
        isBasic: isBasic,
      );
      addedThisIter += 1;
    }

    if (addedThisIter == 0) break;
  }
}

Future<int> _bootstrapSparseCompleteInput({
  required Pool pool,
  required CompleteBuildAccumulator state,
  required Set<String> commanderColorIdentity,
  required String deckFormat,
  required String targetArchetype,
  required String detectedTheme,
  required int? bracket,
  required int maxTotal,
}) async {
  final currentLands = _countCurrentLands(state.virtualDeck);
  final targetLands = (state.commanderRecommendedLands ?? 36).clamp(32, 40);
  final targetSpells =
      (maxTotal - targetLands).clamp(state.virtualTotal, maxTotal);
  final spellSlotsToFill = (targetSpells - state.virtualTotal).clamp(0, 48);
  if (spellSlotsToFill <= 0) return 0;

  final existingNames = state.virtualDeck
      .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();

  final selected = <Map<String, dynamic>>[];
  final selectedNames = <String>{};

  void addUnique(Iterable<Map<String, dynamic>> items) {
    for (final item in items) {
      final lowerName = ((item['name'] as String?) ?? '').trim().toLowerCase();
      if (lowerName.isEmpty) continue;
      if (existingNames.contains(lowerName) ||
          selectedNames.contains(lowerName)) {
        continue;
      }
      selected.add(item);
      selectedNames.add(lowerName);
      if (selected.length >= spellSlotsToFill) {
        return;
      }
    }
  }

  final foundationPool = await loadArchetypeCommanderFoundationFillers(
    pool: pool,
    commanderColorIdentity: commanderColorIdentity,
    targetArchetype: targetArchetype,
    detectedTheme: detectedTheme,
    excludeNames: existingNames,
    limit: spellSlotsToFill,
  );
  addUnique(foundationPool);

  if (selected.length < spellSlotsToFill) {
    final universalPool = await loadUniversalCommanderFallbacks(
      pool: pool,
      excludeNames: existingNames.union(selectedNames),
      commanderColorIdentity: commanderColorIdentity,
      limit: spellSlotsToFill - selected.length,
    );
    addUnique(universalPool);
  }

  final preferredPool = await loadPreferredNameFillers(
    pool: pool,
    preferredNames: state.aiSuggestedNames,
    commanderColorIdentity: commanderColorIdentity,
    excludeNames: existingNames.union(selectedNames),
    limit: spellSlotsToFill - selected.length,
  );
  addUnique(preferredPool);

  if (selected.length < spellSlotsToFill) {
    final broadPool = await loadBroadCommanderNonLandFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: existingNames.union(selectedNames),
      bracket: bracket,
      limit: spellSlotsToFill - selected.length,
    );
    addUnique(broadPool);
  }

  if (selected.length < spellSlotsToFill) {
    final identitySafePool = await loadIdentitySafeNonLandFillers(
      pool: pool,
      commanderColorIdentity: commanderColorIdentity,
      excludeNames: existingNames.union(selectedNames),
      limit: spellSlotsToFill - selected.length,
    );
    addUnique(identitySafePool);
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
        (candidate['color_identity'] as List?)?.cast<String>() ?? const [];
    final nameLower = name.toLowerCase();
    final maxCopies = maxCopiesForFormat(
      deckFormat: deckFormat,
      typeLine: typeLine,
      name: name,
    );

    if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) continue;

    _addCardToVirtualDeck(
      state: state,
      id: id,
      name: name,
      typeLine: typeLine,
      oracleText: oracleText,
      colors: colors,
      colorIdentity: colorIdentity,
    );
    added += 1;
  }

  if (added > 0) {
    state.deterministicStageUsed = true;
    Log.i(
      'Complete sparse bootstrap: current_lands=$currentLands target_lands=$targetLands '
      'spell_slots=$spellSlotsToFill added=$added foundation_pool=${foundationPool.length} preferred_pool=${preferredPool.length}',
    );
  }

  return added;
}

void rebalanceCompleteDeckForLandDeficit({
  required CompleteBuildAccumulator state,
  required int maxTotal,
}) {
  var currentLands = 0;
  for (final card in state.virtualDeck) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) {
      currentLands += (card['quantity'] as int?) ?? 1;
    }
  }

  final nonLandCards = state.virtualDeck.where((card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    return !typeLine.contains('land');
  }).toList();

  var avgCmc = 0.0;
  if (nonLandCards.isNotEmpty) {
    avgCmc = nonLandCards.fold<double>(0, (sum, card) {
          return sum + ((card['cmc'] as num?)?.toDouble() ?? 0.0);
        }) /
        nonLandCards.length;
  }

  final idealLands = (state.commanderRecommendedLands ??
          (avgCmc < 2.0 ? 32 : (avgCmc < 3.0 ? 35 : (avgCmc < 4.0 ? 37 : 39))))
      .clamp(28, 42);
  final landDeficit = idealLands - currentLands;
  final slotsAvailable = maxTotal - state.virtualTotal;

  if (landDeficit <= slotsAvailable || landDeficit <= 0) {
    return;
  }

  final slotsToFree = landDeficit - slotsAvailable;
  Log.d(
    'Land rebalancing: deficit=$landDeficit, available=$slotsAvailable, freeing=$slotsToFree slots',
  );

  var freed = 0;
  for (var i = state.virtualDeck.length - 1;
      i >= 0 && freed < slotsToFree;
      i--) {
    final card = state.virtualDeck[i];
    final cardId = card['card_id'] as String?;
    if (cardId == null) continue;
    if (!state.addedCountsById.containsKey(cardId)) continue;

    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) continue;
    if (card['is_commander'] == true) continue;

    final qty = (card['quantity'] as int?) ?? 1;
    final addedQty = state.addedCountsById[cardId] ?? 0;
    if (addedQty <= 0) continue;

    state.addedCountsById[cardId] = addedQty - 1;
    if (state.addedCountsById[cardId]! <= 0) {
      state.addedCountsById.remove(cardId);
    }

    state.virtualCountsById[cardId] =
        (state.virtualCountsById[cardId] ?? 1) - 1;
    final nameLower = ((card['name'] as String?) ?? '').toLowerCase();
    state.virtualCountsByName[nameLower] =
        (state.virtualCountsByName[nameLower] ?? 1) - 1;
    state.virtualTotal -= 1;

    if (qty <= 1) {
      state.virtualDeck.removeAt(i);
    } else {
      state.virtualDeck[i] = {...card, 'quantity': qty - 1};
    }
    freed += 1;
  }

  Log.d('Land rebalancing: freed $freed slots for lands');
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
}) async {
  if (state.virtualTotal >= maxTotal) return;

  final missing = maxTotal - state.virtualTotal;
  var currentLands = _countCurrentLands(state.virtualDeck);
  final avgCmc = _calculateAverageNonLandCmc(state.virtualDeck);
  final idealLands = (state.commanderRecommendedLands ??
          (avgCmc < 2.0 ? 32 : (avgCmc < 3.0 ? 35 : (avgCmc < 4.0 ? 37 : 39))))
      .clamp(28, 42);
  final landsNeeded = (idealLands - currentLands).clamp(0, missing);
  final spellsNeeded = missing - landsNeeded;

  Log.d('Complete fallback inteligente:');
  Log.d(
    '  Cartas faltando: $missing | Lands atuais: $currentLands | Ideal: $idealLands',
  );
  Log.d(
      '  Lands a adicionar: $landsNeeded | Spells a adicionar: $spellsNeeded');

  if (spellsNeeded > 0) {
    try {
      final existingNames = state.virtualDeck
          .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
          .toSet();
      final selectedSpells = <Map<String, dynamic>>[];
      final selectedSpellNames = <String>{};
      void mergeUniqueSpells(List<Map<String, dynamic>> incoming) {
        for (final item in incoming) {
          final lowerName =
              ((item['name'] as String?) ?? '').trim().toLowerCase();
          if (lowerName.isEmpty) continue;
          if (existingNames.contains(lowerName) ||
              selectedSpellNames.contains(lowerName)) {
            continue;
          }
          selectedSpells.add(item);
          selectedSpellNames.add(lowerName);
          if (selectedSpells.length >= spellsNeeded) {
            return;
          }
        }
      }

      final initialSynergySpells = await findSynergyReplacements(
        pool: pool,
        commanders: commanders,
        commanderColorIdentity: commanderColorIdentity,
        targetArchetype: targetArchetype,
        bracket: bracket,
        keepTheme: keepTheme,
        detectedTheme: detectedTheme,
        coreCards: coreCards,
        missingCount: spellsNeeded,
        removedCards: const [],
        excludeNames: existingNames,
        allCardData: state.virtualDeck,
        preferredNames: state.aiSuggestedNames,
      );
      mergeUniqueSpells(dedupeCandidatesByName(initialSynergySpells));

      if (selectedSpells.isEmpty) {
        final universalFallback = await loadUniversalCommanderFallbacks(
          pool: pool,
          excludeNames: existingNames,
          commanderColorIdentity: commanderColorIdentity,
          limit: spellsNeeded,
        );
        if (universalFallback.isNotEmpty) {
          Log.d(
            '  Synergy replacements vazios; aplicando fallback universal (${universalFallback.length} cartas).',
          );
          mergeUniqueSpells(universalFallback);
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
          limit: spellsNeeded - selectedSpells.length,
        );
        if (foundationFallback.isNotEmpty) {
          Log.d(
            '  Fallback foundation aplicado (+${foundationFallback.length} cartas).',
          );
          mergeUniqueSpells(foundationFallback);
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
          limit: spellsNeeded - selectedSpells.length,
        );
        if (preferredPool.isNotEmpty) {
          Log.d(
            '  Fallback preferred-name aplicado (+${preferredPool.length} cartas).',
          );
          mergeUniqueSpells(preferredPool);
        }

        if (selectedSpells.length < spellsNeeded) {
          final broadPool = await loadBroadCommanderNonLandFillers(
            pool: pool,
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(selectedSpellNames),
            bracket: bracket,
            limit: spellsNeeded - selectedSpells.length,
          );
          Log.d('  Broad pool retornou: ${broadPool.length} cartas.');
          if (broadPool.isNotEmpty) {
            Log.d(
              '  Fallback broad pool aplicado (+${broadPool.length} cartas).',
            );
            mergeUniqueSpells(broadPool);
          }
        }

        if (selectedSpells.length < spellsNeeded) {
          final emergencyIdentityPool = await loadIdentitySafeNonLandFillers(
            pool: pool,
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(selectedSpellNames),
            limit: spellsNeeded - selectedSpells.length,
          );
          if (emergencyIdentityPool.isNotEmpty) {
            Log.d(
              '  Fallback identity-safe aplicado (+${emergencyIdentityPool.length} cartas).',
            );
            mergeUniqueSpells(emergencyIdentityPool);
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

        _addCardToVirtualDeck(
          state: state,
          id: id,
          name: name,
          typeLine: '',
          oracleText: '',
          colors: const <String>[],
          colorIdentity: const <String>[],
        );
        actuallyAddedSpells += 1;
      }

      Log.d('  Spells não-terreno adicionadas: $actuallyAddedSpells');
    } catch (e) {
      Log.w('Falha ao buscar spells sinérgicas: $e');
    }
  }

  if (state.virtualTotal < maxTotal) {
    currentLands = _countCurrentLands(state.virtualDeck);
    var landsToAdd =
        (idealLands - currentLands).clamp(0, maxTotal - state.virtualTotal);
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
        limit: nonBasicLimit,
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
    final existingNames = state.virtualDeck
        .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
        .toSet();

    final fillers = await loadGuaranteedNonBasicFillers(
      pool: pool,
      currentDeckCards: state.virtualDeck,
      targetArchetype: targetArchetype,
      commanderColorIdentity: commanderColorIdentity,
      bracket: bracket,
      excludeNames: existingNames,
      preferredNames: state.aiSuggestedNames,
      limit: remaining,
    );
    if (fillers.isNotEmpty) state.deterministicStageUsed = true;

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

      _addCardToVirtualDeck(
        state: state,
        id: id,
        name: name,
        typeLine: filler['type_line'] as String? ?? '',
        oracleText: filler['oracle_text'] as String? ?? '',
        colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
        colorIdentity:
            (filler['color_identity'] as List?)?.cast<String>() ?? const [],
      );
    }

    if (state.virtualTotal < maxTotal) {
      final emergencyRemaining = maxTotal - state.virtualTotal;
      final emergencyFillers = await loadEmergencyNonBasicFillers(
        pool: pool,
        excludeNames: state.virtualDeck
            .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
            .where((n) => n.isNotEmpty)
            .toSet(),
        bracket: bracket,
        limit: emergencyRemaining,
      );
      if (emergencyFillers.isNotEmpty) state.deterministicStageUsed = true;

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
        if ((state.virtualCountsByName[nameLower] ?? 0) >= maxCopies) continue;

        _addCardToVirtualDeck(
          state: state,
          id: id,
          name: name,
          typeLine: filler['type_line'] as String? ?? '',
          oracleText: filler['oracle_text'] as String? ?? '',
          colors: (filler['colors'] as List?)?.cast<String>() ?? const [],
          colorIdentity:
              (filler['color_identity'] as List?)?.cast<String>() ?? const [],
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
      limit: remaining,
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

void _addCardToVirtualDeck({
  required CompleteBuildAccumulator state,
  required String id,
  required String name,
  required String typeLine,
  required String oracleText,
  required List<String> colors,
  required List<String> colorIdentity,
  bool isBasic = false,
}) {
  final nameLower = name.toLowerCase();
  state.virtualCountsById[id] = (state.virtualCountsById[id] ?? 0) + 1;
  state.virtualCountsByName[nameLower] =
      (state.virtualCountsByName[nameLower] ?? 0) + 1;
  state.addedCountsById[id] = (state.addedCountsById[id] ?? 0) + 1;
  state.virtualTotal += 1;
  if (isBasic) {
    state.basicAddedDuringBuild += 1;
  }

  final existingIndex =
      state.virtualDeck.indexWhere((e) => (e['card_id'] as String?) == id);
  if (existingIndex == -1) {
    state.virtualDeck.add({
      'card_id': id,
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'colors': colors,
      'color_identity': colorIdentity,
      'quantity': 1,
      'is_commander': false,
      'mana_cost': '',
      'cmc': 0.0,
    });
  } else {
    final existing = state.virtualDeck[existingIndex];
    state.virtualDeck[existingIndex] = {
      ...existing,
      'quantity': (existing['quantity'] as int? ?? 1) + 1,
    };
  }
}

int _countCurrentLands(List<Map<String, dynamic>> cards) {
  return cards.fold<int>(0, (sum, card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (typeLine.contains('land')) {
      return sum + ((card['quantity'] as int?) ?? 1);
    }
    return sum;
  });
}

double _calculateAverageNonLandCmc(List<Map<String, dynamic>> cards) {
  final nonLandCards = cards.where((card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    return !typeLine.contains('land');
  }).toList();

  if (nonLandCards.isEmpty) return 0.0;

  return nonLandCards.fold<double>(0, (sum, card) {
        return sum + ((card['cmc'] as num?)?.toDouble() ?? 0.0);
      }) /
      nonLandCards.length;
}

Map<String, dynamic> buildCompleteIntermediatePayload({
  required CompleteBuildAccumulator state,
  required int maxTotal,
  required int currentTotalCards,
  required String targetArchetype,
}) {
  final additionsDetailed = <Map<String, dynamic>>[];
  for (final entry in state.addedCountsById.entries) {
    additionsDetailed.add({
      'card_id': entry.key,
      'quantity': entry.value,
    });
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
  } else if (targetTotal >= 40 && basicAdded > state.maxBasicAdditions) {
    qualityError = {
      'code': 'COMPLETE_QUALITY_BASIC_OVERFLOW',
      'message':
          'Complete com excesso de terrenos básicos para montagem competitiva.',
      'target_additions': targetTotal,
      'added_total': addedTotal,
      'basic_added': basicAdded,
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
    'target_additions': targetTotal,
    'iterations': state.iterations,
    'additions_detailed': additionsDetailed,
    'reasoning': (state.virtualTotal >= maxTotal)
        ? 'Deck completado com cartas sinérgicas ao arquétipo $targetArchetype, priorizando sinergia com o Commander e a proporção ideal de terrenos/spells.'
        : 'Deck parcialmente completado; algumas sugestões foram bloqueadas/filtradas.',
    'warnings': {
      if (state.invalidAll.isNotEmpty) 'invalid_cards': state.invalidAll,
      if (state.filteredByIdentityAll.isNotEmpty)
        'filtered_by_color_identity': {
          'removed_additions': state.filteredByIdentityAll,
        },
      if (state.blockedByBracketAll.isNotEmpty)
        'blocked_by_bracket': {
          'blocked_additions': state.blockedByBracketAll,
        },
    },
    'consistency_slo': {
      'completed_target': addedTotal >= targetTotal,
      'ai_stage_used': state.aiStageUsed,
      'competitive_model_stage_used': state.competitiveModelStageUsed,
      'average_deck_seed_stage_used': state.averageDeckSeedStageUsed,
      'deterministic_stage_used': state.deterministicStageUsed,
      'guaranteed_basics_stage_used': state.guaranteedBasicsStageUsed,
      'added_total': addedTotal,
      'target_total': targetTotal,
      'non_basic_added': nonBasicAdded,
      'basic_added': basicAdded,
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
}) async {
  final rawAdditionsDetailed = (jsonResponse['additions_detailed'] as List)
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
  final cardInfoById = <String, Map<String, String>>{};
  var additionsDetailed = <Map<String, dynamic>>[];
  Map<String, dynamic>? postAnalysisComplete;

  if (ids.isNotEmpty) {
    final namesAndTypes = await pool.execute(
      Sql.named(
          'SELECT id::text, name, type_line FROM cards WHERE id = ANY(@ids)'),
      parameters: {'ids': ids},
    );
    for (final row in namesAndTypes) {
      cardInfoById[row[0] as String] = {
        'name': row[1] as String,
        'type_line': (row[2] as String?) ?? '',
      };
    }

    final aggregatedByName = <String, Map<String, dynamic>>{};
    for (final entry in rawAdditionsDetailed) {
      final cardId = entry['card_id'] as String;
      final cardInfo = cardInfoById[cardId];
      if (cardInfo == null) continue;

      final name = cardInfo['name'] ?? '';
      final typeLine = cardInfo['type_line'] ?? '';
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
        };
      } else {
        aggregatedByName[name.toLowerCase()] = {
          ...existing,
          'quantity': currentQty + allowedToAdd,
        };
      }
    }

    additionsDetailed = aggregatedByName.values
        .map((e) => {
              'card_id': e['card_id'],
              'quantity': e['quantity'],
              'name': e['name'],
              'is_basic_land':
                  isBasicLandName(((e['name'] as String?) ?? '').trim()),
            })
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

      final additionsData = additionsDataResult
          .map((row) => {
                'name': (row[0] as String?) ?? '',
                'type_line': (row[1] as String?) ?? '',
                'mana_cost': (row[2] as String?) ?? '',
                'colors': (row[3] as List?)?.cast<String>() ?? [],
                'cmc': (row[4] as num?)?.toDouble() ?? 0.0,
                'oracle_text': (row[5] as String?) ?? '',
              })
          .toList();

      final additionsForAnalysis = additionsDetailed.map((add) {
        final data = additionsData.firstWhere(
          (d) =>
              (d['name'] as String).toLowerCase() ==
              ((add['name'] as String?) ?? '').toLowerCase(),
          orElse: () => {
            'name': add['name'] ?? '',
            'type_line': '',
            'mana_cost': '',
            'colors': <String>[],
            'cmc': 0.0,
            'oracle_text': '',
          },
        );
        return {
          ...data,
          'quantity': (add['quantity'] as int?) ?? 1,
        };
      }).toList();

      final virtualDeck = buildVirtualDeckForAnalysis(
        originalDeck: originalDeck,
        additions: additionsForAnalysis,
      );
      final postAnalyzer = DeckArchetypeAnalyzerCore(
        virtualDeck,
        deckColors.toList(),
      );
      postAnalysisComplete = postAnalyzer.generateAnalysis();
    } catch (e) {
      Log.w('Falha ao gerar post_analysis para modo complete: $e');
    }
  }

  final responseBody = <String, dynamic>{
    'mode': 'complete',
    'constraints': {
      'keep_theme': keepTheme,
    },
    'theme': theme,
    'bracket': bracket,
    'target_additions': jsonResponse['target_additions'],
    'iterations': jsonResponse['iterations'],
    'additions':
        additionsDetailed.map((e) => e['name'] ?? e['card_id']).toList(),
    'additions_detailed': additionsDetailed
        .map((e) => {
              'card_id': e['card_id'],
              'quantity': e['quantity'],
              'name': e['name'],
              'is_basic_land': e['is_basic_land'] ??
                  isBasicLandName(((e['name'] as String?) ?? '').trim()),
            })
        .toList(),
    'removals': const <String>[],
    'removals_detailed': const <Map<String, dynamic>>[],
    'reasoning': jsonResponse['reasoning'] ?? '',
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysisComplete,
    'validation_warnings': const <String>[],
  };

  final warnings = (jsonResponse['warnings'] is Map)
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

  final metaReferenceContext = jsonResponse['meta_reference_context'];
  if (metaReferenceContext is Map) {
    responseBody['meta_reference_context'] =
        augmentMetaDeckEvidencePayloadWithOutputMatches(
      metaReferenceContext.cast<String, dynamic>(),
      outputCardNames:
          additionsDetailed.map((entry) => '${entry['name'] ?? ''}'),
    );
  }

  return responseBody;
}
