import 'package:test/test.dart';

import '../lib/edh_bracket_policy.dart';
import '../lib/ai/optimize_runtime_support.dart';

void main() {
  group('resolveOptimizeIntensity', () {
    test('omitted intensity remains backward-compatible focused default', () {
      final config = resolveOptimizeIntensity(null);

      expect(config.selected, equals('focused'));
      expect(config.wasOmitted, isTrue);
      expect(config.targetMin, equals(6));
      expect(config.targetMax, equals(10));
      expect(config.toJson()['source'], equals('omitted_default'));
    });

    test('maps official intensities to target swap scopes', () {
      final light = resolveOptimizeIntensity('light');
      final focused = resolveOptimizeIntensity('focused');
      final aggressive = resolveOptimizeIntensity('aggressive');
      final rebuild = resolveOptimizeIntensity('rebuild');

      expect(light.targetMin, equals(3));
      expect(light.targetMax, equals(5));
      expect(focused.targetMin, equals(6));
      expect(focused.targetMax, equals(10));
      expect(aggressive.targetMin, equals(10));
      expect(aggressive.targetMax, equals(20));
      expect(rebuild.isRebuild, isTrue);
      expect(rebuild.targetMax, equals(0));
    });

    test('rejects unknown intensity values', () {
      final config = resolveOptimizeIntensity('reckless');

      expect(config.valid, isFalse);
      expect(config.source, equals('invalid'));
    });
  });

  group('shouldUseAsyncOptimizeExecutor', () {
    test('routes aggressive optimize to async by default', () {
      final aggressive = resolveOptimizeIntensity('aggressive');

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: false,
        ),
        isTrue,
      );
    });

    test('preserves focused sync compatibility when async is omitted', () {
      final focused = resolveOptimizeIntensity(null);

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: focused,
          requestMode: 'optimize',
          forceSync: false,
        ),
        isFalse,
      );
    });

    test('honors internal force sync and explicit async opt-out', () {
      final aggressive = resolveOptimizeIntensity('aggressive');

      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: true,
        ),
        isFalse,
      );
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: false,
          asyncRequested: false,
        ),
        isFalse,
      );
    });

    test('does not turn complete or rebuild into optimize async jobs', () {
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: resolveOptimizeIntensity('aggressive'),
          requestMode: 'complete',
          forceSync: false,
        ),
        isFalse,
      );
      expect(
        shouldUseAsyncOptimizeExecutor(
          intensity: resolveOptimizeIntensity('rebuild'),
          requestMode: 'optimize',
          forceSync: false,
          asyncRequested: true,
        ),
        isFalse,
      );
    });
  });

  group('buildOptimizeCacheKey', () {
    test('separates cache entries by intensity', () {
      final light = buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'midrange',
        mode: 'optimize',
        bracket: 2,
        keepTheme: true,
        deckSignature: 'a:1|b:1',
        intensity: 'light',
      );
      final aggressive = buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'midrange',
        mode: 'optimize',
        bracket: 2,
        keepTheme: true,
        deckSignature: 'a:1|b:1',
        intensity: 'aggressive',
      );

      expect(light, isNot(equals(aggressive)));
      expect(light, startsWith('v7:'));
      expect(aggressive, startsWith('v7:'));
    });
  });

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

    test('rejects additions outside commander color identity', () {
      expect(
        shouldKeepCommanderFillerCandidate(
          candidate: {
            'name': 'Swords to Plowshares',
            'mana_cost': '{W}',
            'oracle_text': 'Exile target creature.',
            'colors': const ['W'],
            'color_identity': const ['W'],
          },
          excludeNames: const <String>{},
          commanderColorIdentity: const {'U'},
          enforceCommanderIdentity: true,
        ),
        isFalse,
      );
    });
  });

  group('bracket safety', () {
    test('blocks power additions above low bracket budgets', () {
      final decision = applyBracketPolicyToAdditions(
        bracket: 1,
        currentDeckCards: const [
          {
            'name': 'Sol Ring',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'quantity': 1,
          }
        ],
        additionsCardsData: const [
          {
            'name': 'Mana Crypt',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {C}{C}.',
            'quantity': 1,
          }
        ],
      );

      expect(decision.allowed, isEmpty);
      expect(decision.blocked.single['name'], equals('Mana Crypt'));
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
