import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'meta_deck_analytics_support.dart';
import 'meta_deck_card_list_support.dart';
import 'meta_deck_format_support.dart';

class MetaDeckReferenceCandidate {
  const MetaDeckReferenceCandidate({
    required this.format,
    required this.archetype,
    required this.commanderName,
    required this.partnerCommanderName,
    required this.shellLabel,
    required this.strategyArchetype,
    required this.sourceUrl,
    required this.cardList,
    required this.placement,
    required this.createdAt,
    required this.sourceName,
    required this.sourceHost,
    required this.sourceChain,
    this.researchPayload = const <String, dynamic>{},
  });

  final String format;
  final String archetype;
  final String commanderName;
  final String partnerCommanderName;
  final String shellLabel;
  final String strategyArchetype;
  final String sourceUrl;
  final String cardList;
  final String placement;
  final DateTime? createdAt;
  final String sourceName;
  final String sourceHost;
  final List<String> sourceChain;
  final Map<String, dynamic> researchPayload;

  MetaDeckFormatDescriptor get formatDescriptor =>
      describeMetaDeckFormat(format);

  String get sourceKind => classifyMetaDeckSource(sourceUrl);

  String? get commanderSubformat => formatDescriptor.commanderSubformat;

  bool get isExternalSource => sourceKind == metaDeckSourceExternal;

  String get sourceLabel {
    final direct = sourceName.trim();
    if (direct.isNotEmpty) return direct;
    if (sourceKind == metaDeckSourceMtgTop8) return 'MTGTop8';
    return 'External';
  }

  List<String> get effectiveSourceChain {
    if (sourceChain.isNotEmpty) return sourceChain;
    if (sourceKind == metaDeckSourceMtgTop8) {
      return const <String>[
        'mtgtop8_format_page',
        'mtgtop8_event',
        'mtgtop8_deck_page',
      ];
    }
    return const <String>['external_source', 'promoted_meta_deck'];
  }

  String get sourceChainSummary =>
      effectiveSourceChain.map(_humanizeSourceChainToken).join(' -> ');

  String? get collectionMethod =>
      _readResearchPayloadString(researchPayload, 'collection_method');

  String? get sourceContext =>
      _readResearchPayloadString(researchPayload, 'source_context');

  String? get playerName =>
      _readResearchPayloadString(researchPayload, 'player_name');

  int? get standing =>
      _readResearchPayloadInt(researchPayload, 'standing') ??
      _parsePlacementRank(placement);

  List<String> get commanders => <String>[
        if (commanderName.trim().isNotEmpty) commanderName.trim(),
        if (partnerCommanderName.trim().isNotEmpty) partnerCommanderName.trim(),
      ];

  String? get eventId {
    final fromPayload =
        _readResearchPayloadString(researchPayload, 'tournament_id') ??
            _readResearchPayloadString(researchPayload, 'event_id') ??
            _readResearchPayloadString(researchPayload, 'event_tid');
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;

    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return null;

    final segments =
        uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
    final tournamentIndex = segments.indexOf('tournament');
    if (tournamentIndex >= 0 && tournamentIndex + 1 < segments.length) {
      return segments[tournamentIndex + 1].trim();
    }

    final eventQuery = uri.queryParameters['e'];
    if (eventQuery != null && eventQuery.trim().isNotEmpty) {
      return 'event-${eventQuery.trim()}';
    }

    if (segments.isNotEmpty &&
        segments.first == 'deck' &&
        segments.length > 1) {
      return segments[1].trim();
    }

    return null;
  }

  String? get eventLabel {
    final rawLabel = _readResearchPayloadString(researchPayload, 'event_name');
    if (rawLabel != null && rawLabel.isNotEmpty) return rawLabel;
    final id = eventId;
    if (id == null || id.isEmpty) return null;
    return _humanizeEventIdentifier(id);
  }

