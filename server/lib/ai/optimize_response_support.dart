import 'package:dart_frog/dart_frog.dart';
import 'optimization_functional_roles.dart';

// ============================================================================
// Optimize Response Builders
// Extracted from routes/ai/optimize/index.dart to reduce route file size
// ============================================================================

Map<String, dynamic> buildSemanticV2OptimizeRejectedBody({
  required Map<String, dynamic> semanticLayerV2,
  required SemanticV2OptimizeEnforcementMode enforcementMode,
  required bool expandedCriticalRoles,
  required Map<String, dynamic> validation,
  required List<String> removals,
  required List<String> additions,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> validationWarnings,
}) {
  final semanticV2Decision = evaluateOptimizationSemanticV2Enforcement(
    semanticLayerV2: semanticLayerV2,
    mode: enforcementMode,
    expandedCriticalRoles: expandedCriticalRoles,
  );
  final semanticsDiagnostics =
      withOptimizationSemanticV2EnforcementDiagnostics(
    semanticLayerV2: semanticLayerV2,
    mode: enforcementMode,
    expandedCriticalRoles: expandedCriticalRoles,
  );
  final semanticReasons = semanticV2Decision.criticalLossRoles
      .map((role) => 'Semantic Layer v2 detectou perda crítica em "$role".')
      .toList();

  return {
    'error': 'A otimizacao sugerida foi bloqueada pela validacao semantica v2.',
    'quality_error': {
      'code': 'OPTIMIZE_SEMANTIC_V2_REJECTED',
      'message':
          'As trocas passaram no gate atual, mas a Semantic Layer v2 em modo partial detectou perda critica.',
      'rejection_source': 'semantic_layer_v2',
      'reasons': semanticReasons,
      'critical_loss_roles': semanticV2Decision.criticalLossRoles,
      'review_loss_roles': semanticV2Decision.reviewLossRoles,
      'blocked_by_semantic_v2': true,
      'semantic_layer_v2': semanticsDiagnostics,
      'validation': validation,
    },
    'mode': 'optimize',
    'removals': removals,
    'additions': additions,
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysis,
    'validation_warnings': validationWarnings,
    'optimize_diagnostics': {
      'semantic_layer_v2': semanticsDiagnostics,
    },
  };
}

Map<String, dynamic> buildOptimizeBracketPolicyDiagnostics({
  required int? bracket,
  required List<Map<String, dynamic>> blockedByBracket,
}) {
  return {
    'bracket': bracket,
    'blocked_count': blockedByBracket.length,
    'blocked_additions': blockedByBracket,
    'message':
        'Algumas adições sugeridas foram bloqueadas por exceder limites do bracket.',
  };
}

void attachOptimizeBracketPolicyDiagnostics(
  Map<String, dynamic> responseBody, {
  required int? bracket,
  required List<Map<String, dynamic>> blockedByBracket,
}) {
  if (blockedByBracket.isEmpty) return;
  final existingDiagnostics = responseBody['optimize_diagnostics'] is Map
      ? (responseBody['optimize_diagnostics'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  responseBody['optimize_diagnostics'] = {
    ...existingDiagnostics,
    'bracket_policy': buildOptimizeBracketPolicyDiagnostics(
      bracket: bracket,
      blockedByBracket: blockedByBracket,
    ),
  };
}

Map<String, dynamic> buildOptimizeResponse({
  required String mode,
  required List<String> removals,
  required List<String> additions,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> validationWarnings,
  required Map<String, dynamic>? semanticLayerV2,
  required Map<String, dynamic> validation,
  List<String>? structuralRecoveryReasons,
  List<String>? droppedReasons,
}) {
  final response = <String, dynamic>{
    'mode': mode,
    'removals': removals,
    'additions': additions,
    'deck_analysis': deckAnalysis,
    'post_analysis': postAnalysis,
    'validation_warnings': validationWarnings,
    'validation': validation,
  };
  if (semanticLayerV2 != null) {
    response['semantic_layer_v2'] = semanticLayerV2;
  }
  if (structuralRecoveryReasons != null) {
    response['structural_recovery_reasons'] = structuralRecoveryReasons;
  }
  if (droppedReasons != null) {
    response['dropped_reasons'] = droppedReasons;
  }
  return response;
}

Future<Response> respondWithOptimizeTelemetry({
  required int statusCode,
  required Map<String, dynamic> body,
  Map<String, dynamic>? postAnalysisOverride,
  Map<String, dynamic>? validationReport,
  List<String>? removalsOverride,
  List<String>? additionsOverride,
  List<String>? validationWarningsOverride,
  List<String>? blockedByColorIdentityOverride,
  List<Map<String, dynamic>>? blockedByBracketOverride,
  bool fromAsyncJob = false,
}) async {
  return Response.json(
    statusCode: statusCode,
    body: body,
  );
}
