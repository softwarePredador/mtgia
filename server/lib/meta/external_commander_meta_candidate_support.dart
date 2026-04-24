import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../import_card_lookup_service.dart';
import 'meta_deck_format_support.dart';

const externalCommanderMetaValidationStatuses = <String>{
  'candidate',
  'staged',
  'validated',
  'rejected',
  'promoted',
};
const externalCommanderMetaStagedValidationStatus = 'staged';

const genericExternalCommanderMetaValidationProfile = 'generic';
const topDeckEdhTop16Stage1ValidationProfile = 'topdeck_edhtop16_stage1';
const topDeckEdhTop16Stage2ValidationProfile = 'topdeck_edhtop16_stage2';

const externalCommanderMetaLegalStatusLegal = 'legal';
const externalCommanderMetaLegalStatusIllegal = 'illegal';
const externalCommanderMetaLegalStatusNotProven = 'not_proven';
const externalCommanderMetaPromotionLegalStatusValid = 'valid';
const externalCommanderMetaPromotionLegalStatusWarningReviewed =
    'warning_reviewed';
const externalCommanderMetaPromotionLegalStatuses = <String>{
  externalCommanderMetaPromotionLegalStatusValid,
  externalCommanderMetaPromotionLegalStatusWarningReviewed,
  'warning_pending',
  'rejected',
};

abstract class ExternalCommanderMetaCandidateLegalityRepository {
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
      List<String> names);

  Future<Map<String, String>> lookupCommanderLegalities(Set<String> cardIds);
}

class PostgresExternalCommanderMetaCandidateLegalityRepository
    implements ExternalCommanderMetaCandidateLegalityRepository {
  PostgresExternalCommanderMetaCandidateLegalityRepository(this._pool);

  final Pool _pool;

  @override
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<String> names,
  ) async {
    if (names.isEmpty) return const <String, Map<String, dynamic>>{};
    return resolveImportCardNames(
      _pool,
      [
        for (final name in names) <String, dynamic>{'name': name},
      ],
    );
  }

  @override
  Future<Map<String, String>> lookupCommanderLegalities(
      Set<String> cardIds) async {
    if (cardIds.isEmpty) return const <String, String>{};

    final result = await _pool.execute(
      Sql.named('''
        SELECT card_id::text, status
        FROM card_legalities
        WHERE format = 'commander'
          AND card_id::text = ANY(@card_ids)
      '''),
      parameters: <String, dynamic>{
        'card_ids': TypedValue(Type.textArray, cardIds.toList(growable: false)),
      },
    );

    final legalities = <String, String>{};
    for (final row in result) {
      final cardId = row[0] as String?;
      final status = row[1]?.toString().trim().toLowerCase();
      if (cardId == null ||
          cardId.isEmpty ||
          status == null ||
          status.isEmpty) {
        continue;
      }
      legalities[cardId] = status;
    }
    return legalities;
  }
}

class ExternalCommanderMetaControlledSourcePolicy {
  const ExternalCommanderMetaControlledSourcePolicy({
    required this.canonicalSourceName,
    required this.aliases,
    required this.allowedHosts,
    required this.requiredPathPrefix,
    required this.allowedSubformats,
  });

  final String canonicalSourceName;
  final Set<String> aliases;
  final Set<String> allowedHosts;
  final String requiredPathPrefix;
  final Set<String> allowedSubformats;
}

const externalCommanderMetaControlledSourcePolicies =
    <ExternalCommanderMetaControlledSourcePolicy>[
  ExternalCommanderMetaControlledSourcePolicy(
    canonicalSourceName: 'TopDeck.gg',
    aliases: <String>{'topdeck.gg', 'topdeck', 'topdeckgg'},
    allowedHosts: <String>{'topdeck.gg', 'www.topdeck.gg'},
    requiredPathPrefix: '/event/',
    allowedSubformats: <String>{'competitive_commander'},
  ),
  ExternalCommanderMetaControlledSourcePolicy(
    canonicalSourceName: 'EDHTop16',
    aliases: <String>{'edhtop16', 'edhtop16.com'},
    allowedHosts: <String>{'edhtop16.com', 'www.edhtop16.com'},
    requiredPathPrefix: '/tournament/',
    allowedSubformats: <String>{'competitive_commander'},
  ),
];

class ExternalCommanderMetaValidationIssue {
  const ExternalCommanderMetaValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
  });

  final String severity;
  final String code;
  final String message;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'severity': severity,
      'code': code,
      'message': message,
    };
  }
}

class ExternalCommanderMetaCandidateUnresolvedCard {
  const ExternalCommanderMetaCandidateUnresolvedCard({
    required this.name,
    required this.quantity,
    required this.role,
  });

  final String name;
  final int quantity;
  final String role;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'role': role,
    };
  }
}

