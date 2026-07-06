import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('production AI mock fallback policy', () {
    test('generate blocks missing OpenAI provider before mock response', () {
      final source = File('routes/ai/generate/index.dart').readAsStringSync();

      _expectGuardBefore(
        source,
        guard: '!aiConfig.allowsMockFallbacks',
        fallback: 'OPENAI_API_KEY nao configurada',
      );
      expect(source, contains('HttpStatus.serviceUnavailable'));
    });

    test('archetypes blocks missing OpenAI provider before mock response', () {
      final source = File('routes/ai/archetypes/index.dart').readAsStringSync();

      _expectGuardBefore(
        source,
        guard: '!aiConfig.allowsMockFallbacks',
        fallback: '_buildMockArchetypesPayload()',
      );
      expect(source, contains('HttpStatus.serviceUnavailable'));
    });

    test('explain blocks missing OpenAI provider before offline response', () {
      final source = File('routes/ai/explain/index.dart').readAsStringSync();

      _expectGuardBefore(
        source,
        guard: '!aiConfig.allowsMockFallbacks',
        fallback: '_generateFallbackExplanation(',
      );
      expect(source, contains('HttpStatus.serviceUnavailable'));
    });

    test('optimize blocks missing OpenAI provider before development mock', () {
      final source = File('routes/ai/optimize/index.dart').readAsStringSync();

      _expectGuardBefore(
        source,
        guard: 'aiProviderMissingInProduction',
        fallback: 'Mock response for development',
      );
      expect(source, contains('HttpStatus.serviceUnavailable'));
    });

    test('deck AI analysis blocks missing provider before heuristic mock', () {
      final source =
          File('routes/decks/[id]/ai-analysis/index.dart').readAsStringSync();

      _expectGuardBefore(
        source,
        guard: '!aiConfig.allowsMockFallbacks',
        fallback: '_heuristicAnalysis(',
      );
      expect(source, contains('HttpStatus.serviceUnavailable'));
    });
  });
}

void _expectGuardBefore(
  String source, {
  required String guard,
  required String fallback,
}) {
  final guardIndex = source.indexOf(guard);
  final fallbackIndex = source.indexOf(fallback);

  expect(guardIndex, isNonNegative, reason: 'Missing guard "$guard".');
  expect(
    fallbackIndex,
    isNonNegative,
    reason: 'Missing fallback marker "$fallback".',
  );
  expect(
    guardIndex,
    lessThan(fallbackIndex),
    reason: 'Production guard must appear before fallback "$fallback".',
  );
}
