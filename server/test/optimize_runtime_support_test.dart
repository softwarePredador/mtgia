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
}
