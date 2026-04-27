import 'dart:convert';

import 'external_commander_meta_candidate_support.dart';

class ExternalCommanderMetaOperationalConfig {
  ExternalCommanderMetaOperationalConfig({
    required this.apply,
    required this.sourceUrl,
    required this.targetValid,
    required this.maxStanding,
    required this.outputDir,
    required this.importedBy,
  });

  final bool apply;
  final String sourceUrl;
  final int targetValid;
  final int maxStanding;
  final String outputDir;
  final String importedBy;

  bool get dryRun => !apply;

  factory ExternalCommanderMetaOperationalConfig.parse(List<String> args) {
    var apply = false;
    var explicitDryRun = false;
    String? sourceUrl;
    int? targetValid;
    int? maxStanding;
    String? outputDir;
    String? importedBy;

    for (final arg in args) {
      if (arg == '--apply') {
        apply = true;
        continue;
      }
      if (arg == '--dry-run') {
        explicitDryRun = true;
        continue;
      }
      if (arg == '--help' || arg == '-h') {
        throw const FormatException(_usage);
      }
      if (arg.startsWith('--source-url=')) {
        sourceUrl = arg.substring('--source-url='.length).trim();
        continue;
      }
      if (arg.startsWith('--target-valid=')) {
        targetValid = int.tryParse(arg.substring('--target-valid='.length));
        continue;
      }
      if (arg.startsWith('--max-standing=')) {
        maxStanding = int.tryParse(arg.substring('--max-standing='.length));
        continue;
      }
      if (arg.startsWith('--output-dir=')) {
        outputDir = arg.substring('--output-dir='.length).trim();
        continue;
      }
      if (arg.startsWith('--imported-by=')) {
        importedBy = arg.substring('--imported-by='.length).trim();
      }
    }

    if (apply && explicitDryRun) {
      throw ArgumentError('Use apenas um modo: --apply ou --dry-run.');
    }
    if (sourceUrl == null || sourceUrl.isEmpty) {
      throw ArgumentError('--source-url e obrigatorio.');
    }
    if (targetValid == null || targetValid <= 0) {
      throw ArgumentError('--target-valid e obrigatorio e deve ser > 0.');
    }
    if (maxStanding == null || maxStanding <= 0) {
      throw ArgumentError('--max-standing e obrigatorio e deve ser > 0.');
    }
    if (maxStanding < targetValid) {
      throw ArgumentError('--max-standing deve ser >= --target-valid.');
    }

    final tournamentId = _safeTournamentId(sourceUrl);
    final today = DateTime.now().toUtc().toIso8601String().split('T').first;
    final resolvedOutputDir = outputDir?.trim().isNotEmpty == true
        ? outputDir!.trim()
        : 'test/artifacts/meta_deck_intelligence_$today/'
            'external_meta_pipeline_$tournamentId';
    final resolvedImportedBy = importedBy?.trim().isNotEmpty == true
        ? importedBy!.trim()
        : 'external_meta_pipeline_${today.replaceAll('-', '_')}_$tournamentId';

    return ExternalCommanderMetaOperationalConfig(
      apply: apply,
      sourceUrl: sourceUrl,
      targetValid: targetValid,
      maxStanding: maxStanding,
      outputDir: resolvedOutputDir,
      importedBy: resolvedImportedBy,
    );
  }
}

class ExternalCommanderMetaEligibilityDecision {
  const ExternalCommanderMetaEligibilityDecision({
    required this.sourceUrl,
    required this.deckName,
    required this.accepted,
    required this.eligibleForStageApply,
    required this.cardCount,
    required this.subformat,
    required this.legalStatus,
    required this.unresolvedCount,
    required this.illegalCount,
    required this.reasons,
  });

  final String sourceUrl;
  final String deckName;
  final bool accepted;
  final bool eligibleForStageApply;
  final int cardCount;
  final String? subformat;
  final String? legalStatus;
  final int unresolvedCount;
  final int illegalCount;
  final List<String> reasons;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source_url': sourceUrl,
      'deck_name': deckName,
      'accepted': accepted,
      'eligible_for_stage_apply': eligibleForStageApply,
      'card_count': cardCount,
      'subformat': subformat,
      'legal_status': legalStatus,
      'unresolved_count': unresolvedCount,
      'illegal_count': illegalCount,
      'reasons': reasons,
    };
  }
}

