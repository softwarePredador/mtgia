import 'optimize_functional_role_support.dart';
import 'optimization_functional_roles.dart';
import 'optimization_quality_gate.dart';
import 'optimization_validator.dart';

class OptimizeRouteQualityGateDecision {
  final bool rejected;
  final List<String> reasons;
  final Map<String, dynamic> validation;

  const OptimizeRouteQualityGateDecision({
    required this.rejected,
    required this.reasons,
    required this.validation,
  });

  static const none = OptimizeRouteQualityGateDecision(
    rejected: false,
    reasons: <String>[],
    validation: <String, dynamic>{},
  );
}

CommanderFunctionalRoleFloorAssessment
assessOptimizeProjectedCommanderRoleFloors({
  required List<Map<String, dynamic>> projectedDeck,
  required String archetype,
}) {
  return assessCommanderFunctionalRoleFloors(
    cards: projectedDeck,
    targetArchetype: archetype,
  );
}

Map<String, dynamic> buildOptimizeRoleFloorRejectedBody({
  required CommanderFunctionalRoleFloorAssessment assessment,
  required List<String> removals,
  required List<String> additions,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> validationWarnings,
}) {
  return {
    'error':
        'A otimização foi bloqueada porque a lista projetada não cobre '
        'funções estruturais mínimas de Commander.',
    'quality_error': {
      'code': 'OPTIMIZE_FUNCTIONAL_ROLE_FLOOR',
      'message':
          'A lista projetada ainda está abaixo do piso estrutural de wipes.',
      'functional_role_policy': assessment.toJson(),
    },
    'mode': 'optimize',
    'functional_role_policy': assessment.toJson(),
    'removals': removals,
    'additions': additions,
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysis,
    'validation_warnings': validationWarnings,
    'can_apply': false,
    'learning_eligible': false,
    'apply_blockers': const ['commander_functional_role_floor_not_met'],
  };
}

OptimizeRouteQualityGateDecision evaluateOptimizeRouteQualityGate({
  required bool isComplete,
  required ValidationReport? validationReport,
  required String archetype,
  required double preCurve,
  required double postCurve,
  required String preManaAssessment,
  required String postManaAssessment,
  Map<String, dynamic>? profileRoleTargets,
}) {
  if (isComplete || validationReport == null) {
    return OptimizeRouteQualityGateDecision.none;
  }

  final hardRejected =
      validationReport.verdict != 'aprovado' || validationReport.score < 70;
  final reasons =
      hardRejected
          ? buildOptimizationRejectionReasons(
            validationReport: validationReport,
            archetype: archetype,
            preCurve: preCurve,
            postCurve: postCurve,
            preManaAssessment: preManaAssessment,
            postManaAssessment: postManaAssessment,
            profileRoleTargets: profileRoleTargets,
          )
          : const <String>[];

  return OptimizeRouteQualityGateDecision(
    rejected: hardRejected || reasons.isNotEmpty,
    reasons: reasons,
    validation: validationReport.toJson(),
  );
}

class OptimizeRouteSerializedValidationDecision {
  final bool rejected;
  final List<String> reasons;
  final Map<String, dynamic> validation;

  const OptimizeRouteSerializedValidationDecision({
    required this.rejected,
    required this.reasons,
    required this.validation,
  });

  static const none = OptimizeRouteSerializedValidationDecision(
    rejected: false,
    reasons: <String>[],
    validation: <String, dynamic>{},
  );
}

OptimizeRouteSerializedValidationDecision evaluateSerializedOptimizeValidation({
  required bool isComplete,
  required Map<String, dynamic>? serializedValidation,
  required ValidationReport? validationReport,
  required String archetype,
  required double preCurve,
  required double postCurve,
  required String preManaAssessment,
  required String postManaAssessment,
  Map<String, dynamic>? profileRoleTargets,
}) {
  if (isComplete || serializedValidation == null) {
    return OptimizeRouteSerializedValidationDecision.none;
  }

  final score =
      (serializedValidation['validation_score'] as num?)?.toInt() ??
      (serializedValidation['score'] as num?)?.toInt() ??
      0;
  final verdict = serializedValidation['verdict']?.toString() ?? '';
  if (verdict == 'aprovado' && score >= 70) {
    return OptimizeRouteSerializedValidationDecision.none;
  }

  final reasons =
      validationReport != null
          ? buildOptimizationRejectionReasons(
            validationReport: validationReport,
            archetype: archetype,
            preCurve: preCurve,
            postCurve: postCurve,
            preManaAssessment: preManaAssessment,
            postManaAssessment: postManaAssessment,
            profileRoleTargets: profileRoleTargets,
          )
          : <String>[
            'A validação final não fechou como "aprovado" (score $score/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.',
          ];

  return OptimizeRouteSerializedValidationDecision(
    rejected: true,
    reasons: reasons,
    validation: serializedValidation,
  );
}

class OptimizeRouteSemanticV2GateDecision {
  final bool rejected;
  final Map<String, dynamic> semanticLayerV2;

  const OptimizeRouteSemanticV2GateDecision({
    required this.rejected,
    required this.semanticLayerV2,
  });

  static const none = OptimizeRouteSemanticV2GateDecision(
    rejected: false,
    semanticLayerV2: <String, dynamic>{},
  );
}

OptimizeRouteSemanticV2GateDecision evaluateOptimizeRouteSemanticV2Gate({
  required bool isComplete,
  required ValidationReport? validationReport,
  required SemanticV2OptimizeEnforcementMode enforcementMode,
  required bool expandedCriticalRoles,
}) {
  if (isComplete || validationReport == null) {
    return OptimizeRouteSemanticV2GateDecision.none;
  }

  final semanticLayerV2 = validationReport.functional.semanticLayerV2;
  if (semanticLayerV2.isEmpty) {
    return OptimizeRouteSemanticV2GateDecision.none;
  }

  final decision = evaluateOptimizationSemanticV2Enforcement(
    semanticLayerV2: semanticLayerV2,
    mode: enforcementMode,
    expandedCriticalRoles: expandedCriticalRoles,
  );

  return OptimizeRouteSemanticV2GateDecision(
    rejected: decision.blockedBySemanticV2,
    semanticLayerV2: semanticLayerV2,
  );
}
