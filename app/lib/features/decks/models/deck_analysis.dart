class DeckAnalysisData {
  const DeckAnalysisData({
    required this.deckId,
    required this.format,
    required this.composition,
    this.functionalTags,
  });

  final String deckId;
  final String? format;
  final Map<String, int> composition;
  final DeckFunctionalTags? functionalTags;

  factory DeckAnalysisData.fromJson(Map<String, dynamic> json) {
    final stats = _asStringMap(json['stats']);
    final composition = _parseIntMap(_asStringMap(stats['composition']));
    final functionalTagsPayload = _asStringMap(json['functional_tags']);
    final functionalTags =
        functionalTagsPayload.isEmpty
            ? null
            : DeckFunctionalTags.fromJson(functionalTagsPayload);

    return DeckAnalysisData(
      deckId: json['deck_id']?.toString() ?? '',
      format: json['format']?.toString(),
      composition: composition,
      functionalTags: functionalTags,
    );
  }

  bool get hasFunctionalTags => functionalTags != null;

  bool get hasAnyCounts {
    if (composition.values.any((value) => value > 0)) return true;
    return functionalTags?.counts.values.any((value) => value > 0) ?? false;
  }

  int countFor({required String tagKey, required String compositionKey}) {
    final tags = functionalTags;
    if (tags != null && tags.counts.containsKey(tagKey)) {
      return tags.counts[tagKey] ?? 0;
    }
    return composition[compositionKey] ?? 0;
  }

  List<DeckFunctionalTagSample> samplesFor(String tagKey) {
    return functionalTags?.samples[tagKey] ?? const <DeckFunctionalTagSample>[];
  }

  String get sourceLabel {
    final tags = functionalTags;
    if (tags == null) {
      return 'stats.composition legado';
    }
    final version = tags.schemaVersion.trim();
    if (version.isEmpty) {
      return 'functional_tags do backend';
    }
    return 'functional_tags ($version)';
  }
}

class DeckFunctionalTags {
  const DeckFunctionalTags({
    required this.schemaVersion,
    this.semanticSchemaVersion,
    this.source,
    required this.counts,
    required this.samples,
    required this.coverage,
  });

  final String schemaVersion;
  final String? semanticSchemaVersion;
  final DeckFunctionalTagsSource? source;
  final Map<String, int> counts;
  final Map<String, List<DeckFunctionalTagSample>> samples;
  final DeckFunctionalTagsCoverage coverage;

  factory DeckFunctionalTags.fromJson(Map<String, dynamic> json) {
    final rawSamples = _asStringMap(json['samples']);
    final rawSampleDetails = _asStringMap(json['sample_details']);
    final parsedSamples = <String, List<DeckFunctionalTagSample>>{};
    for (final entry in rawSamples.entries) {
      final rawList = entry.value;
      if (rawList is! List) continue;
      final samples = rawList
          .map(DeckFunctionalTagSample.fromDynamic)
          .whereType<DeckFunctionalTagSample>()
          .toList(growable: false);
      parsedSamples[entry.key] = samples;
    }
    for (final entry in rawSampleDetails.entries) {
      final rawList = entry.value;
      if (rawList is! List) continue;
      final samples = rawList
          .map(DeckFunctionalTagSample.fromDynamic)
          .whereType<DeckFunctionalTagSample>()
          .toList(growable: false);
      if (samples.isEmpty) continue;
      parsedSamples[entry.key] = samples;
    }

    return DeckFunctionalTags(
      schemaVersion: json['schema_version']?.toString() ?? '',
      semanticSchemaVersion: _optionalTrimmedString(
        json['semantic_schema_version'],
      ),
      source: DeckFunctionalTagsSource.fromJson(_asStringMap(json['source'])),
      counts: _parseIntMap(_asStringMap(json['counts'])),
      samples: Map.unmodifiable(parsedSamples),
      coverage: DeckFunctionalTagsCoverage.fromJson(
        _asStringMap(json['coverage']),
      ),
    );
  }
}

class DeckFunctionalTagsSource {
  const DeckFunctionalTagsSource({
    required this.priority,
    required this.persistedRows,
    required this.persistedCopies,
    required this.heuristicRows,
    required this.heuristicCopies,
  });

  final String? priority;
  final int persistedRows;
  final int persistedCopies;
  final int heuristicRows;
  final int heuristicCopies;

  factory DeckFunctionalTagsSource.fromJson(Map<String, dynamic> json) {
    return DeckFunctionalTagsSource(
      priority: _optionalTrimmedString(json['priority']),
      persistedRows: _parseInt(json['persisted_rows']),
      persistedCopies: _parseInt(json['persisted_copies']),
      heuristicRows: _parseInt(json['heuristic_rows']),
      heuristicCopies: _parseInt(json['heuristic_copies']),
    );
  }

