import 'dart:collection';
import 'dart:convert';

import '../color_identity.dart';
import 'external_commander_meta_candidate_support.dart';
import 'external_commander_meta_import_support.dart';

const externalCommanderMetaStage2DefaultExpansionArtifactPath =
    'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json';
const externalCommanderMetaStage2DefaultValidationArtifactPath =
    'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json';

class ExternalCommanderMetaStagingConfig {
  const ExternalCommanderMetaStagingConfig({
    required this.apply,
    required this.expansionArtifactPath,
    required this.validationArtifactPath,
    required this.importedBy,
    this.reportJsonOut,
  });

  final bool apply;
  final String expansionArtifactPath;
  final String validationArtifactPath;
  final String importedBy;
  final String? reportJsonOut;

  bool get dryRun => !apply;

  factory ExternalCommanderMetaStagingConfig.parse(List<String> args) {
    var apply = false;
    var explicitDryRun = false;
    var expansionArtifactPath =
        externalCommanderMetaStage2DefaultExpansionArtifactPath;
    var validationArtifactPath =
        externalCommanderMetaStage2DefaultValidationArtifactPath;
    var importedBy = 'meta_deck_intelligence_2026_04_24';
    String? reportJsonOut;

    for (final arg in args) {
      if (arg == '--apply') {
        apply = true;
        continue;
      }
      if (arg == '--dry-run') {
        explicitDryRun = true;
        continue;
      }
      if (arg.startsWith('--expansion-artifact=')) {
        expansionArtifactPath =
            arg.substring('--expansion-artifact='.length).trim();
        continue;
      }
      if (arg.startsWith('--validation-artifact=')) {
        validationArtifactPath =
            arg.substring('--validation-artifact='.length).trim();
        continue;
      }
      if (arg.startsWith('--imported-by=')) {
        importedBy = arg.substring('--imported-by='.length).trim();
        continue;
      }
      if (arg.startsWith('--report-json-out=')) {
        reportJsonOut = arg.substring('--report-json-out='.length).trim();
      }
    }

    if (apply && explicitDryRun) {
      throw ArgumentError('Use apenas um modo: --apply ou --dry-run.');
    }

    return ExternalCommanderMetaStagingConfig(
      apply: apply,
      expansionArtifactPath: expansionArtifactPath,
      validationArtifactPath: validationArtifactPath,
      importedBy: importedBy,
      reportJsonOut: reportJsonOut == null || reportJsonOut.isEmpty
          ? null
          : reportJsonOut,
    );
  }
}

class ExternalCommanderMetaStagingPlan {
  const ExternalCommanderMetaStagingPlan({
    required this.validationProfile,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.expansionRejectedCount,
    required this.candidatesToPersist,
    required this.duplicateSourceUrls,
  });

  final String validationProfile;
  final int acceptedCount;
  final int rejectedCount;
  final int expansionRejectedCount;
  final List<ExternalCommanderMetaCandidate> candidatesToPersist;
  final List<String> duplicateSourceUrls;

  int get duplicateCount => duplicateSourceUrls.length;
}

