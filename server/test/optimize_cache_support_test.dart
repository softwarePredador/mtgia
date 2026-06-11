import 'package:test/test.dart';

import '../lib/ai/optimize_cache_support.dart' as cache_support;
import '../lib/ai/optimize_runtime_support.dart' as runtime_support;

void main() {
  group('optimize cache support', () {
    test('buildOptimizeCacheKey is stable and separates intensity', () {
      final focused = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: ' Spellslinger ',
        mode: ' Optimize ',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'focused',
      );

      final focusedAgain = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'spellslinger',
        mode: 'optimize',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'focused',
      );

      final aggressive = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        archetype: 'spellslinger',
        mode: 'optimize',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'aggressive',
      );

      expect(focused, startsWith('v7:'));
      expect(focused, equals(focusedAgain));
      expect(aggressive, isNot(equals(focused)));
    });

    test('runtime wrapper delegates to extracted cache key implementation', () {
      final direct = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-2',
        archetype: 'control',
        mode: 'complete',
        bracket: null,
        keepTheme: false,
        deckSignature: 'cmd:1|land:37',
        intensity: 'light',
      );

      final wrapped = runtime_support.buildOptimizeCacheKey(
        deckId: 'deck-2',
        archetype: 'control',
        mode: 'complete',
        bracket: null,
        keepTheme: false,
        deckSignature: 'cmd:1|land:37',
        intensity: 'light',
      );

      expect(wrapped, equals(direct));
    });

    test('stableOptimizeHash returns deterministic lowercase hex', () {
      final first = cache_support.stableOptimizeHash('mana-loom');
      final second = cache_support.stableOptimizeHash('mana-loom');

      expect(first, equals(second));
      expect(first, matches(RegExp(r'^[0-9a-f]+$')));
      expect(cache_support.stableOptimizeHash('mana-loon'), isNot(first));
    });
  });
}