  String get bestShellLabel {
    final shell = shellLabel.trim();
    if (shell.isNotEmpty) return shell;
    final primary = commanderName.trim();
    final partner = partnerCommanderName.trim();
    if (primary.isEmpty) return archetype.trim();
    if (partner.isEmpty) return primary;
    return '$primary + $partner';
  }

  Set<String> get commanderSet => {
        if (commanderName.trim().isNotEmpty)
          _normalizeMetaDeckText(commanderName),
        if (partnerCommanderName.trim().isNotEmpty)
          _normalizeMetaDeckText(partnerCommanderName),
      };

  factory MetaDeckReferenceCandidate.fromDatabaseRow(ResultRow row) {
    return MetaDeckReferenceCandidate(
      format: (row[0] as String?) ?? '',
      archetype: (row[1] as String?) ?? '',
      commanderName: (row[2] as String?) ?? '',
      partnerCommanderName: (row[3] as String?) ?? '',
      shellLabel: (row[4] as String?) ?? '',
      strategyArchetype: (row[5] as String?) ?? '',
      sourceUrl: (row[6] as String?) ?? '',
      cardList: (row[7] as String?) ?? '',
      placement: (row[8] as String?) ?? '',
      createdAt: row[9] as DateTime?,
      sourceName: (row[10] as String?) ?? '',
      sourceHost: (row[11] as String?) ?? '',
      sourceChain: _decodeSourceChain(row[12]),
      researchPayload: _decodeResearchPayload(row[12]),
    );
  }
}

class MetaDeckReferenceSelectionResult {
  const MetaDeckReferenceSelectionResult({
    required this.commanderScope,
    required this.selectionReason,
    required this.references,
    required this.priorityCardNames,
    required this.sourceBreakdown,
  });

  final String? commanderScope;
  final String selectionReason;
  final List<MetaDeckReferenceCandidate> references;
  final List<String> priorityCardNames;
  final Map<String, int> sourceBreakdown;

  bool get hasReferences => references.isNotEmpty;

  String get optimizePrioritySource {
    if (!hasReferences) return 'none';
    final scopePrefix = switch (normalizeCommanderMetaScope(
      commanderScope,
      fallback: 'competitive_commander',
    )) {
      'duel_commander' => 'duel_meta',
      'competitive_commander' => 'competitive_meta',
      _ => 'meta_decks',
    };
    return '${scopePrefix}_$selectionReason';
  }
}

class MetaDeckReferenceQueryParts {
  const MetaDeckReferenceQueryParts({
    required this.filters,
    required this.parameters,
  });

  final List<String> filters;
  final Map<String, dynamic> parameters;

  bool get hasFilters => filters.isNotEmpty;
}