class ExternalCommanderMetaCandidateIllegalCard {
  const ExternalCommanderMetaCandidateIllegalCard({
    required this.name,
    required this.quantity,
    required this.role,
    required this.resolvedName,
    required this.cardColorIdentity,
    required this.reasons,
    this.commanderLegalStatus,
  });

  final String name;
  final int quantity;
  final String role;
  final String resolvedName;
  final Set<String> cardColorIdentity;
  final List<String> reasons;
  final String? commanderLegalStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'role': role,
      'resolved_name': resolvedName,
      'card_color_identity': cardColorIdentity.toList()..sort(),
      'reasons': reasons,
      'commander_legal_status': commanderLegalStatus,
    };
  }
}

class ExternalCommanderMetaCandidateLegalityEvidence {
  const ExternalCommanderMetaCandidateLegalityEvidence({
    required this.commanderColorIdentity,
    required this.unresolvedCards,
    required this.illegalCards,
    required this.legalStatus,
  });

  final Set<String> commanderColorIdentity;
  final List<ExternalCommanderMetaCandidateUnresolvedCard> unresolvedCards;
  final List<ExternalCommanderMetaCandidateIllegalCard> illegalCards;
  final String legalStatus;
}

class ExternalCommanderMetaCandidateValidationResult {
  const ExternalCommanderMetaCandidateValidationResult({
    required this.candidate,
    required this.profile,
    required this.issues,
    this.legalityEvidence,
  });

  final ExternalCommanderMetaCandidate candidate;
  final String profile;
  final List<ExternalCommanderMetaValidationIssue> issues;
  final ExternalCommanderMetaCandidateLegalityEvidence? legalityEvidence;

  bool get accepted => !issues.any((issue) => issue.severity == 'error');

  ExternalCommanderMetaCandidateLegalityEvidence
      get effectiveLegalityEvidence =>
          _effectiveCandidateLegalityEvidence(candidate, legalityEvidence);

  Map<String, dynamic> toJson() {
    final evidence = effectiveLegalityEvidence;
    return <String, dynamic>{
      'accepted': accepted,
      'profile': profile,
      'candidate': candidate.toJson(),
      'card_count': candidate.cardCount,
      'commander_color_identity': evidence.commanderColorIdentity.toList()
        ..sort(),
      'unresolved_cards': evidence.unresolvedCards
          .map((card) => card.toJson())
          .toList(growable: false),
      'illegal_cards': evidence.illegalCards
          .map((card) => card.toJson())
          .toList(growable: false),
      'legal_status': evidence.legalStatus,
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
    };
  }
}

class ExternalCommanderMetaCandidate {
  ExternalCommanderMetaCandidate({
    required this.sourceName,
    required this.sourceUrl,
    required this.deckName,
    required this.cardList,
    required this.importedBy,
    this.sourceHost,
    this.commanderName,
    this.partnerCommanderName,
    this.format = 'commander',
    this.subformat,
    this.archetype,
    this.placement,
    Set<String>? colorIdentity,
    this.isCommanderLegal,
    this.validationStatus = 'candidate',
    this.legalStatus,
    this.validationNotes,
    Map<String, dynamic>? researchPayload,
  })  : colorIdentity = colorIdentity ?? <String>{},
        researchPayload = researchPayload ?? <String, dynamic>{};

  final String sourceName;
  final String? sourceHost;
  final String sourceUrl;
  final String deckName;
  final String? commanderName;
  final String? partnerCommanderName;
  final String format;
  final String? subformat;
  final String? archetype;
  final String cardList;
  final String? placement;
  final Set<String> colorIdentity;
  final bool? isCommanderLegal;
  final String validationStatus;
  final String? legalStatus;
  final String? validationNotes;
  final Map<String, dynamic> researchPayload;
  final String importedBy;

  String get normalizedSourceName =>
      canonicalizeExternalCommanderMetaSourceName(
        sourceName,
        sourceUrl: sourceUrl,
      );

  String? get normalizedSubformat =>
      normalizeCommanderMetaSubformat(subformat ?? format);

  int get cardCount =>
      cardList.split('\n').where((line) => line.trim().isNotEmpty).length;

  String? get metaDeckFormatCode {
    return legacyMetaDeckFormatCodeForCommanderSubformat(normalizedSubformat);
  }

  List<String> get commanderNames {
    final names = <String>[];
    final seen = <String>{};

    void addName(String? raw) {
      final normalized = raw?.trim();
      if (normalized == null || normalized.isEmpty) return;
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        names.add(normalized);
      }
    }

    addName(commanderName);
    for (final name
        in (partnerCommanderName ?? '').split(RegExp(r'\s*\+\s*'))) {
      addName(name);
    }

