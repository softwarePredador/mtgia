import 'package:test/test.dart';
import 'package:server/ai/optimize_payload_support.dart' as payload;
import 'package:server/ai/optimize_runtime_support.dart' as runtime;

void main() {
  group('optimize payload support', () {
    test('normalizes mode aliases and reasoning values', () {
      final normalized = payload.normalizeOptimizePayload(
        {
          'modde': 'complete deck',
          'reasoning': 42,
        },
        defaultMode: 'optimize',
      );

      expect(normalized['mode'], 'complete');
      expect(normalized['reasoning'], '42');
    });

    test('parses swap strings and resolves aggressive async eligibility', () {
      final parsed = payload.parseOptimizeSuggestions({
        'swaps': ['Mind Stone -> Arcane Signet'],
      });
      final aggressive = payload.resolveOptimizeIntensity('aggressive');

      expect(parsed['removals'], ['Mind Stone']);
      expect(parsed['additions'], ['Arcane Signet']);
      expect(parsed['recognized_format'], isTrue);
      expect(
        payload.shouldUseAsyncOptimizeExecutor(
          intensity: aggressive,
          requestMode: 'optimize',
          forceSync: false,
        ),
        isTrue,
      );
    });

    test('builds deterministic response and recommendation detail', () {
      final response = payload.buildDeterministicOptimizeResponse(
        deterministicSwapCandidates: [
          {
            'remove': 'Mind Stone',
            'add': 'Arcane Signet',
            'role': 'ramp',
            'candidate_quality_sources': ['deterministic_semantic_v2'],
          },
        ],
        targetArchetype: 'Spellslinger',
        intensity: payload.resolveOptimizeIntensity('light'),
      );
      final detail = payload.buildOptimizeRecommendationDetail(
        type: 'remove',
        name: 'Mind Stone',
        cardId: 'card-1',
        quantity: 1,
        targetArchetype: 'Spellslinger',
        confidenceLevel: 'média',
        cmcBefore: 3.2,
        cmcAfter: 2.9,
        keepTheme: true,
        functionalRole: 'ramp',
        functionalRoles: const ['ramp', 'draw'],
      );

      expect(response['mode'], 'optimize');
      expect((response['swaps'] as List).single['priority'], 'Medium');
      expect(
        (response['swaps'] as List).single['reason'],
        contains('Sinal semântico v2'),
      );
      expect(detail['reason'], contains('Sugestão de saída'));
      expect(detail['role'], 'ramp');
      expect(detail['function'], 'ramp');
      expect(detail['roles'], ['draw', 'ramp']);
      expect(detail['functions'], ['draw', 'ramp']);
      expect(
        detail['reason'],
        contains('abre espaço na função ramp para uma troca revisável'),
      );
      final explanation = detail['explanation'] as Map;
      expect(
        explanation['schema_version'],
        'optimize_recommendation_explanation_v1_2026-07-01',
      );
      expect(explanation['summary'], detail['reason']);
      expect(explanation['decision'], 'remove');
      expect(explanation['target_archetype'], 'Spellslinger');
      expect(explanation['why'], contains('Função principal: ramp.'));
      expect(
        explanation['why'],
        contains('Funções consideradas: draw, ramp.'),
      );
      expect((explanation['safety'] as Map)['preview_required'], isTrue);
      expect((explanation['safety'] as Map)['theme_preserved'], isTrue);
      expect(detail['impact_estimate']['curve'], 'ΔCMC -0.30');
      expect(detail['impact_estimate']['consistency'], 'alta');
    });

    test('runtime export remains compatible', () {
      expect(runtime.resolveOptimizeIntensity('focused').targetMax, 10);
      expect(runtime.normalizeOptimizeReasoning(null), '');
      expect(
        runtime.shouldRetryOptimizeWithAiFallback(
          deterministicFirstEnabled: true,
          fallbackAlreadyAttempted: false,
          strategySource: 'deterministic_first',
          qualityErrorCode: 'OPTIMIZE_NO_SAFE_SWAPS',
          isComplete: false,
        ),
        isTrue,
      );
    });
  });
}