MetaDeckReferenceQueryParts buildMetaDeckReferenceQueryParts({
  required List<String> formatCodes,
  List<String> commanderNames = const <String>[],
  List<String> keywordPatterns = const <String>[],
  required int limit,
}) {
  if (formatCodes.isEmpty || limit <= 0) {
    return const MetaDeckReferenceQueryParts(
      filters: <String>[],
      parameters: <String, dynamic>{},
    );
  }

  final normalizedCommanders = commanderNames
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final commanderLikePatterns = normalizedCommanders
      .map((name) => '%${name.replaceAll('%', '')}%')
      .toList(growable: false);
  final normalizedKeywordPatterns = keywordPatterns
      .map((pattern) => pattern.trim().toLowerCase())
      .where((pattern) => pattern.isNotEmpty)
      .toSet()
      .map((pattern) => '%${pattern.replaceAll('%', '')}%')
      .toList(growable: false);

  final filters = <String>[];
  final parameters = <String, dynamic>{
    'formats': TypedValue(Type.textArray, formatCodes),
    'limit': limit,
  };

  if (normalizedCommanders.isNotEmpty) {
    filters.addAll(const <String>[
      'LOWER(COALESCE(md.commander_name, \'\')) = ANY(@commander_names)',
      'LOWER(COALESCE(md.partner_commander_name, \'\')) = ANY(@commander_names)',
      'LOWER(COALESCE(md.shell_label, \'\')) LIKE ANY(@commander_like_patterns)',
      'LOWER(COALESCE(md.card_list, \'\')) LIKE ANY(@commander_like_patterns)',
    ]);
    parameters['commander_names'] =
        TypedValue(Type.textArray, normalizedCommanders);
    parameters['commander_like_patterns'] =
        TypedValue(Type.textArray, commanderLikePatterns);
  }

  if (normalizedKeywordPatterns.isNotEmpty) {
    filters.addAll(const <String>[
      'LOWER(COALESCE(md.archetype, \'\')) LIKE ANY(@keyword_patterns)',
      'LOWER(COALESCE(md.shell_label, \'\')) LIKE ANY(@keyword_patterns)',
      'LOWER(COALESCE(md.strategy_archetype, \'\')) LIKE ANY(@keyword_patterns)',
      'LOWER(COALESCE(md.commander_name, \'\')) LIKE ANY(@keyword_patterns)',
      'LOWER(COALESCE(md.partner_commander_name, \'\')) LIKE ANY(@keyword_patterns)',
    ]);
    parameters['keyword_patterns'] =
        TypedValue(Type.textArray, normalizedKeywordPatterns);
  }

  return MetaDeckReferenceQueryParts(
    filters: filters,
    parameters: parameters,
  );
}

Future<List<MetaDeckReferenceCandidate>> queryMetaDeckReferenceCandidates({
  required Pool pool,
  required List<String> formatCodes,
  List<String> commanderNames = const <String>[],
  List<String> keywordPatterns = const <String>[],
  int limit = 250,
}) async {
  final queryParts = buildMetaDeckReferenceQueryParts(
    formatCodes: formatCodes,
    commanderNames: commanderNames,
    keywordPatterns: keywordPatterns,
    limit: limit,
  );
  if (!queryParts.hasFilters) return const <MetaDeckReferenceCandidate>[];

  final rows = await pool.execute(
    Sql.named('''
      SELECT
        md.format,
        md.archetype,
        md.commander_name,
        md.partner_commander_name,
        md.shell_label,
        md.strategy_archetype,
        md.source_url,
        md.card_list,
        md.placement,
        md.created_at,
        COALESCE(
          ecmc.source_name,
          CASE
            WHEN md.source_url ILIKE 'https://www.mtgtop8.com/%' THEN 'MTGTop8'
            ELSE 'External'
          END
        ) AS source_name,
        COALESCE(ecmc.source_host, '') AS source_host,
        CAST(COALESCE(ecmc.research_payload, '{}'::jsonb) AS text) AS research_payload
      FROM meta_decks md
      LEFT JOIN external_commander_meta_candidates ecmc
        ON ecmc.source_url = md.source_url
      WHERE md.format = ANY(@formats)
        AND (${queryParts.filters.join(' OR ')})
      ORDER BY md.created_at DESC NULLS LAST, md.source_url ASC
      LIMIT @limit
    '''),
    parameters: queryParts.parameters,
  );

  return rows
      .map(MetaDeckReferenceCandidate.fromDatabaseRow)
      .where((candidate) => candidate.cardList.trim().isNotEmpty)
      .toList(growable: false);
}

