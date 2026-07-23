import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../deck_snapshot_contract.dart';

class PostGameNotePage {
  const PostGameNotePage({required this.notes, required this.syncCursor});

  final List<Map<String, dynamic>> notes;
  final DateTime syncCursor;
}

class PostGameConflictException implements Exception {
  const PostGameConflictException(this.currentNote);

  final Map<String, dynamic>? currentNote;
}

class PostGameValidationException implements Exception {
  const PostGameValidationException(this.message);

  final String message;
}

class PostGameNoteNotFoundException implements Exception {}

class PostGameNoteService {
  PostGameNoteService(this.pool);

  static const _noteColumns = '''
    id, deck_id, created_at, result, table_level, notes,
    performed_well, underperformed, issues, play_session_id,
    session_started_at, session_ended_at, deck_snapshot_hash,
    deck_version_at, revision, deleted_at, updated_at
  ''';

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

  Future<PostGameNotePage> listNotes({
    required String userId,
    required String deckId,
    bool includeDeleted = false,
    DateTime? updatedSince,
  }) {
    return pool.runTx((session) async {
      final syncCursor = await _reserveSyncWatermark(session);
      final deletedFilter = includeDeleted ? '' : 'AND deleted_at IS NULL';
      final orderBy =
          updatedSince == null
              ? 'created_at DESC, updated_at DESC'
              : 'updated_at ASC, id ASC';
      final result = await session.execute(
        Sql.named('''
          SELECT $_noteColumns
          FROM post_game_notes
          WHERE deck_id = CAST(@deckId AS uuid)
            AND user_id = CAST(@userId AS uuid)
            AND updated_at <= @syncCursor
            AND (
              CAST(@updatedSince AS timestamptz) IS NULL
              OR updated_at > CAST(@updatedSince AS timestamptz)
            )
            $deletedFilter
          ORDER BY $orderBy
        '''),
        parameters: {
          'deckId': deckId,
          'userId': userId,
          'syncCursor': syncCursor,
          'updatedSince': updatedSince,
        },
      );

      return PostGameNotePage(
        notes: result.map(_rowToJson).toList(growable: false),
        syncCursor: syncCursor.toUtc(),
      );
    });
  }

