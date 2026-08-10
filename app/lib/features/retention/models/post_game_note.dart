enum PostGameIssue { mana, draw, removal, winCondition, speed, protection }

extension PostGameIssueLabel on PostGameIssue {
  String get id => switch (this) {
    PostGameIssue.mana => 'mana',
    PostGameIssue.draw => 'draw',
    PostGameIssue.removal => 'removal',
    PostGameIssue.winCondition => 'win_condition',
    PostGameIssue.speed => 'speed',
    PostGameIssue.protection => 'protection',
  };

  String get label => switch (this) {
    PostGameIssue.mana => 'Mana',
    PostGameIssue.draw => 'Compra',
    PostGameIssue.removal => 'Remoção',
    PostGameIssue.winCondition => 'Condição de vitória',
    PostGameIssue.speed => 'Velocidade',
    PostGameIssue.protection => 'Proteção',
  };

  String get suggestion => switch (this) {
    PostGameIssue.mana =>
      'Revisar base de mana, ramp e quantidade de terrenos antes da próxima otimização.',
    PostGameIssue.draw =>
      'Adicionar ou priorizar fontes de compra e seleção de cartas.',
    PostGameIssue.removal =>
      'Aumentar interação pontual ou wipes conforme o nível da mesa.',
    PostGameIssue.winCondition =>
      'Clarificar finalizadores e linhas reais para encerrar partidas.',
    PostGameIssue.speed =>
      'Baixar a curva ou adicionar aceleração para chegar antes ao plano.',
    PostGameIssue.protection =>
      'Incluir proteção para comandante, peças-chave ou combo.',
  };

  static PostGameIssue fromId(String id) {
    return PostGameIssue.values.firstWhere(
      (issue) => issue.id == id,
      orElse: () => PostGameIssue.mana,
    );
  }
}

/// A card signal selected from the exact deck revision used by the player.
///
/// Legacy post-game notes may only have [name]. New notes created by the app
/// keep the exact printing [cardId] and its already-resolved artwork. The UI
/// must never manufacture artwork from [name] when [cardId] is absent.
class PostGameCardEvidence {
  const PostGameCardEvidence({
    required this.name,
    this.cardId,
    this.imageUrl,
    this.setCode,
    this.collectorNumber,
    this.quantity = 1,
    this.isCommander = false,
  });

  final String name;
  final String? cardId;
  final String? imageUrl;
  final String? setCode;
  final String? collectorNumber;
  final int quantity;
  final bool isCommander;

  bool get hasExactIdentity => cardId != null && cardId!.trim().isNotEmpty;

  factory PostGameCardEvidence.fromJson(Object? value) {
    if (value is Map) {
      final json = value.map((key, nested) => MapEntry(key.toString(), nested));
      return PostGameCardEvidence(
        name: _cleanText(json['name']) ?? _cleanText(json['card_name']) ?? '',
        cardId: _cleanText(json['card_id']),
        imageUrl: _cleanText(json['image_url']),
        setCode: _cleanText(json['set_code']),
        collectorNumber: _cleanText(json['collector_number']),
        quantity: _positiveInt(json['quantity']) ?? 1,
        isCommander: json['is_commander'] == true,
      );
    }
    return PostGameCardEvidence(name: _cleanText(value) ?? '');
  }

  Object toJsonValue() {
    if (!hasExactIdentity &&
        imageUrl == null &&
        setCode == null &&
        collectorNumber == null &&
        quantity == 1 &&
        !isCommander) {
      return name;
    }
    return <String, dynamic>{
      'card_id': cardId,
      'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (setCode != null) 'set_code': setCode,
      if (collectorNumber != null) 'collector_number': collectorNumber,
      'quantity': quantity,
      if (isCommander) 'is_commander': true,
    };
  }

  static String? _cleanText(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => int.tryParse(value?.toString() ?? ''),
    };
    return parsed == null || parsed < 1 ? null : parsed;
  }
}

class PostGameNote {
  final String id;
  final String deckId;
  final DateTime createdAt;
  final String result;
  final String tableLevel;
  final String notes;
  final List<PostGameCardEvidence> performedWellEvidence;
  final List<PostGameCardEvidence> underperformedEvidence;
  final List<PostGameIssue> issues;
  final String? playSessionId;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final String? deckSnapshotHash;
  final DateTime? deckVersionAt;
  final int revision;

  const PostGameNote({
    required this.id,
    required this.deckId,
    required this.createdAt,
    required this.result,
    required this.tableLevel,
    required this.notes,
    this.performedWellEvidence = const <PostGameCardEvidence>[],
    this.underperformedEvidence = const <PostGameCardEvidence>[],
    this.issues = const <PostGameIssue>[],
    this.playSessionId,
    this.sessionStartedAt,
    this.sessionEndedAt,
    this.deckSnapshotHash,
    this.deckVersionAt,
    this.revision = 1,
  });