class ExternalCommanderMetaEligibilityBatch {
  const ExternalCommanderMetaEligibilityBatch({
    required this.filteredExpansionArtifact,
    required this.filteredValidationArtifact,
    required this.decisions,
  });

  final Map<String, dynamic> filteredExpansionArtifact;
  final Map<String, dynamic> filteredValidationArtifact;
  final List<ExternalCommanderMetaEligibilityDecision> decisions;

  int get eligibleCount =>
      decisions.where((decision) => decision.eligibleForStageApply).length;

  int get excludedCount => decisions.length - eligibleCount;

  Map<String, int> get exclusionCountsByReason {
    final counts = <String, int>{};
    for (final decision in decisions.where(
      (decision) => !decision.eligibleForStageApply,
    )) {
      for (final reason in decision.reasons) {
        counts[reason] = (counts[reason] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, dynamic> toReportJson() {
    return <String, dynamic>{
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'strict_gate': const <String, dynamic>{
        'accepted_only': true,
        'subformat': 'competitive_commander',
        'card_count_exact': 100,
        'legal_status': 'legal',
        'unresolved_cards_exact': 0,
        'illegal_cards_exact': 0,
      },
      'summary': <String, dynamic>{
        'eligible_count': eligibleCount,
        'excluded_count': excludedCount,
        'exclusion_counts_by_reason': exclusionCountsByReason,
      },
      'decisions': decisions.map((decision) => decision.toJson()).toList(),
    };
  }
}

ExternalCommanderMetaEligibilityBatch buildStrictOperationalEligibilityBatch({
  required Map<String, dynamic> expansionArtifact,
  required Map<String, dynamic> validationArtifact,
}) {
  final validationProfile =
      validationArtifact['validation_profile']?.toString().trim();
  if (validationProfile != topDeckEdhTop16Stage2ValidationProfile) {
    throw StateError(
      'Strict gate exige validation_profile='
      '$topDeckEdhTop16Stage2ValidationProfile.',
    );
  }

  final expansionCandidates =
      (expansionArtifact['candidates'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
  final expansionResults =
      (expansionArtifact['results'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
  final validationResults =
      (validationArtifact['results'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);

  final candidatesBySourceUrl = <String, Map<String, dynamic>>{
    for (final candidate in expansionCandidates)
      if (_sourceUrlOf(candidate).isNotEmpty)
        _sourceUrlOf(candidate): candidate,
  };
  final decisions = <ExternalCommanderMetaEligibilityDecision>[];
  final eligibleSourceUrls = <String>{};

  for (final result in validationResults) {
    final candidateJson =
        (result['candidate'] as Map?)?.cast<String, dynamic>();
    final sourceUrl = _sourceUrlOf(candidateJson);
    final reasons = <String>[];
    final accepted = result['accepted'] == true;
    final cardCount = _readInt(result['card_count']);
    final subformat =
        candidateJson?['subformat']?.toString().trim().toLowerCase();
    final legalStatus = result['legal_status']?.toString().trim().toLowerCase();
    final unresolvedCount = _readListLength(result['unresolved_cards']);
    final illegalCount = _readListLength(result['illegal_cards']);

    if (!accepted) {
      reasons.add('validation_rejected');
    }
    if (subformat != 'competitive_commander') {
      reasons.add('invalid_subformat');
    }
    if (cardCount != 100) {
      reasons.add('card_count_not_100');
    }
    if (legalStatus != externalCommanderMetaLegalStatusLegal) {
      reasons.add('legal_status_not_legal');
    }
    if (unresolvedCount != 0) {
      reasons.add('unresolved_cards_non_zero');
    }
    if (illegalCount != 0) {
      reasons.add('illegal_cards_non_zero');
    }
    if (sourceUrl.isEmpty || !candidatesBySourceUrl.containsKey(sourceUrl)) {
      reasons.add('missing_expansion_candidate');
    }

    final eligible = reasons.isEmpty;
    if (eligible) {
      eligibleSourceUrls.add(sourceUrl);
    }

    decisions.add(
      ExternalCommanderMetaEligibilityDecision(
        sourceUrl: sourceUrl,
        deckName: candidateJson?['deck_name']?.toString() ?? '',
        accepted: accepted,
        eligibleForStageApply: eligible,
        cardCount: cardCount,
        subformat: subformat,
        legalStatus: legalStatus,
        unresolvedCount: unresolvedCount,
        illegalCount: illegalCount,
        reasons: List<String>.unmodifiable(reasons),
      ),
    );
  }

  final filteredCandidates = expansionCandidates
      .where(
          (candidate) => eligibleSourceUrls.contains(_sourceUrlOf(candidate)))
      .map(_deepCopyMap)
      .toList(growable: false);
  final filteredExpansionResults = expansionResults
      .where((result) =>
          eligibleSourceUrls.contains(_sourceUrlOf(result['candidate'])))
      .map(_deepCopyMap)
      .toList(growable: false);
  final filteredValidationResults = validationResults
      .where((result) {
        final candidateJson =
            (result['candidate'] as Map?)?.cast<String, dynamic>();
        return eligibleSourceUrls.contains(_sourceUrlOf(candidateJson));
      })
      .map(_deepCopyMap)
      .toList(growable: false);

  final filteredExpansionArtifact = <String, dynamic>{
    ..._deepCopyMap(expansionArtifact),
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'strict_gate': const <String, dynamic>{
      'accepted_only': true,
      'subformat': 'competitive_commander',
      'card_count_exact': 100,
      'legal_status': 'legal',
      'unresolved_cards_exact': 0,
      'illegal_cards_exact': 0,
    },
    'filtered_from_expanded_count':
        _readInt(expansionArtifact['expanded_count']),
    'expanded_count': filteredCandidates.length,
    'rejected_count': decisions.length - filteredCandidates.length,
    'goal_reached': filteredCandidates.length >=
        _readInt(expansionArtifact['target_valid_count']),
    'candidates': filteredCandidates,
    'results': filteredExpansionResults,
  };
  final filteredValidationArtifact = <String, dynamic>{
    ..._deepCopyMap(validationArtifact),
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'accepted_count': filteredValidationResults.length,
    'rejected_count': 0,
    'results': filteredValidationResults,
  };

  return ExternalCommanderMetaEligibilityBatch(
    filteredExpansionArtifact: filteredExpansionArtifact,
    filteredValidationArtifact: filteredValidationArtifact,
    decisions: List<ExternalCommanderMetaEligibilityDecision>.unmodifiable(
      decisions,
    ),
  );
}

String _sourceUrlOf(Object? raw) {
  if (raw is Map) {
    return raw['source_url']?.toString().trim() ?? '';
  }
  return '';
}

int _readInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

int _readListLength(dynamic raw) => raw is List ? raw.length : 0;

Map<String, dynamic> _deepCopyMap(Object? raw) {
  final encoded = jsonEncode(raw);
  final decoded = jsonDecode(encoded);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Esperado objeto JSON.');
  }
  return decoded;
}

String _safeTournamentId(String sourceUrl) {
  final uri = Uri.tryParse(sourceUrl);
  final segments = uri?.pathSegments ?? const <String>[];
  final tournamentIndex = segments.indexOf('tournament');
  if (tournamentIndex >= 0 && tournamentIndex + 1 < segments.length) {
    final raw = segments[tournamentIndex + 1].trim().toLowerCase();
    if (raw.isNotEmpty) {
      return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }
  }
  return 'unknown_tournament';
}

const _usage = '''
Usage:
  dart run bin/run_external_commander_meta_pipeline.dart [options]

Required options:
  --source-url=<url>     EDHTop16 tournament URL.
  --target-valid=<n>     Mandatory hard limit of valid expanded decks.
  --max-standing=<n>     Mandatory hard limit of standings scanned.

Optional:
  --apply                Executes stage apply + promote apply.
  --dry-run              Explicit dry-run (default).
  --output-dir=<path>    Artifact directory.
  --imported-by=<label>  Audit label persisted on stage apply.
''';
