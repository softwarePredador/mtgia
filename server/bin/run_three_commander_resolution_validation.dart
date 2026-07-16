#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/ai/deck_state_analysis.dart';
import '../lib/database.dart';
import '../lib/runtime_environment.dart';

const _defaultApiBaseUrl = 'http://127.0.0.1:8080';
const _postgresWriteApprovalEnvironment = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const _deferCleanupToHarnessEnvironment = 'VALIDATION_DEFER_CLEANUP_TO_HARNESS';
const _explicitApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
late final String _artifactDirPath;
late final String _summaryJsonPath;
late final String _summaryMdPath;
late final int _validationLimit;
late final int _validationCorpusOffset;
late final String _selectionMode;
late final String? _corpusPath;
late final String _validationRunToken;
const _generatedDeckNameFilters = '''
        AND d.name NOT LIKE 'Optimization Validation - %'
        AND d.name NOT LIKE 'Resolution Validation - %'
        AND d.name NOT LIKE 'Rebuild Draft - %'
        AND d.name NOT LIKE 'Rebuild Preview - %'
''';

class SourceDeckCandidate {
  SourceDeckCandidate({
    required this.deckId,
    required this.deckName,
    required this.commanderName,
    required this.commanderCardId,
    required this.commanderColors,
    required this.sourceArchetype,
    required this.bracket,
    required this.cards,
    required this.sourceDeckStateStatus,
    required this.sourceSeverityScore,
    this.expectedFlowPaths = const [],
    this.expectedFlowContract,
    this.corpusLabel,
    this.corpusNote,
  });

  final String deckId;
  final String deckName;
  final String commanderName;
  final String commanderCardId;
  final List<String> commanderColors;
  final String? sourceArchetype;
  final int? bracket;
  final List<Map<String, dynamic>> cards;
  final String sourceDeckStateStatus;
  final int sourceSeverityScore;
  final List<String> expectedFlowPaths;
  final String? expectedFlowContract;
  final String? corpusLabel;
  final String? corpusNote;

  int get expectedCommanderCount {
    final count = cards
        .where((card) => card['is_commander'] == true)
        .fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));
    return count.clamp(1, 2);
  }

  SourceDeckCandidate withCorpusEntry(ValidationCorpusEntry entry) {
    return SourceDeckCandidate(
      deckId: deckId,
      deckName: deckName,
      commanderName: commanderName,
      commanderCardId: commanderCardId,
      commanderColors: commanderColors,
      sourceArchetype: sourceArchetype,
      bracket: bracket,
      cards: cards,
      sourceDeckStateStatus: sourceDeckStateStatus,
      sourceSeverityScore: sourceSeverityScore,
      expectedFlowPaths: entry.expectedFlowPaths,
      expectedFlowContract: entry.expectedFlowContract,
      corpusLabel: entry.label,
      corpusNote: entry.note,
    );
  }

  String get resolvedArchetype {
    final detected = _normalizeArchetype(sourceArchetype);
    if (detected != null) return detected;
    final analysis =
        DeckArchetypeAnalyzer(cards, commanderColors).generateAnalysis();
    final byAnalysis = _normalizeArchetype(
      analysis['detected_archetype']?.toString(),
    );
    return byAnalysis ?? 'midrange';
  }
}

class ValidationAuthSession {
  const ValidationAuthSession({required this.token});

  final String token;
}

class ValidationIdentity {
  const ValidationIdentity({
    required this.email,
    required this.username,
    required this.password,
  });

  final String email;
  final String username;
  final String password;
}

class ValidationCorpusEntry {
  ValidationCorpusEntry({
    required this.deckId,
    this.label,
    this.expectedFlowPaths = const [],
    this.expectedFlowContract,
    this.note,
  });

  final String deckId;
  final String? label;
  final List<String> expectedFlowPaths;
  final String? expectedFlowContract;
  final String? note;
}

class ProviderCallEvidence {
  const ProviderCallEvidence({
    required this.id,
    required this.endpoint,
    required this.model,
    required this.success,
    required this.inputTokens,
    required this.outputTokens,
    required this.latencyMs,
    required this.createdAt,
  });

  final String id;
  final String endpoint;
  final String model;
  final bool success;
  final int? inputTokens;
  final int? outputTokens;
  final int latencyMs;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': endpoint,
    'model': model,
    'success': success,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'latency_ms': latencyMs,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

String classifyResolutionRuntimeOrigin({
  required String? strategySource,
  required bool? cacheHit,
  required List<ProviderCallEvidence> providerCalls,
}) {
  if (cacheHit == true) return 'cache';
  final normalizedStrategy = strategySource?.trim().toLowerCase();
  if (normalizedStrategy == 'deterministic_first') return 'deterministic';
  if (normalizedStrategy == 'state_gate') return 'state_gate';

  final hasSuccessfulProviderCall = providerCalls.any((call) => call.success);
  if (const {
        'ai_primary',
        'ai_after_deterministic_fallback',
      }.contains(normalizedStrategy) &&
      !hasSuccessfulProviderCall) {
    return 'unknown';
  }
  return hasSuccessfulProviderCall ? 'provider' : 'unknown';
}

bool qualifiesAsSafeNoChangeOutcome({
  required int httpStatus,
  required String outcomeCode,
  required String qualityCode,
  required String deckStateStatus,
}) {
  const safeQualityCodes = {
    'OPTIMIZE_NO_SAFE_SWAPS',
    'OPTIMIZE_NO_ACTIONABLE_SWAPS',
    'OPTIMIZE_QUALITY_REJECTED',
    'OPTIMIZE_SEMANTIC_V2_REJECTED',
  };
  return httpStatus == HttpStatus.unprocessableEntity &&
      const {'near_peak', 'no_safe_upgrade_found'}.contains(outcomeCode) &&
      safeQualityCodes.contains(qualityCode) &&
      deckStateStatus == 'healthy';
}

class OptimizeOutcomeEvidence {
  const OptimizeOutcomeEvidence({
    required this.httpStatus,
    required this.outcomeCode,
    required this.isMock,
    required this.canApply,
    required this.learningEligible,
    required this.removalCount,
    required this.additionCount,
    required this.actionableRemovalCount,
    required this.actionableAdditionCount,
    required this.directApplyAccepted,
    required this.rejectionReasons,
  });

  final int httpStatus;
  final String? outcomeCode;
  final bool? isMock;
  final bool? canApply;
  final bool? learningEligible;
  final int removalCount;
  final int additionCount;
  final int actionableRemovalCount;
  final int actionableAdditionCount;
  final bool directApplyAccepted;
  final List<String> rejectionReasons;

  int get actionableSwapCount =>
      actionableRemovalCount < actionableAdditionCount
          ? actionableRemovalCount
          : actionableAdditionCount;

  int get candidateSwapCount =>
      removalCount < additionCount ? removalCount : additionCount;

  bool get responseFlagsWellTyped =>
      !rejectionReasons.any(
        (reason) => const {
          'is_mock_not_bool',
          'can_apply_not_bool',
          'learning_eligible_not_bool',
        }.contains(reason),
      );

  Map<String, dynamic> toJson() => {
    'http_status': httpStatus,
    'outcome_code': outcomeCode,
    'is_mock': isMock,
    'can_apply': canApply,
    'learning_eligible': learningEligible,
    'removal_count': removalCount,
    'addition_count': additionCount,
    'actionable_removal_count': actionableRemovalCount,
    'actionable_addition_count': actionableAdditionCount,
    'actionable_swap_count': actionableSwapCount,
    'candidate_swap_count': candidateSwapCount,
    'response_flags_well_typed': responseFlagsWellTyped,
    'direct_apply_accepted': directApplyAccepted,
    'rejection_reasons': rejectionReasons,
  };
}

OptimizeOutcomeEvidence assessOptimizeOutcomeEvidence({
  required int httpStatus,
  required Map<String, dynamic> responseBody,
}) {
  final outcomeCode = responseBody['outcome_code']?.toString().trim();
  final normalizedOutcomeCode = outcomeCode?.toLowerCase();
  final isMock = _optionalBool(responseBody['is_mock']);
  final canApply = _optionalBool(responseBody['can_apply']);
  final learningEligible = _optionalBool(responseBody['learning_eligible']);
  final removalNames = _parseRecommendationNames(responseBody['removals']);
  final additionNames = _parseRecommendationNames(responseBody['additions']);
  final removalDetails = _parseRecommendationDetails(
    responseBody['removals_detailed'],
  );
  final additionDetails = _parseRecommendationDetails(
    responseBody['additions_detailed'],
  );
  final removalCount = removalNames.names.length;
  final additionCount = additionNames.names.length;
  final actionableRemovalCount = removalDetails.details.length;
  final actionableAdditionCount = additionDetails.details.length;
  final rejectionReasons = <String>[];

  if (responseBody.containsKey('is_mock') && responseBody['is_mock'] is! bool) {
    rejectionReasons.add('is_mock_not_bool');
  }
  if (responseBody.containsKey('can_apply') &&
      responseBody['can_apply'] is! bool) {
    rejectionReasons.add('can_apply_not_bool');
  }
  if (responseBody.containsKey('learning_eligible') &&
      responseBody['learning_eligible'] is! bool) {
    rejectionReasons.add('learning_eligible_not_bool');
  }
  if (isMock == true) rejectionReasons.add('mock_response');

  if (httpStatus != HttpStatus.ok) {
    rejectionReasons.add('http_status_not_200');
  } else {
    if (normalizedOutcomeCode != 'optimized') {
      rejectionReasons.add('unexpected_success_outcome');
    }
    if (responseBody.containsKey('quality_error')) {
      rejectionReasons.add('quality_error_present');
    }
    if (canApply == false) rejectionReasons.add('can_apply_false');
    if (learningEligible == false) {
      rejectionReasons.add('learning_eligible_false');
    }
    if (normalizedOutcomeCode == 'mock_non_actionable') {
      rejectionReasons.add('mock_non_actionable_outcome');
    }
    if (!removalNames.valid || !additionNames.valid) {
      rejectionReasons.add('recommendation_names_malformed');
    }
    if (removalCount == 0 || additionCount == 0) {
      rejectionReasons.add('no_recommendation_pairs');
    } else if (removalCount != additionCount) {
      rejectionReasons.add('unbalanced_recommendation_pairs');
    }
    if (!removalDetails.valid ||
        !additionDetails.valid ||
        actionableRemovalCount != removalCount ||
        actionableAdditionCount != additionCount) {
      rejectionReasons.add('recommendation_details_not_actionable');
    }
    if (!_sameNameMultiset(removalNames.names, removalDetails.names)) {
      rejectionReasons.add('removal_raw_detail_name_mismatch');
    }
    if (!_sameNameMultiset(additionNames.names, additionDetails.names)) {
      rejectionReasons.add('addition_raw_detail_name_mismatch');
    }
    if (!_allUnique(removalNames.names) || !_allUnique(removalDetails.names)) {
      rejectionReasons.add('duplicate_removal_names');
    }
    if (!_allUnique(additionNames.names) ||
        !_allUnique(additionDetails.names)) {
      rejectionReasons.add('duplicate_addition_names');
    }
    if (!_allUnique(removalDetails.cardIds)) {
      rejectionReasons.add('duplicate_removal_card_ids');
    }
    if (!_allUnique(additionDetails.cardIds)) {
      rejectionReasons.add('duplicate_addition_card_ids');
    }
    if (removalDetails.names
        .toSet()
        .intersection(additionDetails.names.toSet())
        .isNotEmpty) {
      rejectionReasons.add('overlapping_recommendation_names');
    }
    if (removalDetails.cardIds
        .toSet()
        .intersection(additionDetails.cardIds.toSet())
        .isNotEmpty) {
      rejectionReasons.add('overlapping_recommendation_card_ids');
    }
  }

  return OptimizeOutcomeEvidence(
    httpStatus: httpStatus,
    outcomeCode:
        outcomeCode == null || outcomeCode.isEmpty ? null : outcomeCode,
    isMock: isMock,
    canApply: canApply,
    learningEligible: learningEligible,
    removalCount: removalCount,
    additionCount: additionCount,
    actionableRemovalCount: actionableRemovalCount,
    actionableAdditionCount: actionableAdditionCount,
    directApplyAccepted:
        httpStatus == HttpStatus.ok && rejectionReasons.isEmpty,
    rejectionReasons: List.unmodifiable(rejectionReasons),
  );
}

bool? _optionalBool(Object? value) => value is bool ? value : null;

class _ParsedRecommendationNames {
  const _ParsedRecommendationNames({required this.names, required this.valid});

