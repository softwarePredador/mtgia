import 'package:test/test.dart';

import '../lib/ai/deck_state_analysis.dart';
import '../lib/ai/optimize_deck_support.dart';
import '../lib/ai/optimize_state_support.dart';

void main() {
  group('Commander mana-base floor', () {
    const symbols = {'W': 20, 'U': 0, 'B': 0, 'R': 0, 'G': 0};
    const sources = {'W': 20, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'Any': 0};

    test('core assessment flags 32 lands against the 34 floor', () {
      final assessment = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        32,
      );

      expect(assessment, contains('Poucos terrenos'));
      expect(assessment, contains('Tem 32'));
      expect(assessment, contains('mínimo seguro 34'));
    });

    test('route analyzer uses the same floor and message', () {
      final analyzer = DeckArchetypeAnalyzer(
        const [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'oracle_text': '{T}: Add {W}.',
            'quantity': 32,
          },
          {
            'name': 'White Spell',
            'type_line': 'Sorcery',
            'mana_cost': '{W}',
            'oracle_text': 'Draw a card.',
            'quantity': 1,
          },
        ],
        const ['W'],
      );

      final assessment = analyzer.analyzeManaBase()['assessment'] as String;
      expect(assessment, contains('Poucos terrenos'));
      expect(assessment, contains('mínimo seguro 34'));
    });

    test('34 lands no longer emits the low-land warning', () {
      final assessment = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        34,
      );

      expect(assessment, isNot(contains('Poucos terrenos')));
    });

    test('colorless Commander still reports a low land count', () {
      final coreAssessment = DeckArchetypeAnalyzerCore.assessManaBase(
        const {'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0},
        const {'W': 0, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'Any': 0},
        9,
      );
      final routeAssessment =
          DeckArchetypeAnalyzer(const [
            {
              'name': 'Wastes',
              'type_line': 'Basic Land — Wastes',
              'oracle_text': '{T}: Add {C}.',
              'quantity': 9,
            },
            {
              'name': 'Colorless Spell',
              'type_line': 'Artifact',
              'mana_cost': '{3}',
              'oracle_text': '',
              'quantity': 91,
            },
          ], const <String>[]).analyzeManaBase()['assessment'];

      expect(coreAssessment, contains('Poucos terrenos'));
      expect(coreAssessment, contains('mínimo seguro 34'));
      expect(routeAssessment, contains('Poucos terrenos'));
      expect(routeAssessment, contains('mínimo seguro 34'));
    });
  });

  group('Brawl mana-base policy', () {
    const symbols = {'W': 20, 'U': 0, 'B': 0, 'R': 0, 'G': 0};
    const sources = {'W': 24, 'U': 0, 'B': 0, 'R': 0, 'G': 0, 'Any': 0};

    test('24 lands satisfies the Brawl floor in both analyzers', () {
      final coreAssessment = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        24,
        deckFormat: 'brawl',
      );
      final routeAssessment =
          DeckArchetypeAnalyzer(
            const [
              {
                'name': 'Plains',
                'type_line': 'Basic Land — Plains',
                'oracle_text': '{T}: Add {W}.',
                'quantity': 24,
              },
              {
                'name': 'White Spell',
                'type_line': 'Creature',
                'mana_cost': '{W}',
                'oracle_text': '',
                'quantity': 36,
              },
            ],
            const ['W'],
            deckFormat: 'brawl',
          ).analyzeManaBase()['assessment'];

      expect(coreAssessment, isNot(contains('Poucos terrenos')));
      expect(routeAssessment, isNot(contains('Poucos terrenos')));
      expect(coreAssessment, isNot(contains('Commander')));
    });

    test('23 lands is low and 31 is above the automatic Brawl range', () {
      final low = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        23,
        deckFormat: 'brawl',
      );
      final high = DeckArchetypeAnalyzerCore.assessManaBase(
        symbols,
        sources,
        31,
        deckFormat: 'brawl',
      );

      expect(low, contains('Poucos terrenos para Brawl'));
      expect(low, contains('mínimo seguro 24'));
      expect(high, contains('Terrenos em excesso'));
      expect(high, contains('faixa automática até 30'));
    });

    test('state assessment accepts 24 lands and repairs 23 lands', () {
      List<Map<String, dynamic>> brawlDeck(int landCount) => [
        {
          'name': 'Brawl Commander',
          'type_line': 'Legendary Creature',
          'mana_cost': '{2}{W}',
          'oracle_text': '',
          'quantity': 1,
          'colors': const ['W'],
          'is_commander': true,
        },
        {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'mana_cost': '',
          'oracle_text': '{T}: Add {W}.',
          'quantity': landCount,
          'colors': const <String>[],
          'is_commander': false,
        },
        {
          'name': 'Brawl Creature',
          'type_line': 'Creature',
          'mana_cost': '{1}{W}',
          'oracle_text': '',
          'quantity': 59 - landCount,
          'colors': const ['W'],
          'is_commander': false,
        },
      ];

      final validCards = brawlDeck(24);
      final validAnalysis =
          DeckArchetypeAnalyzerCore(validCards, const [
            'W',
          ], deckFormat: 'brawl').generateAnalysis();
      final validState = assessDeckOptimizationStateCore(
        cards: validCards,
        deckAnalysis: validAnalysis,
        deckFormat: 'brawl',
        currentTotalCards: 60,
        commanderColorIdentity: const {'W'},
      );

      final lowCards = brawlDeck(23);
      final lowAnalysis =
          DeckArchetypeAnalyzerCore(lowCards, const [
            'W',
          ], deckFormat: 'brawl').generateAnalysis();
      final lowState = assessDeckOptimizationStateCore(
        cards: lowCards,
        deckAnalysis: lowAnalysis,
        deckFormat: 'brawl',
        currentTotalCards: 60,
        commanderColorIdentity: const {'W'},
      );

      expect(validState.status, 'healthy');
      expect(lowState.status, 'needs_repair');
      expect(lowState.reasons, contains(contains('mínimo seguro de 24')));
      expect((lowState.repairPlan['role_targets'] as Map)['lands_to_add'], 2);
    });
  });

  group('repair-plan land diagnosis', () {
    test('Commander 9-land canary explains the 27-land repair', () {
      final plan = buildDeckRepairPlan(
        deckFormat: 'commander',
        landCount: 9,
        nonLandCount: 91,
        instantSorceryCount: 0,
        artifactCount: 0,
        enchantmentCount: 0,
        commanderColorIdentity: const {'R', 'W'},
        commanderText: '',
        manaAssessment: '',
      );

      expect(plan['target_land_count'], 36);
      expect((plan['role_targets'] as Map)['lands_to_add'], 27);
      expect(
        plan['priority_repairs'],
        contains(contains('Adicionar aproximadamente 27 terrenos')),
      );
    });

    test('Brawl 9-land canary explains the 16-land repair', () {
      final plan = buildDeckRepairPlan(
        deckFormat: 'brawl',
        landCount: 9,
        nonLandCount: 51,
        instantSorceryCount: 0,
        artifactCount: 0,
        enchantmentCount: 0,
        commanderColorIdentity: const {'U'},
        commanderText: '',
        manaAssessment: '',
      );

      expect(plan['target_land_count'], 25);
      expect((plan['role_targets'] as Map)['lands_to_add'], 16);
    });
  });

  group('incomplete deck completion feasibility', () {
    test('routes a 90-card nine-land Commander deck to rebuild', () {
      final cards = <Map<String, dynamic>>[
        const {
          'name': 'Commander',
          'type_line': 'Legendary Creature',
          'quantity': 1,
          'is_commander': true,
        },
        const {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 9,
        },
        const {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 80},
      ];
      const analysis = {
        'type_distribution': {'lands': 9},
      };

      final route = assessDeckOptimizationState(
        cards: cards,
        deckAnalysis: analysis,
        deckFormat: 'commander',
        currentTotalCards: 90,
        commanderColorIdentity: const {'W'},
      );
      final core = assessDeckOptimizationStateCore(
        cards: cards,
        deckAnalysis: analysis,
        deckFormat: 'commander',
        currentTotalCards: 90,
        commanderColorIdentity: const {'W'},
      );

      expect(route.status, 'needs_repair');
      expect(core.status, 'needs_repair');
      expect(route.recommendedMode, 'repair');
      expect(core.recommendedMode, 'repair');
      expect(route.reasons.single, contains('no máximo 19 terrenos'));
      expect((core.repairPlan['role_targets'] as Map)['lands_to_add'], 27);
    });

    test('routes an incomplete 90-land Commander deck to rebuild', () {
      final cards = <Map<String, dynamic>>[
        const {
          'name': 'Commander',
          'type_line': 'Legendary Creature',
          'quantity': 1,
          'is_commander': true,
        },
        const {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 90,
        },
        const {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 4},
      ];
      const analysis = {
        'type_distribution': {'lands': 90},
      };

      final route = assessDeckOptimizationState(
        cards: cards,
        deckAnalysis: analysis,
        deckFormat: 'commander',
        currentTotalCards: 95,
        commanderColorIdentity: const {'W'},
      );
      final core = assessDeckOptimizationStateCore(
        cards: cards,
        deckAnalysis: analysis,
        deckFormat: 'commander',
        currentTotalCards: 95,
        commanderColorIdentity: const {'W'},
      );

      expect(route.status, 'needs_repair');
      expect(core.status, 'needs_repair');
      expect(route.reasons.single, contains('cortar o excesso'));
      expect((core.repairPlan['role_targets'] as Map)['lands_to_remove'], 54);
    });

    test('keeps a fillable sparse deck in Complete and ignores Standard', () {
      final commander = assessDeckOptimizationStateCore(
        cards: const [
          {
            'name': 'Commander',
            'type_line': 'Legendary Creature',
            'quantity': 1,
            'is_commander': true,
          },
          {'name': 'Plains', 'type_line': 'Basic Land — Plains', 'quantity': 9},
        ],
        deckAnalysis: const {
          'type_distribution': {'lands': 9},
        },
        deckFormat: 'commander',
        currentTotalCards: 10,
        commanderColorIdentity: const {'W'},
      );
      final standard = assessDeckOptimizationStateCore(
        cards: const [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 24,
          },
          {'name': 'Spell', 'type_line': 'Sorcery', 'quantity': 36},
        ],
        deckAnalysis: const {
          'type_distribution': {'lands': 24},
        },
        deckFormat: 'standard',
        currentTotalCards: 60,
        commanderColorIdentity: const <String>{},
      );

      expect(commander.status, 'incomplete');
      expect(commander.recommendedMode, 'complete');
      expect(standard.status, 'healthy');
    });
  });
}
