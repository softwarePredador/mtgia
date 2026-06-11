import 'package:test/test.dart';

import '../lib/ai/optimize_removal_candidate_support.dart';

void main() {
  group('optimize removal candidate support', () {
    test('does not count lands as ramp surplus for nonland removals', () {
      final removals = buildDeterministicOptimizeRemovalCandidates(
        allCardData: const [
          {
            'name': 'Commander Card',
            'type_line': 'Legendary Creature',
            'oracle_text': 'Flying',
            'quantity': 1,
            'cmc': 3.0,
          },
          {
            'name': 'Island',
            'type_line': 'Basic Land - Island',
            'oracle_text': '({T}: Add {U}.)',
            'quantity': 36,
            'cmc': 0.0,
          },
          {
            'name': 'Counterspell',
            'type_line': 'Instant',
            'oracle_text': 'Counter target spell.',
            'quantity': 1,
            'cmc': 2.0,
          },
          {
            'name': 'Ponder',
            'type_line': 'Sorcery',
            'oracle_text':
                'Look at the top three cards of your library, then draw a card.',
            'quantity': 1,
            'cmc': 1.0,
          },
        ],
        commanders: const ['Commander Card'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'control',
        keepTheme: true,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(
        removals.where((candidate) => candidate['name'] == 'Counterspell'),
        isEmpty,
      );
      expect(
        removals.where((candidate) => candidate['name'] == 'Ponder'),
        isEmpty,
      );
    });

    test('allows land removals when lands are excessive and off-plan', () {
      final removals = buildDeterministicOptimizeRemovalCandidates(
        allCardData: const [
          {
            'name': 'Talrand, Sky Summoner',
            'type_line': 'Legendary Creature',
            'oracle_text':
                'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
            'quantity': 1,
            'cmc': 4.0,
          },
          {
            'name': 'Wastes',
            'type_line': 'Basic Land - Wastes',
            'oracle_text': '({T}: Add {C}.)',
            'quantity': 38,
            'cmc': 0.0,
          },
          {
            'name': 'Island',
            'type_line': 'Basic Land - Island',
            'oracle_text': '({T}: Add {U}.)',
            'quantity': 28,
            'cmc': 0.0,
          },
          {
            'name': 'Opt',
            'type_line': 'Instant',
            'oracle_text': 'Scry 1. Draw a card.',
            'quantity': 1,
            'cmc': 1.0,
          },
        ],
        commanders: const ['Talrand, Sky Summoner'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'midrange',
        keepTheme: true,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(removals, isNotEmpty);
      expect(removals.first['role'], equals('land'));
      expect(removals.first['name'], equals('Wastes'));
    });

    test('expanded swap limit can expose more safe clunky removals', () {
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Commander Card',
          'type_line': 'Legendary Creature',
          'oracle_text': 'Flying',
          'quantity': 1,
          'cmc': 3.0,
        },
        {
          'name': 'Island',
          'type_line': 'Basic Land - Island',
          'oracle_text': '({T}: Add {U}.)',
          'quantity': 36,
          'cmc': 0.0,
        },
        for (var i = 0; i < 16; i++)
          {
            'name': 'Clunky Artifact $i',
            'type_line': 'Artifact',
            'oracle_text': 'A slow artifact with no immediate impact.',
            'quantity': 1,
            'cmc': 6.0 + (i % 3),
          },
      ];

      final light = buildDeterministicOptimizeRemovalCandidates(
        allCardData: cards,
        commanders: const ['Commander Card'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'midrange',
        keepTheme: true,
        coreCards: const [],
        commanderPriorityNames: const [],
        swapLimit: 5,
      );
      final aggressive = buildDeterministicOptimizeRemovalCandidates(
        allCardData: cards,
        commanders: const ['Commander Card'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'midrange',
        keepTheme: true,
        coreCards: const [],
        commanderPriorityNames: const [],
        swapLimit: 20,
      );

      expect(light, hasLength(5));
      expect(aggressive.length, greaterThan(light.length));
      expect(aggressive.length, lessThanOrEqualTo(20));
    });
  });
}
