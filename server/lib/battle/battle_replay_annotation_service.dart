import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'battle_replay_payload_sanitizer.dart';

const battleReplayAnnotationSchema = 'battle_replay_annotation_v1';
const battleReplayAnnotationKinds = <String>{
  'bookmark',
  'note',
  'would_do_differently',
  'mulligan_decision',
  'helpful_feedback',
  'event_report',
};

final RegExp _idempotencyKeyPattern = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
final RegExp _eventRefPattern = RegExp(r'^event:(0|[1-9][0-9]{0,5})$');
final RegExp _snapshotRefPattern = RegExp(r'^snapshot:(0|[1-9][0-9]{0,5})$');

class BattleReplayAnnotationValidationException implements Exception {
  const BattleReplayAnnotationValidationException(this.message);

  final String message;
}

class BattleReplayAnnotationNotFoundException implements Exception {
  const BattleReplayAnnotationNotFoundException();
}

class BattleReplayAnnotationRevisionUnavailableException implements Exception {
  const BattleReplayAnnotationRevisionUnavailableException();
}

class BattleReplayAnnotationIdempotencyConflictException implements Exception {
  const BattleReplayAnnotationIdempotencyConflictException();
}

class BattleReplayAnnotationAlreadyRecordedException implements Exception {
  const BattleReplayAnnotationAlreadyRecordedException();
}

class BattleReplayAnnotationCreateResult {
  const BattleReplayAnnotationCreateResult({
    required this.annotation,
    required this.created,
  });

  final Map<String, dynamic> annotation;
  final bool created;
}

class BattleReplayAnnotationService {
  const BattleReplayAnnotationService(this._pool);

  final Pool _pool;

