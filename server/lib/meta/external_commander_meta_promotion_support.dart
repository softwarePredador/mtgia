import 'external_commander_meta_candidate_support.dart';
import 'meta_deck_commander_shell_support.dart';
import 'meta_deck_card_list_support.dart';
import 'meta_deck_format_support.dart';

class ExternalCommanderMetaPromotionConfig {
  const ExternalCommanderMetaPromotionConfig({
    required this.apply,
    this.reportJsonOut,
    this.sourceUrl,
    this.limit,
  });

  final bool apply;
  final String? reportJsonOut;
  final String? sourceUrl;
  final int? limit;

  bool get dryRun => !apply;

  factory ExternalCommanderMetaPromotionConfig.parse(List<String> args) {
    var apply = false;
    var explicitDryRun = false;
    String? reportJsonOut;
    String? sourceUrl;
    int? limit;

    for (final arg in args) {
      if (arg == '--apply') {
        apply = true;
        continue;
      }
      if (arg == '--dry-run') {
        explicitDryRun = true;
        continue;
      }
      if (arg.startsWith('--report-json-out=')) {
        reportJsonOut = arg.substring('--report-json-out='.length).trim();
        continue;
      }
      if (arg.startsWith('--source-url=')) {
        sourceUrl = arg.substring('--source-url='.length).trim();
        continue;
      }
      if (arg.startsWith('--limit=')) {
        limit = int.tryParse(arg.substring('--limit='.length).trim());
      }
    }

    if (apply && explicitDryRun) {
      throw ArgumentError('Use apenas um modo: --apply ou --dry-run.');
    }
    if (limit != null && limit <= 0) {
      throw ArgumentError('--limit deve ser maior que zero quando informado.');
    }

    return ExternalCommanderMetaPromotionConfig(
      apply: apply,
      reportJsonOut: reportJsonOut,
      sourceUrl: sourceUrl == null || sourceUrl.isEmpty ? null : sourceUrl,
      limit: limit,
    );
  }
}

class ExternalCommanderMetaPromotionSnapshot {
  const ExternalCommanderMetaPromotionSnapshot({
    required this.candidate,
    this.promotedToMetaDecksAt,
  });

  final ExternalCommanderMetaCandidate candidate;
  final DateTime? promotedToMetaDecksAt;
}

class ExternalCommanderMetaPromotionIssue {
  const ExternalCommanderMetaPromotionIssue({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'message': message,
    };
  }
}

class ExternalCommanderMetaPromotionInsertPlan {
  const ExternalCommanderMetaPromotionInsertPlan({
    required this.format,
    required this.archetype,
    required this.commanderName,
    required this.partnerCommanderName,
    required this.shellLabel,
    required this.strategyArchetype,
    required this.sourceUrl,
    required this.cardList,
    required this.placement,
  });

  final String format;
  final String archetype;
  final String? commanderName;
  final String? partnerCommanderName;
  final String? shellLabel;
  final String? strategyArchetype;
  final String sourceUrl;
  final String cardList;
  final String? placement;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'format': format,
      'archetype': archetype,
      'commander_name': commanderName,
      'partner_commander_name': partnerCommanderName,
      'shell_label': shellLabel,
      'strategy_archetype': strategyArchetype,
      'source_url': sourceUrl,
      'card_list': cardList,
      'placement': placement,
    };
  }
}

class ExternalCommanderMetaPromotionResult {
  const ExternalCommanderMetaPromotionResult({
    required this.snapshot,
    required this.issues,
    this.insertPlan,
  });

  final ExternalCommanderMetaPromotionSnapshot snapshot;
  final List<ExternalCommanderMetaPromotionIssue> issues;
  final ExternalCommanderMetaPromotionInsertPlan? insertPlan;

  ExternalCommanderMetaCandidate get candidate => snapshot.candidate;

  bool get accepted => issues.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accepted': accepted,
      'candidate': candidate.toJson(),
      'card_count': candidate.cardCount,
      'promoted_to_meta_decks_at':
          snapshot.promotedToMetaDecksAt?.toUtc().toIso8601String(),
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      'planned_meta_deck': insertPlan?.toJson(),
    };
  }
}

class ExternalCommanderMetaPromotionPlan {
  const ExternalCommanderMetaPromotionPlan({
    required this.results,
  });

  final List<ExternalCommanderMetaPromotionResult> results;

  int get totalCount => results.length;

  int get acceptedCount => results.where((result) => result.accepted).length;