  final List<String> names;
  final bool valid;
}

class _RecommendationDetail {
  const _RecommendationDetail({required this.name, required this.cardId});

  final String name;
  final String cardId;
}

class _ParsedRecommendationDetails {
  const _ParsedRecommendationDetails({
    required this.details,
    required this.valid,
  });

  final List<_RecommendationDetail> details;
  final bool valid;

  List<String> get names => details.map((detail) => detail.name).toList();
  List<String> get cardIds => details.map((detail) => detail.cardId).toList();
}

_ParsedRecommendationNames _parseRecommendationNames(Object? value) {
  if (value is! List) {
    return const _ParsedRecommendationNames(names: [], valid: false);
  }
  final names = <String>[];
  var valid = true;
  for (final entry in value) {
    if (entry is! String || entry.trim().isEmpty) {
      valid = false;
      continue;
    }
    names.add(_normalizeRecommendationToken(entry));
  }
  return _ParsedRecommendationNames(names: names, valid: valid);
}

_ParsedRecommendationDetails _parseRecommendationDetails(Object? value) {
  if (value is! List) {
    return const _ParsedRecommendationDetails(details: [], valid: false);
  }
  final details = <_RecommendationDetail>[];
  var valid = true;
  for (final entry in value) {
    if (entry is! Map) {
      valid = false;
      continue;
    }
    final detail = entry.cast<Object?, Object?>();
    final rawName = detail['name'];
    final rawCardId = detail['card_id'];
    final quantity = detail['quantity'];
    if (rawName is! String ||
        rawName.trim().isEmpty ||
        rawCardId is! String ||
        rawCardId.trim().isEmpty ||
        quantity is! int ||
        quantity != 1) {
      valid = false;
      continue;
    }
    details.add(
      _RecommendationDetail(
        name: _normalizeRecommendationToken(rawName),
        cardId: rawCardId.trim().toLowerCase(),
      ),
    );
  }
  return _ParsedRecommendationDetails(details: details, valid: valid);
}

String _normalizeRecommendationToken(String value) =>
    value.trim().toLowerCase();

bool _allUnique(List<String> values) => values.toSet().length == values.length;

bool _sameNameMultiset(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  final counts = <String, int>{};
  for (final value in left) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  for (final value in right) {
    final remaining = counts[value];
    if (remaining == null || remaining == 0) return false;
    if (remaining == 1) {
      counts.remove(value);
    } else {
      counts[value] = remaining - 1;
    }
  }
  return counts.isEmpty;
}

String buildResolutionDeckSignature(List<Map<String, dynamic>> cards) {
  final quantities = <String, int>{};
  for (final card in cards) {
    final cardId = card['card_id']?.toString().trim().toLowerCase() ?? '';
    final fallbackName =
        card['name']?.toString().trim().toLowerCase() ?? 'unknown';
    final identity = cardId.isEmpty ? 'name:$fallbackName' : 'id:$cardId';
    final commander = card['is_commander'] == true ? 'commander' : 'main';
    final quantity = card['quantity'] is int ? card['quantity'] as int : 0;
    final key = '$commander|$identity';
    quantities[key] = (quantities[key] ?? 0) + quantity;
  }
  final entries =
      quantities.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
  return entries.map((entry) => '${entry.key}|q:${entry.value}').join('\n');
}

class ResolutionRunResult {
  ResolutionRunResult({
    required this.commanderName,
    required this.sourceDeckId,
    required this.sourceDeckName,
    required this.cloneDeckId,
    required this.finalDeckId,
    required this.archetype,
    required this.bracket,
    required this.flowPath,
    required this.optimizeStatus,
    required this.optimizeOutcome,
    required this.optimizeProposalChangedDeck,
    required this.optimizePutStatus,
    required this.optimizePersistedDeckConfirmed,
    required this.strategySource,
    required this.cacheHit,
    required this.runtimeOrigin,
    required this.providerCalls,
    required this.rebuildStatus,
    required this.finalDeckValid,
    required this.finalDeckState,
    required this.finalAverageCmc,
    required this.finalLandCount,
    required this.finalInteraction,
    required this.savedArtifactPath,
    required this.expectedChecks,
    required this.failedChecks,
    required this.warnings,
  });

  final String commanderName;
  final String sourceDeckId;
  final String sourceDeckName;
  final String cloneDeckId;
  final String finalDeckId;
  final String archetype;
  final int bracket;
  final String flowPath;
  final int optimizeStatus;
  final OptimizeOutcomeEvidence optimizeOutcome;
  final bool? optimizeProposalChangedDeck;
  final int? optimizePutStatus;
  final bool? optimizePersistedDeckConfirmed;
  final String? strategySource;
  final bool? cacheHit;
  final String runtimeOrigin;
  final List<ProviderCallEvidence> providerCalls;
  final int? rebuildStatus;
  final bool finalDeckValid;
  final String finalDeckState;
  final double finalAverageCmc;
  final int finalLandCount;
  final int finalInteraction;
  final String savedArtifactPath;
  final List<String> expectedChecks;
  final List<String> failedChecks;
  final List<String> warnings;

  bool get passed => failedChecks.isEmpty;

  Map<String, dynamic> toJson() => {
    'commander_name': commanderName,
    'source_deck_id': sourceDeckId,
    'source_deck_name': sourceDeckName,
    'clone_deck_id': cloneDeckId,
    'final_deck_id': finalDeckId,
    'archetype': archetype,
    'bracket': bracket,
    'flow_path': flowPath,
    'optimize_status': optimizeStatus,
    'optimize_outcome': optimizeOutcome.toJson(),
    'optimize_application': {
      'proposal_changed_deck': optimizeProposalChangedDeck,
      'put_status': optimizePutStatus,
      'persisted_signature_confirmed': optimizePersistedDeckConfirmed,
    },
    'runtime_provenance': {
      'origin': runtimeOrigin,
      'strategy_source': strategySource,
      'cache_hit': cacheHit,
    },
    'provider_evidence': {
      'call_count': providerCalls.length,
      'successful_calls': providerCalls.where((call) => call.success).length,
      'calls': providerCalls.map((call) => call.toJson()).toList(),
    },
    'rebuild_status': rebuildStatus,
    'final_deck_valid': finalDeckValid,
    'final_deck_state': finalDeckState,
    'final_average_cmc': finalAverageCmc,
    'final_land_count': finalLandCount,
    'final_interaction': finalInteraction,
    'saved_artifact_path': savedArtifactPath,
    'expected_checks': expectedChecks,
    'failed_checks': failedChecks,
    'warnings': warnings,
    'passed': passed,
  };
}

Map<String, int> _providerModelCounts(List<ResolutionRunResult> results) {
  final counts = <String, int>{};
  for (final result in results) {
    for (final call in result.providerCalls) {
      counts[call.model] = (counts[call.model] ?? 0) + 1;
    }
  }
  return Map<String, int>.fromEntries(
    counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key)),
  );
}

Map<String, int> _runtimeOriginCounts(List<ResolutionRunResult> results) {
  final counts = <String, int>{};
  for (final result in results) {
    counts[result.runtimeOrigin] = (counts[result.runtimeOrigin] ?? 0) + 1;
  }
  return Map<String, int>.fromEntries(
    counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key)),
  );
}