  factory PostGameNote.create({
    required String deckId,
    required String result,
    required String tableLevel,
    required String notes,
    List<String> performedWell = const <String>[],
    List<String> underperformed = const <String>[],
    List<PostGameCardEvidence> performedWellEvidence =
        const <PostGameCardEvidence>[],
    List<PostGameCardEvidence> underperformedEvidence =
        const <PostGameCardEvidence>[],
    List<PostGameIssue> issues = const <PostGameIssue>[],
    String? playSessionId,
    DateTime? sessionStartedAt,
    DateTime? sessionEndedAt,
    String? deckSnapshotHash,
    DateTime? deckVersionAt,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.now();
    final normalizedDeckSnapshotHash = _validDeckSnapshotHash(deckSnapshotHash);
    final normalizedDeckVersionAt = _validSessionDate(deckVersionAt);
    final hasCompleteDeckVersion =
        normalizedDeckSnapshotHash != null && normalizedDeckVersionAt != null;
    return PostGameNote(
      id: '${timestamp.microsecondsSinceEpoch}',
      deckId: deckId,
      createdAt: timestamp,
      result: result.trim(),
      tableLevel: tableLevel.trim(),
      notes: notes.trim(),
      performedWellEvidence: _cleanEvidence([
        ...performedWellEvidence,
        ..._cleanList(
          performedWell,
        ).map((name) => PostGameCardEvidence(name: name)),
      ]),
      underperformedEvidence: _cleanEvidence([
        ...underperformedEvidence,
        ..._cleanList(
          underperformed,
        ).map((name) => PostGameCardEvidence(name: name)),
      ]),
      issues: List<PostGameIssue>.unmodifiable(issues),
      playSessionId: _cleanOptional(playSessionId),
      sessionStartedAt: _validSessionDate(sessionStartedAt),
      sessionEndedAt: _validSessionDate(sessionEndedAt),
      deckSnapshotHash: hasCompleteDeckVersion
          ? normalizedDeckSnapshotHash
          : null,
      deckVersionAt: hasCompleteDeckVersion ? normalizedDeckVersionAt : null,
    );
  }

  factory PostGameNote.fromJson(Map<String, dynamic> json) {
    final normalizedDeckSnapshotHash = _validDeckSnapshotHash(
      json['deck_snapshot_hash']?.toString(),
    );
    final normalizedDeckVersionAt = _readSessionDate(json['deck_version_at']);
    final hasCompleteDeckVersion =
        normalizedDeckSnapshotHash != null && normalizedDeckVersionAt != null;
    return PostGameNote(
      id: json['id']?.toString() ?? '',
      deckId: json['deck_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      result: json['result']?.toString() ?? '',
      tableLevel: json['table_level']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      performedWellEvidence: _readEvidenceList(json['performed_well']),
      underperformedEvidence: _readEvidenceList(json['underperformed']),
      issues: _readStringList(
        json['issues'],
      ).map(PostGameIssueLabel.fromId).toList(growable: false),
      playSessionId: _cleanOptional(json['play_session_id']?.toString()),
      sessionStartedAt: _readSessionDate(json['session_started_at']),
      sessionEndedAt: _readSessionDate(json['session_ended_at']),
      deckSnapshotHash: hasCompleteDeckVersion
          ? normalizedDeckSnapshotHash
          : null,
      deckVersionAt: hasCompleteDeckVersion ? normalizedDeckVersionAt : null,
      revision: _positiveRevision(json['revision']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'created_at': createdAt.toIso8601String(),
      'result': result,
      'table_level': tableLevel,
      'notes': notes,
      'performed_well': performedWellEvidence
          .map((card) => card.toJsonValue())
          .toList(growable: false),
      'underperformed': underperformedEvidence
          .map((card) => card.toJsonValue())
          .toList(growable: false),
      'issues': issues.map((issue) => issue.id).toList(),
      'revision': revision,
      if (playSessionId != null) 'play_session_id': playSessionId,
      if (sessionStartedAt != null)
        'session_started_at': sessionStartedAt!.toIso8601String(),
      if (sessionEndedAt != null)
        'session_ended_at': sessionEndedAt!.toIso8601String(),
      if (deckSnapshotHash != null) 'deck_snapshot_hash': deckSnapshotHash,
      if (deckVersionAt != null)
        'deck_version_at': deckVersionAt!.toIso8601String(),
    };
  }

  Duration? get sessionDuration {
    final startedAt = sessionStartedAt;
    final endedAt = sessionEndedAt;
    if (startedAt == null || endedAt == null || endedAt.isBefore(startedAt)) {
      return null;
    }
    return endedAt.difference(startedAt);
  }

  List<String> get performedWell => performedWellEvidence
      .map((card) => card.name)
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  List<String> get underperformed => underperformedEvidence
      .map((card) => card.name)
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  String? get battleReplayId {
    const prefix = 'battle-replay:';
    final sessionId = playSessionId;
    if (sessionId == null || !sessionId.startsWith(prefix)) return null;
    final replayId = sessionId.substring(prefix.length).trim();
    return replayId.isEmpty ? null : replayId;
  }

  List<String> get automaticSuggestions {
    final lines = <String>[
      for (final issue in issues) issue.suggestion,
      if (underperformed.isNotEmpty)
        'Revisar ${underperformed.take(3).join(', ')} na próxima otimização.',
      if (performedWell.isNotEmpty)
        'Preservar ${performedWell.take(3).join(', ')} como núcleo do deck.',
    ];
    return lines.toSet().toList(growable: false);
  }

  static List<String> _cleanList(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static List<PostGameCardEvidence> _cleanEvidence(
    Iterable<PostGameCardEvidence> values,
  ) {
    final byIdentity = <String, PostGameCardEvidence>{};
    for (final value in values) {
      final name = value.name.trim();
      if (name.isEmpty) continue;
      final cardId = _cleanOptional(value.cardId);
      final key = cardId == null
          ? 'name:${name.toLowerCase()}'
          : 'id:${cardId.toLowerCase()}';
      byIdentity.putIfAbsent(
        key,
        () => PostGameCardEvidence(
          name: name,
          cardId: cardId,
          imageUrl: _cleanOptional(value.imageUrl),
          setCode: _cleanOptional(value.setCode),
          collectorNumber: _cleanOptional(value.collectorNumber),
          quantity: value.quantity < 1 ? 1 : value.quantity,
          isCommander: value.isCommander,
        ),
      );
    }
    return List<PostGameCardEvidence>.unmodifiable(byIdentity.values);
  }

  static String? _cleanOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _validDeckSnapshotHash(String? value) {
    final normalized = _cleanOptional(value)?.toLowerCase();
    if (normalized == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static DateTime? _validSessionDate(DateTime? value) {
    if (value == null || value.millisecondsSinceEpoch <= 0) return null;
    return value;
  }

  static DateTime? _readSessionDate(Object? value) {
    return _validSessionDate(DateTime.tryParse(value?.toString() ?? ''));
  }

  static List<String> _readStringList(dynamic value) {
    return (value as List? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<PostGameCardEvidence> _readEvidenceList(Object? value) {
    if (value is! List) return const <PostGameCardEvidence>[];
    return _cleanEvidence(value.map(PostGameCardEvidence.fromJson));
  }

  static int _positiveRevision(Object? value) {
    final parsed = switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => int.tryParse(value?.toString() ?? ''),
    };
    return parsed == null || parsed < 1 ? 1 : parsed;
  }
}

class DeckEvolutionSummary {
  final int totalMatches;
  final Map<PostGameIssue, int> issueCounts;
  final List<String> topPerformers;
  final List<String> reviewCandidates;
  final List<String> suggestions;

  const DeckEvolutionSummary({
    required this.totalMatches,
    required this.issueCounts,
    required this.topPerformers,
    required this.reviewCandidates,
    required this.suggestions,
  });

  factory DeckEvolutionSummary.fromNotes(List<PostGameNote> notes) {
    final issueCounts = <PostGameIssue, int>{};
    final performerCounts = <String, int>{};
    final reviewCounts = <String, int>{};
    final suggestions = <String>{};

    for (final note in notes) {
      for (final issue in note.issues) {
        issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
      }
      for (final card in note.performedWell) {
        performerCounts[card] = (performerCounts[card] ?? 0) + 1;
      }
      for (final card in note.underperformed) {
        reviewCounts[card] = (reviewCounts[card] ?? 0) + 1;
      }
      suggestions.addAll(note.automaticSuggestions);
    }

    return DeckEvolutionSummary(
      totalMatches: notes.length,
      issueCounts: issueCounts,
      topPerformers: _topKeys(performerCounts),
      reviewCandidates: _topKeys(reviewCounts),
      suggestions: suggestions.take(5).toList(growable: false),
    );
  }

  static List<String> _topKeys(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
    return entries.take(5).map((entry) => entry.key).toList(growable: false);
  }
}