    return names;
  }

  bool get isPromotionEligible =>
      validationStatus == 'validated' &&
      metaDeckFormatCode != null &&
      cardList.trim().isNotEmpty;

  String get persistedFormat {
    final normalized = normalizeCommanderMetaFormat(format);
    if (normalized == 'cedh' ||
        normalized == 'edh' ||
        normalized == 'commander') {
      return 'commander';
    }
    return normalized;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source_name': normalizedSourceName,
      'source_host': sourceHost,
      'source_url': sourceUrl,
      'deck_name': deckName,
      'commander_name': commanderName,
      'partner_commander_name': partnerCommanderName,
      'format': persistedFormat,
      'subformat': normalizedSubformat,
      'archetype': archetype,
      'card_list': cardList,
      'placement': placement,
      'color_identity': colorIdentity.toList()..sort(),
      'is_commander_legal': isCommanderLegal,
      'validation_status': validationStatus,
      'legal_status': legalStatus,
      'validation_notes': validationNotes,
      'research_payload': researchPayload,
      'imported_by': importedBy,
    };
  }

  factory ExternalCommanderMetaCandidate.fromJson(
    Map<String, dynamic> json, {
    String importedBy = 'copilot_cli_web_agent',
  }) {
    final sourceUrl = _requireString(
      json,
      const ['source_url', 'url'],
      fieldName: 'source_url',
    );
    final sourceName = _firstNonEmptyString(
          json,
          const ['source_name', 'source'],
        ) ??
        Uri.tryParse(sourceUrl)?.host ??
        'unknown';
    final commanderName = _firstNonEmptyString(
      json,
      const ['commander_name', 'commander'],
    );
    final deckName = _firstNonEmptyString(
          json,
          const ['deck_name', 'name', 'title'],
        ) ??
        commanderName ??
        sourceName;
    final rawFormat = _firstNonEmptyString(
          json,
          const ['format'],
        ) ??
        'commander';
    final rawSubformat = _firstNonEmptyString(
          json,
          const ['subformat', 'queue', 'meta_format'],
        ) ??
        rawFormat;
    final researchPayload = _normalizeResearchPayload(json);

    return ExternalCommanderMetaCandidate(
      sourceName: sourceName,
      sourceHost: Uri.tryParse(sourceUrl)?.host,
      sourceUrl: sourceUrl,
      deckName: deckName,
      commanderName: commanderName,
      partnerCommanderName: _firstNonEmptyString(
        json,
        const [
          'partner_commander_name',
          'secondary_commander_name',
          'partner_commander',
        ],
      ),
      format: normalizeCommanderMetaFormat(rawFormat),
      subformat: normalizeCommanderMetaSubformat(rawSubformat),
      archetype: _firstNonEmptyString(json, const ['archetype']),
      cardList: _normalizeCardList(json),
      placement: _firstNonEmptyString(json, const ['placement', 'rank']),
      colorIdentity: _normalizeCandidateColorIdentity(json),
      isCommanderLegal: _normalizeNullableBool(
        json['is_commander_legal'] ?? json['commander_legal'],
      ),
      validationStatus: normalizeExternalCommanderMetaValidationStatus(
        _firstNonEmptyString(
              json,
              const ['validation_status', 'status'],
            ) ??
            'candidate',
      ),
      legalStatus: normalizeExternalCommanderMetaPromotionLegalStatus(
        _firstNonEmptyString(
              json,
              const ['legal_status', 'promotion_legal_status'],
            ) ??
            _firstNonEmptyString(
              researchPayload,
              const ['legal_status', 'promotion_legal_status'],
            ),
      ),
      validationNotes: _firstNonEmptyString(
        json,
        const ['validation_notes', 'notes'],
      ),
      researchPayload: researchPayload,
      importedBy: importedBy,
    );
  }
}

List<ExternalCommanderMetaCandidate> parseExternalCommanderMetaCandidates(
  String rawJson, {
  String importedBy = 'copilot_cli_web_agent',
}) {
  final decoded = jsonDecode(rawJson);
  final objects = switch (decoded) {
    List<dynamic> _ => decoded,
    Map<String, dynamic> _ when decoded['candidates'] is List<dynamic> =>
      decoded['candidates'] as List<dynamic>,
    Map<String, dynamic> _ => <dynamic>[decoded],
    _ => throw FormatException(
        'Payload deve ser objeto JSON, lista JSON, ou { "candidates": [...] }.',
      ),
  };

  return objects
      .whereType<Map<String, dynamic>>()
      .map(
        (candidate) => ExternalCommanderMetaCandidate.fromJson(
          candidate,
          importedBy: importedBy,
        ),
      )
      .toList(growable: false);
}

String normalizeCommanderMetaFormat(String? raw) {
  final normalized = (raw ?? 'commander').trim().toLowerCase();
  if (normalized.isEmpty) return 'commander';
  return switch (normalized) {
    'edh' || 'cedh' || 'commander' => 'commander',
    _ => normalized,
  };
}

