import 'package:postgres/postgres.dart';
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

      expect(focused, startsWith('v8:'));
      expect(focused, equals(focusedAgain));
      expect(aggressive, isNot(equals(focused)));
    });

    test(
      'buildOptimizeCacheKey keeps legacy key unless context is present',
      () {
        final withoutContext = cache_support.buildOptimizeCacheKey(
          deckId: 'deck-1',
          archetype: 'control',
          mode: 'optimize',
          bracket: 2,
          keepTheme: true,
          deckSignature: 'a:1',
          intensity: 'focused',
        );

        final explicitEmptyContext = cache_support.buildOptimizeCacheKey(
          deckId: 'deck-1',
          archetype: 'control',
          mode: 'optimize',
          bracket: 2,
          keepTheme: true,
          deckSignature: 'a:1',
          intensity: 'focused',
          recommendationContextSignature: '',
        );

        final withContext = cache_support.buildOptimizeCacheKey(
          deckId: 'deck-1',
          archetype: 'control',
          mode: 'optimize',
          bracket: 2,
          keepTheme: true,
          deckSignature: 'a:1',
          intensity: 'focused',
          recommendationContextSignature:
              'budget_limit_brl=100|rebuild_intent=upgraded',
        );

        expect(explicitEmptyContext, equals(withoutContext));
        expect(withContext, isNot(withoutContext));
      },
    );

    test('runtime wrapper delegates to extracted cache key implementation', () {
      final direct = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-2',
        archetype: 'control',
        mode: 'complete',
        bracket: null,
        keepTheme: false,
        deckSignature: 'cmd:1|land:37',
        intensity: 'light',
        recommendationContextSignature: 'budget_limit_brl=50',
      );

      final wrapped = runtime_support.buildOptimizeCacheKey(
        deckId: 'deck-2',
        archetype: 'control',
        mode: 'complete',
        bracket: null,
        keepTheme: false,
        deckSignature: 'cmd:1|land:37',
        intensity: 'light',
        recommendationContextSignature: 'budget_limit_brl=50',
      );

      expect(wrapped, equals(direct));
    });

    test('deck signature includes physical condition with NM fallback', () {
      final rows = [
        _optimizeResultRow(cardId: 'card-b', quantity: 2, condition: 'lp'),
        _optimizeResultRow(cardId: 'card-a', quantity: 1, condition: 'HP'),
        _legacyOptimizeResultRow(cardId: 'card-c', quantity: 1),
      ];

      expect(
        cache_support.buildOptimizeDeckSignature(rows),
        'card-a:1:HP|card-b:2:LP|card-c:1:NM',
      );
      expect(
        runtime_support.buildOptimizeDeckSignature(rows),
        'card-a:1:HP|card-b:2:LP|card-c:1:NM',
      );
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

ResultRow _optimizeResultRow({
  required String cardId,
  required int quantity,
  required String condition,
}) {
  return _row([
    'Test Card',
    false,
    quantity,
    'Artifact',
    '{2}',
    <String>[],
    2,
    '',
    <String>[],
    cardId,
    null,
    null,
    condition,
  ]);
}

ResultRow _legacyOptimizeResultRow({
  required String cardId,
  required int quantity,
}) {
  return _row([
    'Legacy Test Card',
    false,
    quantity,
    'Artifact',
    '{2}',
    <String>[],
    2,
    '',
    <String>[],
    cardId,
    null,
    null,
  ]);
}

ResultRow _row(List<Object?> values) {
  return ResultRow(values: values, schema: ResultSchema(const []));
}