  Future<Map<String, dynamic>> buildTimeline({
    required String userId,
    required String deckId,
  }) async {
    final page = await listNotes(userId: userId, deckId: deckId);
    final notes = page.notes;
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
    final id = _boundedString(note['id'], 'id', 128, allowEmpty: true);
    final resolvedId =
        id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id;
    final createdAt = _optionalDate(note['created_at'], 'created_at');
    final result = _boundedString(note['result'], 'result', 80);
    final tableLevel = _boundedString(note['table_level'], 'table_level', 120);
    final notes = _boundedString(note['notes'], 'notes', 8000);
    final performedWell = _boundedList(
      note['performed_well'],
      'performed_well',
    );
    final underperformed = _boundedList(
      note['underperformed'],
      'underperformed',
    );
    final issues = _boundedList(note['issues'], 'issues');
    final playSessionId = _optionalBoundedString(
      note['play_session_id'],
      'play_session_id',
      160,
    );
    final sessionStartedAt = _optionalDate(
      note['session_started_at'],
      'session_started_at',
    );
    final sessionEndedAt = _optionalDate(
      note['session_ended_at'],
      'session_ended_at',
    );
    if (sessionStartedAt != null &&
        sessionEndedAt != null &&
        sessionEndedAt.isBefore(sessionStartedAt)) {
      throw const PostGameValidationException(
        'session_ended_at deve ser posterior a session_started_at.',
      );
    }
    final requestedDeckSnapshotHash = _optionalDeckSnapshotHash(
      note['deck_snapshot_hash'],
    );
    final requestedDeckVersionAt = _optionalDate(
      note['deck_version_at'],
      'deck_version_at',
    );
    if ((requestedDeckSnapshotHash == null) !=
        (requestedDeckVersionAt == null)) {
      throw const PostGameValidationException(
        'deck_snapshot_hash e deck_version_at devem ser enviados juntos.',
      );
    }
    final baseRevision = _optionalRevision(note['base_revision']);

    try {
      return await pool.runTx((session) async {
        final mutationAt = await _reserveSyncWatermark(session);
        final currentDeckSnapshot = await _captureDeckSnapshot(
          session,
          userId: userId,
          deckId: deckId,
        );
        final current = await session.execute(
          Sql.named('''
            SELECT user_id, $_noteColumns
            FROM post_game_notes
            WHERE id = @id
            FOR UPDATE
          '''),
          parameters: {'id': resolvedId},
        );
        var snapshot = currentDeckSnapshot;
        if (current.isNotEmpty) {
          final currentMap = current.first.toColumnMap();
          final persistedHash = _nullableString(
            currentMap['deck_snapshot_hash'],
          );
          final persistedAt = currentMap['deck_version_at'];
          if (persistedHash != null && persistedAt is DateTime) {
            snapshot = DeckSnapshotIdentity(
              hash: persistedHash,
              capturedAt: persistedAt.toUtc(),
            );
          } else if (requestedDeckSnapshotHash != null &&
              requestedDeckVersionAt != null) {
            snapshot = DeckSnapshotIdentity(
              hash: requestedDeckSnapshotHash,
              capturedAt: requestedDeckVersionAt,
            );
          }
        } else if (requestedDeckSnapshotHash != null &&
            requestedDeckVersionAt != null) {
          snapshot = DeckSnapshotIdentity(
            hash: requestedDeckSnapshotHash,
            capturedAt: requestedDeckVersionAt,
          );
        }

        if (current.isEmpty) {
          if (baseRevision != null && baseRevision != 0) {
            throw const PostGameConflictException(null);
          }
          final inserted = await session.execute(
            Sql.named('''
              INSERT INTO post_game_notes (
                id, user_id, deck_id, created_at, result, table_level, notes,
                performed_well, underperformed, issues, play_session_id,
                session_started_at, session_ended_at, deck_snapshot_hash,
                deck_version_at, revision, deleted_at, updated_at
              )
              VALUES (
                @id, CAST(@userId AS uuid), CAST(@deckId AS uuid),
                COALESCE(
                  CAST(@createdAt AS timestamptz),
                  CAST(@mutationAt AS timestamptz)
                ),
                @result, @tableLevel,
                @notes, @performedWell::jsonb, @underperformed::jsonb,
                @issues::jsonb, @playSessionId, @sessionStartedAt,
                @sessionEndedAt, @deckSnapshotHash, @deckVersionAt, 1, NULL,
                CAST(@mutationAt AS timestamptz)
              )
              RETURNING $_noteColumns
            '''),
            parameters: {
              'id': resolvedId,
              'userId': userId,
              'deckId': deckId,
              'createdAt': createdAt,
              'mutationAt': mutationAt,
              'result': result,
              'tableLevel': tableLevel,
              'notes': notes,
              'performedWell': jsonEncode(performedWell),
              'underperformed': jsonEncode(underperformed),
              'issues': jsonEncode(issues),
              'playSessionId': playSessionId,
              'sessionStartedAt': sessionStartedAt,
              'sessionEndedAt': sessionEndedAt,
              'deckSnapshotHash': snapshot.hash,
              'deckVersionAt': snapshot.capturedAt,
            },
          );
          return _rowToJson(inserted.first);
        }

        final currentRow = current.first;
        final currentMap = currentRow.toColumnMap();
        if (currentMap['user_id']?.toString() != userId ||
            currentMap['deck_id']?.toString() != deckId) {
          throw PostGameNoteNotFoundException();
        }
        final currentJson = _rowToJson(currentRow);
        if (currentMap['deleted_at'] != null) {
          throw PostGameConflictException(currentJson);
        }
        final currentRevision = _asInt(currentMap['revision'], fallback: 1);
        if (baseRevision != null && baseRevision != currentRevision) {
          throw PostGameConflictException(currentJson);
        }

        final updated = await session.execute(
          Sql.named('''
            UPDATE post_game_notes
            SET result = @result,
                table_level = @tableLevel,
                notes = @notes,
                performed_well = @performedWell::jsonb,
                underperformed = @underperformed::jsonb,
                issues = @issues::jsonb,
                play_session_id = @playSessionId,
                session_started_at = @sessionStartedAt,
                session_ended_at = @sessionEndedAt,
                deck_snapshot_hash = @deckSnapshotHash,
                deck_version_at = @deckVersionAt,
                revision = revision + 1,
                updated_at = CAST(@mutationAt AS timestamptz)
            WHERE id = @id
              AND user_id = CAST(@userId AS uuid)
              AND deck_id = CAST(@deckId AS uuid)
              AND deleted_at IS NULL
            RETURNING $_noteColumns
          '''),
          parameters: {
            'id': resolvedId,
            'userId': userId,
            'deckId': deckId,
            'result': result,
            'tableLevel': tableLevel,
            'notes': notes,
            'performedWell': jsonEncode(performedWell),
            'underperformed': jsonEncode(underperformed),
            'issues': jsonEncode(issues),
            'playSessionId': playSessionId,
            'sessionStartedAt': sessionStartedAt,
            'sessionEndedAt': sessionEndedAt,
            'deckSnapshotHash': snapshot.hash,
            'deckVersionAt': snapshot.capturedAt,
            'mutationAt': mutationAt,
          },
        );
        if (updated.isEmpty) throw PostGameConflictException(currentJson);
        return _rowToJson(updated.first);
      });
    } on ServerException catch (error) {
      if (error.code == '23505') {
        throw const PostGameConflictException(null);
      }
      rethrow;
    }
  }

