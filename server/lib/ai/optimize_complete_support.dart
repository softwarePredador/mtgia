import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../card_validation_service.dart';
import '../edh_bracket_policy.dart';
import '../logger.dart';
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
    final recommended = (state.commanderRecommendedLands ?? 38).clamp(28, 42);
    state.maxBasicAdditions = recommended + 6;
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

  final priorityNames = await loadCommanderCompetitivePriorities(
    pool: pool,
    commanderName: commanderName,
    limit: 120,
  );
  if (priorityNames.isNotEmpty) {
    state.competitiveModelStageUsed = true;
    state.commanderMetaPriorityNames.addAll(priorityNames);
    state.aiSuggestedNames.addAll(priorityNames.map((e) => e.toLowerCase()));
  } else {
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

  while (state.iterations < maxIterations && state.virtualTotal < maxTotal) {
    state.iterations++;
    final missingNow = maxTotal - state.virtualTotal;

    Map<String, dynamic> iterResponse;
    try {
      iterResponse = await optimizer.completeDeck(
        deckData: {
          'cards': state.virtualDeck,
          'colors': deckColors.toList(),
        },
        commanders: commanders,
        targetArchetype: targetArchetype,
        targetAdditions: missingNow,
        bracket: bracket,
        keepTheme: keepTheme,
        detectedTheme: detectedTheme,
        coreCards: coreCards,
      );
    } catch (e) {
      Log.w(
        'Falha no completeDeck da IA; aplicando fallback determinístico. iteration=${state.iterations} missing=$missingNow error=$e',
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

      var selectedSpells = await findSynergyReplacements(
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

      if (selectedSpells.isEmpty) {
        final universalFallback = await loadUniversalCommanderFallbacks(
          pool: pool,
          excludeNames: existingNames,
          limit: spellsNeeded,
        );
        if (universalFallback.isNotEmpty) {
          Log.d(
            '  Synergy replacements vazios; aplicando fallback universal (${universalFallback.length} cartas).',
          );
          selectedSpells = universalFallback;
        }
      }

      if (selectedSpells.length < spellsNeeded) {
        Log.d(
          '  Expansão de spells ativada: selected=${selectedSpells.length}, spellsNeeded=$spellsNeeded, identity=${commanderColorIdentity.join(',')}',
        );
        final alreadySelectedNames = selectedSpells
            .map((e) => ((e['name'] as String?) ?? '').toLowerCase())
            .where((name) => name.isNotEmpty)
            .toSet();

        final preferredPool = await loadPreferredNameFillers(
          pool: pool,
          preferredNames: state.aiSuggestedNames,
          commanderColorIdentity: commanderColorIdentity,
          excludeNames: existingNames.union(alreadySelectedNames),
          limit: spellsNeeded - selectedSpells.length,
        );
        if (preferredPool.isNotEmpty) {
          Log.d(
            '  Fallback preferred-name aplicado (+${preferredPool.length} cartas).',
          );
          selectedSpells = [...selectedSpells, ...preferredPool];
        }

        if (selectedSpells.length < spellsNeeded) {
          final broadPool = await loadBroadCommanderNonLandFillers(
            pool: pool,
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(alreadySelectedNames),
            bracket: bracket,
            limit: spellsNeeded - selectedSpells.length,
          );
          Log.d('  Broad pool retornou: ${broadPool.length} cartas.');
          if (broadPool.isNotEmpty) {
            Log.d(
              '  Fallback broad pool aplicado (+${broadPool.length} cartas).',
            );
            selectedSpells = [...selectedSpells, ...broadPool];
          }
        }

        if (selectedSpells.length < spellsNeeded) {
          final emergencyIdentityPool = await loadIdentitySafeNonLandFillers(
            pool: pool,
            commanderColorIdentity: commanderColorIdentity,
            excludeNames: existingNames.union(alreadySelectedNames),
            limit: spellsNeeded - selectedSpells.length,
          );
          if (emergencyIdentityPool.isNotEmpty) {
            Log.d(
              '  Fallback identity-safe aplicado (+${emergencyIdentityPool.length} cartas).',
            );
            selectedSpells = [...selectedSpells, ...emergencyIdentityPool];
          }
        }
      }

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
      }

      Log.d('  Spells não-terreno adicionadas: ${selectedSpells.length}');
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
    landsToAdd = landsToAdd.clamp(0, remainingBasicBudget);
    final basicNames = basicLandNamesForIdentity(commanderColorIdentity);
    final basicsWithIds = await loadBasicLandIds(pool, basicNames);
    if (basicsWithIds.isNotEmpty) {
      final keys = basicsWithIds.keys.toList();
      var i = 0;
      while (landsToAdd > 0) {
        final name = keys[i % keys.length];
        final id = basicsWithIds[name]!;
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
        landsToAdd--;
        i++;
      }
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
    final basicNames = basicLandNamesForIdentity(commanderColorIdentity);
    final basicsWithIds = await loadBasicLandIds(pool, basicNames);
    if (basicsWithIds.isNotEmpty) {
      state.guaranteedBasicsStageUsed = true;
      final keys = basicsWithIds.keys.toList();
      var i = 0;
      while (state.virtualTotal < maxTotal &&
          state.basicAddedDuringBuild < state.maxBasicAdditions) {
        final name = keys[i % keys.length];
        final id = basicsWithIds[name]!;
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
        i++;
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
  } else if (targetTotal >= 40 &&
      basicAdded >
          ((state.commanderRecommendedLands ?? 38).clamp(28, 42) + 6)) {
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

  return responseBody;
}
