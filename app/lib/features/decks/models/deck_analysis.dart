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
    required this.counts,
    required this.samples,
    required this.coverage,
  });

  final String schemaVersion;
  final Map<String, int> counts;
  final Map<String, List<DeckFunctionalTagSample>> samples;
  final DeckFunctionalTagsCoverage coverage;

  factory DeckFunctionalTags.fromJson(Map<String, dynamic> json) {
    final rawSamples = _asStringMap(json['samples']);
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

    return DeckFunctionalTags(
      schemaVersion: json['schema_version']?.toString() ?? '',
      counts: _parseIntMap(_asStringMap(json['counts'])),
      samples: Map.unmodifiable(parsedSamples),
      coverage: DeckFunctionalTagsCoverage.fromJson(
        _asStringMap(json['coverage']),
      ),
    );
  }
}

class DeckFunctionalTagSample {
  const DeckFunctionalTagSample({required this.name, this.reason, this.role});

  final String name;
  final String? reason;
  final String? role;

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
        reason: _optionalTrimmedString(map['reason'] ?? map['evidence']),
        role: _optionalTrimmedString(map['role'] ?? map['function']),
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