MetaDeckReferenceSelectionResult selectMetaDeckReferenceCandidates({
  required Iterable<MetaDeckReferenceCandidate> candidates,
  List<String> commanderNames = const <String>[],
  List<String> keywordPatterns = const <String>[],
  String? commanderScope,
  int deckLimit = 4,
  int priorityCardLimit = 120,
  bool preferExternalCompetitive = false,
}) {
  if (deckLimit <= 0 || priorityCardLimit <= 0) {
    return MetaDeckReferenceSelectionResult(
      commanderScope: commanderScope,
      selectionReason: 'no_match',
      references: const <MetaDeckReferenceCandidate>[],
      priorityCardNames: const <String>[],
      sourceBreakdown: const <String, int>{},
    );
  }

  final normalizedCommanders = commanderNames
      .map(_normalizeMetaDeckText)
      .where((name) => name.isNotEmpty)
      .toSet();
  final normalizedKeywords = keywordPatterns
      .map(_normalizeMetaDeckText)
      .where((pattern) => pattern.isNotEmpty)
      .toSet();
  final normalizedScope = commanderScope == null
      ? null
      : normalizeCommanderMetaScope(commanderScope, fallback: commanderScope);

  final ranked = <_RankedMetaDeckReference>[];
  for (final candidate in candidates) {
    if (normalizedScope != null &&
        candidate.commanderSubformat != null &&
        candidate.commanderSubformat != normalizedScope) {
      continue;
    }

    final ranking = _rankMetaDeckReferenceCandidate(
      candidate: candidate,
      normalizedCommanders: normalizedCommanders,
      normalizedKeywords: normalizedKeywords,
      preferExternalCompetitive: preferExternalCompetitive,
    );
    if (ranking == null) continue;
    ranked.add(ranking);
  }

  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final aTime = a.candidate.createdAt?.millisecondsSinceEpoch ??
        DateTime(1970).millisecondsSinceEpoch;
    final bTime = b.candidate.createdAt?.millisecondsSinceEpoch ??
        DateTime(1970).millisecondsSinceEpoch;
    final byTime = bTime.compareTo(aTime);
    if (byTime != 0) return byTime;
    return a.candidate.sourceUrl.compareTo(b.candidate.sourceUrl);
  });

  final selected = <MetaDeckReferenceCandidate>[];
  final seenSourceUrls = <String>{};
  for (final entry in ranked) {
    if (!seenSourceUrls.add(entry.candidate.sourceUrl)) continue;
    selected.add(entry.candidate);
    if (selected.length >= deckLimit) break;
  }

  final priorityCards = _buildPriorityCardNames(
    selected,
    requestedCommanders: normalizedCommanders,
    limit: priorityCardLimit,
  );
  final sourceBreakdown = <String, int>{};
  for (final candidate in selected) {
    sourceBreakdown[candidate.sourceKind] =
        (sourceBreakdown[candidate.sourceKind] ?? 0) + 1;
  }

  final selectionReason =
      ranked.isEmpty ? 'no_match' : ranked.first.selectionReason;

  return MetaDeckReferenceSelectionResult(
    commanderScope: commanderScope,
    selectionReason: selectionReason,
    references: selected,
    priorityCardNames: priorityCards,
    sourceBreakdown: sourceBreakdown,
  );
}

