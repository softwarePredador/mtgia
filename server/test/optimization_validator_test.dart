import 'package:test/test.dart';
import '../lib/ai/optimization_validator.dart';

void main() {
  group('OptimizationValidator', () {
    late OptimizationValidator validator;

    setUp(() {
      validator = OptimizationValidator(); // Sem API key = sem Critic AI
    });

    test('validate approves when optimization improves consistency', () async {
      // Deck original: mal balanceado (poucos terrenos, CMC alto)
      final originalDeck = [
        ..._makeLands(28), // Poucos terrenos
        ..._makeSpells(72, avgCmc: 4), // CMC alto
      ];

      // Deck otimizado: melhor balanceado
      final optimizedDeck = [
        ..._makeLands(35), // Mais terrenos
        ..._makeSpells(65, avgCmc: 3), // CMC menor
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: ['Expensive Spell 1', 'Expensive Spell 2'],
        additions: ['Sol Ring', 'Arcane Signet'],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      expect(report.score, greaterThan(0));
      expect(report.verdict, isNotEmpty);
      expect(report.monteCarlo.before.consistencyScore, isNotNull);
      expect(report.monteCarlo.after.consistencyScore, isNotNull);
      print('Score: ${report.score}, Verdict: ${report.verdict}');
    });

    test('functional analysis detects role preservation', () async {
      final originalDeck = [
        {
          'name': 'Counterspell',
          'type_line': 'Instant',
          'mana_cost': '{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 2,
          'quantity': 1,
        },
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];

      final optimizedDeck = [
        {
          'name': 'Swan Song',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text':
              'Counter target enchantment, instant, or sorcery spell.',
          'cmc': 1,
          'quantity': 1,
        },
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: ['Counterspell'],
        additions: ['Swan Song'],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      // Removal → Removal = role preserved = upgrade (CMC menor)
      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('removal'));
      expect(swap.addedRole, equals('removal'));
      expect(swap.rolePreserved, isTrue);
      expect(swap.verdict, equals('upgrade'));
      print('Swap: ${swap.removed} → ${swap.added} = ${swap.verdict}');
    });

    test('mulligan report produces reasonable rates', () async {
      final deck = [
        ..._makeLands(36),
        ..._makeSpells(64, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: deck,
        optimizedDeck: deck, // Same deck = no change
        removals: [],
        additions: [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final mulligan = report.monteCarlo.beforeMulligan;
      expect(mulligan.keepAt7Rate, greaterThan(0.3)); // >30% keep at 7
      expect(mulligan.avgMulligans, lessThan(2.0)); // Average < 2 mulls
      print('Keep@7: ${(mulligan.keepAt7Rate * 100).toStringAsFixed(1)}%');
      print('Avg mulligans: ${mulligan.avgMulligans.toStringAsFixed(2)}');
    });

    test('toJson produces valid JSON structure', () async {
      final deck = [
        ..._makeLands(36),
        ..._makeSpells(64, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: deck,
        optimizedDeck: deck,
        removals: [],
        additions: [],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      final json = report.toJson();
      expect(json['validation_score'], isA<int>());
      expect(json['verdict'], isA<String>());
      expect(json['monte_carlo'], isA<Map>());
      expect(json['functional_analysis'], isA<Map>());
      expect(json['warnings'], isA<List>());
      expect(json.containsKey('critic_ai'), isFalse); // No API key = no critic
    });

    test('approves healthy deck with measurable but incremental upgrade',
        () async {
      final originalDeck = [
        {
          'name': 'Test Commander',
          'type_line': 'Legendary Creature',
          'mana_cost': '{3}{U}',
          'oracle_text': 'Flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeLands(32),
        ...List.generate(
          4,
          (i) => {
            'name': 'Wastes ${i + 1}',
            'type_line': 'Basic Land',
            'mana_cost': '',
            'oracle_text': '{T}: Add {C}.',
            'cmc': 0,
            'quantity': 1,
            'colors': <String>[],
          },
        ),
        {
          'name': 'Clunky Spell 1',
          'type_line': 'Instant',
          'mana_cost': '{4}{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 6,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Clunky Spell 2',
          'type_line': 'Sorcery',
          'mana_cost': '{4}{U}',
          'oracle_text': 'Draw two cards.',
          'cmc': 5,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Clunky Spell 3',
          'type_line': 'Sorcery',
          'mana_cost': '{5}{U}',
          'oracle_text': 'Draw three cards.',
          'cmc': 5,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Clunky Spell 4',
          'type_line': 'Instant',
          'mana_cost': '{4}{U}',
          'oracle_text': 'Destroy target creature.',
          'cmc': 6,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeSpells(59, avgCmc: 3),
      ];

      final optimizedDeck = [
        {
          'name': 'Test Commander',
          'type_line': 'Legendary Creature',
          'mana_cost': '{3}{U}',
          'oracle_text': 'Flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeLands(36),
        {
          'name': 'Brainstorm',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text':
              'Draw three cards, then put two cards from your hand on top of your library in any order.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Counterspell',
          'type_line': 'Instant',
          'mana_cost': '{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 2,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Preordain',
          'type_line': 'Sorcery',
          'mana_cost': '{U}',
          'oracle_text': 'Scry 2, then draw a card.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Rapid Hybridization',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text': 'Destroy target creature. It cannot be regenerated.',
          'cmc': 1,
          'quantity': 1,
          'colors': ['U'],
        },
        ..._makeSpells(59, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: const [
          'Wastes 1',
          'Wastes 2',
          'Wastes 3',
          'Wastes 4',
          'Clunky Spell 1',
          'Clunky Spell 2',
          'Clunky Spell 3',
          'Clunky Spell 4',
        ],
        additions: const [
          'Island 33',
          'Island 34',
          'Island 35',
          'Island 36',
          'Brainstorm',
          'Counterspell',
          'Preordain',
          'Rapid Hybridization',
        ],
        commanders: const ['Test Commander'],
        archetype: 'control',
      );

      expect(report.healthScore, greaterThanOrEqualTo(70));
      expect(report.improvementScore, greaterThanOrEqualTo(55));
      expect(report.score, greaterThanOrEqualTo(75));
      expect(report.verdict, equals('aprovado'));
    });

    test('keeps degenerate deck rejected even after cosmetic land swap',
        () async {
      final originalDeck = [
        {
          'name': 'Talrand, Sky Summoner',
          'type_line': 'Legendary Creature',
          'mana_cost': '{2}{U}{U}',
          'oracle_text':
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Wastes',
          'type_line': 'Basic Land',
          'mana_cost': '',
          'oracle_text': '{T}: Add {C}.',
          'cmc': 0,
          'quantity': 99,
          'colors': <String>[],
        },
      ];

      final optimizedDeck = [
        {
          'name': 'Talrand, Sky Summoner',
          'type_line': 'Legendary Creature',
          'mana_cost': '{2}{U}{U}',
          'oracle_text':
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Wastes',
          'type_line': 'Basic Land',
          'mana_cost': '',
          'oracle_text': '{T}: Add {C}.',
          'cmc': 0,
          'quantity': 98,
          'colors': <String>[],
        },
        {
          'name': 'Command Tower',
          'type_line': 'Land',
          'mana_cost': '',
          'oracle_text':
              '{T}: Add one mana of any color in your commander\'s color identity.',
          'cmc': 0,
          'quantity': 1,
          'colors': <String>[],
        },
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: const ['Wastes'],
        additions: const ['Command Tower'],
        commanders: const ['Talrand, Sky Summoner'],
        archetype: 'control',
      );

      expect(report.healthScore, lessThan(45));
      expect(report.score, lessThan(45));
      expect(report.verdict, equals('reprovado'));
    });
  });
}

/// Helper: cria N terrenos básicos
List<Map<String, dynamic>> _makeLands(int count) {
  return List.generate(
      count,
      (i) => {
            'name': 'Island ${i + 1}',
            'type_line': 'Basic Land — Island',
            'mana_cost': '',
            'oracle_text': '{T}: Add {U}.',
            'cmc': 0,
            'quantity': 1,
            'colors': <String>[],
          });
}

/// Helper: cria N spells com CMC médio controlado
List<Map<String, dynamic>> _makeSpells(int count, {int avgCmc = 3}) {
  return List.generate(count, (i) {
    final cmc = (i % 5) + 1; // CMC varia de 1-5
    final adjustedCmc = (cmc * avgCmc / 3).round().clamp(1, 8);
    return {
      'name': 'Spell ${i + 1}',
      'type_line': i % 3 == 0
          ? 'Creature — Wizard'
          : (i % 3 == 1 ? 'Instant' : 'Sorcery'),
      'mana_cost': '{${adjustedCmc}}',
      'oracle_text': i % 4 == 0
          ? 'Draw a card.'
          : (i % 4 == 1
              ? 'Destroy target creature.'
              : 'Target player gains 2 life.'),
      'cmc': adjustedCmc,
      'quantity': 1,
      'colors': ['U'],
    };
  });
}