  Future<List<Map<String, dynamic>>> list({
    required String userId,
    required String deckId,
    required String replayId,
    int limit = 50,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          annotation.id::text AS id,
          annotation.replay_id::text AS replay_id,
          annotation.attempt_id::text AS attempt_id,
          annotation.subject_deck_id::text AS subject_deck_id,
          annotation.subject_deck_key,
          annotation.deck_hash_schema,
          annotation.subject_deck_hash,
          annotation.subject_deck_revision,
          annotation.event_ref,
          annotation.snapshot_ref,
          annotation.kind,
          annotation.payload,
          annotation.created_at,
          annotation.updated_at
        FROM battle_replay_annotations annotation
        JOIN decks requested
          ON requested.id = CAST(@deckId AS uuid)
         AND requested.user_id = CAST(@userId AS uuid)
        WHERE annotation.user_id = CAST(@userId AS uuid)
          AND annotation.subject_deck_id = requested.id
          AND annotation.replay_id = CAST(@replayId AS uuid)
        ORDER BY annotation.created_at DESC, annotation.id DESC
        LIMIT @limit
      '''),
      parameters: {
        'userId': userId,
        'deckId': deckId,
        'replayId': replayId,
        'limit': limit.clamp(1, 100),
      },
    );
    return result
        .map((row) => _annotationFromRow(row.toColumnMap()))
        .toList(growable: false);
  }

  Future<BattleReplayAnnotationCreateResult> create({
    required String userId,
    required String deckId,
    required String replayId,
    required String idempotencyKey,
    required Map<String, dynamic> body,
  }) async {
    final request = _BattleReplayAnnotationRequest.parse(
      body,
      idempotencyKey: idempotencyKey,
    );

    return _pool.runTx((session) async {
      final scopeResult = await session.execute(
        Sql.named('''
          SELECT
            attempt.id::text AS attempt_id,
            CASE
              WHEN simulation.deck_a_id = requested.id THEN 'deck_a'
              ELSE 'deck_b'
            END AS subject_deck_key,
            attempt.deck_hash_schema,
            CASE
              WHEN simulation.deck_a_id = requested.id
              THEN attempt.deck_a_hash
              ELSE attempt.deck_b_hash
            END AS subject_deck_hash,
            simulation.game_log
          FROM battle_simulations simulation
          JOIN decks requested
            ON requested.id = CAST(@deckId AS uuid)
           AND requested.user_id = CAST(@userId AS uuid)
          JOIN battle_simulation_attempts attempt
            ON attempt.replay_id = simulation.id
          WHERE simulation.id = CAST(@replayId AS uuid)
            AND requested.id IN (
              simulation.deck_a_id,
              simulation.deck_b_id
            )
          LIMIT 1
          FOR KEY SHARE OF simulation, requested, attempt
        '''),
        parameters: {'userId': userId, 'deckId': deckId, 'replayId': replayId},
      );
      if (scopeResult.isEmpty) {
        throw const BattleReplayAnnotationNotFoundException();
      }

      final scope = scopeResult.first.toColumnMap();
      final deckHashSchema = _nonEmpty(scope['deck_hash_schema']);
      final subjectDeckHash = _nonEmpty(scope['subject_deck_hash']);
      if (deckHashSchema == null ||
          subjectDeckHash == null ||
          subjectDeckHash.length != 64) {
        throw const BattleReplayAnnotationRevisionUnavailableException();
      }
      if (deckHashSchema.length > 48) {
        throw const BattleReplayAnnotationRevisionUnavailableException();
      }

      _validateReplayReferenceBounds(
        request,
        persistedGameLog: scope['game_log'],
      );
      final subjectDeckRevision = '$deckHashSchema:$subjectDeckHash';
      final fingerprint = _fingerprint({
        'schema_version': battleReplayAnnotationSchema,
        'replay_id': replayId,
        'attempt_id': scope['attempt_id'],
        'subject_deck_id': deckId,
        'subject_deck_key': scope['subject_deck_key'],
        'deck_hash_schema': deckHashSchema,
        'subject_deck_hash': subjectDeckHash,
        'subject_deck_revision': subjectDeckRevision,
        'event_ref': request.eventRef,
        'snapshot_ref': request.snapshotRef,
        'kind': request.kind,
        'payload': request.payload,
      });

      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO battle_replay_annotations (
            user_id,
            replay_id,
            attempt_id,
            subject_deck_id,
            subject_deck_key,
            deck_hash_schema,
            subject_deck_hash,
            subject_deck_revision,
            event_ref,
            snapshot_ref,
            kind,
            payload,
            idempotency_key,
            request_fingerprint
          )
          VALUES (
            CAST(@userId AS uuid),
            CAST(@replayId AS uuid),
            CAST(@attemptId AS uuid),
            CAST(@deckId AS uuid),
            @subjectDeckKey,
            @deckHashSchema,
            @subjectDeckHash,
            @subjectDeckRevision,
            @eventRef,
            @snapshotRef,
            @kind,
            @payload::jsonb,
            @idempotencyKey,
            @requestFingerprint
          )
          ON CONFLICT DO NOTHING
          RETURNING
            id::text AS id,
            replay_id::text AS replay_id,
            attempt_id::text AS attempt_id,
            subject_deck_id::text AS subject_deck_id,
            subject_deck_key,
            deck_hash_schema,
            subject_deck_hash,
            subject_deck_revision,
            event_ref,
            snapshot_ref,
            kind,
            payload,
            created_at,
            updated_at
        '''),
        parameters: {
          'userId': userId,
          'replayId': replayId,
          'attemptId': scope['attempt_id'],
          'deckId': deckId,
          'subjectDeckKey': scope['subject_deck_key'],
          'deckHashSchema': deckHashSchema,
          'subjectDeckHash': subjectDeckHash,
          'subjectDeckRevision': subjectDeckRevision,
          'eventRef': request.eventRef,
          'snapshotRef': request.snapshotRef,
          'kind': request.kind,
          'payload': jsonEncode(request.payload),
          'idempotencyKey': request.idempotencyKey,
          'requestFingerprint': fingerprint,
        },
      );
      if (inserted.isNotEmpty) {
        return BattleReplayAnnotationCreateResult(
          annotation: _annotationFromRow(inserted.first.toColumnMap()),
          created: true,
        );
      }

      final byIdempotency = await _findByIdempotencyKey(
        session,
        userId: userId,
        idempotencyKey: request.idempotencyKey,
      );
      if (byIdempotency != null) {
        if (byIdempotency['request_fingerprint']?.toString() != fingerprint) {
          throw const BattleReplayAnnotationIdempotencyConflictException();
        }
        return BattleReplayAnnotationCreateResult(
          annotation: _annotationFromRow(byIdempotency),
          created: false,
        );
      }