Map<String, dynamic> buildMetaDeckEvidencePayload(
  MetaDeckReferenceSelectionResult selection, {
  int maxPriorityCards = 16,
  int maxReferences = 4,
}) {
  if (!selection.hasReferences) return const <String, dynamic>{};

  return <String, dynamic>{
    'meta_scope': <String, dynamic>{
      'key': selection.commanderScope,
      'label': selection.commanderScope == null
          ? 'Format meta'
          : commanderMetaScopeLabel(selection.commanderScope),
    },
    'selection_reason_code': selection.selectionReason,
    'selection_reason': _selectionReasonLabel(selection.selectionReason),
    'priority_source': selection.optimizePrioritySource,
    'source_chain_note':
        'source_chain is provenance metadata that explains how each reference list was observed in the ingestion pipeline; use it as evidence, not as a gameplay instruction.',
    'source_summary': selection.sourceBreakdown,
    'priority_cards': selection.priorityCardNames
        .take(maxPriorityCards)
        .toList(growable: false),
    'influenced_cards': _buildInfluencedCardPayload(
      selection.references,
      limit: maxPriorityCards,
    ),
    'references': <Map<String, dynamic>>[
      for (final indexed in selection.references.take(maxReferences).indexed)
        <String, dynamic>{
          'selection_rank': indexed.$1 + 1,
          'shell_label': indexed.$2.bestShellLabel,
          'commanders': indexed.$2.commanders,
          if (indexed.$2.strategyArchetype.trim().isNotEmpty)
            'strategy_archetype': indexed.$2.strategyArchetype.trim(),
          if (indexed.$2.placement.trim().isNotEmpty)
            'placement': indexed.$2.placement.trim(),
          if (indexed.$2.standing != null) 'standing': indexed.$2.standing,
          'meta_scope': indexed.$2.commanderSubformat == null
              ? indexed.$2.formatDescriptor.label
              : commanderMetaScopeLabel(indexed.$2.commanderSubformat),
          'source': indexed.$2.sourceLabel,
          'source_kind': indexed.$2.sourceKind,
          if (indexed.$2.sourceHost.trim().isNotEmpty)
            'source_host': indexed.$2.sourceHost.trim(),
          'source_chain': indexed.$2.sourceChainSummary,
          'provenance': <String, dynamic>{
            if (indexed.$2.collectionMethod != null)
              'collection_method': indexed.$2.collectionMethod,
            if (indexed.$2.sourceContext != null)
              'source_context': indexed.$2.sourceContext,
            'source_chain_tokens': indexed.$2.effectiveSourceChain,
          },
          if (indexed.$2.eventId != null || indexed.$2.eventLabel != null)
            'event': <String, dynamic>{
              if (indexed.$2.eventId != null) 'id': indexed.$2.eventId,
              if (indexed.$2.eventLabel != null) 'label': indexed.$2.eventLabel,
            },
          if (indexed.$2.playerName != null)
            'player_name': indexed.$2.playerName,
        },
    ],
  };
}

Map<String, dynamic> augmentMetaDeckEvidencePayloadWithOutputMatches(
  Map<String, dynamic> payload, {
  required Iterable<String> outputCardNames,
  int maxMatches = 12,
}) {
  if (payload.isEmpty) return const <String, dynamic>{};

  final matchesByLower = <String, Map<String, dynamic>>{};
  final influencedCards =
      (payload['influenced_cards'] as List?)?.whereType<Map>().map((entry) {
            final normalized = entry.cast<String, dynamic>();
            final name =
                _normalizeMetaDeckText(normalized['name']?.toString() ?? '');
            if (name.isNotEmpty) {
              matchesByLower[name] = normalized;
            }
            return normalized;
          }).toList(growable: false) ??
          const <Map<String, dynamic>>[];
  if (influencedCards.isEmpty) return Map<String, dynamic>.from(payload);

  final matched = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final rawName in outputCardNames) {
    final name = rawName.trim();
    if (name.isEmpty) continue;
    final normalized = _normalizeMetaDeckText(name);
    if (!seen.add(normalized)) continue;
    final influence = matchesByLower[normalized];
    if (influence == null) continue;
    matched.add(<String, dynamic>{
      'name': influence['name'] ?? name,
      'reference_count': influence['reference_count'],
      if (influence['copy_count'] != null)
        'copy_count': influence['copy_count'],
      if (influence['shells'] is List) 'shells': influence['shells'],
      'reason': 'Returned output also appears in the selected meta references.',
    });
    if (matched.length >= maxMatches) break;
  }

  final normalizedPayload = Map<String, dynamic>.from(payload);
  normalizedPayload['suggested_cards_influenced'] = matched;
  return normalizedPayload;
}

