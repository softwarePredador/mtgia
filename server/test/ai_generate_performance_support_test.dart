import 'package:test/test.dart';

import '../lib/ai_generate_performance_support.dart';

void main() {
  group('AI generate performance support', () {
    test('builds stable cache keys from normalized prompt format and bracket',
        () {
      final first = buildAiGenerateCacheKey(
        prompt: '  Mono   Red Aggro  ',
        format: 'STANDARD',
        bracket: 2,
      );
      final second = buildAiGenerateCacheKey(
        prompt: 'mono red aggro',
        format: 'standard',
        bracket: '2',
      );
      final differentBracket = buildAiGenerateCacheKey(
        prompt: 'mono red aggro',
        format: 'standard',
        bracket: 3,
      );

      expect(first, equals(second));
      expect(first, isNot(equals(differentBracket)));
      expect(first, startsWith('ai_generate:v1:'));
      expect(first, isNot(contains('mono red')));
    });

    test('returns cache hits as cloned payloads with cache metadata', () {
      final cacheKey = buildAiGenerateCacheKey(
        prompt: 'azorius control',
        format: 'standard',
      );
      final payload = {
        'prompt': 'azorius control',
        'format': 'Standard',
        'generated_deck': {
          'cards': [
            {'name': 'Island', 'quantity': 30},
            {'name': 'Plains', 'quantity': 30},
          ],
        },
        'validation': {'is_valid': true},
        'timings': {'openai_ms': 9000, 'total_ms': 10000},
      };

      writeAiGenerateCache(
        cacheKey: cacheKey,
        payload: payload,
        ttl: const Duration(minutes: 5),
      );

      final firstHit = readAiGenerateCache(cacheKey);
      expect(firstHit, isNotNull);
      expect((firstHit!['cache'] as Map)['hit'], isTrue);
      expect((firstHit['cache'] as Map)['cache_key'], equals(cacheKey));
      expect(firstHit['timings'], isNull);

      ((firstHit['generated_deck'] as Map)['cards'] as List).clear();
      final secondHit = readAiGenerateCache(cacheKey);
      expect(
        ((secondHit!['generated_deck'] as Map)['cards'] as List).length,
        equals(2),
      );
    });
  });
}