String? normalizeCommanderMetaSubformat(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;

  return switch (normalized) {
    'duel_commander' || 'duel commander' || 'mtgtop8 edh' => 'duel_commander',
    'cedh' ||
    'competitive edh' ||
    'competitive commander' ||
    'competitive_commander' =>
      'competitive_commander',
    'commander' ||
    'edh' ||
    'multiplayer commander' ||
    'casual commander' =>
      'commander',
    _ => normalized,
  };
}

String normalizeExternalCommanderMetaValidationStatus(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (externalCommanderMetaValidationStatuses.contains(normalized)) {
    return normalized;
  }
  return 'candidate';
}

String? normalizeExternalCommanderMetaPromotionLegalStatus(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;

  return switch (normalized) {
    'valid' || 'validated' => externalCommanderMetaPromotionLegalStatusValid,
    'warning_reviewed' ||
    'warning reviewed' ||
    'reviewed_warning' =>
      externalCommanderMetaPromotionLegalStatusWarningReviewed,
    'warning_pending' ||
    'warning pending' ||
    'warning' ||
    'review_needed' =>
      'warning_pending',
    'rejected' || 'invalid' => 'rejected',
    _ => externalCommanderMetaPromotionLegalStatuses.contains(normalized)
        ? normalized
        : null,
  };
}

