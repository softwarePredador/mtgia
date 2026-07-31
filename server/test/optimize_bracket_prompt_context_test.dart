import 'package:server/ai/otimizacao.dart';
import 'package:test/test.dart';

void main() {
  test('builds distinct canonical prompt context for brackets 1 through 5', () {
    final expected = <int, Map<String, Object?>>{
      1: {
        'label': 'Exhibition',
        'minimum_turns_played': 9,
        'game_changer_cap': 0,
        'competitive_lane': false,
      },
      2: {
        'label': 'Core',
        'minimum_turns_played': 8,
        'game_changer_cap': 0,
        'competitive_lane': false,
      },
      3: {
        'label': 'Upgraded',
        'minimum_turns_played': 6,
        'game_changer_cap': 3,
        'competitive_lane': false,
      },
      4: {
        'label': 'Optimized',
        'minimum_turns_played': 4,
        'game_changer_cap': null,
        'numeric_game_changer_cap_applies': false,
        'competitive_lane': false,
      },
      5: {
        'label': 'cEDH',
        'minimum_turns_played': null,
        'game_changer_cap': null,
        'numeric_game_changer_cap_applies': false,
        'competitive_lane': true,
      },
    };

    for (final entry in expected.entries) {
      final context = buildCommanderBracketPromptContext(
        deckFormat: 'commander',
        bracket: entry.key,
      );
      expect(context, isNotNull);
      expect(context!['bracket'], entry.key);
      expect(context['policy_version'], isNotEmpty);
      for (final field in entry.value.entries) {
        expect(
          context[field.key],
          field.value,
          reason: 'Bracket ${entry.key}, field ${field.key}',
        );
      }
    }
  });

  test(
    'does not apply Commander bracket context to other formats or bad input',
    () {
      expect(
        buildCommanderBracketPromptContext(deckFormat: 'brawl', bracket: 3),
        isNull,
      );
      expect(
        buildCommanderBracketPromptContext(deckFormat: 'commander', bracket: 0),
        isNull,
      );
      expect(
        buildCommanderBracketPromptContext(deckFormat: 'commander', bracket: 6),
        isNull,
      );
      expect(
        buildCommanderBracketPromptContext(
          deckFormat: 'commander',
          bracket: null,
        ),
        isNull,
      );
    },
  );
}
