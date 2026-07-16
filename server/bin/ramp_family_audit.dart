#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:server/basic_land_utils.dart' as land_utils;
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:server/ai/optimization_ramp_profile.dart';
import 'package:server/database.dart';

const _heuristicSource = 'deterministic_heuristic_v1';
const _semanticSource = 'deterministic_semantic_v2';
const _rampTag = 'ramp';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('''
Read-only ramp family audit.

Usage:
  dart run bin/ramp_family_audit.dart \
    --artifact-dir=/tmp/manaloom_ramp_family_audit \
    [--sample-limit=20]
''');
    return;
  }

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ?? '/tmp/manaloom_ramp_family_audit',
  );
  final sampleLimit = _readIntArg(args, '--sample-limit=', fallback: 20);
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  try {
    final pool = database.connection;
    final heuristicCards = await _loadHeuristicOwnerCards(pool);
    final semanticCards = await _loadSemanticOwnerCards(pool);
    final functionRows = await _loadFunctionRows(pool);
    final roleRows = await _loadRoleRows(pool);
    final semanticRows = await _loadSemanticRows(pool);

    final heuristicById = {for (final card in heuristicCards) card.id: card};
    final semanticById = {for (final card in semanticCards) card.id: card};
    final allById = <String, _AuditCard>{...semanticById, ...heuristicById};

    final expectedHeuristic = <String>{
      for (final card in heuristicCards)
        if (_candidateHasRamp(card)) card.id,
    };
    final globalExpectedSemantic = <String>{
      for (final card in semanticCards)
        if (_semanticHasRamp(card)) card.id,
    };
    final existingSemanticIds = semanticRows.map((row) => row.cardId).toSet();
    final expectedSemantic = globalExpectedSemantic.intersection(
      existingSemanticIds,
    );

    final currentHeuristic =
        functionRows
            .where((row) => row.source == _heuristicSource)
            .map((row) => row.cardId)
            .toSet();
    final currentSemanticFunction =
        functionRows
            .where((row) => row.source == _semanticSource)
            .map((row) => row.cardId)
            .toSet();
    final currentSemanticJson =
        semanticRows
            .where((row) => row.hasRamp)
            .map((row) => row.cardId)
            .toSet();

    final heuristicToRemove = currentHeuristic.difference(expectedHeuristic);
    final heuristicToAdd = expectedHeuristic.difference(currentHeuristic);
    final semanticFunctionToRemove = currentSemanticFunction.difference(
      expectedSemantic,
    );
    final semanticFunctionToAdd = expectedSemantic.difference(
      currentSemanticFunction,
    );
    final semanticJsonToRemove = currentSemanticJson.difference(
      expectedSemantic,
    );
    final semanticJsonToAdd = expectedSemantic.difference(currentSemanticJson);

    final confirmedLandIds = <String>{
      ...heuristicToRemove.where((id) => allById[id]?.isLand ?? false),
      ...semanticFunctionToRemove.where((id) => allById[id]?.isLand ?? false),
      ...semanticJsonToRemove.where((id) => allById[id]?.isLand ?? false),
      ...roleRows
          .where((row) => allById[row.cardId]?.isLand ?? false)
          .map((row) => row.cardId),
    };
    final heuristicNonlandRemovals = heuristicToRemove.difference(
      confirmedLandIds,
    );
    final semanticNonlandRemovals = <String>{
      ...semanticFunctionToRemove,
      ...semanticJsonToRemove,
    }.difference(confirmedLandIds);
    final falseRoleRows = roleRows
        .where((row) {
          final card = allById[row.cardId];
          return card != null && !_candidateHasRampRole(card);
        })
        .toList(growable: false);
    final confirmedFalsePositiveIds = <String>{
      ...heuristicToRemove,
      ...semanticFunctionToRemove,
      ...semanticJsonToRemove,
      ...falseRoleRows.map((row) => row.cardId),
    };
    final falseRoleManifest =
        falseRoleRows.map((row) {
            final card = allById[row.cardId]!;
            return {
              'card_id': row.cardId,
              'card_name': card.name,
              'type_line': card.typeLine,
              'oracle_text': card.oracleText,
              'classification':
                  card.isLand
                      ? _landClassification(card)
                      : _nonlandRampRemovalClassification(card),
              'row_key': row.key,
            };
          }).toList()
          ..sort(
            (a, b) =>
                (a['card_name'] as String).compareTo(b['card_name'] as String),
          );
    final legitimateNonlandAdditions =
        <String>{
          ...heuristicToAdd,
          ...semanticFunctionToAdd,
          ...semanticJsonToAdd,
        }.where((id) => !(allById[id]?.isLand ?? false)).toSet();

    final landManifest =
        confirmedLandIds.map((id) {
            final card = allById[id]!;
            return {
              'card_id': id,
              'card_name': card.name,
              'type_line': card.typeLine,
              'classification': _landClassification(card),
              'heuristic_function_row': currentHeuristic.contains(id),
              'heuristic_role_row_count':
                  roleRows.where((row) => row.cardId == id).length,
              'semantic_function_row': currentSemanticFunction.contains(id),
              'semantic_json_tag': currentSemanticJson.contains(id),
              'expected_heuristic_ramp': expectedHeuristic.contains(id),
              'expected_semantic_ramp': expectedSemantic.contains(id),
            };
          }).toList()
          ..sort(
            (a, b) =>
                (a['card_name'] as String).compareTo(b['card_name'] as String),
          );

    final legitimateManifest =
        legitimateNonlandAdditions.map((id) {
            final card = allById[id]!;
            final profile = _rampProfile(card);
            return {
              'card_id': id,
              'card_name': card.name,
              'type_line': card.typeLine,
              'oracle_text': card.oracleText,
              'classification': _nonlandRampClassification(card),
              'expected_heuristic_ramp': expectedHeuristic.contains(id),
              'expected_semantic_ramp': expectedSemantic.contains(id),
              'missing_heuristic_function': heuristicToAdd.contains(id),
              'missing_semantic_function': semanticFunctionToAdd.contains(id),
              'missing_semantic_json': semanticJsonToAdd.contains(id),
              'ramp_profile': profile.toJson(),
            };
          }).toList()
          ..sort(
            (a, b) =>
                (a['card_name'] as String).compareTo(b['card_name'] as String),
          );

    final expectedNonlandIds =
        <String>{
          ...expectedHeuristic,
          ...expectedSemantic,
        }.where((id) => !(allById[id]?.isLand ?? false)).toSet();
    final expectedNonlandManifest =
        expectedNonlandIds.map((id) {
            final card = allById[id]!;
            final profile = _rampProfile(card);
            return {
              'card_id': id,
              'card_name': card.name,
              'type_line': card.typeLine,
              'oracle_text': card.oracleText,
              'classification': _nonlandRampClassification(card),
              'expected_heuristic_ramp': expectedHeuristic.contains(id),
              'expected_semantic_ramp': expectedSemantic.contains(id),
              'ramp_profile': profile.toJson(),
            };
          }).toList()
          ..sort(
            (a, b) =>
                (a['card_name'] as String).compareTo(b['card_name'] as String),
          );

    final structuralRampAdditionIds =
        legitimateNonlandAdditions
            .where((id) => _rampProfile(allById[id]!).countsTowardGenericFloor)
            .toSet();
    final contextualRampAdditionIds = legitimateNonlandAdditions.difference(
      structuralRampAdditionIds,
    );
    final expectedRampFloorIds =
        expectedNonlandIds
            .where((id) => _rampProfile(allById[id]!).countsTowardGenericFloor)
            .toSet();
    final structuralRampAdditionManifest = legitimateManifest
        .where(
          (row) => structuralRampAdditionIds.contains(row['card_id'] as String),
        )
        .toList(growable: false);
    final contextualRampAdditionManifest = legitimateManifest
        .where(
          (row) => contextualRampAdditionIds.contains(row['card_id'] as String),
        )
        .toList(growable: false);
    final expectedRampFloorManifest = expectedNonlandManifest
        .where((row) => expectedRampFloorIds.contains(row['card_id'] as String))
        .toList(growable: false);

    final nonlandRemovalIds = <String>{
      ...heuristicNonlandRemovals,
      ...semanticNonlandRemovals,
    };
    final nonlandRemovalManifest =
        nonlandRemovalIds.map((id) {
            final card = allById[id]!;
            return {
              'card_id': id,
              'card_name': card.name,
              'type_line': card.typeLine,
              'oracle_text': card.oracleText,
              'classification': _nonlandRampRemovalClassification(card),
              'current_heuristic_ramp': currentHeuristic.contains(id),
              'current_semantic_ramp': currentSemanticFunction.contains(id),
              'expected_heuristic_ramp': expectedHeuristic.contains(id),
              'expected_semantic_ramp': expectedSemantic.contains(id),
              'heuristic_role_row_count':
                  roleRows.where((row) => row.cardId == id).length,
            };
          }).toList()
          ..sort(
            (a, b) =>
                (a['card_name'] as String).compareTo(b['card_name'] as String),
          );

    final summary = <String, dynamic>{
      'schema_version': 'ramp_family_audit_v3',
      'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'db_mutations': false,
      'contract': {
        'land':
            'Every land remains structural land/fixing and never satisfies a generic nonland ramp slot, including fetches and conditional multi-mana lands.',
        'nonland':
            'Land-search spells, mana rocks/dorks, temporary rituals, treasure, extra-land effects and cost reduction remain eligible ramp.',
        'postgres_truth': true,
        'semantic_partial_snapshot_creation': false,
      },
      'heuristic_function_lane': _laneSummary(
        expected: expectedHeuristic,
        current: currentHeuristic,
        cards: allById,
        sampleLimit: sampleLimit,
      ),
      'semantic_function_lane': {
        'global_expected_count': globalExpectedSemantic.length,
        'global_expected_card_id_sha256': _digest(globalExpectedSemantic),
        'existing_semantic_snapshot_count': existingSemanticIds.length,
        ..._laneSummary(
          expected: expectedSemantic,
          current: currentSemanticFunction,
          cards: allById,
          sampleLimit: sampleLimit,
        ),
      },
      'semantic_json_lane': _laneSummary(
        expected: expectedSemantic,
        current: currentSemanticJson,
        cards: allById,
        sampleLimit: sampleLimit,
      ),
      'confirmed_false_positive_land_scope': {
        'card_count': confirmedLandIds.length,
        'card_id_sha256': _digest(confirmedLandIds),
        'classification_counts': _countManifest(landManifest),
        'heuristic_function_rows':
            currentHeuristic.intersection(confirmedLandIds).length,
        'heuristic_function_card_id_sha256': _digest(
          currentHeuristic.intersection(confirmedLandIds),
        ),
        'heuristic_role_rows':
            roleRows
                .where((row) => confirmedLandIds.contains(row.cardId))
                .length,
        'heuristic_role_row_key_sha256': _digestStrings(
          roleRows
              .where((row) => confirmedLandIds.contains(row.cardId))
              .map((row) => row.key),
        ),
        'semantic_function_rows':
            currentSemanticFunction.intersection(confirmedLandIds).length,
        'semantic_function_card_id_sha256': _digest(
          currentSemanticFunction.intersection(confirmedLandIds),
        ),
        'semantic_json_rows':
            currentSemanticJson.intersection(confirmedLandIds).length,
        'semantic_json_card_id_sha256': _digest(
          currentSemanticJson.intersection(confirmedLandIds),
        ),
        'all_expected_ramp_false': confirmedLandIds.every(
          (id) =>
              !expectedHeuristic.contains(id) && !expectedSemantic.contains(id),
        ),
        'artifact': 'confirmed_false_positive_land_rows.json',
        'samples': _sampleNames(confirmedLandIds, allById, sampleLimit),
      },
      'confirmed_false_positive_package_scope': {
        'card_count': confirmedFalsePositiveIds.length,
        'card_id_sha256': _digest(confirmedFalsePositiveIds),
        'heuristic_function_rows': heuristicToRemove.length,
        'heuristic_function_card_id_sha256': _digest(heuristicToRemove),
        'heuristic_role_rows': falseRoleRows.length,
        'heuristic_role_row_key_sha256': _digestStrings(
          falseRoleRows.map((row) => row.key),
        ),
        'heuristic_role_classification_counts': _countManifest(
          falseRoleManifest,
        ),
        'heuristic_role_artifact': 'false_ramp_role_rows.json',
        'semantic_function_rows': semanticFunctionToRemove.length,
        'semantic_function_card_id_sha256': _digest(semanticFunctionToRemove),
        'semantic_json_rows': semanticJsonToRemove.length,
        'semantic_json_card_id_sha256': _digest(semanticJsonToRemove),
        'all_expected_ramp_false': confirmedFalsePositiveIds.every((id) {
          final card = allById[id];
          return card != null &&
              !_candidateHasRampRole(card) &&
              !_semanticHasRamp(card);
        }),
        'proposed_action':
            'exact remove-only package after independent Oracle review; no missing rows are added',
      },
      'legitimate_nonland_drift': {
        'addition_card_count': legitimateNonlandAdditions.length,
        'addition_card_id_sha256': _digest(legitimateNonlandAdditions),
        'classification_counts': _countManifest(legitimateManifest),
        'artifact': 'legitimate_nonland_drift.json',
        'package_action':
            'split structural and contextual ramp before any bulk upsert',
        'structural_floor_addition_count': structuralRampAdditionIds.length,
        'structural_floor_addition_card_id_sha256': _digest(
          structuralRampAdditionIds,
        ),
        'structural_floor_artifact': 'ramp_drift_structural_rows.json',
        'contextual_addition_count': contextualRampAdditionIds.length,
        'contextual_addition_card_id_sha256': _digest(
          contextualRampAdditionIds,
        ),
        'contextual_artifact': 'ramp_drift_contextual_rows.json',
        'samples': _sampleNames(
          legitimateNonlandAdditions,
          allById,
          sampleLimit,
        ),
      },
      'expected_nonland_ramp_scope': {
        'card_count': expectedNonlandIds.length,
        'card_id_sha256': _digest(expectedNonlandIds),
        'classification_counts': _countManifest(expectedNonlandManifest),
        'artifact': 'expected_nonland_ramp_rows.json',
      },
      'expected_ramp_floor_scope': {
        'card_count': expectedRampFloorIds.length,
        'card_id_sha256': _digest(expectedRampFloorIds),
        'artifact': 'expected_ramp_floor_rows.json',
      },
      'nonland_removal_review': {
        'card_count': nonlandRemovalIds.length,
        'card_id_sha256': _digest(nonlandRemovalIds),
        'classification_counts': _countManifest(nonlandRemovalManifest),
        'artifact': 'nonland_removal_review.json',
        'heuristic_count': heuristicNonlandRemovals.length,
        'heuristic_card_id_sha256': _digest(heuristicNonlandRemovals),
        'heuristic_samples': _sampleNames(
          heuristicNonlandRemovals,
          allById,
          sampleLimit,
        ),
        'semantic_count': semanticNonlandRemovals.length,
        'semantic_card_id_sha256': _digest(semanticNonlandRemovals),
        'semantic_samples': _sampleNames(
          semanticNonlandRemovals,
          allById,
          sampleLimit,
        ),
        'package_action':
            'proposed after exact classifier, independent review and hash precheck',
      },
      'cross_lane_consistency': {
        'semantic_function_vs_json_diff_count':
            {
              ...currentSemanticFunction.difference(currentSemanticJson),
              ...currentSemanticJson.difference(currentSemanticFunction),
            }.length,
        'semantic_expected_function_vs_json_diff_count':
            {
              ...semanticFunctionToAdd.difference(semanticJsonToAdd),
              ...semanticJsonToAdd.difference(semanticFunctionToAdd),
              ...semanticFunctionToRemove.difference(semanticJsonToRemove),
              ...semanticJsonToRemove.difference(semanticFunctionToRemove),
            }.length,
      },
    };

    await _writeJson('${artifactDir.path}/summary.json', summary);
    await _writeJson(
      '${artifactDir.path}/confirmed_false_positive_land_rows.json',
      landManifest,
    );
    await _writeJson(
      '${artifactDir.path}/legitimate_nonland_drift.json',
      legitimateManifest,
    );
    await _writeJson(
      '${artifactDir.path}/expected_nonland_ramp_rows.json',
      expectedNonlandManifest,
    );
    await _writeJson(
      '${artifactDir.path}/ramp_drift_structural_rows.json',
      structuralRampAdditionManifest,
    );
    await _writeJson(
      '${artifactDir.path}/ramp_drift_contextual_rows.json',
      contextualRampAdditionManifest,
    );
    await _writeJson(
      '${artifactDir.path}/expected_ramp_floor_rows.json',
      expectedRampFloorManifest,
    );
    await _writeJson(
      '${artifactDir.path}/nonland_removal_review.json',
      nonlandRemovalManifest,
    );
    await _writeJson(
      '${artifactDir.path}/false_ramp_role_rows.json',
      falseRoleManifest,
    );
    print(const JsonEncoder.withIndent('  ').convert(summary));
  } finally {
    await database.close();
  }
}