  int get blockedCount => totalCount - acceptedCount;

  List<ExternalCommanderMetaPromotionResult> get acceptedResults =>
      results.where((result) => result.accepted).toList(growable: false);
}

ExternalCommanderMetaPromotionPlan buildExternalCommanderMetaPromotionPlan(
  List<ExternalCommanderMetaPromotionSnapshot> snapshots, {
  Set<String> sourceUrlsAlreadyInMetaDecks = const <String>{},
  Set<String> deckFingerprintsAlreadyInMetaDecks = const <String>{},
}) {
  final occurrencesBySourceUrl = <String, int>{};
  final occurrencesByDeckFingerprint = <String, int>{};
  for (final snapshot in snapshots) {
    final sourceUrl = snapshot.candidate.sourceUrl;
    occurrencesBySourceUrl[sourceUrl] =
        (occurrencesBySourceUrl[sourceUrl] ?? 0) + 1;
    final deckFingerprint = buildMetaDeckCardListFingerprint(
      format: legacyCompetitiveCommanderFormatCode,
      cardList: snapshot.candidate.cardList,
    );
    occurrencesByDeckFingerprint[deckFingerprint] =
        (occurrencesByDeckFingerprint[deckFingerprint] ?? 0) + 1;
  }

  return ExternalCommanderMetaPromotionPlan(
    results: snapshots
        .map(
          (snapshot) => evaluateExternalCommanderMetaPromotionSnapshot(
            snapshot,
            sourceUrlOccurrencesInStage:
                occurrencesBySourceUrl[snapshot.candidate.sourceUrl] ?? 0,
            deckFingerprintOccurrencesInStage: occurrencesByDeckFingerprint[
                    buildMetaDeckCardListFingerprint(
                      format: legacyCompetitiveCommanderFormatCode,
                      cardList: snapshot.candidate.cardList,
                    )] ??
                0,
            sourceUrlAlreadyInMetaDecks: sourceUrlsAlreadyInMetaDecks
                .contains(snapshot.candidate.sourceUrl),
            deckFingerprintAlreadyInMetaDecks:
                deckFingerprintsAlreadyInMetaDecks.contains(
              buildMetaDeckCardListFingerprint(
                format: legacyCompetitiveCommanderFormatCode,
                cardList: snapshot.candidate.cardList,
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

ExternalCommanderMetaPromotionResult
    evaluateExternalCommanderMetaPromotionSnapshot(
  ExternalCommanderMetaPromotionSnapshot snapshot, {
  required int sourceUrlOccurrencesInStage,
  required int deckFingerprintOccurrencesInStage,
  required bool sourceUrlAlreadyInMetaDecks,
  required bool deckFingerprintAlreadyInMetaDecks,
}) {
  final candidate = snapshot.candidate;
  final issues = <ExternalCommanderMetaPromotionIssue>[];
  final promotionDeckProfile = _buildPromotionDeckProfile(candidate);

  if (snapshot.promotedToMetaDecksAt != null ||
      candidate.validationStatus == 'promoted') {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'already_promoted',
        message: 'Candidate ja foi promovido anteriormente para meta_decks.',
      ),
    );
  }

  if (candidate.validationStatus != externalCommanderMetaStagedValidationStatus) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'validation_status_not_staged',
        message:
            'Candidate precisa ter validation_status=staged. Valor atual: ${candidate.validationStatus}.',
      ),
    );
  }

  if (candidate.normalizedSubformat != 'competitive_commander') {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'invalid_subformat',
        message:
            'Promocao exige subformat=competitive_commander. Valor atual: ${candidate.normalizedSubformat ?? "(vazio)"}.',
      ),
    );
  }

  if (promotionDeckProfile.totalCards != 100) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'deck_total_not_100',
        message:
            'Promocao exige decklist completa de 100 cartas. Valor atual: ${promotionDeckProfile.totalCards}.',
      ),
    );
  }

  if (!externalCommanderMetaPromotionLegalStatuses
      .contains(candidate.legalStatus)) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'missing_or_invalid_legal_status',
        message:
            'Promocao exige legal_status em {valid, warning_reviewed}. Valor atual: ${candidate.legalStatus ?? "(vazio)"}.',
      ),
    );
  } else if (candidate.legalStatus !=
          externalCommanderMetaPromotionLegalStatusValid &&
      candidate.legalStatus !=
          externalCommanderMetaPromotionLegalStatusWarningReviewed) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'legal_status_not_promotable',
        message:
            'Promocao aceita apenas legal_status=valid ou warning_reviewed. Valor atual: ${candidate.legalStatus}.',
      ),
    );
  }

  if (candidate.isCommanderLegal != true) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'commander_legality_not_confirmed',
        message:
            'Promocao exige is_commander_legal=true. Valor atual: ${candidate.isCommanderLegal}.',
      ),
    );
  }

  if ((candidate.commanderName ?? '').trim().isEmpty) {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'missing_commander_name',
        message: 'Promocao exige commander_name presente.',
      ),
    );
  }

  if (!_isSourceAllowlisted(candidate)) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'source_not_allowlisted',
        message:
            'Promocao exige source allowlisted. Source atual: ${candidate.normalizedSourceName} ${candidate.sourceUrl}',
      ),
    );
  }

  if (!_hasResearchSourceChain(candidate.researchPayload)) {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'missing_source_chain',
        message: 'Promocao exige research_payload.source_chain presente.',
      ),
    );
  }

  if (!promotionDeckProfile.hasStagingAudit) {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'missing_staging_audit',
        message:
            'Promocao exige research_payload.staging_audit para auditoria do stage 2.',
      ),
    );
  }

  if (promotionDeckProfile.unresolvedCards.isNotEmpty) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'unresolved_cards_blocking',
        message:
            'Promocao bloqueada por unresolved_cards no staging_audit: ${promotionDeckProfile.unresolvedCards.length}.',
      ),
    );
  }

  if (promotionDeckProfile.illegalCards.isNotEmpty) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'illegal_cards_blocking',
        message:
            'Promocao bloqueada por illegal_cards no staging_audit: ${promotionDeckProfile.illegalCards.length}.',
      ),
    );
  }

  if (promotionDeckProfile.validationLegalStatus == 'illegal') {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'validation_legal_status_illegal',
        message:
            'Promocao exige staging_audit.validation_legal_status diferente de illegal.',
      ),
    );
  }

  if (sourceUrlOccurrencesInStage != 1) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'duplicate_source_url_in_stage',
        message:
            'Promocao exige source_url unico no staging. Ocorrencias atuais: $sourceUrlOccurrencesInStage.',
      ),
    );
  }

  if (deckFingerprintOccurrencesInStage != 1) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'duplicate_deck_fingerprint_in_stage',
        message:
            'Promocao exige fingerprint unico no staging. Ocorrencias atuais: $deckFingerprintOccurrencesInStage.',
      ),
    );
  }

  if (sourceUrlAlreadyInMetaDecks) {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'source_url_already_present_in_meta_decks',
        message:
            'Promocao exige source_url unico; esta URL ja existe em meta_decks.',
      ),
    );
  }

  if (deckFingerprintAlreadyInMetaDecks) {
    issues.add(
      const ExternalCommanderMetaPromotionIssue(
        code: 'deck_fingerprint_already_present_in_meta_decks',
        message:
            'Promocao exige fingerprint unico; esta decklist ja existe em meta_decks.',
      ),
    );
  }

  final targetFormat = candidate.metaDeckFormatCode;
  if (targetFormat != legacyCompetitiveCommanderFormatCode) {
    issues.add(
      ExternalCommanderMetaPromotionIssue(
        code: 'invalid_target_meta_deck_format',
        message:
            'Promocao atual suporta apenas competitive_commander -> cEDH. Target atual: ${targetFormat ?? "(vazio)"}.',
      ),
    );
  }

  if (issues.isNotEmpty) {
    return ExternalCommanderMetaPromotionResult(
      snapshot: snapshot,
      issues: issues,
    );
  }

  final rawArchetype = _firstNonBlank(
    candidate.archetype,
    candidate.deckName,
    candidate.commanderName,
  )!;
  final commanderShell = resolveCommanderShellMetadata(
    format: legacyCompetitiveCommanderFormatCode,
    cardList: candidate.cardList,
    rawArchetype: rawArchetype,
    commanderName: candidate.commanderName,
    partnerCommanderName: candidate.partnerCommanderName,
  );
  final shellLabel = _firstNonBlank(
    _buildCommanderShellLabel(
      commanderName: commanderShell.commanderName ?? candidate.commanderName,
      partnerCommanderName:
          commanderShell.partnerCommanderName ?? candidate.partnerCommanderName,
    ),
    commanderShell.shellLabel,
    rawArchetype,
  );

  return ExternalCommanderMetaPromotionResult(
    snapshot: snapshot,
    issues: issues,
    insertPlan: ExternalCommanderMetaPromotionInsertPlan(
      format: legacyCompetitiveCommanderFormatCode,
      archetype: rawArchetype,
      commanderName: commanderShell.commanderName,
      partnerCommanderName: commanderShell.partnerCommanderName,
      shellLabel: shellLabel,
      strategyArchetype: commanderShell.strategyArchetype,
      sourceUrl: candidate.sourceUrl,
      cardList: candidate.cardList,
      placement: candidate.placement,
    ),
  );
}

