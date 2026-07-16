import 'dart:convert';

import 'package:postgres/postgres.dart';

class PostGameNoteService {
  PostGameNoteService(this.pool);

  final Pool pool;

  Future<bool> ownsDeck({
    required String userId,
    required String deckId,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT 1
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> listNotes({
    required String userId,
    required String deckId,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT id, deck_id, created_at, result, table_level, notes,
               performed_well, underperformed, issues, updated_at
        FROM post_game_notes
        WHERE deck_id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        ORDER BY created_at DESC, updated_at DESC
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );

    return result.map(_rowToJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> buildTimeline({
    required String userId,
    required String deckId,
  }) async {
    final notes = await listNotes(userId: userId, deckId: deckId);
    final issueCounts = <String, int>{};
    final performerCounts = <String, int>{};
    final reviewCounts = <String, int>{};
    final weekly = <String, int>{};

    for (final note in notes) {
      for (final issue in _stringList(note['issues'])) {
        issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
      }
      for (final card in _stringList(note['performed_well'])) {
        performerCounts[card] = (performerCounts[card] ?? 0) + 1;
      }
      for (final card in _stringList(note['underperformed'])) {
        reviewCounts[card] = (reviewCounts[card] ?? 0) + 1;
      }
      final createdAt = DateTime.tryParse(note['created_at']?.toString() ?? '');
      if (createdAt != null) {
        final weekKey = _weekKey(createdAt.toUtc());
        weekly[weekKey] = (weekly[weekKey] ?? 0) + 1;
      }
    }

    final dominantIssues = _top(issueCounts);
    final reviewCandidates = _top(reviewCounts);
    return {
      'deck_id': deckId,
      'match_count': notes.length,
      'issue_counts': issueCounts,
      'dominant_issues': dominantIssues,
      'top_performers': _top(performerCounts),
      'review_candidates': reviewCandidates,
      'weekly_activity': weekly.entries
          .map((entry) => {'week': entry.key, 'match_count': entry.value})
          .toList(growable: false),
      'diagnostics': _diagnostics(dominantIssues, reviewCandidates),
      'next_actions': _nextActions(dominantIssues, reviewCandidates),
      'timeline': notes,
    };
  }

  Future<Map<String, dynamic>> upsertNote({
    required String userId,
    required String deckId,
    required Map<String, dynamic> note,
  }) async {
    final id = _cleanString(note['id']);
    final createdAt = _cleanString(note['created_at']);
    final result = _cleanString(note['result']);
    final tableLevel = _cleanString(note['table_level']);
    final notes = _cleanString(note['notes']);
    final performedWell = _stringList(note['performed_well']);
    final underperformed = _stringList(note['underperformed']);
    final issues = _stringList(note['issues']);

    final inserted = await pool.execute(
      Sql.named('''
        INSERT INTO post_game_notes (
          id,
          user_id,
          deck_id,
          created_at,
          result,
          table_level,
          notes,
          performed_well,
          underperformed,
          issues,
          updated_at
        )
        VALUES (
          @id,
          CAST(@userId AS uuid),
          CAST(@deckId AS uuid),
          COALESCE(CAST(NULLIF(@createdAt, '') AS timestamptz), NOW()),
          @result,
          @tableLevel,
          @notes,
          @performedWell::jsonb,
          @underperformed::jsonb,
          @issues::jsonb,
          NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
          result = EXCLUDED.result,
          table_level = EXCLUDED.table_level,
          notes = EXCLUDED.notes,
          performed_well = EXCLUDED.performed_well,
          underperformed = EXCLUDED.underperformed,
          issues = EXCLUDED.issues,
          updated_at = NOW()
        WHERE post_game_notes.user_id = CAST(@userId AS uuid)
          AND post_game_notes.deck_id = CAST(@deckId AS uuid)
        RETURNING id, deck_id, created_at, result, table_level, notes,
                  performed_well, underperformed, issues, updated_at
      '''),
      parameters: {
        'id':
            id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
        'userId': userId,
        'deckId': deckId,
        'createdAt': createdAt,
        'result': result,
        'tableLevel': tableLevel,
        'notes': notes,
        'performedWell': jsonEncode(performedWell),
        'underperformed': jsonEncode(underperformed),
        'issues': jsonEncode(issues),
      },
    );

    if (inserted.isEmpty) {
      throw StateError('Post-game note not found or permission denied.');
    }

    return _rowToJson(inserted.first);
  }

  Future<bool> deleteNote({
    required String userId,
    required String deckId,
    required String noteId,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        DELETE FROM post_game_notes
        WHERE id = @noteId
          AND deck_id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        RETURNING id
      '''),
      parameters: {'noteId': noteId, 'deckId': deckId, 'userId': userId},
    );
    return result.isNotEmpty;
  }

  Map<String, dynamic> _rowToJson(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id']?.toString() ?? '',
      'deck_id': map['deck_id']?.toString() ?? '',
      'created_at': _dateString(map['created_at']),
      'result': map['result']?.toString() ?? '',
      'table_level': map['table_level']?.toString() ?? '',
      'notes': map['notes']?.toString() ?? '',
      'performed_well': _stringList(map['performed_well']),
      'underperformed': _stringList(map['underperformed']),
      'issues': _stringList(map['issues']),
      'updated_at': _dateString(map['updated_at']),
    };
  }

  static String _cleanString(Object? value) => value?.toString().trim() ?? '';

  static String? _dateString(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    final text = value?.toString();
    return text == null || text.trim().isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    final raw = value is String ? _decodeJsonList(value) : value;
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static Object? _decodeJsonList(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return const <String>[];
    }
  }

  static List<String> _top(Map<String, int> counts) {
    final entries =
        counts.entries.toList()..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key);
        });
    return entries.take(5).map((entry) => entry.key).toList(growable: false);
  }

  static List<Map<String, dynamic>> _diagnostics(
    List<String> dominantIssues,
    List<String> reviewCandidates,
  ) {
    final diagnostics = <Map<String, dynamic>>[
      for (final issue in dominantIssues)
        {
          'issue': issue,
          'label': _issueLabel(issue),
          'message': _issueDiagnostic(issue),
        },
      if (reviewCandidates.isNotEmpty)
        {
          'issue': 'underperformers',
          'label': 'Cartas para revisar',
          'message':
              'As cartas ${reviewCandidates.take(3).join(', ')} apareceram como baixo desempenho. Revise funcao, curva e alternativas antes do proximo upgrade.',
        },
    ];
    return diagnostics;
  }

  static List<String> _nextActions(
    List<String> dominantIssues,
    List<String> reviewCandidates,
  ) {
    final actions = <String>[
      for (final issue in dominantIssues) _issueAction(issue),
      if (reviewCandidates.isNotEmpty)
        'Abrir otimizacao focada preservando o plano principal e substituindo ${reviewCandidates.take(3).join(', ')} somente se houver ganho claro.',
    ];
    return actions.toSet().take(6).toList(growable: false);
  }

  static String _issueLabel(String issue) => switch (issue) {
    'mana' => 'Mana',
    'draw' => 'Compra',
    'removal' => 'Remocao',
    'win_condition' => 'Win condition',
    'speed' => 'Velocidade',
    'protection' => 'Protecao',
    _ => issue,
  };

  static String _issueDiagnostic(String issue) => switch (issue) {
    'mana' =>
      'O deck esta registrando problema de mana. Priorize base, ramp e curva antes de adicionar novas pecas de valor.',
    'draw' =>
      'A partida indicou falta de compra ou selecao. Procure fontes repetiveis e cartas que nao quebrem o plano do comandante.',
    'removal' =>
      'A mesa exigiu mais interacao. Compare removals pontuais, wipes e respostas flexiveis por bracket.',
    'win_condition' =>
      'O deck gerou jogo mas nao encerrou. Revise finalizadores, redundancia e linhas reais de vitoria.',
    'speed' =>
      'O deck pareceu atrasado no ritmo da mesa. Baixe curva ou aumente aceleracao sem sacrificar consistencia.',
    'protection' =>
      'Pecas-chave ficaram vulneraveis. Inclua protecao adequada ao bracket e ao tipo de remocao esperado.',
    _ => 'Sinal recorrente registrado no historico pos-jogo.',
  };

  static String _issueAction(String issue) => switch (issue) {
    'mana' => 'Rodar otimizacao por mana/curva antes de trocar payoff.',
    'draw' => 'Priorizar 2-4 fontes de compra ou selecao no proximo ajuste.',
    'removal' => 'Comparar pacote de remocao com o nivel da mesa.',
    'win_condition' =>
      'Definir finalizadores e redundancia antes do proximo teste.',
    'speed' => 'Revisar curva inicial e ramp de baixo custo.',
    'protection' => 'Adicionar protecao para comandante ou motor principal.',
    _ => 'Revisar notas recentes antes de aplicar upgrade.',
  };

  static String _weekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final year = monday.year.toString().padLeft(4, '0');
    final month = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