ExternalCommanderMetaStagingPlan buildExternalCommanderMetaStagingPlan({
  required Map<String, dynamic> expansionArtifact,
  required Map<String, dynamic> validationArtifact,
  required String importedBy,
}) {
  final validationProfile =
      validationArtifact['validation_profile']?.toString().trim() ?? '';
  if (validationProfile != topDeckEdhTop16Stage2ValidationProfile) {
    throw StateError(
      'Persistencia segura exige validation_profile='
      '$topDeckEdhTop16Stage2ValidationProfile. '
      'Valor atual: ${validationProfile.isEmpty ? "(vazio)" : validationProfile}.',
    );
  }

  final rejectedCount = _readInt(validationArtifact['rejected_count']);
  if (rejectedCount > 0) {
    throw StateError(
      'Persistencia segura bloqueada: validation rejected_count=$rejectedCount.',
    );
  }

  final rawValidationResults = validationArtifact['results'];
  if (rawValidationResults is! List) {
    throw StateError('Artifact de validacao sem lista results.');
  }

  final rawExpansionCandidates = expansionArtifact['candidates'];
  if (rawExpansionCandidates is! List) {
    throw StateError('Artifact de expansao sem lista candidates.');
  }

  final expansionCandidatesBySourceUrl = <String, Map<String, dynamic>>{};
  for (final rawCandidate in rawExpansionCandidates.whereType<Map>()) {
    final candidate = rawCandidate.cast<String, dynamic>();
    final sourceUrl = candidate['source_url']?.toString().trim();
    if (sourceUrl == null || sourceUrl.isEmpty) {
      continue;
    }
    expansionCandidatesBySourceUrl[sourceUrl] = candidate;
  }

  final dedupedBySourceUrl =
      LinkedHashMap<String, ExternalCommanderMetaCandidate>();
  final duplicateSourceUrls = <String>{};
  var acceptedCount = 0;

  for (final rawResult in rawValidationResults.whereType<Map>()) {
    final result = rawResult.cast<String, dynamic>();
    if (result['accepted'] != true) {
      continue;
    }

    final rawValidationCandidate = result['candidate'];
    if (rawValidationCandidate is! Map) {
      throw StateError('Resultado aceito sem candidate objeto.');
    }
    final sourceUrl =
        rawValidationCandidate['source_url']?.toString().trim() ?? '';
    if (sourceUrl.isEmpty) {
      throw StateError('Resultado aceito sem source_url.');
    }

    final expansionCandidate = expansionCandidatesBySourceUrl[sourceUrl];
    if (expansionCandidate == null) {
      throw StateError(
        'Persistencia segura bloqueada: source_url ausente no artifact de expansao: $sourceUrl',
      );
    }

    final stagedCandidate = _buildStagedCandidate(
      expansionCandidate: expansionCandidate,
      validationResult: result,
      validationArtifact: validationArtifact,
      expansionArtifact: expansionArtifact,
      importedBy: importedBy,
    );

    acceptedCount++;
    if (dedupedBySourceUrl.containsKey(sourceUrl)) {
      duplicateSourceUrls.add(sourceUrl);
    }
    dedupedBySourceUrl[sourceUrl] = stagedCandidate;
  }

  return ExternalCommanderMetaStagingPlan(
    validationProfile: validationProfile,
    acceptedCount: acceptedCount,
    rejectedCount: rejectedCount,
    expansionRejectedCount: _readInt(expansionArtifact['rejected_count']),
    candidatesToPersist: dedupedBySourceUrl.values.toList(growable: false),
    duplicateSourceUrls: duplicateSourceUrls.toList(growable: false)..sort(),
  );
}

Future<void> persistExternalCommanderMetaStagingPlan(
  dynamic conn,
  ExternalCommanderMetaStagingPlan plan,
) async {
  for (final candidate in plan.candidatesToPersist) {
    await upsertExternalCommanderMetaCandidate(conn, candidate);
  }
}

Map<String, dynamic> buildExternalCommanderMetaStagingReport(
  ExternalCommanderMetaStagingPlan plan, {
  required ExternalCommanderMetaStagingConfig config,
}) {
  return <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'mode': config.dryRun ? 'dry_run' : 'apply',
    'expansion_artifact': config.expansionArtifactPath,
    'validation_artifact': config.validationArtifactPath,
    'validation_profile': plan.validationProfile,
    'summary': <String, dynamic>{
      'accepted_count': plan.acceptedCount,
      'validation_rejected_count': plan.rejectedCount,
      'expansion_rejected_count': plan.expansionRejectedCount,
      'to_persist_count': plan.candidatesToPersist.length,
      'duplicate_source_url_count': plan.duplicateCount,
    },
    'duplicate_source_urls': plan.duplicateSourceUrls,
    'candidates': plan.candidatesToPersist
        .map((candidate) => candidate.toJson())
        .toList(growable: false),
  };
}