String buildMetaDeckEvidenceText(
  MetaDeckReferenceSelectionResult selection, {
  int maxPriorityCards = 16,
  int maxReferences = 4,
}) {
  final payload = buildMetaDeckEvidencePayload(
    selection,
    maxPriorityCards: maxPriorityCards,
    maxReferences: maxReferences,
  );
  if (payload.isEmpty) return '';

  final scopePayload = (payload['meta_scope'] as Map).cast<String, dynamic>();
  final references =
      (payload['references'] as List).whereType<Map>().map((entry) {
    return entry.cast<String, dynamic>();
  }).toList(growable: false);
  final priorityCards =
      (payload['priority_cards'] as List).map((entry) => '$entry').toList();
  final outputMatches = (payload['suggested_cards_influenced'] as List?)
          ?.whereType<Map>()
          .map((entry) => entry['name']?.toString() ?? '')
          .where((entry) => entry.trim().isNotEmpty)
          .toList(growable: false) ??
      const <String>[];
  final sourceSummary =
      (payload['source_summary'] as Map).cast<String, dynamic>();

  final buffer = StringBuffer()
    ..writeln('Meta evidence:')
    ..writeln('- Scope: ${scopePayload['label']}.')
    ..writeln('- Selection reason: ${payload['selection_reason']}.')
    ..writeln('- source_chain note: ${payload['source_chain_note']}');

  if (sourceSummary.isNotEmpty) {
    final parts = sourceSummary.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    buffer.writeln('- Source mix: $parts.');
  }

  if (priorityCards.isNotEmpty) {
    buffer.writeln(
      '- Repeated priority cards from selected references: ${priorityCards.join(', ')}.',
    );
  }

  if (outputMatches.isNotEmpty) {
    buffer.writeln(
      '- Suggested output aligned with selected references: ${outputMatches.join(', ')}.',
    );
  }

  if (references.isNotEmpty) {
    buffer.writeln('- Reference snapshots:');
    for (final reference in references) {
      final shell = reference['shell_label']?.toString() ?? 'unknown shell';
      final strategy = reference['strategy_archetype']?.toString();
      final placement = reference['placement']?.toString();
      final scope = reference['meta_scope']?.toString() ?? 'meta';
      final source = reference['source']?.toString() ?? 'source';
      final chain =
          reference['source_chain']?.toString() ?? 'unknown provenance';

      final summary = <String>[
        shell,
        if (strategy != null && strategy.isNotEmpty) 'plan=$strategy',
        'scope=$scope',
        if (placement != null && placement.isNotEmpty) 'placement=$placement',
        'evidence=$source via $chain',
      ].join(' | ');
      buffer.writeln('  - $summary');
    }
  }

  return buffer.toString().trimRight();
}

String _selectionReasonLabel(String code) {
  return switch (code) {
    'exact_shell_match' => 'exact commander shell match',
    'commander_shell_match' => 'commander shell compatible match',
    'commander_match' => 'commander-compatible meta match',
    'keyword_meta_match' => 'keyword-driven meta match',
    _ => 'no qualified meta match',
  };
}

