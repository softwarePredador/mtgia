import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../logger.dart';
import 'optimization_validator.dart';

Map<String, dynamic> buildOptimizationAnalysisLogEntry({
  required String deckId,
  required String? userId,
  required String commanderName,
  required List<String> commanderColors,
  required String operationMode,
  required String requestedMode,
  required String targetArchetype,
  required String? detectedTheme,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> removals,
  required List<String> additions,
  required int statusCode,
  required Map<String, dynamic>? qualityError,
  required ValidationReport? validationReport,
  required List<String> validationWarnings,
  required List<String> blockedByColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
  required List<String> commanderPriorityNames,
  required String commanderPrioritySource,
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String cacheKey,
  required int executionTimeMs,
}) {
  final beforeTypes =
      (deckAnalysis['type_distribution'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final afterTypes =
      (postAnalysis?['type_distribution'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final validationJson = validationReport?.toJson();
  final validationFromQualityError = qualityError?['validation'];
  final validationScoreCandidate = validationJson?['validation_score'] ??
      validationJson?['score'] ??
      (validationFromQualityError is Map
          ? validationFromQualityError['validation_score'] ??
              validationFromQualityError['score']
          : null);
  final validationScore =
      validationReport?.score ?? _toNullableInt(validationScoreCandidate);
  final validationVerdict = validationReport?.verdict ??
      validationJson?['validation_verdict']?.toString() ??
      validationJson?['verdict']?.toString() ??
      (validationFromQualityError is Map
          ? validationFromQualityError['validation_verdict']?.toString() ??
              validationFromQualityError['verdict']?.toString()
          : null) ??
      (statusCode == 200 ? 'aprovado' : 'rejeitado');
  final qualityReasons = qualityError?['reasons'] is List
      ? (qualityError?['reasons'] as List).map((e) => '$e').toList()
      : const <String>[];

  final acceptedPairs = <Map<String, dynamic>>[];
  final pairCount =
      removals.length < additions.length ? removals.length : additions.length;
  for (var i = 0; i < pairCount; i++) {
    acceptedPairs.add({
      'remove': removals[i],
      'add': additions[i],
    });
  }

  return {
    'deck_id': deckId,
    'user_id': userId,
    'commander_name': commanderName,
    'commander_colors': commanderColors,
    'initial_card_count': _extractDeckCardCount(deckAnalysis),
    'final_card_count': _extractDeckCardCount(postAnalysis) ??
        _extractDeckCardCount(deckAnalysis),
    'operation_mode': operationMode,
    'target_archetype': targetArchetype,
    'detected_theme': detectedTheme,
    'before_avg_cmc': _toNullableDouble(deckAnalysis['average_cmc']),
    'before_land_count': _toNullableInt(beforeTypes['lands']) ?? 0,
    'before_creature_count': _toNullableInt(beforeTypes['creatures']) ?? 0,
    'after_avg_cmc': _toNullableDouble(postAnalysis?['average_cmc']),
    'after_land_count': _toNullableInt(afterTypes['lands']) ?? 0,
    'after_creature_count': _toNullableInt(afterTypes['creatures']) ?? 0,
    'removals_count': removals.length,
    'additions_count': additions.length,
    'removals_list': removals,
    'additions_list': additions,
    'validation_score': validationScore,
    'validation_verdict': validationVerdict,
    'color_identity_violations': blockedByColorIdentity.length,
    'edhrec_validated_count': 0,
    'edhrec_not_validated_count': 0,
    'validation_warnings': validationWarnings,
    'decisions_reasoning': {
      'status_code': statusCode,
      'requested_mode': requestedMode,
      'response_mode': operationMode,
      'cache_key': cacheKey,
      'quality_error_code': qualityError?['code'],
      'quality_error_message': qualityError?['message'],
      'quality_error_reasons': qualityReasons,
      'commander_priority_source': commanderPrioritySource,
      'commander_priority_pool_size': commanderPriorityNames.length,
      'commander_priority_pool_sample':
          commanderPriorityNames.take(25).toList(),
      'deterministic_swap_candidate_count': deterministicSwapCandidates.length,
      'deterministic_swap_candidate_sample':
          deterministicSwapCandidates.take(10).toList(),
    },
    'swap_analysis': {
      'accepted_pairs': acceptedPairs,
      'blocked_by_color_identity': blockedByColorIdentity,
      'blocked_by_bracket': blockedByBracket,
      'status_code': statusCode,
    },
    'role_delta': {
      'before': beforeTypes,
      'after': afterTypes,
    },
    'execution_time_ms': executionTimeMs,
    'effectiveness_score': validationScore?.toDouble(),
    'improvements_achieved':
        (postAnalysis?['improvements'] as List?)?.map((e) => '$e').toList() ??
            const <String>[],
    'potential_issues': [
      if (qualityError != null) qualityError,
      if (blockedByColorIdentity.isNotEmpty)
        {
          'type': 'color_identity_blocks',
          'count': blockedByColorIdentity.length,
          'cards': blockedByColorIdentity,
        },
      if (blockedByBracket.isNotEmpty)
        {
          'type': 'bracket_blocks',
          'count': blockedByBracket.length,
          'cards': blockedByBracket,
        },
    ],
    'alternative_approaches': const <Map<String, dynamic>>[],
    'lessons_learned':
        'status=$statusCode source=$commanderPrioritySource pairs=$pairCount commander=$commanderName',
  };
}

Future<void> recordOptimizeAnalysisOutcome({
  required Pool pool,
  required String deckId,
  required String? userId,
  required String commanderName,
  required List<String> commanderColors,
  required String operationMode,
  required String requestedMode,
  required String targetArchetype,
  required String? detectedTheme,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> removals,
  required List<String> additions,
  required int statusCode,
  required Map<String, dynamic>? qualityError,
  required ValidationReport? validationReport,
  required List<String> validationWarnings,
  required List<String> blockedByColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
  required List<String> commanderPriorityNames,
  required String commanderPrioritySource,
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String cacheKey,
  required int executionTimeMs,
}) async {
  try {
    final entry = buildOptimizationAnalysisLogEntry(
      deckId: deckId,
      userId: userId,
      commanderName: commanderName,
      commanderColors: commanderColors,
      operationMode: operationMode,
      requestedMode: requestedMode,
      targetArchetype: targetArchetype,
      detectedTheme: detectedTheme,
      deckAnalysis: deckAnalysis,
      postAnalysis: postAnalysis,
      removals: removals,
      additions: additions,
      statusCode: statusCode,
      qualityError: qualityError,
      validationReport: validationReport,
      validationWarnings: validationWarnings,
      blockedByColorIdentity: blockedByColorIdentity,
      blockedByBracket: blockedByBracket,
      commanderPriorityNames: commanderPriorityNames,
      commanderPrioritySource: commanderPrioritySource,
      deterministicSwapCandidates: deterministicSwapCandidates,
      cacheKey: cacheKey,
      executionTimeMs: executionTimeMs,
    );

    await pool.execute(
      Sql.named('''
        INSERT INTO optimization_analysis_logs (
          test_run_id, test_number, commander_name, commander_colors,
          initial_card_count, final_card_count, operation_mode, target_archetype,
          detected_theme, before_avg_cmc, before_land_count, before_creature_count,
          after_avg_cmc, after_land_count, after_creature_count,
          removals_count, additions_count, removals_list, additions_list,
          validation_score, validation_verdict, color_identity_violations,
          edhrec_validated_count, edhrec_not_validated_count, validation_warnings,
          decisions_reasoning, swap_analysis, role_delta, execution_time_ms,
          effectiveness_score, improvements_achieved, potential_issues,
          alternative_approaches, lessons_learned
        ) VALUES (
          gen_random_uuid(), 1, @commander_name, @commander_colors,
          @initial_card_count, @final_card_count, @operation_mode, @target_archetype,
          @detected_theme, @before_avg_cmc, @before_land_count, @before_creature_count,
          @after_avg_cmc, @after_land_count, @after_creature_count,
          @removals_count, @additions_count, @removals_list::jsonb, @additions_list::jsonb,
          @validation_score, @validation_verdict, @color_identity_violations,
          @edhrec_validated_count, @edhrec_not_validated_count, @validation_warnings::jsonb,
          @decisions_reasoning::jsonb, @swap_analysis::jsonb, @role_delta::jsonb,
          @execution_time_ms, @effectiveness_score, @improvements_achieved::jsonb,
          @potential_issues::jsonb, @alternative_approaches::jsonb, @lessons_learned
        )
      '''),
      parameters: {
        'commander_name': entry['commander_name'],
        'commander_colors': entry['commander_colors'],
        'initial_card_count': entry['initial_card_count'],
        'final_card_count': entry['final_card_count'],
        'operation_mode': entry['operation_mode'],
        'target_archetype': entry['target_archetype'],
        'detected_theme': entry['detected_theme'],
        'before_avg_cmc': entry['before_avg_cmc'],
        'before_land_count': entry['before_land_count'],
        'before_creature_count': entry['before_creature_count'],
        'after_avg_cmc': entry['after_avg_cmc'],
        'after_land_count': entry['after_land_count'],
        'after_creature_count': entry['after_creature_count'],
        'removals_count': entry['removals_count'],
        'additions_count': entry['additions_count'],
        'removals_list': jsonEncode(entry['removals_list']),
        'additions_list': jsonEncode(entry['additions_list']),
        'validation_score': entry['validation_score'],
        'validation_verdict': entry['validation_verdict'],
        'color_identity_violations': entry['color_identity_violations'],
        'edhrec_validated_count': entry['edhrec_validated_count'],
        'edhrec_not_validated_count': entry['edhrec_not_validated_count'],
        'validation_warnings': jsonEncode(entry['validation_warnings']),
        'decisions_reasoning': jsonEncode(entry['decisions_reasoning']),
        'swap_analysis': jsonEncode(entry['swap_analysis']),
        'role_delta': jsonEncode(entry['role_delta']),
        'execution_time_ms': entry['execution_time_ms'],
        'effectiveness_score': entry['effectiveness_score'],
        'improvements_achieved': jsonEncode(entry['improvements_achieved']),
        'potential_issues': jsonEncode(entry['potential_issues']),
        'alternative_approaches': jsonEncode(entry['alternative_approaches']),
        'lessons_learned': entry['lessons_learned'],
      },
    );
  } catch (e) {
    Log.w('Falha ao persistir optimization_analysis_logs: $e');
  }
}

int? _extractDeckCardCount(Map<String, dynamic>? analysis) {
  if (analysis == null) return null;
  final typeDistribution =
      (analysis['type_distribution'] as Map?)?.cast<String, dynamic>();
  if (typeDistribution != null && typeDistribution.isNotEmpty) {
    return typeDistribution.values
        .map(_toNullableInt)
        .whereType<int>()
        .fold<int>(0, (sum, value) => sum + value);
  }
  return null;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