bool _candidateHasRamp(_AuditCard card) => inferCandidateFunctionTags(
  name: card.name,
  typeLine: card.typeLine,
  oracleText: card.oracleText,
  manaCost: card.manaCost,
).any((tag) => tag.tag == _rampTag);

bool _candidateHasRampRole(_AuditCard card) =>
    !card.isLand &&
    inferCandidateFunctionTags(
      name: card.name,
      typeLine: card.typeLine,
      oracleText: card.oracleText,
      manaCost: card.manaCost,
    ).any((tag) => normalizeCandidateQualityRole(tag.tag) == _rampTag);

bool _semanticHasRamp(_AuditCard card) => inferSemanticCardAnalysisV2(
  name: card.name,
  typeLine: card.typeLine,
  oracleText: card.oracleText,
  manaCost: card.manaCost,
  cmc: card.cmc,
).tags.any((tag) => tag.tag == _rampTag);

OptimizationRampProfile _rampProfile(_AuditCard card) =>
    classifyOptimizationRampProfile(
      name: card.name,
      typeLine: card.typeLine,
      oracleText: card.oracleText,
      manaCost: card.manaCost,
      cmc: card.cmc,
    );

Map<String, dynamic> _laneSummary({
  required Set<String> expected,
  required Set<String> current,
  required Map<String, _AuditCard> cards,
  required int sampleLimit,
}) {
  final toAdd = expected.difference(current);
  final toRemove = current.difference(expected);
  return {
    'expected_count': expected.length,
    'expected_card_id_sha256': _digest(expected),
    'current_count': current.length,
    'current_card_id_sha256': _digest(current),
    'retained_count': expected.intersection(current).length,
    'to_add_count': toAdd.length,
    'to_add_card_id_sha256': _digest(toAdd),
    'to_add_samples': _sampleNames(toAdd, cards, sampleLimit),
    'to_remove_count': toRemove.length,
    'to_remove_card_id_sha256': _digest(toRemove),
    'to_remove_samples': _sampleNames(toRemove, cards, sampleLimit),
  };
}