      final singleton = await _findSingleton(
        session,
        userId: userId,
        deckId: deckId,
        replayId: replayId,
        request: request,
      );
      if (singleton != null) {
        if (singleton['request_fingerprint']?.toString() == fingerprint) {
          return BattleReplayAnnotationCreateResult(
            annotation: _annotationFromRow(singleton),
            created: false,
          );
        }
        throw const BattleReplayAnnotationAlreadyRecordedException();
      }
      throw StateError('Battle annotation insert did not return a row.');
    });
  }

  Future<bool> delete({
    required String userId,
    required String deckId,
    required String replayId,
    required String annotationId,
  }) async {
    final deleted = await _pool.execute(
      Sql.named('''
        DELETE FROM battle_replay_annotations annotation
        USING decks requested
        WHERE annotation.id = CAST(@annotationId AS uuid)
          AND annotation.user_id = CAST(@userId AS uuid)
          AND annotation.subject_deck_id = CAST(@deckId AS uuid)
          AND annotation.replay_id = CAST(@replayId AS uuid)
          AND requested.id = annotation.subject_deck_id
          AND requested.user_id = CAST(@userId AS uuid)
        RETURNING annotation.id::text
      '''),
      parameters: {
        'userId': userId,
        'deckId': deckId,
        'replayId': replayId,
        'annotationId': annotationId,
      },
    );
    return deleted.isNotEmpty;
  }

  Future<Map<String, dynamic>?> _findByIdempotencyKey(
    Session session, {
    required String userId,
    required String idempotencyKey,
  }) async {
    final result = await session.execute(
      Sql.named('''
        SELECT
          id::text AS id,
          replay_id::text AS replay_id,
          attempt_id::text AS attempt_id,
          subject_deck_id::text AS subject_deck_id,
          subject_deck_key,
          deck_hash_schema,
          subject_deck_hash,
          subject_deck_revision,
          event_ref,
          snapshot_ref,
          kind,
          payload,
          request_fingerprint,
          created_at,
          updated_at
        FROM battle_replay_annotations
        WHERE user_id = CAST(@userId AS uuid)
          AND idempotency_key = @idempotencyKey
        LIMIT 1
      '''),
      parameters: {'userId': userId, 'idempotencyKey': idempotencyKey},
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> _findSingleton(
    Session session, {
    required String userId,
    required String deckId,
    required String replayId,
    required _BattleReplayAnnotationRequest request,
  }) async {
    final predicate = switch (request.kind) {
      'would_do_differently' => 'AND event_ref = @eventRef',
      'mulligan_decision' => 'AND snapshot_ref = @snapshotRef',
      'helpful_feedback' => '',
      _ => null,
    };
    if (predicate == null) return null;

    final result = await session.execute(
      Sql.named('''
        SELECT
          id::text AS id,
          replay_id::text AS replay_id,
          attempt_id::text AS attempt_id,
          subject_deck_id::text AS subject_deck_id,
          subject_deck_key,
          deck_hash_schema,
          subject_deck_hash,
          subject_deck_revision,
          event_ref,
          snapshot_ref,
          kind,
          payload,
          request_fingerprint,
          created_at,
          updated_at
        FROM battle_replay_annotations
        WHERE user_id = CAST(@userId AS uuid)
          AND subject_deck_id = CAST(@deckId AS uuid)
          AND replay_id = CAST(@replayId AS uuid)
          AND kind = @kind
          $predicate
        LIMIT 1
      '''),
      parameters: {
        'userId': userId,
        'deckId': deckId,
        'replayId': replayId,
        'kind': request.kind,
        'eventRef': request.eventRef,
        'snapshotRef': request.snapshotRef,
      },
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }
}

class _BattleReplayAnnotationRequest {
  const _BattleReplayAnnotationRequest({
    required this.kind,
    required this.payload,
    required this.idempotencyKey,
    this.eventRef,
    this.snapshotRef,
  });

  final String kind;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final String? eventRef;
  final String? snapshotRef;

  static _BattleReplayAnnotationRequest parse(
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) {
    const allowedTopLevelKeys = {
      'kind',
      'payload',
      'event_ref',
      'snapshot_ref',
      'idempotency_key',
    };
    final unknownKeys = body.keys
        .where((key) => !allowedTopLevelKeys.contains(key))
        .toList(growable: false);
    if (unknownKeys.isNotEmpty) {
      throw const BattleReplayAnnotationValidationException(
        'O corpo contem campos nao suportados.',
      );
    }

    final normalizedKey = idempotencyKey.trim();
    if (!_idempotencyKeyPattern.hasMatch(normalizedKey)) {
      throw const BattleReplayAnnotationValidationException(
        'Idempotency-Key deve ter 1 a 128 caracteres seguros.',
      );
    }
    final bodyKey = _optionalText(body['idempotency_key']);
    if (bodyKey != null && bodyKey != normalizedKey) {
      throw const BattleReplayAnnotationValidationException(
        'Idempotency-Key diverge do corpo.',
      );
    }

    final kind = _requiredText(body['kind'], field: 'kind').toLowerCase();
    if (!battleReplayAnnotationKinds.contains(kind)) {
      throw const BattleReplayAnnotationValidationException(
        'kind nao suportado.',
      );
    }
    final eventRef = _reference(
      body['event_ref'],
      field: 'event_ref',
      pattern: _eventRefPattern,
      prefix: 'event',
    );
    final snapshotRef = _reference(
      body['snapshot_ref'],
      field: 'snapshot_ref',
      pattern: _snapshotRefPattern,
      prefix: 'snapshot',
    );
    final rawPayload = body['payload'];
    if (rawPayload != null && rawPayload is! Map) {
      throw const BattleReplayAnnotationValidationException(
        'payload deve ser um objeto JSON.',
      );
    }
    final payload = _normalizePayload(
      kind,
      rawPayload is Map
          ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{},
      eventRef: eventRef,
      snapshotRef: snapshotRef,
    );

    return _BattleReplayAnnotationRequest(
      kind: kind,
      payload: payload,
      idempotencyKey: normalizedKey,
      eventRef: eventRef,
      snapshotRef: snapshotRef,
    );
  }
}

Map<String, dynamic> _normalizePayload(
  String kind,
  Map<String, dynamic> payload, {
  required String? eventRef,
  required String? snapshotRef,
}) {
  late final Map<String, dynamic> normalized;
  switch (kind) {
    case 'bookmark':
      _requireOnly(payload, const {'label'});
      normalized = {
        if (payload['label'] != null)
          'label': _boundedText(
            payload['label'],
            field: 'payload.label',
            maxLength: 120,
          ),
      };
      break;
    case 'note':
      _requireOnly(payload, const {'text', 'title'});
      normalized = {
        'text': _boundedText(
          payload['text'],
          field: 'payload.text',
          maxLength: 2000,
        ),
        if (payload['title'] != null)
          'title': _boundedText(
            payload['title'],
            field: 'payload.title',
            maxLength: 120,
          ),
      };
      break;
    case 'would_do_differently':
      if (eventRef == null) {
        throw const BattleReplayAnnotationValidationException(
          'would_do_differently exige event_ref.',
        );
      }
      if (snapshotRef != null) {
        throw const BattleReplayAnnotationValidationException(
          'would_do_differently nao aceita snapshot_ref.',
        );
      }
      _requireOnly(payload, const {'stance', 'reason'});
      final stance =
          _requiredText(
            payload['stance'],
            field: 'payload.stance',
          ).toLowerCase();
      if (!const {'would_change', 'would_repeat', 'unsure'}.contains(stance)) {
        throw const BattleReplayAnnotationValidationException(
          'payload.stance nao suportado.',
        );
      }
      normalized = {
        'stance': stance,
        if (payload['reason'] != null)
          'reason': _boundedText(
            payload['reason'],
            field: 'payload.reason',
            maxLength: 1000,
          ),
        'capture_contract': 'before_next_event_reveal',
      };
      break;
    case 'mulligan_decision':
      if (snapshotRef == null) {
        throw const BattleReplayAnnotationValidationException(
          'mulligan_decision exige snapshot_ref.',
        );
      }
      if (eventRef != null) {
        throw const BattleReplayAnnotationValidationException(
          'mulligan_decision nao aceita event_ref.',
        );
      }
      _requireOnly(payload, const {'choice', 'hand_size', 'mulligan_number'});
      final choice =
          _requiredText(
            payload['choice'],
            field: 'payload.choice',
          ).toLowerCase();
      if (!const {'keep', 'mulligan'}.contains(choice)) {
        throw const BattleReplayAnnotationValidationException(
          'payload.choice deve ser keep ou mulligan.',
        );
      }
      final handSize = _boundedInt(
        payload['hand_size'],
        field: 'payload.hand_size',
        min: 0,
        max: 7,
      );
      final mulliganNumber = _boundedInt(
        payload['mulligan_number'],
        field: 'payload.mulligan_number',
        min: 0,
        max: 7,
      );
      normalized = {
        'choice': choice,
        'hand_size': handSize,
        'mulligan_number': mulliganNumber,
        'capture_contract': 'human_choice_before_heuristic_reveal',
        'claims_correct_answer': false,
      };
      break;
    case 'helpful_feedback':
      if (eventRef != null || snapshotRef != null) {
        throw const BattleReplayAnnotationValidationException(
          'helpful_feedback nao aceita referencia de replay.',
        );
      }
      _requireOnly(payload, const {'helpful', 'surface'});
      if (payload['helpful'] is! bool) {
        throw const BattleReplayAnnotationValidationException(
          'payload.helpful deve ser booleano.',
        );
      }
      final surface =
          _requiredText(
            payload['surface'],
            field: 'payload.surface',
          ).toLowerCase();
      if (!const {
        'post_battle_report',
        'replay_timeline',
        'battle_insight',
      }.contains(surface)) {
        throw const BattleReplayAnnotationValidationException(
          'payload.surface nao suportado.',
        );
      }
      normalized = {'helpful': payload['helpful'], 'surface': surface};
      break;
    case 'event_report':
      if (eventRef == null) {
        throw const BattleReplayAnnotationValidationException(
          'event_report exige event_ref.',
        );
      }
      if (snapshotRef != null) {
        throw const BattleReplayAnnotationValidationException(
          'event_report nao aceita snapshot_ref.',
        );
      }
      _requireOnly(payload, const {'reason_code', 'details'});
      final reasonCode =
          _requiredText(
            payload['reason_code'],
            field: 'payload.reason_code',
          ).toLowerCase();
      if (!const {
        'incorrect_event',
        'wrong_attribution',
        'hidden_information',
        'missing_context',
        'other',
      }.contains(reasonCode)) {
        throw const BattleReplayAnnotationValidationException(
          'payload.reason_code nao suportado.',
        );
      }
      normalized = {
        'reason_code': reasonCode,
        if (payload['details'] != null)
          'details': _boundedText(
            payload['details'],
            field: 'payload.details',
            maxLength: 500,
          ),
      };
      break;
    default:
      throw const BattleReplayAnnotationValidationException(
        'kind nao suportado.',
      );
  }

  final sanitized = sanitizeBattleReplayMetadata(normalized);
  if (utf8.encode(jsonEncode(sanitized)).length > 8192) {
    throw const BattleReplayAnnotationValidationException(
      'payload excede o limite permitido.',
    );
  }
  return sanitized;
}

void _validateReplayReferenceBounds(
  _BattleReplayAnnotationRequest request, {
  required Object? persistedGameLog,
}) {
  final decoded = _decodeJson(persistedGameLog);
  final events = _events(decoded);
  final snapshots = _snapshots(decoded, events: events);

  final eventIndex = _referenceIndex(request.eventRef);
  if (eventIndex != null && eventIndex >= events.length) {
    throw const BattleReplayAnnotationValidationException(
      'event_ref nao existe neste replay.',
    );
  }
  final snapshotIndex = _referenceIndex(request.snapshotRef);
  if (snapshotIndex != null && snapshotIndex >= snapshots.length) {
    throw const BattleReplayAnnotationValidationException(
      'snapshot_ref nao existe neste replay.',
    );
  }
}

Object? _decodeJson(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    throw StateError('Persisted battle replay is invalid.');
  }
}

List<dynamic> _events(Object? replay) {
  if (replay is List) return replay;
  if (replay is Map) {
    final nested = replay['game_log'];
    if (nested is List) return nested;
    final events = replay['events'];
    if (events is List) return events;
  }
  return const [];
}

List<dynamic> _snapshots(Object? replay, {required List<dynamic> events}) {
  if (replay is! Map) return const [];
  for (final key in const [
    'visual_snapshots',
    'snapshots',
    'replay_snapshots',
  ]) {
    final value = replay[key];
    if (value is List && value.isNotEmpty) return value;
  }
  final eventSnapshots = events
      .whereType<Map>()
      .map((event) => event['snapshot'])
      .whereType<Map>()
      .toList(growable: false);
  if (eventSnapshots.isNotEmpty) return eventSnapshots;
  return replay['final_state'] is Map ? const [{}] : const [];
}

int? _referenceIndex(String? reference) =>
    reference == null ? null : int.parse(reference.split(':').last);

Map<String, dynamic> _annotationFromRow(Map<String, dynamic> row) => {
  'schema_version': battleReplayAnnotationSchema,
  'id': row['id']?.toString(),
  'replay_id': row['replay_id']?.toString(),
  'attempt_id': row['attempt_id']?.toString(),
  'subject_deck_id': row['subject_deck_id']?.toString(),
  'subject_deck_key': row['subject_deck_key']?.toString(),
  'deck_hash_schema': row['deck_hash_schema']?.toString(),
  'subject_deck_hash': row['subject_deck_hash']?.toString(),
  'subject_deck_revision': row['subject_deck_revision']?.toString(),
  if (row['event_ref'] != null) 'event_ref': row['event_ref']?.toString(),
  if (row['snapshot_ref'] != null)
    'snapshot_ref': row['snapshot_ref']?.toString(),
  'kind': row['kind']?.toString(),
  'payload': _jsonMap(row['payload']),
  'created_at': _timestamp(row['created_at']),
  'updated_at': _timestamp(row['updated_at']),
  'immutable_replay': true,
};

Map<String, dynamic> _jsonMap(Object? value) {
  final decoded = _decodeJson(value);
  if (decoded is Map) {
    return decoded.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String _fingerprint(Map<String, dynamic> value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalJson(value)))).toString();

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalJson(value[key])};
  }
  if (value is List) {
    return value.map(_canonicalJson).toList(growable: false);
  }
  return value;
}