String canonicalizeExternalCommanderMetaSourceName(
  String? raw, {
  String? sourceUrl,
}) {
  final normalizedRaw = raw?.trim().toLowerCase();
  final sourceHost = _normalizeExternalCommanderMetaHost(
    Uri.tryParse(sourceUrl ?? '')?.host,
  );

  for (final policy in externalCommanderMetaControlledSourcePolicies) {
    if (policy.aliases.contains(normalizedRaw) ||
        policy.allowedHosts.contains(normalizedRaw) ||
        policy.allowedHosts.contains(sourceHost)) {
      return policy.canonicalSourceName;
    }
  }

  if (raw != null && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  if (sourceHost.isNotEmpty) {
    return sourceHost;
  }
  return 'unknown';
}

List<ExternalCommanderMetaCandidateValidationResult>
    validateExternalCommanderMetaCandidates(
  List<ExternalCommanderMetaCandidate> candidates, {
  String profile = genericExternalCommanderMetaValidationProfile,
  bool dryRun = false,
  Map<String, ExternalCommanderMetaCandidateLegalityEvidence> legalityBySourceUrl =
      const <String, ExternalCommanderMetaCandidateLegalityEvidence>{},
}) {
  return candidates
      .map(
        (candidate) => validateExternalCommanderMetaCandidate(
          candidate,
          profile: profile,
          dryRun: dryRun,
          legalityEvidence: legalityBySourceUrl[candidate.sourceUrl],
        ),
      )
      .toList(growable: false);
}

Future<Map<String, ExternalCommanderMetaCandidateLegalityEvidence>>
    evaluateExternalCommanderMetaCandidatesLegality(
  List<ExternalCommanderMetaCandidate> candidates, {
  required ExternalCommanderMetaCandidateLegalityRepository repository,
}) async {
  final results = <String, ExternalCommanderMetaCandidateLegalityEvidence>{};
  for (final candidate in candidates) {
    results[candidate.sourceUrl] =
        await evaluateExternalCommanderMetaCandidateLegality(
      candidate,
      repository: repository,
    );
  }
  return results;
}

Future<ExternalCommanderMetaCandidateLegalityEvidence>
    evaluateExternalCommanderMetaCandidateLegality(
  ExternalCommanderMetaCandidate candidate, {
  required ExternalCommanderMetaCandidateLegalityRepository repository,
}) async {
  final deckEntries = _parseCandidateCardList(candidate.cardList);
  final explicitDeckNames = deckEntries
      .map((entry) => entry.name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();
  final syntheticCommanderEntries = [
    for (final commanderName in candidate.commanderNames)
      if (!explicitDeckNames.contains(commanderName.trim().toLowerCase()))
        _ExternalCommanderMetaParsedCardEntry(
          name: commanderName,
          quantity: 1,
          role: 'commander',
        ),
  ];

  final lookupNames = <String>{
    for (final entry in deckEntries) entry.name,
    for (final entry in candidate.commanderNames) entry,
    for (final entry in syntheticCommanderEntries) entry.name,
  }.where((name) => name.trim().isNotEmpty).toList(growable: false);

  final resolvedCards = lookupNames.isEmpty
      ? const <String, Map<String, dynamic>>{}
      : await repository.resolveCardNames(lookupNames);

  final unresolvedByKey = <String, _ExternalCommanderMetaParsedCardEntry>{};
  final commanderColorIdentity = <String>{};
  var resolvedCommanderCount = 0;

  for (final commanderName in candidate.commanderNames) {
    final resolvedCard = _resolvedCardForName(commanderName, resolvedCards);
    if (resolvedCard == null) {
      _registerUnresolvedCard(
        unresolvedByKey,
        _ExternalCommanderMetaParsedCardEntry(
          name: commanderName,
          quantity: 1,
          role: 'commander',
        ),
      );
      continue;
    }

    resolvedCommanderCount++;
    commanderColorIdentity.addAll(_resolveIdentityFromCardRecord(resolvedCard));
  }

  if (commanderColorIdentity.isEmpty && candidate.colorIdentity.isNotEmpty) {
    commanderColorIdentity.addAll(candidate.colorIdentity);
  }

  final entriesToValidate = <_ExternalCommanderMetaParsedCardEntry>[
    ...deckEntries,
    ...syntheticCommanderEntries,
  ];
  final resolvedEntries = <_ResolvedExternalCommanderMetaCardEntry>[];
  final resolvedCardIds = <String>{};

  for (final entry in entriesToValidate) {
    final resolvedCard = _resolvedCardForName(entry.name, resolvedCards);
    if (resolvedCard == null) {
      _registerUnresolvedCard(unresolvedByKey, entry);
      continue;
    }

    final cardId = resolvedCard['id']?.toString();
    if (cardId != null && cardId.isNotEmpty) {
      resolvedCardIds.add(cardId);
    }
    resolvedEntries.add(
      _ResolvedExternalCommanderMetaCardEntry(entry: entry, card: resolvedCard),
    );
  }

  final legalities =
      await repository.lookupCommanderLegalities(resolvedCardIds);
  final illegalCards = <ExternalCommanderMetaCandidateIllegalCard>[];

  for (final resolvedEntry in resolvedEntries) {
    final card = resolvedEntry.card;
    final cardId = card['id']?.toString();
    final cardIdentity = _resolveIdentityFromCardRecord(card);
    final reasons = <String>[];

    if (commanderColorIdentity.isNotEmpty &&
        !isWithinCommanderIdentity(
          cardIdentity: cardIdentity,
          commanderIdentity: commanderColorIdentity,
        )) {
      reasons.add('outside_commander_identity');
    }

    final commanderLegalStatus =
        cardId == null ? null : legalities[cardId]?.trim().toLowerCase();
    if (!_isCommanderLegalStatusAllowed(commanderLegalStatus)) {
      reasons.add('not_legal_in_commander');
    }

    if (reasons.isEmpty) continue;

    illegalCards.add(
      ExternalCommanderMetaCandidateIllegalCard(
        name: resolvedEntry.entry.name,
        quantity: resolvedEntry.entry.quantity,
        role: resolvedEntry.entry.role,
        resolvedName: card['name']?.toString() ?? resolvedEntry.entry.name,
        cardColorIdentity: cardIdentity,
        reasons: reasons,
        commanderLegalStatus: commanderLegalStatus ?? 'missing',
      ),
    );
  }

  final unresolvedCards = unresolvedByKey.values
      .map(
        (entry) => ExternalCommanderMetaCandidateUnresolvedCard(
          name: entry.name,
          quantity: entry.quantity,
          role: entry.role,
        ),
      )
      .toList(growable: false);

  final legalStatus =
      candidate.isCommanderLegal == false || illegalCards.isNotEmpty
          ? externalCommanderMetaLegalStatusIllegal
          : unresolvedCards.isNotEmpty ||
                  (candidate.commanderNames.isNotEmpty &&
                      resolvedCommanderCount == 0 &&
                      candidate.colorIdentity.isEmpty)
              ? externalCommanderMetaLegalStatusNotProven
              : externalCommanderMetaLegalStatusLegal;

  return ExternalCommanderMetaCandidateLegalityEvidence(
    commanderColorIdentity: commanderColorIdentity,
    unresolvedCards: unresolvedCards,
    illegalCards: illegalCards,
    legalStatus: legalStatus,
  );
}

ExternalCommanderMetaCandidateValidationResult
    validateExternalCommanderMetaCandidate(
  ExternalCommanderMetaCandidate candidate, {
  String profile = genericExternalCommanderMetaValidationProfile,
  bool dryRun = false,
  ExternalCommanderMetaCandidateLegalityEvidence? legalityEvidence,
}) {
  final issues = <ExternalCommanderMetaValidationIssue>[];

  if (candidate.cardList.trim().isEmpty) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'missing_card_list',
        message: 'Candidate precisa de card_list nao vazio.',
      ),
    );
  }

  if (candidate.cardCount < 3) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'warning',
        code: 'small_card_list',
        message:
            'Card list curta (${candidate.cardCount} linhas). Dry-run schema valido, mas deck real ainda nao comprovado.',
      ),
    );
  }

  if (profile == topDeckEdhTop16Stage1ValidationProfile) {
    _applyTopDeckEdhTop16Stage1Validation(candidate, issues);
  } else if (profile == topDeckEdhTop16Stage2ValidationProfile) {
    _applyTopDeckEdhTop16Stage2Validation(candidate, issues);
  }

  _applyCommanderLegalityEvidence(
    candidate,
    issues,
    dryRun: dryRun,
    legalityEvidence: legalityEvidence,
  );

  return ExternalCommanderMetaCandidateValidationResult(
    candidate: candidate,
    profile: profile,
    issues: issues,
    legalityEvidence: legalityEvidence,
  );
}