bool _hasResearchSourceChain(Map<String, dynamic> researchPayload) {
  final raw = researchPayload['source_chain'];
  if (raw is String) return raw.trim().isNotEmpty;
  if (raw is Iterable) {
    return raw.any((entry) => entry.toString().trim().isNotEmpty);
  }
  return false;
}

String? _firstNonBlank(String? a, String? b, String? c) {
  for (final value in <String?>[a, b, c]) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String? _buildCommanderShellLabel({
  String? commanderName,
  String? partnerCommanderName,
}) {
  final primary = commanderName?.trim();
  final partner = partnerCommanderName?.trim();
  if (primary == null || primary.isEmpty) return null;
  if (partner == null || partner.isEmpty) return primary;
  return '$primary + $partner';
}

String buildMetaDeckCardListFingerprint({
  required String format,
  required String cardList,
}) {
  final parsed = parseMetaDeckCardList(format: format, cardList: cardList);
  final entries = parsed.effectiveCards.entries.toList(growable: false)
    ..sort(
      (a, b) => normalizeMetaDeckCardName(a.key)
          .toLowerCase()
          .compareTo(normalizeMetaDeckCardName(b.key).toLowerCase()),
    );
  return entries
      .map(
        (entry) =>
            '${entry.value} ${normalizeMetaDeckCardName(entry.key).toLowerCase()}',
      )
      .join('|');
}

class _PromotionDeckProfile {
  const _PromotionDeckProfile({
    required this.totalCards,
    required this.unresolvedCards,
    required this.illegalCards,
    required this.validationLegalStatus,
    required this.hasStagingAudit,
  });

  final int totalCards;
  final List<dynamic> unresolvedCards;
  final List<dynamic> illegalCards;
  final String? validationLegalStatus;
  final bool hasStagingAudit;
}

_PromotionDeckProfile _buildPromotionDeckProfile(
  ExternalCommanderMetaCandidate candidate,
) {
  final parsed = parseMetaDeckCardList(
    format: legacyCompetitiveCommanderFormatCode,
    cardList: candidate.cardList,
  );
  final stagingAudit = candidate.researchPayload['staging_audit'];
  if (stagingAudit is! Map<String, dynamic>) {
    return _PromotionDeckProfile(
      totalCards: parsed.effectiveTotal,
      unresolvedCards: const <dynamic>[],
      illegalCards: const <dynamic>[],
      validationLegalStatus: null,
      hasStagingAudit: false,
    );
  }

  return _PromotionDeckProfile(
    totalCards: parsed.effectiveTotal,
    unresolvedCards: _readAuditList(stagingAudit['unresolved_cards']),
    illegalCards: _readAuditList(stagingAudit['illegal_cards']),
    validationLegalStatus:
        stagingAudit['validation_legal_status']?.toString().trim().toLowerCase(),
    hasStagingAudit: true,
  );
}

List<dynamic> _readAuditList(dynamic raw) {
  if (raw is List) {
    return raw;
  }
  return const <dynamic>[];
}

bool _isSourceAllowlisted(ExternalCommanderMetaCandidate candidate) {
  final sourceUri = Uri.tryParse(candidate.sourceUrl);
  final sourceHost =
      sourceUri?.host.toLowerCase().replaceFirst('www.', '') ?? '';
  final sourcePath = sourceUri?.path.toLowerCase() ?? '';
  final normalizedName = candidate.normalizedSourceName.toLowerCase();

  for (final policy in externalCommanderMetaControlledSourcePolicies) {
    final matchesName = policy.canonicalSourceName.toLowerCase() ==
            normalizedName ||
        policy.aliases.contains(normalizedName);
    final matchesHost = policy.allowedHosts.contains(sourceHost);
    if ((matchesName || matchesHost) &&
        sourcePath.startsWith(policy.requiredPathPrefix)) {
      return true;
    }
  }
  return false;
}
