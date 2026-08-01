import 'package:server/ai/goldfish_simulator.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:server/ai/optimization_validator.dart';
import 'package:server/ai/optimize_route_final_gate_support.dart';
import 'package:test/test.dart';

void main() {
  test('evaluateOptimizeRouteQualityGate rejects failed final validation', () {
    final report = _validationReport(score: 62, verdict: 'reprovado');

    final decision = evaluateOptimizeRouteQualityGate(
      isComplete: false,
      validationReport: report,
      archetype: 'control',
      preCurve: 3.0,
      postCurve: 3.1,
      preManaAssessment: 'ok',
      postManaAssessment: 'ok',
    );

    expect(decision.rejected, isTrue);
    expect(decision.validation, report.toJson());
    expect(decision.reasons, isNotEmpty);
    expect(decision.reasons.join(' '), contains('62/100'));
  });

  test(
    'evaluateOptimizeRouteQualityGate skips complete mode and approved swaps',
    () {
      final report = _validationReport(score: 88, verdict: 'aprovado');

      expect(
        evaluateOptimizeRouteQualityGate(
          isComplete: true,
          validationReport: _validationReport(score: 20, verdict: 'reprovado'),
          archetype: 'control',
          preCurve: 3.0,
          postCurve: 4.0,
          preManaAssessment: 'ok',
          postManaAssessment: 'critical',
        ).rejected,
        isFalse,
      );

      expect(
        evaluateOptimizeRouteQualityGate(
          isComplete: false,
          validationReport: report,
          archetype: 'control',
          preCurve: 3.0,
          postCurve: 3.0,
          preManaAssessment: 'ok',
          postManaAssessment: 'ok',
        ).rejected,
        isFalse,
      );
    },
  );

  test(
    'evaluateSerializedOptimizeValidation rejects stale serialized failure',
    () {
      final decision = evaluateSerializedOptimizeValidation(
        isComplete: false,
        serializedValidation: const {
          'validation_score': 69,
          'verdict': 'aprovado',
        },
        validationReport: null,
        archetype: 'control',
        preCurve: 3.0,
        postCurve: 3.0,
        preManaAssessment: 'ok',
        postManaAssessment: 'ok',
      );

      expect(decision.rejected, isTrue);
      expect(decision.validation['validation_score'], 69);
      expect(decision.reasons.single, contains('69/100'));
    },
  );

  test(
    'evaluateOptimizeRouteSemanticV2Gate blocks critical losses in partial',
    () {
      final report = _validationReport(
        score: 90,
        verdict: 'aprovado',
        semanticLayerV2: const {
          'role_delta': {'draw': -1, 'protection': -1},
        },
      );

      final decision = evaluateOptimizeRouteSemanticV2Gate(
        isComplete: false,
        validationReport: report,
        enforcementMode: SemanticV2OptimizeEnforcementMode.partial,
        expandedCriticalRoles: false,
      );

      expect(decision.rejected, isTrue);
      expect(decision.semanticLayerV2['role_delta'], isA<Map>());

      expect(
        evaluateOptimizeRouteSemanticV2Gate(
          isComplete: false,
          validationReport: report,
          enforcementMode: SemanticV2OptimizeEnforcementMode.disabled,
          expandedCriticalRoles: false,
        ).rejected,
        isFalse,
      );
    },
  );

  test('projected Commander role gate reports every critical deficit', () {
    final assessment = assessOptimizeProjectedCommanderRoleFloors(
      projectedDeck: [
        const {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 36,
        },
        const {
          'name': 'Fair Creature',
          'type_line': 'Creature',
          'oracle_text': 'Vigilance.',
          'quantity': 64,
        },
      ],
      archetype: 'midrange',
    );

    expect(assessment.applies, isTrue);
    expect(assessment.satisfied, isFalse);
    expect(assessment.deficits, {
      'ramp': 8,
      'draw': 8,
      'interaction': 6,
      'wipe': 2,
    });

    final body = buildOptimizeRoleFloorRejectedBody(
      assessment: assessment,
      removals: const ['Fair Creature'],
      additions: const ['Another Creature'],
      deckAnalysis: const {},
      postAnalysis: null,
      validationWarnings: const [],
    );
    expect(
      (body['quality_error'] as Map)['code'],
      'OPTIMIZE_FUNCTIONAL_ROLE_FLOOR',
    );
    expect(
      (body['quality_error'] as Map)['message'],
      contains('ramp, compra, interação ou wipes'),
    );
    expect(body['can_apply'], isFalse);
    expect(
      body['apply_blockers'],
      contains('commander_functional_role_floor_not_met'),
    );
  });

  test('projected Commander role gate accepts every critical floor', () {
    final assessment = assessOptimizeProjectedCommanderRoleFloors(
      projectedDeck: [
        const {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 36,
        },
        const {
          'name': 'Fair Creature',
          'type_line': 'Creature',
          'oracle_text': 'Vigilance.',
          'quantity': 54,
        },
        const {
          'name': 'Persistent Structural Engine',
          'type_line': 'Artifact',
          'oracle_text':
              '{T}: Add one mana of any color. Whenever you cast your second '
              'spell each turn, draw a card. {2}, {T}: Exile target nonland '
              'permanent.',
          'functional_tags': ['ramp', 'draw', 'interaction'],
          'quantity': 8,
        },
        const {
          'name': 'Wrath of God',
          'type_line': 'Sorcery',
          'oracle_text': 'Destroy all creatures.',
          'quantity': 1,
        },
        const {
          'name': 'Blasphemous Act',
          'type_line': 'Sorcery',
          'oracle_text': 'Blasphemous Act deals 13 damage to each creature.',
          'quantity': 1,
        },
      ],
      archetype: 'midrange',
    );

    expect(assessment.applies, isTrue);
    expect(assessment.satisfied, isTrue);
    expect(assessment.actualCounts, {
      'ramp': 8,
      'draw': 8,
      'interaction': 8,
      'wipe': 2,
    });
  });

  test(
    'projected role gate carries the B1-B5 wipe policy to the final deck',
    () {
      final withoutWipes = <Map<String, dynamic>>[
        const {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 36,
        },
        const {
          'name': 'Persistent Structural Engine',
          'type_line': 'Artifact',
          'oracle_text':
              '{T}: Add one mana of any color. Whenever you cast your second '
              'spell each turn, draw a card. {2}, {T}: Exile target nonland '
              'permanent.',
          'functional_tags': ['ramp', 'draw', 'interaction'],
          'quantity': 8,
        },
        const {
          'name': 'Fair Creature',
          'type_line': 'Creature',
          'quantity': 56,
        },
      ];

      for (var bracket = 1; bracket <= 4; bracket += 1) {
        final assessment = assessOptimizeProjectedCommanderRoleFloors(
          projectedDeck: withoutWipes,
          archetype: 'midrange',
          bracket: bracket,
        );
        expect(assessment.satisfied, isFalse, reason: 'B$bracket');
        expect(
          assessment.deficits['wipe'],
          bracket == 4 ? 1 : 2,
          reason: 'B$bracket',
        );
      }

      final competitive = assessOptimizeProjectedCommanderRoleFloors(
        projectedDeck: withoutWipes,
        archetype: 'midrange',
        bracket: 5,
      );
      expect(competitive.bracket, 5);
      expect(competitive.minimumCounts['wipe'], 0);
      expect(competitive.satisfied, isTrue);
    },
  );
}