Future<void> main() async {
  final env = loadRuntimeEnvironment();
  final apiBaseUrl = env['TEST_API_BASE_URL'] ?? _defaultApiBaseUrl;
  _artifactDirPath =
      env['VALIDATION_ARTIFACT_DIR'] ??
      'test/artifacts/optimization_resolution_three_decks';
  _summaryJsonPath =
      env['VALIDATION_SUMMARY_JSON_PATH'] ??
      'test/artifacts/optimization_resolution_three_decks/latest_summary.json';
  _summaryMdPath =
      env['VALIDATION_SUMMARY_MD_PATH'] ??
      '../RELATORIO_RESOLUCAO_3_DECKS_2026-03-17.md';
  _validationLimit = int.tryParse(env['VALIDATION_LIMIT'] ?? '') ?? 3;
  _validationCorpusOffset =
      int.tryParse(env['VALIDATION_CORPUS_OFFSET'] ?? '') ?? 0;
  if (_validationCorpusOffset < 0) {
    throw StateError('VALIDATION_CORPUS_OFFSET nao pode ser negativo.');
  }
  _selectionMode = (env['VALIDATION_SELECTION_MODE'] ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('-', '_');
  _corpusPath = _resolveCorpusPath(env['VALIDATION_CORPUS_PATH']);
  _validationRunToken = _resolveValidationRunToken(env['VALIDATION_RUN_TOKEN']);
  final preflightOnly = const {
    '1',
    'true',
    'yes',
  }.contains((env['VALIDATION_PREFLIGHT_ONLY'] ?? '').trim().toLowerCase());
  final deferCleanupToHarness = const {'1', 'true', 'yes'}.contains(
    (env[_deferCleanupToHarnessEnvironment] ?? '').trim().toLowerCase(),
  );

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    stderr.writeln('Falha ao conectar ao banco.');
    exitCode = 1;
    return;
  }

  final pool = db.connection;
  ValidationIdentity? cleanupIdentity;
  DateTime? cleanupRunStartedAt;
  var cleanupRequired = false;

  try {
    final corpusEntries =
        _corpusPath != null
            ? _loadCorpusEntries(_corpusPath!)
            : const <ValidationCorpusEntry>[];
    final usingCorpus = corpusEntries.isNotEmpty;
    final corpusDeckIds = corpusEntries.map((entry) => entry.deckId).toSet();
    final candidates = await _loadSourceCandidates(
      pool,
      deckIds: usingCorpus ? corpusDeckIds : const <String>{},
    );
    final selected =
        usingCorpus
            ? _selectCandidatesFromCorpus(
              candidates,
              corpusEntries: corpusEntries,
              limit: _validationLimit,
              offset: _validationCorpusOffset,
            )
            : _selectCandidates(
              candidates,
              limit: _validationLimit,
              selectionMode: _selectionMode,
            );

    if (selected.length < _validationLimit) {
      stderr.writeln(
        'Nao foi possivel selecionar ${_validationLimit} decks Commander validos e distintos. Encontrados: ${selected.length}',
      );
      exitCode = 1;
      return;
    }

    if (preflightOnly) {
      print(
        'Preflight read-only aprovado: ${selected.length} deck(s) Commander validos e distintos.',
      );
      return;
    }

    if (!_hasPostgresWriteApproval()) {
      stderr.writeln(
        'BLOCKED: o runner de resolucao mutavel exige aprovacao PostgreSQL explicita.',
      );
      exitCode = 2;
      return;
    }

    final serverOk = await _ensureServerIsReachable(
      apiBaseUrl,
      requireIsolatedRuntime: true,
    );
    if (!serverOk) {
      stderr.writeln(
        'BLOCKED: servidor local indisponivel ou sem isolamento E2E '
        'confirmado em $apiBaseUrl.',
      );
      exitCode = 2;
      return;
    }

    final artifactsDir = Directory(_artifactDirPath);
    if (!artifactsDir.existsSync()) {
      artifactsDir.createSync(recursive: true);
    }

    final validationIdentity = _resolveValidationIdentity();
    await _assertValidationIdentityIsUnused(pool, validationIdentity);
    cleanupIdentity = validationIdentity;
    cleanupRunStartedAt = DateTime.now().toUtc();
    cleanupRequired = true;
    final authSession = await _registerValidationUser(
      apiBaseUrl,
      validationIdentity,
    );
    final token = authSession.token;

    final results = <ResolutionRunResult>[];
    final runStartedAt = DateTime.now().toIso8601String();

    for (var index = 0; index < selected.length; index += 1) {
      final candidate = selected[index];
      print('');
      print(
        '=== ${candidate.commanderName} | ${candidate.resolvedArchetype} ===',
      );
      final result = await _runResolutionForDeck(
        apiBaseUrl: apiBaseUrl,
        token: token,
        pool: pool,
        candidate: candidate,
        runIndex: index + 1,
      );
      results.add(result);
      print(
        '${result.passed ? 'PASSOU' : 'FALHOU'} | '
        '${result.flowPath} | '
        'deck final ${result.finalDeckState} | '
        'lands=${result.finalLandCount} | '
        'interaction=${result.finalInteraction}',
      );
    }

    final summary = {
      'generated_at': DateTime.now().toIso8601String(),
      'run_started_at': runStartedAt,
      'api_base_url': apiBaseUrl,
      'artifact_dir': _artifactDirPath,
      'cleanup_owner': deferCleanupToHarness ? 'harness' : 'runner',
      'e2e_isolated_runtime': true,
      'selection_mode': usingCorpus ? 'corpus' : _selectionMode,
      if (usingCorpus) 'corpus_offset': _validationCorpusOffset,
      if (_corpusPath != null) 'corpus_path': _corpusPath,
      'total': results.length,
      'direct_optimizations':
          results.where((r) => r.flowPath == 'optimized_directly').length,
      'rebuild_resolutions':
          results.where((r) => r.flowPath == 'rebuild_guided').length,
      'safe_no_change':
          results.where((r) => r.flowPath == 'safe_no_change').length,
      'unresolved':
          results.where((r) => r.flowPath == 'unresolved_rejection').length,
      'optimize_outcome_summary': {
        'contract_accepted_http_200':
            results
                .where(
                  (r) =>
                      r.optimizeStatus == HttpStatus.ok &&
                      r.optimizeOutcome.directApplyAccepted,
                )
                .length,
        'contract_rejected_http_200':
            results
                .where(
                  (r) =>
                      r.optimizeStatus == HttpStatus.ok &&
                      !r.optimizeOutcome.directApplyAccepted,
                )
                .length,
        'mock_responses':
            results.where((r) => r.optimizeOutcome.isMock == true).length,
        'mock_non_actionable_outcomes':
            results
                .where(
                  (r) =>
                      r.optimizeOutcome.outcomeCode?.toLowerCase() ==
                      'mock_non_actionable',
                )
                .length,
        'candidate_swap_pairs': results.fold<int>(
          0,
          (sum, result) => sum + result.optimizeOutcome.candidateSwapCount,
        ),
        'rejected_candidate_swap_pairs': results.fold<int>(
          0,
          (sum, result) =>
              sum +
              (result.optimizeOutcome.directApplyAccepted
                  ? 0
                  : result.optimizeOutcome.candidateSwapCount),
        ),
        'actionable_swap_pairs': results.fold<int>(
          0,
          (sum, result) =>
              sum +
              (result.optimizeOutcome.directApplyAccepted
                  ? result.optimizeOutcome.actionableSwapCount
                  : 0),
        ),
        'proposal_changed_deck':
            results.where((r) => r.optimizeProposalChangedDeck == true).length,
        'put_succeeded':
            results.where((r) => r.optimizePutStatus == HttpStatus.ok).length,
        'persisted_signature_confirmed':
            results
                .where((r) => r.optimizePersistedDeckConfirmed == true)
                .length,
      },
      'provider_evidence_summary': {
        'results_with_calls':
            results.where((result) => result.providerCalls.isNotEmpty).length,
        'call_count': results.fold<int>(
          0,
          (sum, result) => sum + result.providerCalls.length,
        ),
        'successful_calls': results.fold<int>(
          0,
          (sum, result) =>
              sum + result.providerCalls.where((call) => call.success).length,
        ),
        'models': _providerModelCounts(results),
      },
      'runtime_provenance_summary': {
        'known_results':
            results.where((result) => result.runtimeOrigin != 'unknown').length,
        'unknown_results':
            results.where((result) => result.runtimeOrigin == 'unknown').length,
        'origins': _runtimeOriginCounts(results),
      },
      'passed': results.where((r) => r.passed).length,
      'failed': results.where((r) => !r.passed).length,
      'results': results.map((r) => r.toJson()).toList(),
    };

    await _writeTextArtifact(
      _summaryJsonPath,
      const JsonEncoder.withIndent('  ').convert(summary),
    );
    await _writeTextArtifact(_summaryMdPath, _buildMarkdownReport(summary));

    print('');
    print('Resumo salvo em $_summaryJsonPath');
    print('Relatorio salvo em $_summaryMdPath');

    if (results.any((r) => !r.passed) ||
        results.any((r) => r.flowPath == 'unresolved_rejection')) {
      exitCode = 1;
    }
  } finally {
    try {
      if (cleanupRequired && cleanupIdentity != null) {
        if (deferCleanupToHarness) {
          print(
            'Cleanup da sessao de validacao delegado ao harness transacional.',
          );
        } else {
          final startedAt = cleanupRunStartedAt;
          if (startedAt == null) {
            throw StateError(
              'Cleanup da validacao sem timestamp de ownership.',
            );
          }
          await _cleanupValidationUser(
            pool,
            cleanupIdentity,
            runStartedAt: startedAt,
            validationRunToken: _validationRunToken,
          );
        }
      }
    } finally {
      await db.close();
    }
  }
}

bool _hasPostgresWriteApproval() =>
    Platform.environment[_postgresWriteApprovalEnvironment] ==
    _explicitApprovalPhrase;