  Future<bool> deleteNote({
    required String userId,
    required String deckId,
    required String noteId,
    int? baseRevision,
  }) {
    return pool.runTx((session) async {
      final mutationAt = await _reserveSyncWatermark(session);
      final current = await session.execute(
        Sql.named('''
          SELECT $_noteColumns
          FROM post_game_notes
          WHERE id = @noteId
            AND deck_id = CAST(@deckId AS uuid)
            AND user_id = CAST(@userId AS uuid)
          FOR UPDATE
        '''),
        parameters: {'noteId': noteId, 'deckId': deckId, 'userId': userId},
      );
      if (current.isEmpty) return false;

      final currentRow = current.first;
      final currentMap = currentRow.toColumnMap();
      if (currentMap['deleted_at'] != null) return true;
      final revision = _asInt(currentMap['revision'], fallback: 1);
      if (baseRevision != null && baseRevision != revision) {
        throw PostGameConflictException(_rowToJson(currentRow));
      }

      final deleted = await session.execute(
        Sql.named('''
          UPDATE post_game_notes
          SET result = '',
              table_level = '',
              notes = '',
              performed_well = '[]'::jsonb,
              underperformed = '[]'::jsonb,
              issues = '[]'::jsonb,
              play_session_id = NULL,
              session_started_at = NULL,
              session_ended_at = NULL,
              deck_snapshot_hash = NULL,
              deck_version_at = NULL,
              revision = revision + 1,
              deleted_at = CAST(@mutationAt AS timestamptz),
              updated_at = CAST(@mutationAt AS timestamptz)
          WHERE id = @noteId
            AND deck_id = CAST(@deckId AS uuid)
            AND user_id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
          RETURNING id
        '''),
        parameters: {
          'noteId': noteId,
          'deckId': deckId,
          'userId': userId,
          'mutationAt': mutationAt,
        },
      );
      return deleted.isNotEmpty;
    });
  }

  /// Reserva um ponto monotono do relogio de sincronizacao. Todas as leituras
  /// incrementais e mutacoes passam por esta unica linha, de modo que uma
  /// escrita concorrente fica necessariamente antes do cursor retornado ou
  /// recebe um timestamp estritamente posterior a ele.
  Future<DateTime> _reserveSyncWatermark(Session session) async {
    final result = await session.execute('''
      UPDATE post_game_sync_state
      SET watermark = GREATEST(
        clock_timestamp(),
        watermark + INTERVAL '1 microsecond'
      )
      WHERE id = 1
      RETURNING watermark
    ''');
    if (result.isEmpty || result.first[0] is! DateTime) {
      throw StateError(
        'post_game_sync_state ausente; aplique a migration 038.',
      );
    }
    return (result.first[0] as DateTime).toUtc();
  }