String? _reference(
  Object? value, {
  required String field,
  required RegExp pattern,
  required String prefix,
}) {
  if (value == null) return null;
  if (value is! String || !pattern.hasMatch(value.trim())) {
    throw BattleReplayAnnotationValidationException(
      '$field deve usar $prefix:<indice>.',
    );
  }
  return '$prefix:${int.parse(value.trim().split(':').last)}';
}

String _requiredText(Object? value, {required String field}) =>
    _boundedText(value, field: field, maxLength: 128);

String _boundedText(
  Object? value, {
  required String field,
  required int maxLength,
}) {
  if (value is! String) {
    throw BattleReplayAnnotationValidationException('$field deve ser texto.');
  }
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.runes.length > maxLength) {
    throw BattleReplayAnnotationValidationException(
      '$field deve ter entre 1 e $maxLength caracteres.',
    );
  }
  return normalized;
}

String? _optionalText(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const BattleReplayAnnotationValidationException(
      'idempotency_key deve ser texto.',
    );
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _boundedInt(
  Object? value, {
  required String field,
  required int min,
  required int max,
}) {
  if (value is! int || value < min || value > max) {
    throw BattleReplayAnnotationValidationException(
      '$field deve estar entre $min e $max.',
    );
  }
  return value;
}

void _requireOnly(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const BattleReplayAnnotationValidationException(
      'payload contem campos nao suportados.',
    );
  }
}

String? _nonEmpty(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _timestamp(Object? value) =>
    value is DateTime ? value.toUtc().toIso8601String() : value?.toString();