  bool get hasAnySignal =>
      persistedRows > 0 ||
      persistedCopies > 0 ||
      heuristicRows > 0 ||
      heuristicCopies > 0 ||
      (priority ?? '').isNotEmpty;

  String get summary {
    if (!hasAnySignal) return 'Origem não informada';
    final parts = <String>[
      if ((priority ?? '').isNotEmpty) 'prioridade $priority',
      if (persistedCopies > 0) '$persistedCopies persistidas',
      if (heuristicCopies > 0) '$heuristicCopies heurísticas',
    ];
    if (parts.isEmpty && persistedRows > 0) {
      parts.add('$persistedRows linhas persistidas');
    }
    if (parts.isEmpty && heuristicRows > 0) {
      parts.add('$heuristicRows linhas heurísticas');
    }
    return parts.join(' • ');
  }
}

class DeckFunctionalTagSample {
  const DeckFunctionalTagSample({
    required this.name,
    this.tag,
    this.reason,
    this.evidence,
    this.role,
    this.confidence,
    this.semanticSchemaVersion,
    this.speed,
    this.manaEfficiency,
    this.cardAdvantageType,
    this.interactionScope,
    this.protectionType,
    this.recursionType,
  });

  final String name;
  final String? tag;
  final String? reason;
  final String? evidence;
  final String? role;
  final double? confidence;
  final String? semanticSchemaVersion;
  final String? speed;
  final String? manaEfficiency;
  final String? cardAdvantageType;
  final String? interactionScope;
  final String? protectionType;
  final String? recursionType;

  static DeckFunctionalTagSample? fromDynamic(dynamic value) {
    if (value is String) {
      final name = value.trim();
      if (name.isEmpty) return null;
      return DeckFunctionalTagSample(name: name);
    }

    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      final rawName =
          map['name'] ??
          map['card_name'] ??
          map['card'] ??
          map['title'] ??
          map['label'];
      final name = rawName?.toString().trim();
      if (name == null || name.isEmpty) return null;
      return DeckFunctionalTagSample(
        name: name,
        tag: _optionalTrimmedString(map['tag']),
        reason: _optionalTrimmedString(map['reason'] ?? map['evidence']),
        evidence: _optionalTrimmedString(map['evidence']),
        role: _optionalTrimmedString(map['role'] ?? map['function']),
        confidence: _optionalDouble(map['confidence']),
        semanticSchemaVersion: _optionalTrimmedString(
          map['semantic_schema_version'],
        ),
        speed: _optionalTrimmedString(map['speed']),
        manaEfficiency: _optionalTrimmedString(map['mana_efficiency']),
        cardAdvantageType: _optionalTrimmedString(map['card_advantage_type']),
        interactionScope: _optionalTrimmedString(map['interaction_scope']),
        protectionType: _optionalTrimmedString(map['protection_type']),
        recursionType: _optionalTrimmedString(map['recursion_type']),
      );
    }

    return null;
  }
}

class DeckFunctionalTagsCoverage {
  const DeckFunctionalTagsCoverage({
    required this.cardRows,
    required this.cardCopies,
    required this.taggedRows,
    required this.taggedCopies,
    required this.otherRows,
    required this.otherCopies,
  });

  final int cardRows;
  final int cardCopies;
  final int taggedRows;
  final int taggedCopies;
  final int otherRows;
  final int otherCopies;

  factory DeckFunctionalTagsCoverage.fromJson(Map<String, dynamic> json) {
    return DeckFunctionalTagsCoverage(
      cardRows: _parseInt(json['card_rows']),
      cardCopies: _parseInt(json['card_copies']),
      taggedRows: _parseInt(json['tagged_rows']),
      taggedCopies: _parseInt(json['tagged_copies']),
      otherRows: _parseInt(json['other_rows']),
      otherCopies: _parseInt(json['other_copies']),
    );
  }

  bool get hasCards => cardRows > 0 || cardCopies > 0;

  double? get taggedCopyRatio {
    if (cardCopies <= 0) return null;
    return taggedCopies / cardCopies;
  }

  String get summary {
    if (cardCopies > 0) {
      return '$taggedCopies/$cardCopies cópias classificadas';
    }
    if (cardRows > 0) {
      return '$taggedRows/$cardRows cartas classificadas';
    }
    return 'Cobertura não informada';
  }
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

Map<String, int> _parseIntMap(Map<String, dynamic> map) {
  final parsed = <String, int>{};
  for (final entry in map.entries) {
    parsed[entry.key] = _parseInt(entry.value);
  }
  return Map.unmodifiable(parsed);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _optionalTrimmedString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double? _optionalDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
