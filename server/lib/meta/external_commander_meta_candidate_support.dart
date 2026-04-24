import 'dart:convert';

import '../color_identity.dart';
import 'meta_deck_format_support.dart';

const externalCommanderMetaValidationStatuses = <String>{
  'candidate',
  'validated',
  'rejected',
  'promoted',
};

const genericExternalCommanderMetaValidationProfile = 'generic';
const topDeckEdhTop16Stage1ValidationProfile = 'topdeck_edhtop16_stage1';
const topDeckEdhTop16Stage2ValidationProfile = 'topdeck_edhtop16_stage2';

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

class ExternalCommanderMetaCandidateValidationResult {
  const ExternalCommanderMetaCandidateValidationResult({
    required this.candidate,
    required this.profile,
    required this.issues,
  });

  final ExternalCommanderMetaCandidate candidate;
  final String profile;
  final List<ExternalCommanderMetaValidationIssue> issues;

  bool get accepted => !issues.any((issue) => issue.severity == 'error');

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accepted': accepted,
      'profile': profile,
      'candidate': candidate.toJson(),
      'card_count': candidate.cardCount,
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
      validationNotes: _firstNonEmptyString(
        json,
        const ['validation_notes', 'notes'],
      ),
      researchPayload: _normalizeResearchPayload(json),
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
}) {
  return candidates
      .map(
        (candidate) => validateExternalCommanderMetaCandidate(
          candidate,
          profile: profile,
        ),
      )
      .toList(growable: false);
}

ExternalCommanderMetaCandidateValidationResult
    validateExternalCommanderMetaCandidate(
  ExternalCommanderMetaCandidate candidate, {
  String profile = genericExternalCommanderMetaValidationProfile,
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

  return ExternalCommanderMetaCandidateValidationResult(
    candidate: candidate,
    profile: profile,
    issues: issues,
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
