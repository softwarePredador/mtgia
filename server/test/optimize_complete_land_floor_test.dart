import 'dart:io';

import 'package:server/ai/optimize_complete_support.dart';
import 'package:test/test.dart';

void main() {
  test(
    'complete uses persisted commander reference packages as a safe seed',
    () {
      final source =
          File('lib/ai/optimize_complete_support.dart').readAsStringSync();

      expect(source, contains('loadUsableCommanderReferenceCardStats'));
      expect(source, contains('state.commanderProfileStageUsed = true'));
      expect(
        source,
        contains('referenceNames.map((name) => name.toLowerCase())'),
      );
    },
  );

  test('complete payload preserves the proven explicit-budget blocker', () {
    final cards = <Map<String, dynamic>>[
      const {
        'card_id': 'commander',
        'name': 'Lorehold, the Historian',
        'type_line': 'Legendary Creature — Elder Dragon',
        'quantity': 1,
        'is_commander': true,
      },
    ];
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: const {'commander': 1},
      currentTotalCards: 1,
    );
    state.recordRecommendationConstraintDiagnostics(
      const {
        'input_count': 2,
        'output_count': 1,
        'budget_limit_brl': 100.0,
        'budget_used_brl': 99.0,
        'budget_blocked_count': 1,
        'budget_exceeded_blocked_count': 1,
        'budget_blocked_additions': [
          {
            'name': 'Expensive Spell',
            'reason': 'budget_exceeded',
            'estimated_price_brl': 25.0,
          },
        ],
        'price_source': 'cards.price_usd_estimated_brl',
        'usd_to_brl_rate': 5.5,
      },
      validationWarnings: const ['Uma carta excedeu o orçamento.'],
    );

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'Miracle Big Spells',
      deckFormat: 'commander',
      bracket: 2,
      budgetLimitBrl: 100,
    );
    final quality = payload['quality_error'] as Map;

    expect(quality['code'], 'COMPLETE_RECOMMENDATION_CONSTRAINTS_UNSATISFIED');
    expect(quality['budget_limit_brl'], 100);
    expect(quality['message'], contains('desative o limite'));
    expect(quality['next_action'], 'increase_or_disable_budget_limit');
    final constraints = quality['recommendation_constraints'] as Map;
    expect(constraints['budget_blocked_count'], 1);
    expect(constraints['budget_exceeded_blocked_count'], 1);
    expect(constraints['satisfied'], isFalse);
    expect(
      (constraints['budget_blocked_additions'] as List).single,
      containsPair('name', 'Expensive Spell'),
    );
  });

  test(
    'complete accumulates recommendation blockers across candidate batches',
    () {
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: const <Map<String, dynamic>>[],
        originalCountsById: const <String, int>{},
        currentTotalCards: 0,
      );
      state.recordRecommendationConstraintDiagnostics(const {
        'input_count': 3,
        'output_count': 2,
        'budget_limit_brl': 50.0,
        'budget_blocked_count': 1,
        'missing_price_blocked_count': 1,
        'budget_blocked_additions': [
          {'name': 'Unknown Price', 'reason': 'missing_price'},
        ],
      });
      state.recordRecommendationConstraintDiagnostics(const {
        'input_count': 4,
        'output_count': 2,
        'budget_limit_brl': 50.0,
        'budget_blocked_count': 2,
        'budget_exceeded_blocked_count': 2,
        'budget_blocked_additions': [
          {'name': 'Costly One', 'reason': 'budget_exceeded'},
          {'name': 'Costly Two', 'reason': 'budget_exceeded'},
        ],
      });

      final diagnostics = state.recommendationConstraintDiagnostics;
      expect(diagnostics['input_count'], 7);
      expect(diagnostics['output_count'], 4);
      expect(diagnostics['budget_blocked_count'], 3);
      expect(diagnostics['missing_price_blocked_count'], 1);
      expect(diagnostics['budget_exceeded_blocked_count'], 2);
      expect(diagnostics['budget_blocked_additions'], hasLength(3));
      expect(state.hasExplicitBudgetConstraintBlock, isTrue);
    },
  );

  test(
    'explicit budget without a recorded budget block remains catalog partial',
    () {
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: const [
          {
            'card_id': 'commander',
            'name': 'Lorehold, the Historian',
            'type_line': 'Legendary Creature — Elder Dragon',
            'quantity': 1,
            'is_commander': true,
          },
        ],
        originalCountsById: const {'commander': 1},
        currentTotalCards: 1,
      );

      final payload = buildCompleteIntermediatePayload(
        state: state,
        maxTotal: 100,
        currentTotalCards: 1,
        targetArchetype: 'Miracle Big Spells',
        deckFormat: 'commander',
        bracket: 2,
        budgetLimitBrl: 100,
      );

      expect(
        (payload['quality_error'] as Map)['code'],
        'COMPLETE_QUALITY_PARTIAL',
      );
    },
  );

  test('final resolution count gate rejects unresolved additions', () {
    final response = <String, dynamic>{
      'can_apply': true,
      'learning_eligible': true,
    };
    final satisfied = applyCompleteFinalResolutionCountGate(
      responseBody: response,
      targetAdditionCount: 99,
      rawAdditionCount: 99,
      resolvedAdditionCount: 98,
      unresolvedAdditionCount: 1,
      unresolvedCardIds: const ['missing-card-id'],
    );
    final quality = response['quality_error'] as Map;

    expect(satisfied, isFalse);
    expect(quality['code'], 'COMPLETE_FINAL_RESOLUTION_COUNT_MISMATCH');
    expect(quality['missing_additions'], 1);
    expect(quality['unresolved_additions'], 1);
    expect(quality['unresolved_card_ids'], ['missing-card-id']);
    expect(quality['message'], contains('Nenhuma alteração parcial'));
    expect(response['can_apply'], isFalse);
    expect(response['learning_eligible'], isFalse);
    expect(
      response['apply_blockers'],
      contains('complete_final_addition_count_mismatch'),
    );
  });

  test('final resolution count gate accepts only an exact target', () {
    expect(
      buildCompleteFinalResolutionCountError(
        targetAdditionCount: 99,
        rawAdditionCount: 99,
        resolvedAdditionCount: 99,
      ),
      isNull,
    );
    expect(
      buildCompleteFinalResolutionCountError(
        targetAdditionCount: 99,
        rawAdditionCount: 100,
        resolvedAdditionCount: 100,
      ),
      isNotNull,
    );
  });

  test(
    'complete payload fails closed when final Commander deck has 9 lands',
    () {
      final cards = <Map<String, dynamic>>[
        const {
          'card_id': 'commander',
          'name': 'Lorehold, the Historian',
          'type_line': 'Legendary Creature — Elder Dragon',
          'quantity': 1,
          'is_commander': true,
        },
        const {
          'card_id': 'command-tower',
          'name': 'Command Tower',
          'type_line': 'Land',
          'quantity': 1,
        },
        for (var index = 0; index < 8; index++)
          {
            'card_id': 'land-$index',
            'name': 'Utility Land $index',
            'type_line': 'Land',
            'quantity': 1,
          },
        for (var index = 0; index < 90; index++)
          {
            'card_id': 'spell-$index',
            'name': 'Spell $index',
            'type_line': 'Sorcery',
            'quantity': 1,
          },
      ];
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 100,
      );

      final payload = buildCompleteIntermediatePayload(
        state: state,
        maxTotal: 100,
        currentTotalCards: 100,
        targetArchetype: 'midrange',
        deckFormat: 'commander',
      );

      expect(
        (payload['quality_error'] as Map)['code'],
        'COMPLETE_QUALITY_LAND_FLOOR',
      );
      expect(
        (payload['consistency_slo'] as Map)['land_floor_satisfied'],
        isFalse,
      );
      expect(payload['mana_foundation_satisfied'], isFalse);
    },
  );

  test('complete payload accepts the strategic floor of 34 lands', () {
    final cards = <Map<String, dynamic>>[
      const {
        'card_id': 'commander',
        'name': 'Lorehold, the Historian',
        'type_line': 'Legendary Creature — Elder Dragon',
        'quantity': 1,
        'is_commander': true,
      },
      const {
        'card_id': 'plains',
        'name': 'Plains // Plains',
        'type_line': 'Basic Land — Plains',
        'quantity': 17,
      },
      const {
        'card_id': 'mountain',
        'name': 'Mountain // Mountain',
        'type_line': 'Basic Land — Mountain',
        'quantity': 17,
      },
      for (var index = 0; index < 65; index++)
        {
          'card_id': 'spell-$index',
          'name': 'Spell $index',
          'type_line': 'Sorcery',
          'quantity': 1,
        },
    ];
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: {
        for (final card in cards)
          card['card_id'] as String: card['quantity'] as int,
      },
      currentTotalCards: 100,
    );

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 100,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
    );

    expect(payload['quality_error'], isNull);
    expect((payload['consistency_slo'] as Map)['land_floor_satisfied'], isTrue);
    expect(payload['mana_foundation_satisfied'], isTrue);
  });

  test('complete payload rejects a structurally flooded deck', () {
    final cards = <Map<String, dynamic>>[
      const {
        'card_id': 'commander',
        'name': 'Commander',
        'type_line': 'Legendary Creature',
        'quantity': 1,
        'is_commander': true,
      },
      const {
        'card_id': 'plains',
        'name': 'Plains',
        'type_line': 'Basic Land — Plains',
        'quantity': 90,
      },
      const {
        'card_id': 'spell',
        'name': 'Spell',
        'type_line': 'Sorcery',
        'quantity': 9,
      },
    ];
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: {
        for (final card in cards)
          card['card_id'] as String: card['quantity'] as int,
      },
      currentTotalCards: 100,
    );

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 100,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
    );

    expect(
      (payload['quality_error'] as Map)['code'],
      'COMPLETE_QUALITY_LAND_EXCESS',
    );
    expect(payload['mana_foundation_satisfied'], isFalse);
  });

  test('complete payload honors a stricter commander profile floor', () {
    final cards = <Map<String, dynamic>>[
      const {
        'card_id': 'commander',
        'name': 'Lorehold, the Historian',
        'type_line': 'Legendary Creature — Elder Dragon',
        'quantity': 1,
        'is_commander': true,
      },
      const {
        'card_id': 'plains',
        'name': 'Plains // Plains',
        'type_line': 'Basic Land — Plains',
        'quantity': 18,
      },
      const {
        'card_id': 'mountain',
        'name': 'Mountain // Mountain',
        'type_line': 'Basic Land — Mountain',
        'quantity': 17,
      },
      for (var index = 0; index < 64; index++)
        {
          'card_id': 'spell-$index',
          'name': 'Spell $index',
          'type_line': 'Sorcery',
          'quantity': 1,
        },
    ];
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: {
        for (final card in cards)
          card['card_id'] as String: card['quantity'] as int,
      },
      currentTotalCards: 100,
    );
    state.commanderRecommendedLands = 35;
    state.commanderMinimumLands = 36;

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 100,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
    );

    expect(
      (payload['quality_error'] as Map)['code'],
      'COMPLETE_QUALITY_LAND_FLOOR',
    );
    expect((payload['consistency_slo'] as Map)['minimum_land_count'], 36);
  });

  test('large Core completion fails closed when a Game Changer leaks', () {
    final cards = _completeCommanderDeck(
      includeWipes: true,
      extraSpell: const {
        'card_id': 'mox-diamond',
        'name': 'Mox Diamond',
        'type_line': 'Artifact',
        'quantity': 1,
      },
    );
    final state = _stateRepresentingCommanderCompletion(cards);

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 2,
    );

    expect(
      (payload['quality_error'] as Map)['code'],
      'COMPLETE_QUALITY_BRACKET_VIOLATION',
    );
    expect((payload['bracket_policy'] as Map)['hard_compliant'], isFalse);
    expect((payload['bracket_policy'] as Map)['game_changer_count'], 1);
  });

  test('large Core completion counts a Game Changer commander', () {
    final cards = _completeCommanderDeck(
      includeWipes: true,
      commanderName: 'Braids, Cabal Minion',
    );
    final state = _stateRepresentingCommanderCompletion(cards);

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 2,
    );

    expect(
      (payload['quality_error'] as Map)['code'],
      'COMPLETE_QUALITY_BRACKET_VIOLATION',
    );
    expect((payload['bracket_policy'] as Map)['game_changer_count'], 1);
    expect(
      ((payload['bracket_policy'] as Map)['violations'] as List).single,
      containsPair('name', 'Braids, Cabal Minion'),
    );
  });

  test('large Commander completion requires the archetype wipe floor', () {
    final cards = _completeCommanderDeck(includeWipes: false);
    final state = _stateRepresentingCommanderCompletion(cards);

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 2,
    );

    final error = (payload['quality_error'] as Map).cast<String, dynamic>();
    expect(error['code'], 'COMPLETE_QUALITY_ROLE_FLOOR');
    expect(error['role'], 'wipe');
    expect(error['actual'], 0);
    expect(error['minimum'], 2);
  });

  test('small Commander completion also requires the wipe floor', () {
    final cards = _completeCommanderDeck(includeWipes: false);
    final state = CompleteBuildAccumulator.fromDeck(
      allCardData: cards,
      originalCountsById: {
        for (final card in cards.take(cards.length - 1))
          card['card_id'] as String: card['quantity'] as int,
      },
      currentTotalCards: 99,
    );
    state.addedCountsById[cards.last['card_id'] as String] = 1;

    final payload = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 99,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 2,
    );

    final error = (payload['quality_error'] as Map).cast<String, dynamic>();
    expect(error['code'], 'COMPLETE_QUALITY_ROLE_FLOOR');
    expect(error['role'], 'wipe');
    expect(error['actual'], 0);
    expect(error['minimum'], 2);
  });

  test('Complete applies the distinct B4 and B5 wipe floors', () {
    final withoutWipes = _completeCommanderDeck(includeWipes: false);
    final state = _stateRepresentingCommanderCompletion(withoutWipes);

    final optimized = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 4,
    );
    final optimizedError =
        (optimized['quality_error'] as Map).cast<String, dynamic>();
    expect(optimizedError['code'], 'COMPLETE_QUALITY_ROLE_FLOOR');
    expect(optimizedError['role'], 'wipe');
    expect(optimizedError['minimum'], 1);

    final competitive = buildCompleteIntermediatePayload(
      state: state,
      maxTotal: 100,
      currentTotalCards: 1,
      targetArchetype: 'midrange',
      deckFormat: 'commander',
      bracket: 5,
    );
    expect(competitive['quality_error'], isNull);
    expect((competitive['functional_role_policy'] as Map)['satisfied'], isTrue);
    expect((competitive['functional_role_policy'] as Map)['bracket'], 5);
  });

  test(
    'complete frees generated filler slots so the wipe floor can be repaired',
    () {
      final cards = _completeCommanderDeck(includeWipes: false);
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 100,
      );
      final generatedIds = [
        cards[cards.length - 1]['card_id'] as String,
        cards[cards.length - 2]['card_id'] as String,
      ];
      for (final id in generatedIds) {
        state.addedCountsById[id] = 1;
      }

      final freed = rebalanceCompleteDeckForFunctionalRoleDeficits(
        state: state,
        maxTotal: 100,
        deckFormat: 'commander',
        targetArchetype: 'midrange',
      );

      expect(freed, 2);
      expect(state.virtualTotal, 98);
      expect(
        generatedIds.every((id) => !state.addedCountsById.containsKey(id)),
        isTrue,
      );
      expect(
        state.virtualDeck.any((card) => generatedIds.contains(card['card_id'])),
        isFalse,
      );
    },
  );

  test(
    'complete preserves generated cards when open slots cover wipe needs',
    () {
      final cards =
          _completeCommanderDeck(includeWipes: false)
            ..removeLast()
            ..removeLast();
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 98,
      );
      final generatedId = cards.last['card_id'] as String;
      state.addedCountsById[generatedId] = 1;
      state.commanderRecommendedLands = 36;

      final freed = rebalanceCompleteDeckForFunctionalRoleDeficits(
        state: state,
        maxTotal: 100,
        deckFormat: 'commander',
        targetArchetype: 'midrange',
      );

      expect(freed, 0);
      expect(state.virtualTotal, 98);
      expect(state.addedCountsById[generatedId], 1);
    },
  );

  test(
    'complete does not reuse land-reserved slots for critical role floors',
    () {
      final cards = <Map<String, dynamic>>[
        const {
          'card_id': 'commander',
          'name': 'Atraxa, Praetors\' Voice',
          'type_line': 'Legendary Creature — Phyrexian Angel Horror',
          'quantity': 1,
          'is_commander': true,
        },
        const {
          'card_id': 'plains',
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 18,
        },
        const {
          'card_id': 'island',
          'name': 'Island',
          'type_line': 'Basic Land — Island',
          'quantity': 18,
        },
        for (var index = 0; index < 63; index++)
          {
            'card_id': 'generic-$index',
            'name': 'Generic Spell $index',
            'type_line': 'Creature',
            'oracle_text': 'Vigilance.',
            'quantity': 1,
          },
      ];
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 100,
      );
      state.commanderRecommendedLands = 40;
      for (final card in cards.where(
        (card) => (card['card_id'] as String).startsWith('generic-'),
      )) {
        state.addedCountsById[card['card_id'] as String] = 1;
      }

      rebalanceCompleteDeckForLandDeficit(
        state: state,
        maxTotal: 100,
        deckFormat: 'commander',
        targetArchetype: 'control',
        bracket: 1,
      );
      expect(
        completeOutstandingLandDeficit(state: state, deckFormat: 'commander'),
        4,
      );
      expect(state.virtualTotal, 96);

      final roleFreed = rebalanceCompleteDeckForFunctionalRoleDeficits(
        state: state,
        maxTotal: 100,
        deckFormat: 'commander',
        targetArchetype: 'control',
        bracket: 1,
      );

      const criticalRoleDeficit = 8 + 8 + 6 + 3;
      expect(roleFreed, criticalRoleDeficit);
      expect(state.virtualTotal, 100 - 4 - criticalRoleDeficit);
      expect(
        100 - state.virtualTotal,
        completeOutstandingLandDeficit(state: state, deckFormat: 'commander') +
            criticalRoleDeficit,
      );
    },
  );

  test(
    'complete preserves an at-floor multi-role card while freeing generic slots',
    () {
      final cards = _completeCommanderDeck(includeWipes: false);
      final state = CompleteBuildAccumulator.fromDeck(
        allCardData: cards,
        originalCountsById: {
          for (final card in cards)
            card['card_id'] as String: card['quantity'] as int,
        },
        currentTotalCards: 100,
      );
      const structuralId = 'structural-engine';
      final genericIds = <String>[
        cards.last['card_id'] as String,
        cards[cards.length - 2]['card_id'] as String,
      ];
      state.addedCountsById[structuralId] = 1;
      for (final id in genericIds) {
        state.addedCountsById[id] = 1;
      }

      final freed = rebalanceCompleteDeckForFunctionalRoleDeficits(
        state: state,
        maxTotal: 100,
        deckFormat: 'commander',
        targetArchetype: 'midrange',
        bracket: 2,
      );

      expect(freed, 2);
      expect(state.addedCountsById[structuralId], 1);
      expect(
        state.virtualDeck.any((card) => card['card_id'] == structuralId),
        isTrue,
      );
      expect(
        genericIds.every((id) => !state.addedCountsById.containsKey(id)),
        isTrue,
      );
    },
  );

  test('Complete runtime propagates bracket into structural rebalancing', () {
    final source =
        File('lib/ai/optimize_route_internal.dart').readAsStringSync();
    final callStart = source.indexOf(
      'rebalanceCompleteDeckForFunctionalRoleDeficits(',
    );
    expect(callStart, greaterThanOrEqualTo(0));
    final callEnd = source.indexOf('),', callStart);
    expect(callEnd, greaterThan(callStart));
    expect(source.substring(callStart, callEnd), contains('bracket: bracket'));
  });

  test('critical Complete needs do not duplicate planned wipe deficits', () {
    expect(
      mergeCriticalCompleteFunctionalNeeds(
        criticalNeeds: const ['wipe', 'wipe'],
        plannedNeeds: const ['draw', 'wipe', 'ramp', 'wipe', 'removal'],
        limit: 5,
      ),
      const ['wipe', 'wipe', 'draw', 'ramp', 'removal'],
    );
  });
}