void _applyTopDeckEdhTop16Stage1Validation(
  ExternalCommanderMetaCandidate candidate,
  List<ExternalCommanderMetaValidationIssue> issues,
) {
  final policy = _policyForCandidate(candidate);
  if (policy == null) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'unsupported_source',
        message:
            'Source ${candidate.normalizedSourceName} nao faz parte do plano controlado TopDeck.gg + EDHTop16.',
      ),
    );
    return;
  }

  final sourceUri = Uri.tryParse(candidate.sourceUrl);
  final sourceHost = _normalizeExternalCommanderMetaHost(sourceUri?.host);
  final sourcePath = sourceUri?.path.toLowerCase() ?? '';
  final normalizedSubformat = candidate.normalizedSubformat;

  if (candidate.validationStatus == 'promoted') {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'promotion_disabled',
        message:
            'Stage 1 aceita apenas dry-run/schema validation. Status promoted e proibido.',
      ),
    );
  }

  if (candidate.persistedFormat != 'commander') {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_format_family',
        message:
            'Formato persistido deve ser commander para ${policy.canonicalSourceName}.',
      ),
    );
  }

  if (!policy.allowedHosts.contains(sourceHost)) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'host_mismatch',
        message:
            'Host ${sourceHost.isEmpty ? "(vazio)" : sourceHost} nao permitido para ${policy.canonicalSourceName}.',
      ),
    );
  }

  if (!sourcePath.startsWith(policy.requiredPathPrefix)) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_source_path',
        message:
            'Source URL deve apontar para ${policy.requiredPathPrefix} em ${policy.canonicalSourceName}.',
      ),
    );
  }

  if (normalizedSubformat == null ||
      !policy.allowedSubformats.contains(normalizedSubformat)) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_subformat',
        message:
            'Subformato deve normalizar para ${policy.allowedSubformats.join(", ")} no stage 1.',
      ),
    );
  }

  if (candidate.isCommanderLegal == false) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'commander_illegal',
        message:
            'Candidate marcado como commander-ilegal nao entra no dry-run.',
      ),
    );
  }

  if (!_hasResearchPayloadValue(
      candidate.researchPayload, 'collection_method')) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'missing_collection_method',
        message:
            'research_payload.collection_method e obrigatorio no plano controlado.',
      ),
    );
  }

  if (!_hasResearchPayloadValue(candidate.researchPayload, 'source_context')) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'missing_source_context',
        message:
            'research_payload.source_context e obrigatorio no plano controlado.',
      ),
    );
  }

  if (candidate.colorIdentity.isEmpty) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'warning',
        code: 'missing_color_identity',
        message:
            'Color identity ausente. Dry-run ainda passa se o restante do schema estiver correto.',
      ),
    );
  }
}

void _applyTopDeckEdhTop16Stage2Validation(
  ExternalCommanderMetaCandidate candidate,
  List<ExternalCommanderMetaValidationIssue> issues,
) {
  _applyTopDeckEdhTop16Stage1Validation(candidate, issues);

  if (candidate.cardCount < 98) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'card_count_below_stage2_minimum',
        message:
            'Stage 2 exige decklist quase completa: card_count=${candidate.cardCount}, minimo=98.',
      ),
    );
  }

  final totalCards =
      _readResearchPayloadInt(candidate.researchPayload, 'total_cards');
  if (candidate.researchPayload.containsKey('total_cards') &&
      totalCards != 100) {
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_total_cards',
        message:
            'Stage 2 exige research_payload.total_cards=100 quando o campo existe. Valor atual: ${candidate.researchPayload['total_cards']}.',
      ),
    );
  }

  if ((candidate.commanderName ?? '').trim().isEmpty) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'missing_commander_name',
        message: 'Stage 2 exige commander_name presente.',
      ),
    );
  }

  if (candidate.persistedFormat != 'commander') {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_stage2_format',
        message: 'Stage 2 exige format=commander.',
      ),
    );
  }

  if (candidate.normalizedSubformat != 'competitive_commander') {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'invalid_stage2_subformat',
        message: 'Stage 2 exige subformat=competitive_commander.',
      ),
    );
  }
}