ValidationReport _validationReport({
  required int score,
  required String verdict,
  Map<String, dynamic> semanticLayerV2 = const <String, dynamic>{},
}) {
  return ValidationReport(
    score: score,
    healthScore: score,
    improvementScore: score,
    verdict: verdict,
    monteCarlo: MonteCarloComparison(
      before: _goldfishResult(),
      after: _goldfishResult(),
      beforeMulligan: _mulliganReport(),
      afterMulligan: _mulliganReport(),
    ),
    functional: FunctionalReport(
      swaps: const [],
      upgrades: 0,
      sidegrades: 0,
      tradeoffs: 0,
      questionable: 0,
      roleDelta: const {},
      semanticLayerV2: semanticLayerV2,
    ),
    warnings: const [],
  );
}

GoldfishResult _goldfishResult() {
  return GoldfishResult(
    simulations: 1,
    screwRate: 0,
    floodRate: 0,
    keepableRate: 1,
    turn1PlayRate: 1,
    turn2PlayRate: 1,
    turn3PlayRate: 1,
    turn4PlayRate: 1,
    noPlayTurn3Rate: 0,
    avgCmc: 2.0,
    landCount: 36,
    cmcDistribution: const {1: 1},
  );
}

MulliganReport _mulliganReport() {
  return MulliganReport(
    runs: 1,
    avgMulligans: 0,
    keepAt7Rate: 1,
    keepAt6Rate: 0,
    keepAt5Rate: 0,
    keepAt4OrLessRate: 0,
    keepableAfterMullRate: 1,
  );
}