String _landClassification(_AuditCard card) {
  final oracle = card.oracleText.toLowerCase();
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle)) {
    return 'fetch_or_land_search_land';
  }
  if (RegExp(r'add\s+\{[^}]+\}\{[^}]+\}').hasMatch(oracle) ||
      oracle.contains('add {') && oracle.contains('for each')) {
    return 'conditional_or_multi_mana_land';
  }
  if (oracle.contains('add ') || oracle.contains('mana of any')) {
    return 'ordinary_mana_land';
  }
  return 'utility_land';
}

String _nonlandRampClassification(_AuditCard card) {
  final oracle = card.oracleText.toLowerCase();
  final type = card.typeLine.toLowerCase();
  final tags =
      inferFunctionalCardTags(
        name: card.name,
        typeLine: card.typeLine,
        oracleText: card.oracleText,
        manaCost: card.manaCost,
        cmc: card.cmc,
      ).map((tag) => tag.tag).toSet();
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle)) {
    return 'land_search_spell';
  }
  if (tags.contains('ritual')) return 'ritual';
  if (oracle.contains('treasure token')) return 'treasure';
  if (oracle.contains('additional land') ||
      oracle.contains('land card from your hand onto the battlefield')) {
    return 'extra_land_effect';
  }
  if (oracle.contains('cost') && oracle.contains('less to cast')) {
    return 'cost_reduction';
  }
  if (type.contains('artifact') && oracle.contains('add ')) {
    return 'mana_rock';
  }
  if (type.contains('creature') && oracle.contains('add ')) {
    return 'mana_creature';
  }
  if (oracle.contains('untap') && oracle.contains('land')) {
    return 'land_untap';
  }
  return 'other_nonland_ramp';
}

