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
    PostGameIssue.winCondition => 'Win condition',
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

class PostGameNote {
  final String id;
  final String deckId;
  final DateTime createdAt;
  final String result;
  final String tableLevel;
  final String notes;
  final List<String> performedWell;
  final List<String> underperformed;
  final List<PostGameIssue> issues;

  const PostGameNote({
    required this.id,
    required this.deckId,
    required this.createdAt,
    required this.result,
    required this.tableLevel,
    required this.notes,
    this.performedWell = const <String>[],
    this.underperformed = const <String>[],
    this.issues = const <PostGameIssue>[],
  });

  factory PostGameNote.create({
    required String deckId,
    required String result,
    required String tableLevel,
    required String notes,
    List<String> performedWell = const <String>[],
    List<String> underperformed = const <String>[],
    List<PostGameIssue> issues = const <PostGameIssue>[],
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.now();
    return PostGameNote(
      id: '${timestamp.microsecondsSinceEpoch}',
      deckId: deckId,
      createdAt: timestamp,
      result: result.trim(),
      tableLevel: tableLevel.trim(),
      notes: notes.trim(),
      performedWell: _cleanList(performedWell),
      underperformed: _cleanList(underperformed),
      issues: List<PostGameIssue>.unmodifiable(issues),
    );
  }

  factory PostGameNote.fromJson(Map<String, dynamic> json) {
    return PostGameNote(
      id: json['id']?.toString() ?? '',
      deckId: json['deck_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      result: json['result']?.toString() ?? '',
      tableLevel: json['table_level']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      performedWell: _readStringList(json['performed_well']),
      underperformed: _readStringList(json['underperformed']),
      issues: _readStringList(
        json['issues'],
      ).map(PostGameIssueLabel.fromId).toList(growable: false),
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
      'performed_well': performedWell,
      'underperformed': underperformed,
      'issues': issues.map((issue) => issue.id).toList(),
    };
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

  static List<String> _readStringList(dynamic value) {
    return (value as List? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
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
    final entries =
        counts.entries.toList()..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key);
        });
    return entries.take(5).map((entry) => entry.key).toList(growable: false);
  }
}
