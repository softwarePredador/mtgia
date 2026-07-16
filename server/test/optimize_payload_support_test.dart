import 'package:test/test.dart';
import 'package:server/ai/optimize_payload_support.dart' as payload;
import 'package:server/ai/optimize_runtime_support.dart' as runtime;

void main() {
  group('optimize payload support', () {
    test('normalizes mode aliases and reasoning values', () {
      final normalized = payload.normalizeOptimizePayload({
        'modde': 'complete deck',
        'reasoning': 42,
      }, defaultMode: 'optimize');

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
            'collection_match': true,
            'owned_quantity': 1,
            'purchase_required': false,
            'estimated_price_brl': 12.34,
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
      expect((response['swaps'] as List).single['collection_match'], isTrue);
      expect((response['swaps'] as List).single['owned_quantity'], 1);
      expect((response['swaps'] as List).single['purchase_required'], isFalse);
      expect((response['swaps'] as List).single['estimated_price_brl'], 12.34);
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
      expect(explanation['why'], contains('Funções consideradas: draw, ramp.'));
      expect((explanation['safety'] as Map)['preview_required'], isTrue);
      expect((explanation['safety'] as Map)['theme_preserved'], isTrue);
      expect(detail['impact_estimate']['curve'], 'ΔCMC -0.30');
      expect(detail['impact_estimate']['consistency'], 'alta');
      expect((detail['player_facing'] as Map)['title'], 'Remover Mind Stone');
      expect(
        (detail['player_facing'] as Map)['theme_label'],
        'Preserva o plano atual',
      );
      expect(
        (detail['battle_validation'] as Map)['status'],
        'pending_after_apply',
      );
    });

    test('decision contract keeps optimize preview non-automatic', () {
      final contract = payload.buildOptimizeDecisionContract(
        mode: 'optimize',
        targetArchetype: 'Spellslinger',
        intensity: 'focused',
        keepTheme: true,
        additionCount: 3,
        removalCount: 3,
      );

      expect(
        contract['schema_version'],
        'optimize_decision_contract_v1_2026-07-07',
      );
      expect(
        (contract['deckbuilder_validation'] as Map)['status'],
        'passed_preview_gate',
      );
      expect(
        (contract['battle_validation'] as Map)['status'],
        'pending_after_apply',
      );
      final decision = contract['user_decision'] as Map;
      expect(decision['preview_required'], isTrue);
      expect(decision['can_select_individual_changes'], isTrue);
      expect(decision['selection_unit'], 'paired_swap');
      expect(decision['paired_selection_required'], isTrue);
      expect(decision['changes_are_not_applied_automatically'], isTrue);
      expect(decision['addition_count'], 3);
      expect(decision['removal_count'], 3);
    });

    test(
      'complete decision contract keeps additions independently selectable',
      () {
        final contract = payload.buildOptimizeDecisionContract(
          mode: 'complete',
          targetArchetype: 'Spellslinger',
          intensity: 'focused',
          keepTheme: true,
          additionCount: 8,
          removalCount: 0,
        );

        final decision = contract['user_decision'] as Map;
        expect(decision['selection_unit'], 'individual_addition');
        expect(decision['paired_selection_required'], isFalse);
      },
    );

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