Map<String, dynamic> decodeExternalCommanderMetaArtifact(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Artifact precisa ser um objeto JSON.');
  }
  return decoded;
}

ExternalCommanderMetaCandidate _buildStagedCandidate({
  required Map<String, dynamic> expansionCandidate,
  required Map<String, dynamic> validationResult,
  required Map<String, dynamic> validationArtifact,
  required Map<String, dynamic> expansionArtifact,
  required String importedBy,
}) {
  final baseCandidate = ExternalCommanderMetaCandidate.fromJson(
    expansionCandidate,
    importedBy: importedBy,
  );

  final sourceUri = Uri.tryParse(baseCandidate.sourceUrl);
  if (sourceUri == null ||
      (sourceUri.scheme != 'http' && sourceUri.scheme != 'https') ||
      (sourceUri.host.trim().isEmpty)) {
    throw StateError(
      'Persistencia segura bloqueada: source_url invalido: ${baseCandidate.sourceUrl}',
    );
  }

  if (baseCandidate.normalizedSourceName.trim().isEmpty ||
      baseCandidate.normalizedSourceName == 'unknown') {
    throw StateError(
      'Persistencia segura bloqueada: source_name invalido para ${baseCandidate.sourceUrl}.',
    );
  }

  if (_policyForSource(baseCandidate) == null) {
    throw StateError(
      'Persistencia segura bloqueada: source fora da allowlist controlada: '
      '${baseCandidate.normalizedSourceName} ${baseCandidate.sourceUrl}',
    );
  }

  if (!_hasResearchPayloadValue(baseCandidate.researchPayload, 'collection_method')) {
    throw StateError(
      'Persistencia segura bloqueada: collection_method ausente em ${baseCandidate.sourceUrl}.',
    );
  }

  if (!_hasResearchPayloadValue(baseCandidate.researchPayload, 'source_context')) {
    throw StateError(
      'Persistencia segura bloqueada: source_context ausente em ${baseCandidate.sourceUrl}.',
    );
  }

  if (baseCandidate.cardList.trim().isEmpty) {
    throw StateError(
      'Persistencia segura bloqueada: card_list vazio em ${baseCandidate.sourceUrl}.',
    );
  }

  if (baseCandidate.isCommanderLegal == false) {
    throw StateError(
      'Persistencia segura bloqueada: is_commander_legal=false em ${baseCandidate.sourceUrl}.',
    );
  }

  final rawValidationLegalStatus =
      validationResult['legal_status']?.toString().trim().toLowerCase();
  final persistedLegalStatus =
      _mapStage2LegalStatusToPersistedLegalStatus(rawValidationLegalStatus);
  if (persistedLegalStatus == null) {
    throw StateError(
      'Persistencia segura bloqueada: legal_status invalido em ${baseCandidate.sourceUrl}. '
      'Valor atual: ${validationResult['legal_status']}.',
    );
  }

  final commanderColorIdentity = normalizeColorIdentity(
    _asStringList(validationResult['commander_color_identity']),
  );
  final unresolvedCards = _deepCopyJson(validationResult['unresolved_cards']);
  final illegalCards = _deepCopyJson(validationResult['illegal_cards']);
  final issues = _deepCopyJson(validationResult['issues']);

  final researchPayload =
      _deepCopyJson(baseCandidate.researchPayload) as Map<String, dynamic>;
  researchPayload['stage_status'] = externalCommanderMetaStagedValidationStatus;
  researchPayload['staging_audit'] = <String, dynamic>{
    'validation_profile': topDeckEdhTop16Stage2ValidationProfile,
    'accepted': true,
    'validation_legal_status': rawValidationLegalStatus,
    'commander_color_identity': commanderColorIdentity.toList()..sort(),
    'unresolved_cards': unresolvedCards,
    'illegal_cards': illegalCards,
    'issues': issues,
    'validation_generated_at': validationArtifact['generated_at'],
    'validation_rejected_count': validationArtifact['rejected_count'],
    'expansion_generated_at': expansionArtifact['generated_at'],
    'expansion_rejected_count': expansionArtifact['rejected_count'],
  };

  final mergedCandidateJson = <String, dynamic>{
    ..._deepCopyJson(expansionCandidate) as Map<String, dynamic>,
    'source_name': baseCandidate.normalizedSourceName,
    'source_url': baseCandidate.sourceUrl,
    'deck_name': baseCandidate.deckName,
    'commander_name': baseCandidate.commanderName,
    'partner_commander_name': baseCandidate.partnerCommanderName,
    'format': baseCandidate.persistedFormat,
    'subformat': baseCandidate.normalizedSubformat,
    'archetype': baseCandidate.archetype,
    'card_list': baseCandidate.cardList,
    'placement': baseCandidate.placement,
    'color_identity': commanderColorIdentity.isEmpty
        ? (baseCandidate.colorIdentity.toList()..sort())
        : (commanderColorIdentity.toList()..sort()),
    'is_commander_legal': rawValidationLegalStatus == 'legal'
        ? true
        : baseCandidate.isCommanderLegal,
    'validation_status': externalCommanderMetaStagedValidationStatus,
    'legal_status': persistedLegalStatus,
    'validation_notes': _buildStagingValidationNotes(
      baseCandidate.validationNotes,
      rawValidationLegalStatus: rawValidationLegalStatus,
      unresolvedCount: _readListLength(unresolvedCards),
      illegalCount: _readListLength(illegalCards),
    ),
    'research_payload': researchPayload,
  };

  return ExternalCommanderMetaCandidate.fromJson(
    mergedCandidateJson,
    importedBy: importedBy,
  );
}

