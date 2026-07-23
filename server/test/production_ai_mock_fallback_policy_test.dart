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

    test(
      'generate blocks invalid output but accepts bounded validated repair',
      () {
        final source = File('routes/ai/generate/index.dart').readAsStringSync();
        final invalidBranchIndex = source.indexOf(
          'if (providerOutputMustBeRejected)',
        );
        final fallbackMarkerIndex = source.indexOf(
          'final fallbackWarningCode',
          invalidBranchIndex,
        );
        final guardIndex = source.indexOf(
          '!aiConfig.allowsMockFallbacks',
          invalidBranchIndex,
        );

        expect(invalidBranchIndex, isNonNegative);
        expect(fallbackMarkerIndex, isNonNegative);
        expect(guardIndex, isNonNegative);
        expect(guardIndex, lessThan(fallbackMarkerIndex));
        expect(source, contains("'fallback_status': 'blocked_in_production'"));
        expect(source, contains('Generated deck failed validation'));
        expect(
          source,
          contains('evaluateAiGenerateProviderRepair(validation)'),
        );
        expect(source, contains("'provider_validated_repair'"));
        expect(source, contains("'learning_eligible': false"));
      },
    );

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

      final providerGuardIndex = source.indexOf(
        'if (aiProviderMissingInProduction',
      );
      final providerGuardEnd = source.indexOf('// 1. Fetch Deck Data');
      final providerGuard = source.substring(
        providerGuardIndex,
        providerGuardEnd,
      );
      expect(providerGuard, contains("'can_apply': false"));
      expect(providerGuard, contains("'learning_eligible': false"));

      final mockBranchIndex = source.indexOf('Mock response for development');
      final nextOptimizerBranchIndex = source.indexOf(
        'final optimizer = deckOptimizer',
        mockBranchIndex,
      );
      final mockBranch = source.substring(
        mockBranchIndex,
        nextOptimizerBranchIndex,
      );
      expect(mockBranch, contains("'removals': const <String>[]"));
      expect(mockBranch, contains("'additions': const <String>[]"));
      expect(mockBranch, contains("'can_apply': false"));
      expect(mockBranch, contains("'learning_eligible': false"));
      expect(mockBranch, contains('persistOutcome: false'));
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