  Future<DeckSnapshotIdentity> _captureDeckSnapshot(
    Session session, {
    required String userId,
    required String deckId,
  }) async {
    final rows = await session.execute(
      Sql.named('''
        SELECT d.name, d.format, dc.card_id::text AS card_id,
               COALESCE(dc.quantity, 0)::int AS quantity,
               COALESCE(dc.is_commander, FALSE) AS is_commander
        FROM decks d
        LEFT JOIN deck_cards dc ON dc.deck_id = d.id
        WHERE d.id = CAST(@deckId AS uuid)
          AND d.user_id = CAST(@userId AS uuid)
        ORDER BY dc.card_id::text, dc.is_commander DESC
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    if (rows.isEmpty) throw PostGameNoteNotFoundException();

    final first = rows.first.toColumnMap();
    return DeckSnapshotIdentity(
      hash: buildDeckSnapshotHash(
        name: first['name']?.toString() ?? '',
        format: first['format']?.toString() ?? '',
        cards: rows.map((row) => row.toColumnMap()),
      ),
      capturedAt: DateTime.now().toUtc(),
    );
  }

  static Map<String, dynamic> _rowToJson(ResultRow row) {
    final map = row.toColumnMap();
    final deletedAt = _dateString(map['deleted_at']);
    final common = <String, dynamic>{
      'id': map['id']?.toString() ?? '',
      'deck_id': map['deck_id']?.toString() ?? '',
      'revision': _asInt(map['revision'], fallback: 1),
      'updated_at': _dateString(map['updated_at']),
      'deleted_at': deletedAt,
      'is_deleted': deletedAt != null,
    };
    if (deletedAt != null) return common;

    return {
      ...common,
      'created_at': _dateString(map['created_at']),
      'result': map['result']?.toString() ?? '',
      'table_level': map['table_level']?.toString() ?? '',
      'notes': map['notes']?.toString() ?? '',
      'performed_well': _stringList(map['performed_well']),
      'underperformed': _stringList(map['underperformed']),
      'issues': _stringList(map['issues']),
      'play_session_id': _nullableString(map['play_session_id']),
      'session_started_at': _dateString(map['session_started_at']),
      'session_ended_at': _dateString(map['session_ended_at']),
      'deck_snapshot_hash': _nullableString(map['deck_snapshot_hash']),
      'deck_version_at': _dateString(map['deck_version_at']),
    };
  }

  static String _boundedString(
    Object? value,
    String field,
    int maxLength, {
    bool allowEmpty = true,
  }) {
    final normalized = value?.toString().trim() ?? '';
    if (!allowEmpty && normalized.isEmpty) {
      throw PostGameValidationException('$field é obrigatório.');
    }
    if (normalized.length > maxLength) {
      throw PostGameValidationException('$field excede $maxLength caracteres.');
    }
    return normalized;
  }

  static String? _optionalBoundedString(
    Object? value,
    String field,
    int maxLength,
  ) {
    final normalized = _boundedString(value, field, maxLength);
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _optionalDate(Object? value, String field) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw PostGameValidationException('$field deve usar ISO-8601.');
    }
    return parsed.toUtc();
  }

  static int? _optionalRevision(Object? value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final revision = int.tryParse(value.toString());
    if (revision == null || revision < 0) {
      throw const PostGameValidationException(
        'base_revision deve ser um inteiro não negativo.',
      );
    }
    return revision;
  }

  static String? _optionalDeckSnapshotHash(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      throw const PostGameValidationException(
        'deck_snapshot_hash deve ser um SHA-256 hexadecimal.',
      );
    }
    return normalized;
  }

  static List<String> _boundedList(Object? value, String field) {
    final values = _stringList(value);
    if (values.length > 80 || values.any((entry) => entry.length > 240)) {
      throw PostGameValidationException('$field excede o limite permitido.');
    }
    return values;
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _nullableString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _dateString(Object? value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
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
    return <Map<String, dynamic>>[
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
