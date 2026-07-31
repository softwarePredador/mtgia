import '../commander_mana_floor.dart';
import 'optimize_functional_role_support.dart';

const aiGenerateCommanderStructuralPolicyVersion =
    'ai_generate_commander_structure_v1_2026-07-31';

class AiGenerateCommanderStructuralAssessment {
  const AiGenerateCommanderStructuralAssessment({
    required this.applicable,
    required this.bracket,
    required this.archetype,
    required this.manaFoundation,
    required this.functionalRoles,
  });

  final bool applicable;
  final int? bracket;
  final String archetype;
  final CommanderManaFloorAssessment manaFoundation;
  final CommanderFunctionalRoleFloorAssessment functionalRoles;

  bool get hardCompliant =>
      !applicable || (manaFoundation.satisfied && functionalRoles.satisfied);

  List<String> get blockers => [
    if (applicable && !manaFoundation.meetsMinimum)
      'commander_land_floor_not_met',
    if (applicable && manaFoundation.hasSevereExcess)
      'commander_land_excess_requires_rebuild',
    if (applicable && !functionalRoles.satisfied)
      'commander_functional_role_floor_not_met',
  ];

  Map<String, dynamic> toJson() => {
    'policy_version': aiGenerateCommanderStructuralPolicyVersion,
    'applicable': applicable,
    if (bracket != null) 'bracket': bracket,
    'archetype': archetype,
    'hard_compliant': hardCompliant,
    'blockers': blockers,
    'mana_foundation': {
      'land_count': manaFoundation.landCount,
      'minimum_land_count': manaFoundation.minimumLandCount,
      'severe_excess_land_count': manaFoundation.severeExcessLandCount,
      'total_card_count': manaFoundation.totalCardCount,
      'meets_minimum': manaFoundation.meetsMinimum,
      'has_severe_excess': manaFoundation.hasSevereExcess,
      'satisfied': manaFoundation.satisfied,
    },
    'functional_role_policy': functionalRoles.toJson(),
  };
}

AiGenerateCommanderStructuralAssessment
evaluateAiGenerateCommanderStructuralQuality({
  required String format,
  required int? requestedBracket,
  required String prompt,
  required Iterable<Map<String, dynamic>> resolvedCards,
}) {
  final normalizedFormat = format.trim().toLowerCase();
  final applicable =
      normalizedFormat == 'commander' || normalizedFormat == 'edh';
  final cards = resolvedCards.toList(growable: false);
  final archetype = inferAiGenerateTargetArchetype(prompt);

  return AiGenerateCommanderStructuralAssessment(
    applicable: applicable,
    bracket: requestedBracket,
    archetype: archetype,
    manaFoundation: assessCommanderManaFloor(
      format: normalizedFormat,
      cards: cards,
    ),
    functionalRoles: assessCommanderFunctionalRoleFloors(
      cards: cards,
      targetArchetype: archetype,
      bracket: requestedBracket,
    ),
  );
}

String inferAiGenerateTargetArchetype(String prompt) {
  final normalized = prompt.trim().toLowerCase();
  if (normalized.contains('control') ||
      normalized.contains('stax') ||
      normalized.contains('prison')) {
    return 'control';
  }
  if (normalized.contains('aggro') ||
      normalized.contains('tribal') ||
      normalized.contains('typal') ||
      normalized.contains('voltron')) {
    return 'aggro';
  }
  if (normalized.contains('combo') ||
      normalized.contains('storm') ||
      normalized.contains('cedh')) {
    return 'combo';
  }
  return 'midrange';
}

Map<String, dynamic> applyAiGenerateCommanderStructuralContract({
  required String format,
  required int? requestedBracket,
  required String prompt,
  required Map<String, dynamic> responseBody,
  required Iterable<Map<String, dynamic>> resolvedCards,
}) {
  final assessment = evaluateAiGenerateCommanderStructuralQuality(
    format: format,
    requestedBracket: requestedBracket,
    prompt: prompt,
    resolvedCards: resolvedCards,
  );
  if (!assessment.applicable) return responseBody;

  final existingContract = _asStringMap(responseBody['deckbuilding_contract']);
  final existingGates = _asStringMap(existingContract['gates']);
  final existingBlockers = _stringList(existingContract['blockers']);
  final blockers = <String>{
    ...existingBlockers,
    if (!assessment.hardCompliant) 'commander_structural_quality_violation',
  }.toList(growable: false);

  return {
    ...responseBody,
    'structural_quality': assessment.toJson(),
    'deckbuilding_contract': {
      ...existingContract,
      'gates': {
        ...existingGates,
        'structural_quality_satisfied': assessment.hardCompliant,
      },
      'blockers': blockers,
    },
    if (!assessment.hardCompliant) ...{
      'can_save': false,
      'learning_eligible': false,
      'learning_exclusion_reason': 'commander_structural_quality_violation',
    },
  };
}

bool aiGenerateCommanderStructuralMustReject(Map<String, dynamic> body) {
  final format = body['format']?.toString().trim().toLowerCase();
  if (format != 'commander' && format != 'edh') return false;
  final structural = _asStringMap(body['structural_quality']);
  return structural['applicable'] != true ||
      structural['hard_compliant'] != true;
}

Map<String, dynamic> buildAiGenerateCommanderStructuralViolationPayload(
  Map<String, dynamic> body,
) {
  final structural = _asStringMap(body['structural_quality']);
  return {
    ...body,
    'error':
        'A lista gerada não atingiu a estrutura mínima para uma partida de '
        'Commander. Tente novamente ou ajuste o pedido.',
    'error_code': 'ai_generate_structural_quality_violation',
    'outcome_code': 'structural_quality_rejected',
    'retryable': true,
    'can_save': false,
    'learning_eligible': false,
    'structural_quality': structural,
  };
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is! Map) return const <String, dynamic>{};
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}