ExternalCommanderMetaControlledSourcePolicy? _policyForCandidate(
  ExternalCommanderMetaCandidate candidate,
) {
  final sourceHost = _normalizeExternalCommanderMetaHost(
    Uri.tryParse(candidate.sourceUrl)?.host,
  );
  final normalizedName = candidate.normalizedSourceName.trim().toLowerCase();

  for (final policy in externalCommanderMetaControlledSourcePolicies) {
    if (policy.allowedHosts.contains(sourceHost) ||
        policy.canonicalSourceName.toLowerCase() == normalizedName ||
        policy.aliases.contains(normalizedName)) {
      return policy;
    }
  }

  return null;
}

Set<String> _normalizeCandidateColorIdentity(Map<String, dynamic> json) {
  final raw = json['color_identity'] ??
      json['commander_color_identity'] ??
      json['colors'];
  if (raw is Iterable) {
    return normalizeColorIdentity(raw.whereType<String>());
  }
  if (raw is String) {
    return normalizeColorIdentity(<String>[raw]);
  }
  return <String>{};
}

Map<String, dynamic> _normalizeResearchPayload(Map<String, dynamic> json) {
  final raw = json['research_payload'];
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  final payload = <String, dynamic>{};
  for (final key in <String>[
    'source_context',
    'source_label',
    'reasoning',
    'notes',
    'tags',
    'web_sources',
  ]) {
    final value = json[key];
    if (value != null) {
      payload[key] = value;
    }
  }
  return payload;
}

String _normalizeCardList(Map<String, dynamic> json) {
  final direct = json['card_list'];
  final cards = json['cards'] ?? json['card_entries'];

  if (direct is String && direct.trim().isNotEmpty) {
    return direct.trim();
  }
  if (cards is List<dynamic>) {
    final lines = cards
        .map(_normalizeCardEntryLine)
        .whereType<String>()
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isNotEmpty) {
      return lines.join('\n');
    }
  }

  throw const FormatException(
    'Candidate precisa de "card_list" em texto ou "cards/card_entries" em lista.',
  );
}

String? _normalizeCardEntryLine(dynamic raw) {
  if (raw is String) {
    final line = raw.trim();
    return line.isEmpty ? null : line;
  }
  if (raw is Map<String, dynamic>) {
    final quantity = raw['quantity'] ?? raw['count'] ?? raw['qty'] ?? 1;
    final cardName = raw['name']?.toString().trim();
    if (cardName == null || cardName.isEmpty) return null;
    return '${int.tryParse(quantity.toString()) ?? 1} $cardName';
  }
  return null;
}

String _requireString(
  Map<String, dynamic> json,
  List<String> keys, {
  required String fieldName,
}) {
  final value = _firstNonEmptyString(json, keys);
  if (value == null) {
    throw FormatException('Campo obrigatório ausente: $fieldName');
  }
  return value;
}

String? _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final normalized = value.toString().trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

bool? _normalizeNullableBool(dynamic raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;

  final value = raw.toString().trim().toLowerCase();
  return switch (value) {
    'true' || '1' || 'yes' || 'y' => true,
    'false' || '0' || 'no' || 'n' => false,
    _ => null,
  };
}

String _normalizeExternalCommanderMetaHost(String? rawHost) {
  final host = rawHost?.trim().toLowerCase() ?? '';
  if (host.startsWith('www.')) {
    return host.substring(4);
  }
  return host;
}

bool _hasResearchPayloadValue(Map<String, dynamic> payload, String key) {
  final raw = payload[key];
  if (raw == null) return false;
  if (raw is String) return raw.trim().isNotEmpty;
  if (raw is Iterable) return raw.isNotEmpty;
  return true;
}

int? _readResearchPayloadInt(Map<String, dynamic> payload, String key) {
  final raw = payload[key];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString().trim() ?? '');
}

ExternalCommanderMetaCandidateLegalityEvidence
    _effectiveCandidateLegalityEvidence(
  ExternalCommanderMetaCandidate candidate,
  ExternalCommanderMetaCandidateLegalityEvidence? legalityEvidence,
) {
  if (legalityEvidence != null) return legalityEvidence;

  final fallbackStatus = switch (candidate.isCommanderLegal) {
    true => externalCommanderMetaLegalStatusLegal,
    false => externalCommanderMetaLegalStatusIllegal,
    null => externalCommanderMetaLegalStatusNotProven,
  };

  return ExternalCommanderMetaCandidateLegalityEvidence(
    commanderColorIdentity: candidate.colorIdentity,
    unresolvedCards: const <ExternalCommanderMetaCandidateUnresolvedCard>[],
    illegalCards: const <ExternalCommanderMetaCandidateIllegalCard>[],
    legalStatus: fallbackStatus,
  );
}

