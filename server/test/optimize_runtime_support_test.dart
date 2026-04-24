import 'package:test/test.dart';

import '../lib/ai/optimize_runtime_support.dart';

void main() {
  group('landFixesCommanderColors', () {
    test('accepts five-color fixing lands', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text': '{T}, Pay 1 life: Add one mana of any color.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U', 'B', 'G'},
        ),
        isTrue,
      );
    });

    test('accepts fetch-style lands that search matching land types', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text':
                '{T}, Pay 1 life, Sacrifice this land: Search your library for a Plains or Island card, put it onto the battlefield, then shuffle.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U'},
        ),
        isTrue,
      );
    });

    test('rejects utility lands that do not fix commander colors', () {
      expect(
        landFixesCommanderColors(
          card: {
            'oracle_text': '{T}: Add {C}{C}.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          commanderColorIdentity: {'W', 'U'},
        ),
        isFalse,
      );
    });
  });

  group('shouldKeepCommanderFillerCandidate', () {
    test(
        'rejects colored spell inferred only from mana cost for colorless commander',
        () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Swan Song',
            'mana_cost': '{U}',
            'oracle_text':
                'Counter target enchantment, instant, or sorcery spell.',
            'colors': const <String>[],
            'color_identity': const <String>[],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const <String>{},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });
  });

  group('resolveCommanderOptimizeMetaScope', () {
    test('uses competitive commander references only for bracket 3+', () {
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 3,
        ),
        equals('competitive_commander'),
      );
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 4,
        ),
        equals('competitive_commander'),
      );
    });

    test('keeps casual commander out of competitive commander meta', () {
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'commander',
          bracket: 2,
        ),
        isNull,
      );
      expect(
        resolveCommanderOptimizeMetaScope(
          deckFormat: 'modern',
          bracket: 4,
        ),
        isNull,
      );
    });
  });
}