Future<ResolutionRunResult> _runResolutionForDeck({
  required String apiBaseUrl,
  required String token,
  required Pool pool,
  required SourceDeckCandidate candidate,
  required int runIndex,
}) async {
  final cloneDeckId = await _createDeckClone(
    apiBaseUrl: apiBaseUrl,
    token: token,
    candidate: candidate,
  );

  final optimizePayload = {
    'deck_id': cloneDeckId,
    'archetype': candidate.resolvedArchetype,
    'bracket': candidate.bracket ?? 2,
    'keep_theme': true,
  };

  final optimizeStartedAt = DateTime.now().toUtc();
  final optimizeResponse = await _optimizeWithPolling(
    apiBaseUrl: apiBaseUrl,
    token: token,
    payload: optimizePayload,
  );
  final providerCalls = await _loadProviderCallEvidence(
    pool,
    deckId: cloneDeckId,
    startedAt: optimizeStartedAt,
  );
  final optimizeBody = _decodeJson(optimizeResponse);
  final strategySource = optimizeBody['strategy_source']?.toString().trim();
  final cache =
      optimizeBody['cache'] is Map
          ? (optimizeBody['cache'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  final cacheHit = _optionalBool(cache['hit']);
  final runtimeOrigin = classifyResolutionRuntimeOrigin(
    strategySource:
        strategySource == null || strategySource.isEmpty
            ? null
            : strategySource,
    cacheHit: cacheHit,
    providerCalls: providerCalls,
  );
  final optimizeOutcome = assessOptimizeOutcomeEvidence(
    httpStatus: optimizeResponse.statusCode,
    responseBody: optimizeBody,
  );

  String flowPath = 'unresolved_rejection';
  int? rebuildStatus;
  String finalDeckId = cloneDeckId;
  Map<String, dynamic>? rebuildBody;
  bool? optimizeProposalChangedDeck;
  int? optimizePutStatus;
  bool? optimizePersistedDeckConfirmed;
  final warnings = <String>[];

  if (optimizeResponse.statusCode == HttpStatus.ok &&
      optimizeOutcome.directApplyAccepted) {
    final clonedCardsBefore = await _loadDeckCards(pool, cloneDeckId);
    final optimizedCards = await _applyRecommendations(
      pool: pool,
      originalCards: clonedCardsBefore,
      responseBody: optimizeBody,
    );
    final beforeSignature = buildResolutionDeckSignature(clonedCardsBefore);
    final proposedSignature = buildResolutionDeckSignature(optimizedCards);
    optimizeProposalChangedDeck = beforeSignature != proposedSignature;

    if (!optimizeProposalChangedDeck) {
      warnings.add(
        'Optimize 200 rejeitado: a aplicacao proposta nao alterou a assinatura do deck.',
      );
    } else {
      final putResponse = await http.put(
        Uri.parse('$apiBaseUrl/decks/$cloneDeckId'),
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'cards':
              optimizedCards
                  .map(
                    (card) => {
                      'card_id': card['card_id'],
                      'quantity': card['quantity'],
                      if (card['is_commander'] == true) 'is_commander': true,
                    },
                  )
                  .toList(),
        }),
      );
      optimizePutStatus = putResponse.statusCode;
      if (putResponse.statusCode != HttpStatus.ok) {
        warnings.add('Falha ao salvar optimize direto: ${putResponse.body}');
      } else {
        final persistedCards = await _loadDeckCards(pool, cloneDeckId);
        final persistedSignature = buildResolutionDeckSignature(persistedCards);
        optimizePersistedDeckConfirmed =
            persistedSignature != beforeSignature &&
            persistedSignature == proposedSignature;
        if (!optimizePersistedDeckConfirmed) {
          warnings.add(
            'Optimize 200 rejeitado: a assinatura persistida nao confirma a proposta aplicada.',
          );
        } else {
          flowPath = 'optimized_directly';
        }
      }
    }
  } else if (optimizeResponse.statusCode == HttpStatus.ok) {
    warnings.add(
      'Optimize 200 rejeitado pelo contrato de resolucao: '
      '${optimizeOutcome.rejectionReasons.join(', ')}.',
    );
  } else {
    final qualityError =
        optimizeBody['quality_error'] is Map
            ? (optimizeBody['quality_error'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final qualityCode = qualityError['code']?.toString() ?? '';
    final outcomeCode = optimizeBody['outcome_code']?.toString() ?? '';
    final deckState =
        optimizeBody['deck_state'] is Map
            ? (optimizeBody['deck_state'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final nextAction =
        optimizeBody['next_action'] is Map
            ? (optimizeBody['next_action'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final nextPayload =
        nextAction['payload'] is Map
            ? (nextAction['payload'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};

    if (qualifiesAsSafeNoChangeOutcome(
      httpStatus: optimizeResponse.statusCode,
      outcomeCode: outcomeCode,
      qualityCode: qualityCode,
      deckStateStatus: deckState['status']?.toString() ?? '',
    )) {
      flowPath = 'safe_no_change';
      warnings.add(
        'Nenhuma troca segura encontrada; deck original preservado em estado saudável.',
      );
    } else if (optimizeResponse.statusCode == 422 &&
        qualityCode == 'OPTIMIZE_NEEDS_REPAIR' &&
        nextAction['type']?.toString() == 'rebuild_guided') {
      final rebuildPayload = {
        'deck_id': nextPayload['deck_id']?.toString() ?? cloneDeckId,
        'archetype':
            nextPayload['archetype']?.toString() ?? candidate.resolvedArchetype,
        'bracket': nextPayload['bracket'] ?? candidate.bracket ?? 2,
        'theme': nextPayload['theme']?.toString(),
        'rebuild_scope': nextPayload['rebuild_scope']?.toString() ?? 'auto',
        'save_mode': nextPayload['save_mode']?.toString() ?? 'draft_clone',
      };

      final rebuildResponse = await http.post(
        Uri.parse('$apiBaseUrl/ai/rebuild'),
        headers: _jsonHeaders(token),
        body: jsonEncode(rebuildPayload),
      );
      rebuildStatus = rebuildResponse.statusCode;
      rebuildBody = _decodeJson(rebuildResponse);

      if (rebuildResponse.statusCode == 200) {
        flowPath = 'rebuild_guided';
        finalDeckId = rebuildBody['draft_deck_id']?.toString() ?? '';
        if (finalDeckId.isEmpty) {
          warnings.add('Rebuild retornou 200 sem draft_deck_id.');
          flowPath = 'unresolved_rejection';
          finalDeckId = cloneDeckId;
        }
      } else {
        warnings.add(
          'Falha ao executar rebuild_guided: ${_extractMessage(rebuildBody)}',
        );
      }
    } else {
      warnings.add(
        'Rejeicao nao resolvida automaticamente: ${_extractMessage(optimizeBody)}',
      );
    }
  }

  final finalCards = await _loadDeckCards(pool, finalDeckId);
  final finalValidate =
      finalDeckId.isNotEmpty
          ? await http.post(
            Uri.parse('$apiBaseUrl/decks/$finalDeckId/validate'),
            headers: _authHeaders(token),
          )
          : http.Response('{"error":"final deck ausente"}', 500);

  final finalAnalysis =
      DeckArchetypeAnalyzer(
        finalCards,
        candidate.commanderColors,
      ).generateAnalysis();
  final finalState = assessDeckOptimizationState(
    cards: finalCards,
    deckAnalysis: finalAnalysis,
    deckFormat: 'commander',
    currentTotalCards: _totalCards(finalCards),
    commanderColorIdentity: candidate.commanderColors.toSet(),
  );

  final artifactPath = await _writeDeckArtifact(
    commanderName: candidate.commanderName,
    sourceDeckId: candidate.deckId,
    runIndex: runIndex,
    payload: {
      'source_deck_id': candidate.deckId,
      'source_deck_name': candidate.deckName,
      'clone_deck_id': cloneDeckId,
      'final_deck_id': finalDeckId,
      'optimize_request': optimizePayload,
      'optimize_status': optimizeResponse.statusCode,
      'optimize_outcome': optimizeOutcome.toJson(),
      'optimize_application': {
        'proposal_changed_deck': optimizeProposalChangedDeck,
        'put_status': optimizePutStatus,
        'persisted_signature_confirmed': optimizePersistedDeckConfirmed,
      },
      'provider_evidence': {
        'query_scope':
            'ai_logs deck_id + endpoint provider:optimize + run window',
        'call_count': providerCalls.length,
        'successful_calls': providerCalls.where((call) => call.success).length,
        'calls': providerCalls.map((call) => call.toJson()).toList(),
      },
      'runtime_provenance': {
        'origin': runtimeOrigin,
        'strategy_source': strategySource,
        'cache_hit': cacheHit,
      },
      'optimize_response': optimizeBody,
      if (rebuildBody != null) 'rebuild_status': rebuildStatus,
      if (rebuildBody != null) 'rebuild_response': rebuildBody,
      'final_validate_status': finalValidate.statusCode,
      'final_validate_response': _decodeJson(finalValidate),
      'final_analysis': finalAnalysis,
      'final_state': finalState.toJson(),
    },
  );

  final expectedChecks = <String>[];
  final failedChecks = <String>[];

  void expectCheck(String description, bool passed) {
    expectedChecks.add(description);
    if (!passed) failedChecks.add(description);
  }

  final finalCardCount = _totalCards(finalCards);
  final commanderCount = finalCards
      .where((card) => card['is_commander'] == true)
      .fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));
  final expectedCommanderCount = candidate.expectedCommanderCount;
  final finalLandCount = _landCount(finalAnalysis);
  final finalInteraction = _countInteraction(finalAnalysis);

  expectCheck('deck final existe', finalDeckId.isNotEmpty);
  expectCheck('deck final mantem 100 cartas', finalCardCount == 100);
  expectCheck(
    'deck final mantem exatamente $expectedCommanderCount comandante${expectedCommanderCount == 1 ? '' : 's'} ${expectedCommanderCount == 1 ? 'legal' : 'legais'}',
    commanderCount == expectedCommanderCount,
  );
  expectCheck(
    'POST /decks/:id/validate aprovou o deck final',
    finalValidate.statusCode == 200,
  );
  expectCheck(
    'deck final terminou em estado healthy',
    finalState.status == 'healthy',
  );
  expectCheck(
    'deck final manteve land count saudável',
    finalLandCount >= 34 && finalLandCount <= 40,
  );

  if (optimizeResponse.statusCode == HttpStatus.ok) {
    expectCheck(
      'optimize 200 retornou pares acionaveis e nao-mock',
      optimizeOutcome.directApplyAccepted,
    );
    if (optimizeOutcome.directApplyAccepted) {
      expectCheck(
        'optimize direto alterou a assinatura do deck antes do PUT',
        optimizeProposalChangedDeck == true,
      );
      if (optimizeProposalChangedDeck == true) {
        expectCheck(
          'optimize direto persistiu a proposta alterada',
          optimizePutStatus == HttpStatus.ok,
        );
        if (optimizePutStatus == HttpStatus.ok) {
          expectCheck(
            'assinatura persistida difere da original e confirma a proposta',
            optimizePersistedDeckConfirmed == true,
          );
        }
      }
    }
  }

  if (flowPath == 'rebuild_guided') {
    final rebuildValidation =
        rebuildBody?['validation'] is Map
            ? (rebuildBody!['validation'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
    final deckStateAfter =
        rebuildValidation['deck_state_after'] is Map
            ? (rebuildValidation['deck_state_after'] as Map)
                .cast<String, dynamic>()
            : const <String, dynamic>{};

    expectCheck('rebuild_guided retornou 200', rebuildStatus == 200);
    expectCheck(
      'rebuild_guided marcou strict_rules_valid',
      rebuildValidation['strict_rules_valid'] == true,
    );
    expectCheck(
      'rebuild_guided retornou deck_state_after healthy',
      deckStateAfter['status']?.toString() == 'healthy',
    );
  }

  if (candidate.expectedFlowPaths.isNotEmpty) {
    expectCheck(
      'flow_path segue expectativa do corpus (${candidate.expectedFlowPaths.join(' / ')})',
      candidate.expectedFlowPaths.contains(flowPath),
    );
  }
  if (candidate.expectedFlowContract == 'runtime_terminal_non_mock') {
    expectCheck(
      'flow terminou em contrato runtime terminal nao-mock',
      const {
            'optimized_directly',
            'safe_no_change',
            'rebuild_guided',
          }.contains(flowPath) &&
          optimizeOutcome.isMock != true &&
          optimizeOutcome.responseFlagsWellTyped &&
          optimizeOutcome.outcomeCode?.toLowerCase() != 'mock_non_actionable' &&
          runtimeOrigin != 'unknown',
    );
  }

  return ResolutionRunResult(
    commanderName: candidate.commanderName,
    sourceDeckId: candidate.deckId,
    sourceDeckName: candidate.deckName,
    cloneDeckId: cloneDeckId,
    finalDeckId: finalDeckId,
    archetype: candidate.resolvedArchetype,
    bracket: candidate.bracket ?? 2,
    flowPath: flowPath,
    optimizeStatus: optimizeResponse.statusCode,
    optimizeOutcome: optimizeOutcome,
    optimizeProposalChangedDeck: optimizeProposalChangedDeck,
    optimizePutStatus: optimizePutStatus,
    optimizePersistedDeckConfirmed: optimizePersistedDeckConfirmed,
    strategySource:
        strategySource == null || strategySource.isEmpty
            ? null
            : strategySource,
    cacheHit: cacheHit,
    runtimeOrigin: runtimeOrigin,
    providerCalls: providerCalls,
    rebuildStatus: rebuildStatus,
    finalDeckValid: finalValidate.statusCode == 200,
    finalDeckState: finalState.status,
    finalAverageCmc: _parseDouble(finalAnalysis['average_cmc']),
    finalLandCount: finalLandCount,
    finalInteraction: finalInteraction,
    savedArtifactPath: artifactPath,
    expectedChecks: expectedChecks,
    failedChecks: failedChecks,
    warnings: warnings,
  );
}

Future<bool> _ensureServerIsReachable(
  String apiBaseUrl, {
  bool requireIsolatedRuntime = false,
}) async {
  final baseUri = Uri.tryParse(apiBaseUrl);
  if (baseUri == null ||
      baseUri.scheme != 'http' ||
      !const {'127.0.0.1', 'localhost', '::1'}.contains(baseUri.host)) {
    return false;
  }

  try {
    final response = await http
        .get(
          Uri.parse(
            '${apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/health/ready',
          ),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != HttpStatus.ok) return false;
    final payload = jsonDecode(response.body);
    return payload is Map &&
        payload['status'] == 'ready' &&
        payload['service'] == 'mtgia-server' &&
        (!requireIsolatedRuntime || payload['e2e_isolated_runtime'] == true);
  } catch (_) {
    return false;
  }
}

ValidationIdentity _resolveValidationIdentity() {
  final runSuffix =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${pid}';
  final email =
      Platform.environment['VALIDATION_USER_EMAIL'] ??
      'optimization.validation.bot.$runSuffix@example.invalid';
  final password =
      Platform.environment['VALIDATION_USER_PASSWORD'] ??
      'OptimizationPass123!$runSuffix';
  final username =
      Platform.environment['VALIDATION_USERNAME'] ??
      'optimization_validation_bot_$runSuffix';

  final normalizedEmail = email.trim().toLowerCase();
  final normalizedUsername = username.trim().toLowerCase();
  final safeEmail = RegExp(
    r'^optimization\.validation\.bot\.[a-z0-9_-]+@example\.invalid$',
  );
  final safeUsername = RegExp(r'^optimization_validation_bot_[a-z0-9_-]+$');
  if (!safeEmail.hasMatch(normalizedEmail) ||
      !safeUsername.hasMatch(normalizedUsername)) {
    throw StateError(
      'A identidade mutavel deve usar os prefixos descartaveis de validacao.',
    );
  }

  return ValidationIdentity(
    email: normalizedEmail,
    username: normalizedUsername,
    password: password,
  );
}

Future<void> _assertValidationIdentityIsUnused(
  Pool pool,
  ValidationIdentity identity,
) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT COUNT(*)::int
      FROM users
      WHERE LOWER(email) = @email OR LOWER(username) = @username
    '''),
    parameters: {'email': identity.email, 'username': identity.username},
  );
  final count = result.first[0] as int? ?? 0;
  if (count != 0) {
    throw StateError('Identidade de validacao ja existe; use um novo token.');
  }
}

Future<ValidationAuthSession> _registerValidationUser(
  String apiBaseUrl,
  ValidationIdentity identity,
) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': identity.email,
      'password': identity.password,
      'username': identity.username,
    }),
  );

  if (response.statusCode != HttpStatus.created) {
    throw Exception('Falha ao registrar usuario de teste: ${response.body}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final token = decoded['token']?.toString();
  if (token == null || token.isEmpty) {
    throw Exception('Token ausente no registro.');
  }
  return ValidationAuthSession(token: token);
}

Future<void> _cleanupValidationUser(
  Pool pool,
  ValidationIdentity identity, {
  required DateTime runStartedAt,
  required String validationRunToken,
}) async {
  final deleted = await pool.runTx((session) async {
    await session.execute(
      Sql.named('''
        CREATE TEMP TABLE manaloom_runner_validation_user_ids
        ON COMMIT DROP AS
        SELECT id
        FROM users
        WHERE LOWER(email) = LOWER(@email)
          AND LOWER(username) = LOWER(@username)
      '''),
      parameters: {'email': identity.email, 'username': identity.username},
    );
    await session.execute('''
      CREATE TEMP TABLE manaloom_runner_validation_deck_ids
      ON COMMIT DROP AS
      SELECT id
      FROM decks
      WHERE user_id IN (
        SELECT id FROM manaloom_runner_validation_user_ids
      )
    ''');

    final counts = <String, int>{};
    counts['ai_logs'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM ai_logs
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['ai_optimize_cache'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM ai_optimize_cache
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['ai_optimize_fallback_telemetry'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM ai_optimize_fallback_telemetry
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['ml_prompt_feedback'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM ml_prompt_feedback
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['optimization_analysis_logs'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM optimization_analysis_logs
            WHERE created_at >= @run_started_at
              AND (
                decisions_reasoning->>'validation_run_token' = @run_token
                OR decisions_reasoning->>'deck_id' IN (
                  SELECT id::text
                  FROM manaloom_runner_validation_deck_ids
                )
                OR decisions_reasoning->>'user_id' IN (
                  SELECT id::text
                  FROM manaloom_runner_validation_user_ids
                )
              )
          '''),
          parameters: {
            'run_started_at': runStartedAt,
            'run_token': validationRunToken,
          },
        )).affectedRows;
    counts['rate_limit_events'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM rate_limit_events
            WHERE created_at >= @run_started_at
              AND identifier IN (
                SELECT id::text FROM manaloom_runner_validation_user_ids
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['deck_learning_events'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM deck_learning_events
            WHERE created_at >= @run_started_at
              AND deck_id IN (
                SELECT id FROM manaloom_runner_validation_deck_ids
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;
    counts['ai_optimize_jobs'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM ai_optimize_jobs
            WHERE created_at >= @run_started_at
              AND deck_id IN (
                SELECT id FROM manaloom_runner_validation_deck_ids
              )
          '''),
          parameters: {'run_started_at': runStartedAt},
        )).affectedRows;

    final telemetryRemaining = await session.execute(
      Sql.named('''
        SELECT
          (
            SELECT COUNT(*)::int
            FROM ai_logs
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM ai_optimize_cache
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM ai_optimize_fallback_telemetry
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM ml_prompt_feedback
            WHERE created_at >= @run_started_at
              AND (
                user_id IN (
                  SELECT id FROM manaloom_runner_validation_user_ids
                )
                OR deck_id IN (
                  SELECT id FROM manaloom_runner_validation_deck_ids
                )
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM optimization_analysis_logs
            WHERE created_at >= @run_started_at
              AND (
                decisions_reasoning->>'validation_run_token' = @run_token
                OR decisions_reasoning->>'deck_id' IN (
                  SELECT id::text
                  FROM manaloom_runner_validation_deck_ids
                )
                OR decisions_reasoning->>'user_id' IN (
                  SELECT id::text
                  FROM manaloom_runner_validation_user_ids
                )
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM rate_limit_events
            WHERE created_at >= @run_started_at
              AND identifier IN (
                SELECT id::text FROM manaloom_runner_validation_user_ids
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM deck_learning_events
            WHERE created_at >= @run_started_at
              AND deck_id IN (
                SELECT id FROM manaloom_runner_validation_deck_ids
              )
          ),
          (
            SELECT COUNT(*)::int
            FROM ai_optimize_jobs
            WHERE created_at >= @run_started_at
              AND deck_id IN (
                SELECT id FROM manaloom_runner_validation_deck_ids
              )
          )
      '''),
      parameters: {
        'run_started_at': runStartedAt,
        'run_token': validationRunToken,
      },
    );
    final telemetryRow = telemetryRemaining.single;
    final remainingCounts = <int>[
      for (var index = 0; index < 8; index += 1)
        (telemetryRow[index] as int?) ?? 0,
    ];
    if (remainingCounts.any((count) => count != 0)) {
      throw StateError(
        'Cleanup transacional deixou telemetria de validacao: '
        '$remainingCounts',
      );
    }

    counts['users'] =
        (await session.execute(
          Sql.named('''
            DELETE FROM users
            WHERE LOWER(email) = LOWER(@email)
              AND LOWER(username) = LOWER(@username)
          '''),
          parameters: {'email': identity.email, 'username': identity.username},
        )).affectedRows;

    final identityRemaining = await session.execute('''
      SELECT
        (
          SELECT COUNT(*)::int
          FROM users
          WHERE id IN (SELECT id FROM manaloom_runner_validation_user_ids)
        ),
        (
          SELECT COUNT(*)::int
          FROM decks
          WHERE id IN (SELECT id FROM manaloom_runner_validation_deck_ids)
        )
    ''');
    final identityRow = identityRemaining.single;
    final identityCounts = <int>[
      (identityRow[0] as int?) ?? 0,
      (identityRow[1] as int?) ?? 0,
    ];
    if (identityCounts.any((count) => count != 0)) {
      throw StateError(
        'Cleanup transacional deixou identidade/decks de validacao: '
        '$identityCounts',
      );
    }
    return counts;
  });
  print('Cleanup transacional da validacao: ${jsonEncode(deleted)}.');
}

Future<List<SourceDeckCandidate>> _loadSourceCandidates(
  Pool pool, {
  Set<String> deckIds = const <String>{},
}) async {
  final corpusFilterSql =
      deckIds.isNotEmpty
          ? '        AND d.id::text = ANY(@deckIds::text[])\n'
          : '';
  final limitSql = deckIds.isNotEmpty ? '' : '      LIMIT 120\n';
  final decksResult = await pool.execute(
    Sql.named('''
      SELECT
        d.id::text,
        d.name,
        NULLIF(TRIM(d.archetype), '') AS archetype,
        d.bracket::int,
        c.id::text AS commander_card_id,
        c.name AS commander_name,
        COALESCE(c.colors, ARRAY[]::text[]) AS commander_colors
      FROM decks d
      JOIN (
        SELECT deck_id, SUM(quantity)::int AS total_cards
        FROM deck_cards
        GROUP BY deck_id
      ) stats ON stats.deck_id = d.id
      JOIN LATERAL (
        SELECT dc.card_id
        FROM deck_cards dc
        WHERE dc.deck_id = d.id AND dc.is_commander = TRUE
        ORDER BY dc.card_id
        LIMIT 1
      ) cmd ON TRUE
      JOIN cards c ON c.id = cmd.card_id
      WHERE d.deleted_at IS NULL
        AND LOWER(d.format) = 'commander'
        AND stats.total_cards = 100
${corpusFilterSql}$_generatedDeckNameFilters
      ORDER BY d.created_at DESC NULLS LAST
${limitSql}
    '''),
    parameters: {if (deckIds.isNotEmpty) 'deckIds': deckIds.toList()},
  );

  final candidates = <SourceDeckCandidate>[];

  for (final row in decksResult) {
    final deckId = row[0] as String;
    final deckName = row[1] as String? ?? 'Commander Deck';
    final archetype = row[2] as String?;
    final bracket = row[3] as int?;
    final commanderCardId = row[4] as String;
    final commanderName = row[5] as String;
    final commanderColors =
        (row[6] as List?)?.cast<String>() ?? const <String>[];

    final cards = await _loadDeckCards(pool, deckId);
    if (cards.isEmpty) continue;

    final total = _totalCards(cards);
    final hasCommander = cards.any((card) => card['is_commander'] == true);
    if (total != 100 || !hasCommander) continue;
    final deckAnalysis =
        DeckArchetypeAnalyzer(cards, commanderColors).generateAnalysis();
    final deckState = assessDeckOptimizationState(
      cards: cards,
      deckAnalysis: deckAnalysis,
      deckFormat: 'commander',
      currentTotalCards: total,
      commanderColorIdentity: commanderColors.toSet(),
    );

    candidates.add(
      SourceDeckCandidate(
        deckId: deckId,
        deckName: deckName,
        commanderName: commanderName,
        commanderCardId: commanderCardId,
        commanderColors: commanderColors,
        sourceArchetype: archetype,
        bracket: bracket,
        cards: cards,
        sourceDeckStateStatus: deckState.status,
        sourceSeverityScore: deckState.severityScore,
      ),
    );
  }

  return candidates;
}

Future<List<Map<String, dynamic>>> _loadDeckCards(
  Pool pool,
  String deckId,
) async {
  if (deckId.isEmpty) return const <Map<String, dynamic>>[];
  final result = await pool.execute(
    Sql.named('''
      SELECT
        dc.card_id::text,
        dc.quantity::int,
        dc.is_commander,
        c.name,
        c.type_line,
        COALESCE(c.mana_cost, '') AS mana_cost,
        COALESCE(c.colors, ARRAY[]::text[]) AS colors,
        COALESCE(
          (
            SELECT SUM(
              CASE
                WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                WHEN m[1] = 'X' THEN 0
                ELSE 1
              END
            )
            FROM regexp_matches(COALESCE(c.mana_cost, ''), '\\{([^}]+)\\}', 'g') AS m(m)
          ),
          0
        )::double precision AS cmc,
        COALESCE(c.oracle_text, '') AS oracle_text
      FROM deck_cards dc
      JOIN cards c ON c.id = dc.card_id
      WHERE dc.deck_id = @deckId
      ORDER BY dc.is_commander DESC, c.name ASC
    '''),
    parameters: {'deckId': deckId},
  );

  return result
      .map(
        (row) => <String, dynamic>{
          'card_id': row[0] as String,
          'quantity': row[1] as int,
          'is_commander': row[2] as bool? ?? false,
          'name': row[3] as String? ?? '',
          'type_line': row[4] as String? ?? '',
          'mana_cost': row[5] as String? ?? '',
          'colors': (row[6] as List?)?.cast<String>() ?? const <String>[],
          'cmc': (row[7] as num?)?.toDouble() ?? 0.0,
          'oracle_text': row[8] as String? ?? '',
        },
      )
      .toList();
}

Future<List<ProviderCallEvidence>> _loadProviderCallEvidence(
  Pool pool, {
  required String deckId,
  required DateTime startedAt,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        id::text,
        endpoint,
        model,
        success,
        input_tokens,
        output_tokens,
        latency_ms,
        created_at
      FROM ai_logs
      WHERE deck_id = @deckId::uuid
        AND endpoint = 'provider:optimize'
        AND created_at >= @startedAt
      ORDER BY created_at ASC, id ASC
    '''),
    parameters: {
      'deckId': deckId,
      'startedAt': startedAt.subtract(const Duration(seconds: 1)),
    },
  );

  return result
      .map(
        (row) => ProviderCallEvidence(
          id: row[0] as String,
          endpoint: row[1] as String,
          model: row[2] as String,
          success: row[3] as bool,
          inputTokens: row[4] as int?,
          outputTokens: row[5] as int?,
          latencyMs: row[6] as int,
          createdAt: row[7] as DateTime,
        ),
      )
      .toList();
}

String? _resolveCorpusPath(String? raw) {
  final normalized = raw?.trim() ?? '';
  if (normalized.isEmpty) return null;
  return normalized;
}

String _resolveValidationRunToken(String? raw) {
  final fallback =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${pid}';
  final token = (raw?.trim().isNotEmpty ?? false) ? raw!.trim() : fallback;
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(token)) {
    throw StateError(
      'VALIDATION_RUN_TOKEN deve conter apenas letras, numeros, _ ou -.',
    );
  }
  return token;
}

List<ValidationCorpusEntry> _loadCorpusEntries(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Corpus de validacao nao encontrado em $path');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final rawEntries = switch (decoded) {
    {'decks': final List decks} => decks,
    final List decks => decks,
    _ =>
      throw StateError(
        'Corpus invalido em $path: esperado lista ou objeto com "decks".',
      ),
  };

  final entries = <ValidationCorpusEntry>[];
  for (final rawEntry in rawEntries) {
    if (rawEntry is! Map) continue;
    final entry = rawEntry.cast<dynamic, dynamic>();
    final deckId = entry['deck_id']?.toString().trim() ?? '';
    if (deckId.isEmpty) continue;
    final expectedFlowPaths = _parseExpectedFlowPaths(entry);
    final expectedFlowContract =
        entry['expected_flow_contract']?.toString().trim().toLowerCase() ?? '';
    if (expectedFlowContract.isNotEmpty &&
        expectedFlowContract != 'runtime_terminal_non_mock') {
      throw StateError(
        'Contrato de flow desconhecido para $deckId: $expectedFlowContract',
      );
    }
    if (expectedFlowPaths.isEmpty && expectedFlowContract.isEmpty) {
      throw StateError(
        'Entrada $deckId sem expected_flow_paths nem expected_flow_contract.',
      );
    }
    if (expectedFlowPaths.isNotEmpty && expectedFlowContract.isNotEmpty) {
      throw StateError(
        'Entrada $deckId mistura expectativa exata e contrato terminal.',
      );
    }
    entries.add(
      ValidationCorpusEntry(
        deckId: deckId,
        label: entry['label']?.toString(),
        expectedFlowPaths: expectedFlowPaths,
        expectedFlowContract:
            expectedFlowContract.isEmpty ? null : expectedFlowContract,
        note: entry['note']?.toString(),
      ),
    );
  }

  return entries;
}

List<SourceDeckCandidate> _selectCandidatesFromCorpus(
  List<SourceDeckCandidate> candidates, {
  required List<ValidationCorpusEntry> corpusEntries,
  required int limit,
  required int offset,
}) {
  if (offset + limit > corpusEntries.length) {
    throw StateError(
      'VALIDATION_CORPUS_OFFSET=$offset + VALIDATION_LIMIT=$limit excede o corpus configurado (${corpusEntries.length} entradas).',
    );
  }

  final byId = <String, SourceDeckCandidate>{
    for (final candidate in candidates) candidate.deckId: candidate,
  };
  final selected = <SourceDeckCandidate>[];
  final missing = <String>[];

  for (final entry in corpusEntries.skip(offset).take(limit)) {
    final candidate = byId[entry.deckId];
    if (candidate == null) {
      missing.add(entry.deckId);
      continue;
    }
    selected.add(candidate.withCorpusEntry(entry));
  }

  if (missing.isNotEmpty) {
    throw StateError(
      'Corpus referencia decks inexistentes ou invalidos: ${missing.join(', ')}',
    );
  }

  return selected;
}

List<String> _parseExpectedFlowPaths(Map<dynamic, dynamic> entry) {
  final multi = entry['expected_flow_paths'];
  if (multi is List) {
    return multi
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  final single = entry['expected_flow_path']?.toString().trim() ?? '';
  if (single.isEmpty) return const [];
  return [single];
}

List<SourceDeckCandidate> _selectCandidates(
  List<SourceDeckCandidate> candidates, {
  required int limit,
  required String selectionMode,
}) {
  if (limit <= 3 && selectionMode != 'balanced') {
    return _selectThreeCandidates(candidates).take(limit).toList();
  }
  return _selectBalancedCandidates(candidates, limit: limit);
}

List<SourceDeckCandidate> _selectThreeCandidates(
  List<SourceDeckCandidate> candidates,
) {
  final selected = <SourceDeckCandidate>[];
  final usedCommanders = <String>{};

  void tryPickByArchetype(String archetype) {
    for (final candidate in candidates) {
      final commanderKey = candidate.commanderName.toLowerCase();
      if (usedCommanders.contains(commanderKey)) continue;
      if (candidate.resolvedArchetype != archetype) continue;
      selected.add(candidate);
      usedCommanders.add(commanderKey);
      return;
    }
  }

  for (final archetype in const ['aggro', 'control', 'midrange']) {
    tryPickByArchetype(archetype);
  }

  for (final candidate in candidates) {
    if (selected.length >= 3) break;
    final commanderKey = candidate.commanderName.toLowerCase();
    if (usedCommanders.contains(commanderKey)) continue;
    selected.add(candidate);
    usedCommanders.add(commanderKey);
  }

  return selected.take(3).toList();
}

List<SourceDeckCandidate> _selectBalancedCandidates(
  List<SourceDeckCandidate> candidates, {
  required int limit,
}) {
  final ordered = [...candidates]..sort((a, b) {
    final statusOrder = _statusPriority(
      a.sourceDeckStateStatus,
    ).compareTo(_statusPriority(b.sourceDeckStateStatus));
    if (statusOrder != 0) return statusOrder;
    final severityOrder = b.sourceSeverityScore.compareTo(
      a.sourceSeverityScore,
    );
    if (severityOrder != 0) return severityOrder;
    return a.commanderName.toLowerCase().compareTo(
      b.commanderName.toLowerCase(),
    );
  });

  final selected = <SourceDeckCandidate>[];
  final usedCommanders = <String>{};
  final preferredStatuses = const ['needs_repair', 'healthy'];
  final preferredArchetypes = const ['aggro', 'control', 'midrange'];

  void tryPick(String status, String archetype) {
    if (selected.length >= limit) return;
    for (final candidate in ordered) {
      final commanderKey = candidate.commanderName.toLowerCase();
      if (usedCommanders.contains(commanderKey)) continue;
      if (candidate.sourceDeckStateStatus != status) continue;
      if (candidate.resolvedArchetype != archetype) continue;
      selected.add(candidate);
      usedCommanders.add(commanderKey);
      return;
    }
  }

  while (selected.length < limit) {
    final before = selected.length;
    for (final status in preferredStatuses) {
      for (final archetype in preferredArchetypes) {
        tryPick(status, archetype);
      }
    }
    if (selected.length == before) break;
  }

  for (final candidate in ordered) {
    if (selected.length >= limit) break;
    final commanderKey = candidate.commanderName.toLowerCase();
    if (usedCommanders.contains(commanderKey)) continue;
    selected.add(candidate);
    usedCommanders.add(commanderKey);
  }

  return selected.take(limit).toList();
}

int _statusPriority(String status) {
  return switch (status) {
    'needs_repair' => 0,
    'incomplete' => 1,
    'healthy' => 2,
    _ => 3,
  };
}

Future<String> _createDeckClone({
  required String apiBaseUrl,
  required String token,
  required SourceDeckCandidate candidate,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/decks'),
    headers: _jsonHeaders(token),
    body: jsonEncode({
      'name':
          'Resolution Validation - $_validationRunToken - ${candidate.commanderName} - ${DateTime.now().millisecondsSinceEpoch}',
      'format': 'commander',
      'description':
          'Deck clone para validacao do fluxo completo de optimize/rebuild',
      'is_public': false,
      'cards':
          candidate.cards
              .map(
                (card) => {
                  'card_id': card['card_id'],
                  'quantity': card['quantity'],
                  if (card['is_commander'] == true) 'is_commander': true,
                },
              )
              .toList(),
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Falha ao criar clone do deck: ${response.body}');
  }

  final body = _decodeJson(response);
  final e2eValidation =
      body['e2e_validation'] is Map
          ? (body['e2e_validation'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  if (e2eValidation['isolated_runtime'] != true ||
      e2eValidation['product_learning_writes_suppressed'] != true) {
    throw StateError(
      'Clone criado sem prova de supressao do aprendizado do produto.',
    );
  }
  final deckId =
      body['id']?.toString() ?? (body['deck']?['id']?.toString() ?? '');
  if (deckId.isEmpty) {
    throw Exception('Resposta sem id do deck clonado: ${response.body}');
  }
  return deckId;
}

Future<http.Response> _optimizeWithPolling({
  required String apiBaseUrl,
  required String token,
  required Map<String, dynamic> payload,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/ai/optimize'),
    headers: _jsonHeaders(token),
    body: jsonEncode(payload),
  );

  if (response.statusCode != 202) {
    return response;
  }

  final body = _decodeJson(response);
  final jobId = body['job_id']?.toString();
  if (jobId == null || jobId.isEmpty) {
    throw Exception('Resposta 202 sem job_id: ${response.body}');
  }

  for (var poll = 0; poll < 180; poll++) {
    await Future<void>.delayed(const Duration(seconds: 2));
    final pollResponse = await http.get(
      Uri.parse('$apiBaseUrl/ai/optimize/jobs/$jobId'),
      headers: _authHeaders(token),
    );
    final pollBody = _decodeJson(pollResponse);
    final status = pollBody['status']?.toString();

    if (status == 'completed') {
      return http.Response(
        jsonEncode(pollBody['result'] ?? <String, dynamic>{}),
        200,
      );
    }
    if (status == 'failed') {
      return http.Response(jsonEncode(pollBody), 422);
    }
  }

  return http.Response(
    jsonEncode({'error': 'Polling timeout para optimize job'}),
    500,
  );
}

Future<List<Map<String, dynamic>>> _applyRecommendations({
  required Pool pool,
  required List<Map<String, dynamic>> originalCards,
  required Map<String, dynamic> responseBody,
}) async {
  final next =
      originalCards.map((card) => Map<String, dynamic>.from(card)).toList();

  final removalsDetailed =
      (responseBody['removals_detailed'] as List?)?.whereType<Map>().toList() ??
      const <Map>[];

  final additionsDetailed =
      (responseBody['additions_detailed'] as List?)
          ?.whereType<Map>()
          .toList() ??
      const <Map>[];

  final removalCounts = <String, int>{};
  for (final raw in removalsDetailed) {
    final card = raw.cast<String, dynamic>();
    final name = card['name']?.toString().trim().toLowerCase();
    if (name == null || name.isEmpty) continue;
    final qty = (card['quantity'] as int?) ?? 1;
    removalCounts[name] = (removalCounts[name] ?? 0) + qty;
  }

  for (final entry in removalCounts.entries) {
    var remaining = entry.value;
    for (var i = next.length - 1; i >= 0 && remaining > 0; i--) {
      final cardName = (next[i]['name']?.toString().trim().toLowerCase() ?? '');
      if (cardName != entry.key) continue;
      if (next[i]['is_commander'] == true) continue;

      final qty = (next[i]['quantity'] as int?) ?? 0;
      if (qty <= remaining) {
        next.removeAt(i);
        remaining -= qty;
      } else {
        next[i]['quantity'] = qty - remaining;
        remaining = 0;
      }
    }
  }

  for (final raw in additionsDetailed) {
    final addition = raw.cast<String, dynamic>();
    final cardId = addition['card_id']?.toString();
    if (cardId == null || cardId.isEmpty) continue;

    final qty = (addition['quantity'] as int?) ?? 1;
    final existingIndex = next.indexWhere((card) => card['card_id'] == cardId);

    if (existingIndex >= 0) {
      next[existingIndex]['quantity'] =
          ((next[existingIndex]['quantity'] as int?) ?? 0) + qty;
      continue;
    }

    next.add({
      'card_id': cardId,
      'quantity': qty,
      'is_commander': false,
      'name': addition['name']?.toString() ?? '',
    });
  }

  final missingCardIds =
      next
          .where(
            (card) =>
                (card['card_id']?.toString().isNotEmpty ?? false) &&
                (((card['type_line'] as String?) ?? '').isEmpty ||
                    ((card['oracle_text'] as String?) ?? '').isEmpty),
          )
          .map((card) => card['card_id'].toString())
          .toSet()
          .toList();

  if (missingCardIds.isNotEmpty) {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id::text,
          name,
          type_line,
          mana_cost,
          colors,
          COALESCE(
            (SELECT SUM(
              CASE
                WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                WHEN m[1] = 'X' THEN 0
                ELSE 1
              END
            ) FROM regexp_matches(cards.mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
            0
          ) as cmc,
          oracle_text
        FROM cards
        WHERE id::text = ANY(@ids)
      '''),
      parameters: {'ids': missingCardIds},
    );

    final byId = <String, Map<String, dynamic>>{};
    for (final row in result) {
      byId[row[0] as String] = {
        'name': row[1] as String? ?? '',
        'type_line': row[2] as String? ?? '',
        'mana_cost': row[3] as String? ?? '',
        'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
        'cmc': (row[5] as num?)?.toDouble() ?? 0.0,
        'oracle_text': row[6] as String? ?? '',
      };
    }

    for (final card in next) {
      final cardId = card['card_id']?.toString();
      if (cardId == null || cardId.isEmpty) continue;
      final details = byId[cardId];
      if (details == null) continue;
      card['name'] = details['name'];
      card['type_line'] = details['type_line'];
      card['mana_cost'] = details['mana_cost'];
      card['colors'] = details['colors'];
      card['cmc'] = details['cmc'];
      card['oracle_text'] = details['oracle_text'];
    }
  }

  return next;
}

Map<String, dynamic> _decodeJson(http.Response response) {
  final body = response.body.trim();
  if (body.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  return {'value': decoded};
}

Future<String> _writeDeckArtifact({
  required String commanderName,
  required String sourceDeckId,
  required int runIndex,
  required Map<String, dynamic> payload,
}) async {
  final slug = _slugify(commanderName);
  final sourceToken = sourceDeckId.replaceAll('-', '');
  final suffix =
      sourceToken.length >= 8 ? sourceToken.substring(0, 8) : sourceToken;
  final path =
      '$_artifactDirPath/${runIndex.toString().padLeft(2, '0')}_${slug}_$suffix.json';
  await File(
    path,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  return path;
}

Future<void> _writeTextArtifact(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

int _totalCards(List<Map<String, dynamic>> cards) {
  return cards.fold<int>(
    0,
    (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
  );
}

int _landCount(Map<String, dynamic> analysis) {
  final types = (analysis['type_distribution'] as Map<String, dynamic>?) ?? {};
  return (types['lands'] as int?) ?? 0;
}

int _countInteraction(Map<String, dynamic> analysis) {
  final types = (analysis['type_distribution'] as Map<String, dynamic>?) ?? {};
  return ((types['instants'] as int?) ?? 0) +
      ((types['sorceries'] as int?) ?? 0);
}

double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0.0;
}

String? _normalizeArchetype(String? archetype) {
  final value = archetype?.trim().toLowerCase();
  if (value == null || value.isEmpty) return null;
  if (const {'aggro', 'control', 'midrange'}.contains(value)) return value;
  return switch (value) {
    'tempo' || 'spellslinger' => 'control',
    'stax' || 'combo' || 'aristocrats' || 'tribal' || 'voltron' => 'midrange',
    _ => null,
  };
}

String _slugify(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'deck' : normalized;
}

Map<String, String> _authHeaders(String token) => {
  'Authorization': 'Bearer $token',
};

Map<String, String> _jsonHeaders(String token) => {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};

String _extractMessage(Map<String, dynamic> body) {
  return body['error']?.toString() ??
      body['message']?.toString() ??
      body.toString();
}

String _buildMarkdownReport(Map<String, dynamic> summary) {
  final results =
      (summary['results'] as List).whereType<Map<String, dynamic>>().toList();
  final optimizeOutcomeSummary =
      (summary['optimize_outcome_summary'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final providerEvidenceSummary =
      (summary['provider_evidence_summary'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final runtimeProvenanceSummary =
      (summary['runtime_provenance_summary'] as Map?)
          ?.cast<String, dynamic>() ??
      const <String, dynamic>{};

  final buffer =
      StringBuffer()
        ..writeln(
          '# Relatorio de Resolucao Real - ${summary['total']} Decks Commander',
        )
        ..writeln()
        ..writeln('- Gerado em: `${summary['generated_at']}`')
        ..writeln('- API: `${summary['api_base_url']}`')
        ..writeln('- Artefatos: `${summary['artifact_dir']}`')
        ..writeln('- Seleção: `${summary['selection_mode']}`')
        ..writeln('- Total: `${summary['total']}`')
        ..writeln('- Otimizacoes diretas: `${summary['direct_optimizations']}`')
        ..writeln(
          '- Resolvidos via rebuild: `${summary['rebuild_resolutions']}`',
        )
        ..writeln('- Sem troca segura: `${summary['safe_no_change']}`')
        ..writeln('- Nao resolvidos: `${summary['unresolved']}`')
        ..writeln(
          '- Optimize 200 aceitos pelo contrato: '
          '`${optimizeOutcomeSummary['contract_accepted_http_200'] ?? 0}`',
        )
        ..writeln(
          '- Optimize 200 rejeitados pelo contrato: '
          '`${optimizeOutcomeSummary['contract_rejected_http_200'] ?? 0}`',
        )
        ..writeln(
          '- Respostas mock: '
          '`${optimizeOutcomeSummary['mock_responses'] ?? 0}`',
        )
        ..writeln(
          '- Pares candidatos retornados: '
          '`${optimizeOutcomeSummary['candidate_swap_pairs'] ?? 0}`',
        )
        ..writeln(
          '- Pares candidatos rejeitados: '
          '`${optimizeOutcomeSummary['rejected_candidate_swap_pairs'] ?? 0}`',
        )
        ..writeln(
          '- Pares acionaveis reportados: '
          '`${optimizeOutcomeSummary['actionable_swap_pairs'] ?? 0}`',
        )
        ..writeln(
          '- Propostas que alteraram o deck: '
          '`${optimizeOutcomeSummary['proposal_changed_deck'] ?? 0}`',
        )
        ..writeln(
          '- Assinaturas persistidas confirmadas: '
          '`${optimizeOutcomeSummary['persisted_signature_confirmed'] ?? 0}`',
        )
        ..writeln(
          '- Chamadas ao provedor observadas: '
          '`${providerEvidenceSummary['call_count'] ?? 0}`',
        )
        ..writeln(
          '- Chamadas ao provedor bem-sucedidas: '
          '`${providerEvidenceSummary['successful_calls'] ?? 0}`',
        )
        ..writeln(
          '- Resultados com origem runtime conhecida: '
          '`${runtimeProvenanceSummary['known_results'] ?? 0}`',
        )
        ..writeln(
          '- Resultados com origem runtime desconhecida: '
          '`${runtimeProvenanceSummary['unknown_results'] ?? 0}`',
        )
        ..writeln('- Passaram: `${summary['passed']}`')
        ..writeln('- Falharam: `${summary['failed']}`')
        ..writeln()
        ..writeln('## Resultado por deck')
        ..writeln();

  for (final result in results) {
    final optimizeOutcome =
        (result['optimize_outcome'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final rejectionReasons =
        (optimizeOutcome['rejection_reasons'] as List?)
            ?.map((item) => '$item')
            .toList() ??
        const <String>[];
    final optimizeApplication =
        (result['optimize_application'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final providerEvidence =
        (result['provider_evidence'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final runtimeProvenance =
        (result['runtime_provenance'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    buffer
      ..writeln('### ${result['commander_name']}')
      ..writeln()
      ..writeln('- Source deck: `${result['source_deck_id']}`')
      ..writeln('- Clone deck: `${result['clone_deck_id']}`')
      ..writeln('- Deck final: `${result['final_deck_id']}`')
      ..writeln('- Caminho: `${result['flow_path']}`')
      ..writeln('- Archetype usado: `${result['archetype']}`')
      ..writeln('- Optimize status: `${result['optimize_status']}`')
      ..writeln(
        '- Optimize outcome: '
        '`${optimizeOutcome['outcome_code'] ?? 'n/d'}`',
      )
      ..writeln(
        '- Apply direto aceito: '
        '`${optimizeOutcome['direct_apply_accepted'] ?? false}`',
      )
      ..writeln(
        '- Pares acionaveis: '
        '`${optimizeOutcome['actionable_swap_count'] ?? 0}`',
      )
      ..writeln(
        '- Rejeicoes do outcome: '
        '`${rejectionReasons.isEmpty ? 'nenhuma' : rejectionReasons.join(', ')}`',
      )
      ..writeln(
        '- Proposta alterou o deck: '
        '`${optimizeApplication['proposal_changed_deck'] ?? 'n/d'}`',
      )
      ..writeln(
        '- PUT do optimize: '
        '`${optimizeApplication['put_status'] ?? 'n/d'}`',
      )
      ..writeln(
        '- Assinatura persistida confirmada: '
        '`${optimizeApplication['persisted_signature_confirmed'] ?? 'n/d'}`',
      )
      ..writeln(
        '- Chamadas ao provedor: '
        '`${providerEvidence['call_count'] ?? 0}` '
        '(sucesso: `${providerEvidence['successful_calls'] ?? 0}`)',
      )
      ..writeln(
        '- Origem runtime: `${runtimeProvenance['origin'] ?? 'unknown'}` '
        '(strategy: `${runtimeProvenance['strategy_source'] ?? 'n/d'}`, '
        'cache: `${runtimeProvenance['cache_hit'] ?? 'n/d'}`)',
      )
      ..writeln('- Rebuild status: `${result['rebuild_status'] ?? 'n/d'}`')
      ..writeln('- Deck final valido: `${result['final_deck_valid']}`')
      ..writeln('- Deck final healthy: `${result['final_deck_state']}`')
      ..writeln('- CMC medio final: `${result['final_average_cmc']}`')
      ..writeln('- Terrenos finais: `${result['final_land_count']}`')
      ..writeln('- Interacao final: `${result['final_interaction']}`')
      ..writeln('- Artifact: `${result['saved_artifact_path']}`')
      ..writeln(
        '- Status final: `${result['passed'] == true ? 'PASSOU' : 'FALHOU'}`',
      )
      ..writeln();

    final failedChecks =
        (result['failed_checks'] as List?)?.map((item) => '$item').toList() ??
        const <String>[];
    if (failedChecks.isNotEmpty) {
      buffer.writeln('Falhas:');
      for (final item in failedChecks) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    final warnings =
        (result['warnings'] as List?)?.map((item) => '$item').toList() ??
        const <String>[];
    if (warnings.isNotEmpty) {
      buffer.writeln('Avisos:');
      for (final item in warnings.take(12)) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }
  }

  return buffer.toString();
}