void _applyCommanderLegalityEvidence(
  ExternalCommanderMetaCandidate candidate,
  List<ExternalCommanderMetaValidationIssue> issues, {
  required bool dryRun,
  ExternalCommanderMetaCandidateLegalityEvidence? legalityEvidence,
}) {
  final evidence =
      _effectiveCandidateLegalityEvidence(candidate, legalityEvidence);

  if (candidate.isCommanderLegal == false &&
      !_hasValidationIssueCode(issues, 'commander_illegal')) {
    issues.add(
      const ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'commander_illegal',
        message:
            'Candidate marcado explicitamente como commander-ilegal foi bloqueado.',
      ),
    );
  }

  if (evidence.illegalCards.isNotEmpty &&
      !_hasValidationIssueCode(issues, 'illegal_cards')) {
    final sample = evidence.illegalCards
        .take(3)
        .map((card) => card.resolvedName)
        .join(', ');
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: 'error',
        code: 'illegal_cards',
        message:
            'Cartas resolvidas fora da identidade/legalidade Commander: $sample'
            '${evidence.illegalCards.length > 3 ? '...' : ''}.',
      ),
    );
  }

  if (evidence.unresolvedCards.isNotEmpty &&
      !_hasValidationIssueCode(issues, 'unresolved_cards')) {
    final sample =
        evidence.unresolvedCards.take(3).map((card) => card.name).join(', ');
    issues.add(
      ExternalCommanderMetaValidationIssue(
        severity: dryRun ? 'warning' : 'error',
        code: 'unresolved_cards',
        message:
            'Nao foi possivel resolver ${evidence.unresolvedCards.length} carta(s) '
            'em cards: $sample${evidence.unresolvedCards.length > 3 ? '...' : ''}.',
      ),
    );
  }
}

bool _hasValidationIssueCode(
  List<ExternalCommanderMetaValidationIssue> issues,
  String code,
) {
  return issues.any((issue) => issue.code == code);
}

List<_ExternalCommanderMetaParsedCardEntry> _parseCandidateCardList(
  String cardList,
) {
  final entries = <_ExternalCommanderMetaParsedCardEntry>[];

  for (final rawLine in cardList.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
    final quantity = int.tryParse(match?.group(1) ?? '') ?? 1;
    final name = (match?.group(2) ?? line).trim();
    if (name.isEmpty || quantity <= 0) continue;

    entries.add(
      _ExternalCommanderMetaParsedCardEntry(
        name: name,
        quantity: quantity,
        role: 'deck',
      ),
    );
  }

  return entries;
}

Map<String, dynamic>? _resolvedCardForName(
  String name,
  Map<String, Map<String, dynamic>> foundCardsMap,
) {
  final originalKey = name.trim().toLowerCase();
  final cleanedKey = cleanImportLookupKey(originalKey);
  if (foundCardsMap.containsKey(originalKey)) {
    return foundCardsMap[originalKey];
  }
  return foundCardsMap[cleanedKey];
}

Set<String> _resolveIdentityFromCardRecord(Map<String, dynamic> card) {
  return resolveCardColorIdentity(
    colorIdentity: _iterableOfStrings(card['color_identity']),
    colors: _iterableOfStrings(card['colors']),
    oracleText: card['oracle_text']?.toString(),
  );
}

Iterable<String> _iterableOfStrings(dynamic raw) {
  if (raw == null) return const <String>[];
  if (raw is Iterable) {
    return raw.map((value) => value.toString());
  }
  return <String>[raw.toString()];
}

bool _isCommanderLegalStatusAllowed(String? status) {
  if (status == null || status.isEmpty || status == 'missing') {
    return true;
  }
  return status == 'legal' || status == 'restricted';
}

void _registerUnresolvedCard(
  Map<String, _ExternalCommanderMetaParsedCardEntry> unresolvedByKey,
  _ExternalCommanderMetaParsedCardEntry entry,
) {
  final key = '${entry.role}:${entry.name.toLowerCase()}';
  final existing = unresolvedByKey[key];
  if (existing == null) {
    unresolvedByKey[key] = entry;
    return;
  }

  unresolvedByKey[key] = _ExternalCommanderMetaParsedCardEntry(
    name: existing.name,
    quantity: existing.quantity + entry.quantity,
    role: existing.role,
  );
}

class _ExternalCommanderMetaParsedCardEntry {
  const _ExternalCommanderMetaParsedCardEntry({
    required this.name,
    required this.quantity,
    required this.role,
  });

  final String name;
  final int quantity;
  final String role;
}

class _ResolvedExternalCommanderMetaCardEntry {
  const _ResolvedExternalCommanderMetaCardEntry({
    required this.entry,
    required this.card,
  });

  final _ExternalCommanderMetaParsedCardEntry entry;
  final Map<String, dynamic> card;
}