_RankedMetaDeckReference? _rankMetaDeckReferenceCandidate({
  required MetaDeckReferenceCandidate candidate,
  required Set<String> normalizedCommanders,
  required Set<String> normalizedKeywords,
  required bool preferExternalCompetitive,
}) {
  final searchableFields = <String>[
    candidate.archetype,
    candidate.shellLabel,
    candidate.strategyArchetype,
    candidate.commanderName,
    candidate.partnerCommanderName,
    candidate.sourceLabel,
  ].map(_normalizeMetaDeckText).toList(growable: false);
  final commanderSet = candidate.commanderSet;
  final shellField = _normalizeMetaDeckText(candidate.bestShellLabel);
  var commanderExactHits = 0;
  var commanderShellHits = 0;
  for (final commander in normalizedCommanders) {
    if (commanderSet.contains(commander)) commanderExactHits++;
    if (shellField.contains(commander)) commanderShellHits++;
  }

  final allCommandersMatched = normalizedCommanders.isNotEmpty &&
      normalizedCommanders.every(
        (commander) =>
            commanderSet.contains(commander) || shellField.contains(commander),
      );
  final exactCommanderPair = normalizedCommanders.isNotEmpty &&
      commanderSet.length == normalizedCommanders.length &&
      commanderSet.containsAll(normalizedCommanders);

  var keywordHits = 0;
  for (final keyword in normalizedKeywords) {
    if (keyword.isEmpty) continue;
    if (searchableFields.any((field) => field.contains(keyword))) {
      keywordHits++;
    }
  }

  if (normalizedCommanders.isNotEmpty &&
      commanderExactHits == 0 &&
      commanderShellHits == 0 &&
      keywordHits == 0) {
    return null;
  }
  if (normalizedCommanders.isEmpty && keywordHits == 0) {
    return null;
  }

  var score = 0;
  if (exactCommanderPair) {
    score += 600;
  } else if (allCommandersMatched) {
    score += 440;
  } else if (commanderExactHits > 0) {
    score += 300;
  } else if (commanderShellHits > 0) {
    score += 220;
  }
  score += commanderExactHits * 90;
  score += commanderShellHits * 45;
  score += keywordHits * 22;

  if (preferExternalCompetitive &&
      candidate.commanderSubformat == 'competitive_commander') {
    if (candidate.isExternalSource) score += 70;
    if (candidate.sourceChain.isNotEmpty) score += 20;
  }

  if (candidate.commanderSubformat == 'competitive_commander') {
    score += 30;
  }

  final placementRank = _parsePlacementRank(candidate.placement);
  if (placementRank != null) {
    score += (24 - placementRank).clamp(0, 20);
  }

  final selectionReason = exactCommanderPair
      ? 'exact_shell_match'
      : allCommandersMatched
          ? 'commander_shell_match'
          : commanderExactHits > 0 || commanderShellHits > 0
              ? 'commander_match'
              : 'keyword_meta_match';

  return _RankedMetaDeckReference(
    candidate: candidate,
    score: score,
    selectionReason: selectionReason,
  );
}

List<String> _buildPriorityCardNames(
  Iterable<MetaDeckReferenceCandidate> references, {
  required Set<String> requestedCommanders,
  required int limit,
}) {
  final counts = <String, int>{};
  final excluded = <String>{...requestedCommanders};
  for (final candidate in references) {
    excluded.addAll(candidate.commanderSet);
    final parsed = parseMetaDeckCardList(
      cardList: candidate.cardList,
      format: candidate.format,
    );
    for (final entry in parsed.effectiveCards.entries) {
      final name = entry.key.trim();
      final normalized = _normalizeMetaDeckText(name);
      if (normalized.isEmpty ||
          excluded.contains(normalized) ||
          _isBasicLandName(normalized)) {
        continue;
      }
      counts[name] = (counts[name] ?? 0) + entry.value;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });

  return sorted.take(limit).map((entry) => entry.key).toList(growable: false);
}

List<Map<String, dynamic>> _buildInfluencedCardPayload(
  Iterable<MetaDeckReferenceCandidate> references, {
  required int limit,
}) {
  final insights = <String, _InfluencedCardInsight>{};
  final excluded = <String>{};
  for (final candidate in references) {
    excluded.addAll(candidate.commanderSet);
    final parsed = parseMetaDeckCardList(
      cardList: candidate.cardList,
      format: candidate.format,
    );
    final seenInReference = <String>{};
    for (final entry in parsed.effectiveCards.entries) {
      final name = entry.key.trim();
      final normalized = _normalizeMetaDeckText(name);
      if (normalized.isEmpty ||
          excluded.contains(normalized) ||
          _isBasicLandName(normalized)) {
        continue;
      }
      final insight = insights.putIfAbsent(
        normalized,
        () => _InfluencedCardInsight(name: name),
      );
      insight.copyCount += entry.value;
      if (seenInReference.add(normalized)) {
        insight.referenceCount += 1;
      }
      insight.shells.add(candidate.bestShellLabel);
    }
  }

  final sorted = insights.values.toList()
    ..sort((a, b) {
      final byReferenceCount = b.referenceCount.compareTo(a.referenceCount);
      if (byReferenceCount != 0) return byReferenceCount;
      final byCopyCount = b.copyCount.compareTo(a.copyCount);
      if (byCopyCount != 0) return byCopyCount;
      return a.name.compareTo(b.name);
    });

  return sorted.take(limit).map((insight) => insight.toJson()).toList();
}

