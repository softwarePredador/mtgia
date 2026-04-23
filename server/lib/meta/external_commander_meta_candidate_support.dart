import 'dart:convert';

import '../color_identity.dart';

const externalCommanderMetaValidationStatuses = <String>{
  'candidate',
  'validated',
  'rejected',
  'promoted',
};

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

  String? get normalizedSubformat =>
      normalizeCommanderMetaSubformat(subformat ?? format);

  String? get metaDeckFormatCode {
    return switch (normalizedSubformat) {
      'cedh' => 'cEDH',
      'edh' || 'commander' => 'EDH',
      _ => null,
    };
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
      'source_name': sourceName,
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
    'commander' => 'edh',
    'edh' || 'duel commander' || 'casual commander' => 'edh',
    'cedh' || 'competitive edh' || 'competitive commander' => 'cedh',
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