List<Map<String, dynamic>> _completeCommanderDeck({
  required bool includeWipes,
  Map<String, dynamic>? extraSpell,
  String commanderName = 'Lorehold, the Historian',
}) {
  final cards = <Map<String, dynamic>>[
    {
      'card_id': 'commander',
      'name': commanderName,
      'type_line': 'Legendary Creature — Elder Dragon',
      'quantity': 1,
      'is_commander': true,
    },
    const {
      'card_id': 'plains',
      'name': 'Plains',
      'type_line': 'Basic Land — Plains',
      'quantity': 18,
    },
    const {
      'card_id': 'mountain',
      'name': 'Mountain',
      'type_line': 'Basic Land — Mountain',
      'quantity': 18,
    },
    const {
      'card_id': 'structural-engine',
      'name': 'Persistent Structural Engine',
      'type_line': 'Artifact',
      'oracle_text':
          '{T}: Add one mana of any color. Whenever you cast your second '
          'spell each turn, draw a card. {2}, {T}: Exile target nonland '
          'permanent.',
      'functional_tags': ['ramp', 'draw', 'interaction'],
      'quantity': 8,
    },
    if (includeWipes)
      const {
        'card_id': 'wipe-1',
        'name': 'Wrath of God',
        'type_line': 'Sorcery',
        'oracle_text': 'Destroy all creatures.',
        'functional_tags': ['board_wipe'],
        'quantity': 1,
      },
    if (includeWipes)
      const {
        'card_id': 'wipe-2',
        'name': 'Blasphemous Act',
        'type_line': 'Sorcery',
        'oracle_text': 'Blasphemous Act deals 13 damage to each creature.',
        'functional_tags': ['board_wipe'],
        'quantity': 1,
      },
    if (extraSpell != null) extraSpell,
  ];
  final occupied = cards.fold<int>(
    0,
    (sum, card) => sum + (card['quantity'] as int),
  );
  for (var index = 0; index < 100 - occupied; index++) {
    cards.add({
      'card_id': 'spell-$index',
      'name': 'Spell $index',
      'type_line': 'Creature',
      'oracle_text': 'A fair creature.',
      'quantity': 1,
    });
  }
  return cards;
}

CompleteBuildAccumulator _stateRepresentingCommanderCompletion(
  List<Map<String, dynamic>> cards,
) {
  final state = CompleteBuildAccumulator.fromDeck(
    allCardData: cards,
    originalCountsById: const {'commander': 1},
    currentTotalCards: 1,
  );
  state.virtualTotal = 100;
  for (final card in cards) {
    final id = card['card_id'] as String;
    if (id == 'commander') continue;
    state.addedCountsById[id] = card['quantity'] as int;
  }
  return state;
}