String _nonlandRampRemovalClassification(_AuditCard card) {
  final oracle = card.oracleText.toLowerCase();
  final treasureSignal = classifyOptimizationTreasureRampText(card.oracleText);
  switch (treasureSignal) {
    case OptimizationTreasureRampSignal.opponentOnly:
      return 'opponent_only_treasure';
    case OptimizationTreasureRampSignal.objectControllerCompensation:
      return 'removed_object_controller_compensation';
    case OptimizationTreasureRampSignal.transformationOnly:
      return 'treasure_transformation_without_acceleration';
    case OptimizationTreasureRampSignal.replacementOrPreventionOnly:
      return 'treasure_replacement_or_prevention';
    case OptimizationTreasureRampSignal.unknownReview:
      return 'treasure_beneficiary_review_required';
    case OptimizationTreasureRampSignal.none:
    case OptimizationTreasureRampSignal.directSelf:
    case OptimizationTreasureRampSignal.sharedIncludesSelf:
    case OptimizationTreasureRampSignal.anyPlayerIncludesSelf:
    case OptimizationTreasureRampSignal.targetPlayerSelectable:
    case OptimizationTreasureRampSignal.controlledGrantedAbility:
      break;
  }
  if (oracle.contains('search your library') &&
      looksLikeOptimizationLandSearchText(oracle) &&
      !looksLikeOptimizationRampText(oracle)) {
    return 'land_search_without_battlefield_acceleration';
  }
  if (RegExp(
    r'\b(?:target|enchanted)\s+(?:land|permanent)\b[^.\n]{0,160}'
    r'\b(?:has|gains?)\b[^.\n]{0,96}\badd\b',
  ).hasMatch(oracle)) {
    return 'target_object_mana_grant_without_net_acceleration';
  }
  if (RegExp(
    r'\b(?:is|are|becomes?|become)\b[^.\n]{0,120}\b(?:land|mountains?)\b'
    r'[^.\n]{0,160}\badd\b',
  ).hasMatch(oracle)) {
    return 'mana_transformation_without_net_acceleration';
  }
  if (card.name == 'Ashling, Rekindled // Ashling, Rimebound') {
    return 'oracle_face_drift_no_mana_text';
  }
  if (oracle.contains('mana of any type can be spent')) {
    return 'payment_permission_any_type_can_be_spent';
  }
  if (oracle.contains('as though it were mana of any')) {
    return 'payment_permission_as_though_any';
  }
  if (RegExp(r'\b(?:may|can) spend mana of any type\b').hasMatch(oracle)) {
    return 'payment_permission_spend_any_type';
  }
  if (oracle.contains('color identity')) {
    return 'commander_color_identity_phrase_collision';
  }
  return 'other_review_required';
}