String? _mapStage2LegalStatusToPersistedLegalStatus(String? raw) {
  return switch (raw) {
    'legal' => externalCommanderMetaPromotionLegalStatusValid,
    'not_proven' => 'warning_pending',
    'illegal' => 'rejected',
    _ => null,
  };
}

String _buildStagingValidationNotes(
  String? originalNotes, {
  required String? rawValidationLegalStatus,
  required int unresolvedCount,
  required int illegalCount,
}) {
  final notes = <String>[];
  final trimmedOriginal = originalNotes?.trim();
  if (trimmedOriginal != null && trimmedOriginal.isNotEmpty) {
    notes.add(trimmedOriginal);
  }
  notes.add(
    'Staged from $topDeckEdhTop16Stage2ValidationProfile '
    '(legal_status=${rawValidationLegalStatus ?? "unknown"}, '
    'unresolved_cards=$unresolvedCount, illegal_cards=$illegalCount).',
  );
  return notes.join(' ');
}

ExternalCommanderMetaControlledSourcePolicy? _policyForSource(
  ExternalCommanderMetaCandidate candidate,
) {
  final sourceUri = Uri.tryParse(candidate.sourceUrl);
  final normalizedHost =
      sourceUri?.host.toLowerCase().replaceFirst('www.', '') ?? '';
  final normalizedName = candidate.normalizedSourceName.toLowerCase();

  for (final policy in externalCommanderMetaControlledSourcePolicies) {
    if (policy.allowedHosts.contains(normalizedHost) ||
        policy.aliases.contains(normalizedName) ||
        policy.canonicalSourceName.toLowerCase() == normalizedName) {
      return policy;
    }
  }
  return null;
}

bool _hasResearchPayloadValue(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  return value != null;
}

List<String> _asStringList(dynamic raw) {
  if (raw is Iterable) {
    return raw.map((value) => value.toString()).toList(growable: false);
  }
  return const <String>[];
}

Object? _deepCopyJson(Object? value) {
  if (value == null) return null;
  return jsonDecode(jsonEncode(value));
}

int _readInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

int _readListLength(Object? raw) => raw is List ? raw.length : 0;