Map<String, dynamic> _decodeResearchPayload(dynamic rawPayload) {
  if (rawPayload is! String || rawPayload.trim().isEmpty) {
    return const <String, dynamic>{};
  }

  try {
    final decoded = jsonDecode(rawPayload);
    if (decoded is! Map) return const <String, dynamic>{};
    return decoded.cast<String, dynamic>();
  } catch (_) {
    return const <String, dynamic>{};
  }
}

List<String> _decodeSourceChain(dynamic rawPayload) {
  final researchPayload = _decodeResearchPayload(rawPayload);
  final rawChain = researchPayload['source_chain'];
  if (rawChain is String && rawChain.trim().isNotEmpty) {
    return <String>[rawChain.trim()];
  }
  if (rawChain is Iterable) {
    return rawChain
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

int? _parsePlacementRank(String rawPlacement) {
  final match = RegExp(r'(\d+)').firstMatch(rawPlacement);
  return int.tryParse(match?.group(1) ?? '');
}

String _normalizeMetaDeckText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String? _readResearchPayloadString(
  Map<String, dynamic> payload,
  String key,
) {
  final value = payload[key];
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _readResearchPayloadInt(
  Map<String, dynamic> payload,
  String key,
) {
  final value = payload[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

String _humanizeEventIdentifier(String rawId) {
  final normalized = rawId.trim().toLowerCase();
  if (normalized.isEmpty) return rawId;

  return normalized
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    return switch (part) {
      'cedh' => 'cEDH',
      'edh' => 'EDH',
      _ => part[0].toUpperCase() + part.substring(1),
    };
  }).join(' ');
}

const Map<String, String> _sourceChainTokenLabels = <String, String>{
  'edhtop16_graphql': 'EDHTop16 standings',
  'topdeck_deck_page': 'TopDeck deck page',
  'mtgtop8_format_page': 'MTGTop8 format page',
  'mtgtop8_event': 'MTGTop8 event page',
  'mtgtop8_deck_page': 'MTGTop8 deck page',
  'external_source': 'external source',
  'promoted_meta_deck': 'promoted meta deck',
};

String _humanizeSourceChainToken(String rawToken) {
  final normalized = rawToken.trim().toLowerCase();
  final mapped = _sourceChainTokenLabels[normalized];
  if (mapped != null) return mapped;

  return normalized
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

bool _isBasicLandName(String normalizedName) {
  return const <String>{
    'plains',
    'island',
    'swamp',
    'mountain',
    'forest',
    'wastes',
    'snow covered plains',
    'snow covered island',
    'snow covered swamp',
    'snow covered mountain',
    'snow covered forest',
  }.contains(normalizedName);
}

class _RankedMetaDeckReference {
  const _RankedMetaDeckReference({
    required this.candidate,
    required this.score,
    required this.selectionReason,
  });

  final MetaDeckReferenceCandidate candidate;
  final int score;
  final String selectionReason;
}

class _InfluencedCardInsight {
  _InfluencedCardInsight({required this.name});

  final String name;
  int referenceCount = 0;
  int copyCount = 0;
  final Set<String> shells = <String>{};

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'reference_count': referenceCount,
      'copy_count': copyCount,
      'shells': shells.take(3).toList(growable: false),
      'reason': referenceCount > 1
          ? 'Repeated across selected meta references.'
          : 'Present in a selected meta reference.',
    };
  }
}
