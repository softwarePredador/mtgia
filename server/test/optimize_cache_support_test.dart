import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_cache_support.dart' as cache_support;
import '../lib/ai/optimize_runtime_support.dart' as runtime_support;

void main() {
  group('optimize cache support', () {
    test('buildOptimizeCacheKey is stable and separates intensity', () {
      final focused = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        deckFormat: 'commander',
        archetype: ' Spellslinger ',
        mode: ' Optimize ',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'focused',
      );

      final focusedAgain = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        deckFormat: 'commander',
        archetype: 'spellslinger',
        mode: 'optimize',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'focused',
      );

      final aggressive = cache_support.buildOptimizeCacheKey(
        deckId: 'deck-1',
        deckFormat: 'commander',
        archetype: 'spellslinger',
        mode: 'optimize',
        bracket: 3,
        keepTheme: true,
        deckSignature: 'a:1|b:2',
        intensity: 'aggressive',
      );

      expect(focused, startsWith('v20:'));
      expect(focused.split(':').last, hasLength(64));
      expect(focused, equals(focusedAgain));
      expect(aggressive, isNot(equals(focused)));
    });

    test(
      'buildOptimizeCacheKey keeps base key shape unless context is present',
      () {
        final withoutContext = cache_support.buildOptimizeCacheKey(
          deckId: 'deck-1',
          deckFormat: 'commander',
          archetype: 'control',
          mode: 'optimize',
          bracket: 2,
          keepTheme: true,
          deckSignature: 'a:1',
          intensity: 'focused',
        );

        final explicitEmptyContext = cache_support.buildOptimizeCacheKey(
          deckId: 'deck-1',
          deckFormat: 'commander',
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
          deckFormat: 'commander',
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
        deckFormat: 'brawl',
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
        deckFormat: 'brawl',
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

    test('cache keys cannot cross Commander and Brawl', () {
      String build(String format) => cache_support.buildOptimizeCacheKey(
        deckId: 'deck-3',
        deckFormat: format,
        archetype: 'midrange',
        mode: 'optimize',
        bracket: 2,
        keepTheme: true,
        deckSignature: 'same:1:NM:commander',
      );

      expect(build('commander'), isNot(build('brawl')));
    });

    test(
      'deck signature includes condition and commander role with NM fallback',
      () {
        final rows = [
          _optimizeResultRow(cardId: 'card-b', quantity: 2, condition: 'lp'),
          _optimizeResultRow(
            cardId: 'card-a',
            quantity: 1,
            condition: 'HP',
            isCommander: true,
          ),
          _legacyOptimizeResultRow(cardId: 'card-c', quantity: 1),
        ];

        expect(
          cache_support.buildOptimizeDeckSignature(rows),
          'card-a:1:HP:commander|card-b:2:LP:main|card-c:1:NM:main',
        );
        expect(
          runtime_support.buildOptimizeDeckSignature(rows),
          'card-a:1:HP:commander|card-b:2:LP:main|card-c:1:NM:main',
        );
        expect(
          cache_support.buildOptimizeDeckSignature([
            _optimizeResultRow(cardId: 'card-a', quantity: 1, condition: 'HP'),
            _optimizeResultRow(
              cardId: 'card-b',
              quantity: 2,
              condition: 'lp',
              isCommander: true,
            ),
            _legacyOptimizeResultRow(cardId: 'card-c', quantity: 1),
          ]),
          isNot(cache_support.buildOptimizeDeckSignature(rows)),
        );
      },
    );

    test('stableOptimizeHash returns deterministic SHA-256 lowercase hex', () {
      final first = cache_support.stableOptimizeHash('mana-loom');
      final second = cache_support.stableOptimizeHash('mana-loom');

      expect(first, equals(second));
      expect(
        first,
        '713c200c7b37efe69a885f11ddc33e978e44aece898e361f0301915ec5d3cce6',
      );
      expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(cache_support.stableOptimizeHash('mana-loon'), isNot(first));
    });

    test('cache reads are scoped to tenant, deck and exact signature', () {
      final source =
          File('lib/ai/optimize_cache_support.dart').readAsStringSync();

      expect(source, contains('required String userId'));
      expect(source, contains('required String deckId'));
      expect(source, contains('required String deckSignature'));
      expect(source, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(source, contains('AND deck_id = CAST(@deck_id AS uuid)'));
      expect(source, contains('AND deck_signature = @deck_signature'));
      expect(source, contains("'user_id': userId"));
      expect(source, contains("'deck_id': deckId"));
      expect(source, contains("'deck_signature': deckSignature"));
    });
  });
}

ResultRow _optimizeResultRow({
  required String cardId,
  required int quantity,
  required String condition,
  bool isCommander = false,
}) {
  return _row([
    'Test Card',
    isCommander,
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