Map<String, int> _countManifest(List<Map<String, dynamic>> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    final key = row['classification']?.toString() ?? 'unknown';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

String _digest(Set<String> ids) => _digestStrings(ids);

String _digestStrings(Iterable<String> values) {
  final sorted = values.toSet().toList()..sort();
  return sha256.convert(utf8.encode(sorted.join('\n'))).toString();
}

List<String> _sampleNames(
  Set<String> ids,
  Map<String, _AuditCard> cards,
  int limit,
) {
  final names = ids.map((id) => cards[id]?.name ?? id).toList()..sort();
  return names.take(limit).toList(growable: false);
}

Future<List<_AuditCard>> _loadHeuristicOwnerCards(Pool pool) async {
  final rows = await pool.execute('''
SELECT DISTINCT ON (LOWER(c.name))
  c.id::text,
  c.name,
  COALESCE(c.oracle_text, ''),
  COALESCE(c.type_line, ''),
  c.mana_cost,
  c.cmc
FROM cards c
WHERE c.name IS NOT NULL
  AND c.name NOT LIKE 'A-%'
  AND c.name NOT LIKE '\\_%' ESCAPE '\\'
  AND c.name NOT LIKE '%World Champion%'
  AND c.name NOT LIKE '%Heroes of the Realm%'
ORDER BY LOWER(c.name), c.set_code ASC NULLS LAST, c.id ASC
''');
  return rows.map(_AuditCard.fromRow).toList(growable: false);
}

Future<List<_AuditCard>> _loadSemanticOwnerCards(Pool pool) async {
  final rows = await pool.execute('''
SELECT id::text, name, COALESCE(oracle_text, ''), COALESCE(type_line, ''),
       mana_cost, cmc
FROM cards
WHERE COALESCE(type_line, '') <> ''
  AND COALESCE(oracle_text, '') <> ''
ORDER BY name, id
''');
  return rows.map(_AuditCard.fromRow).toList(growable: false);
}

Future<List<_FunctionRow>> _loadFunctionRows(Pool pool) async {
  final rows = await pool.execute('''
SELECT card_id::text, source
FROM card_function_tags
WHERE tag='ramp'
  AND source IN ('deterministic_heuristic_v1','deterministic_semantic_v2')
''');
  return rows.map(_FunctionRow.fromRow).toList(growable: false);
}

Future<List<_RoleRow>> _loadRoleRows(Pool pool) async {
  final rows = await pool.execute('''
SELECT card_id::text, format, subformat, bracket_scope, budget_tier
FROM card_role_scores
WHERE source='deterministic_heuristic_v1' AND role='ramp'
''');
  return rows.map(_RoleRow.fromRow).toList(growable: false);
}

Future<List<_SemanticRow>> _loadSemanticRows(Pool pool) async {
  final rows = await pool.execute('''
SELECT card_id::text, tags @> '[{"tag":"ramp"}]'::jsonb
FROM card_semantic_tags_v2
WHERE source='deterministic_semantic_v2'
  AND schema_version='semantic_layer_v2_2026_05_18'
''');
  return rows.map(_SemanticRow.fromRow).toList(growable: false);
}

Future<void> _writeJson(String path, Object value) => File(
  path,
).writeAsString('${const JsonEncoder.withIndent('  ').convert(value)}\n');

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

int _readIntArg(List<String> args, String prefix, {required int fallback}) {
  final value = _readArg(args, prefix);
  final parsed = value == null ? null : int.tryParse(value);
  return parsed == null || parsed < 0 ? fallback : parsed;
}

class _AuditCard {
  const _AuditCard({
    required this.id,
    required this.name,
    required this.oracleText,
    required this.typeLine,
    required this.manaCost,
    required this.cmc,
  });

  final String id;
  final String name;
  final String oracleText;
  final String typeLine;
  final String? manaCost;
  final Object? cmc;

  bool get isLand => land_utils.isLandTypeLine(typeLine);

  factory _AuditCard.fromRow(ResultRow row) => _AuditCard(
    id: row[0].toString(),
    name: (row[1] as String?)?.trim() ?? '',
    oracleText: (row[2] as String?) ?? '',
    typeLine: (row[3] as String?)?.trim() ?? '',
    manaCost: (row[4] as String?)?.trim(),
    cmc: row[5],
  );
}

class _FunctionRow {
  const _FunctionRow({required this.cardId, required this.source});
  final String cardId;
  final String source;

  factory _FunctionRow.fromRow(ResultRow row) => _FunctionRow(
    cardId: row[0].toString(),
    source: (row[1] as String?) ?? '',
  );
}

class _RoleRow {
  const _RoleRow({
    required this.cardId,
    required this.format,
    required this.subformat,
    required this.bracketScope,
    required this.budgetTier,
  });

  final String cardId;
  final String format;
  final String subformat;
  final String bracketScope;
  final String budgetTier;

  String get key => '$cardId|$format|$subformat|$bracketScope|$budgetTier';

  factory _RoleRow.fromRow(ResultRow row) => _RoleRow(
    cardId: row[0].toString(),
    format: (row[1] as String?) ?? '',
    subformat: (row[2] as String?) ?? '',
    bracketScope: (row[3] as String?) ?? '',
    budgetTier: (row[4] as String?) ?? '',
  );
}

class _SemanticRow {
  const _SemanticRow({required this.cardId, required this.hasRamp});
  final String cardId;
  final bool hasRamp;

  factory _SemanticRow.fromRow(ResultRow row) => _SemanticRow(
    cardId: row[0].toString(),
    hasRamp: (row[1] as bool?) ?? false,
  );
}
