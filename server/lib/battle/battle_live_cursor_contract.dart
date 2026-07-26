import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

const battleLiveCursorSchemaVersion = 'battle_live_cursor_v1';
const battleLivePollingTransport = 'polling_long_polling';
const battleLiveDefaultPageLimit = 50;
const battleLiveMaximumPageLimit = 100;
const battleLiveDefaultMaximumPayloadBytes = 128 * 1024;

class BattleLiveContractException implements Exception {
  const BattleLiveContractException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveContractException($code)';
}

enum BattleLiveStatus {
  queued,
  claimed,
  running,
  cancelPending,
  completed,
  censored,
  timeout,
  coverageError,
  engineError,
  cancelled,
  persistenceError,
  interrupted,
}

extension BattleLiveStatusContract on BattleLiveStatus {
  String get wireValue => switch (this) {
    BattleLiveStatus.queued => 'queued',
    BattleLiveStatus.claimed => 'claimed',
    BattleLiveStatus.running => 'running',
    BattleLiveStatus.cancelPending => 'cancel_pending',
    BattleLiveStatus.completed => 'completed',
    BattleLiveStatus.censored => 'censored',
    BattleLiveStatus.timeout => 'timeout',
    BattleLiveStatus.coverageError => 'coverage_error',
    BattleLiveStatus.engineError => 'engine_error',
    BattleLiveStatus.cancelled => 'cancelled',
    BattleLiveStatus.persistenceError => 'persistence_error',
    BattleLiveStatus.interrupted => 'interrupted',
  };

  bool get isTerminal => switch (this) {
    BattleLiveStatus.queued ||
    BattleLiveStatus.claimed ||
    BattleLiveStatus.running ||
    BattleLiveStatus.cancelPending => false,
    _ => true,
  };
}

enum BattleLiveRecordKind { event, snapshot }

extension BattleLiveRecordKindContract on BattleLiveRecordKind {
  String get wireValue => switch (this) {
    BattleLiveRecordKind.event => 'event',
    BattleLiveRecordKind.snapshot => 'snapshot',
  };
}

class BattleLiveSourceRecord {
  BattleLiveSourceRecord.event({
    required this.sequence,
    required this.recordId,
    required Map<String, dynamic> event,
    this.contentTruncated = false,
  }) : kind = BattleLiveRecordKind.event,
       payload = Map.unmodifiable(event);

  BattleLiveSourceRecord.snapshot({
    required this.sequence,
    required this.recordId,
    required Map<String, dynamic> snapshot,
    this.contentTruncated = false,
  }) : kind = BattleLiveRecordKind.snapshot,
       payload = Map.unmodifiable(snapshot);

  final int sequence;
  final String recordId;
  final BattleLiveRecordKind kind;
  final Map<String, dynamic> payload;
  final bool contentTruncated;
}

class BattleLivePublicItem {
  BattleLivePublicItem({
    required this.sequence,
    required this.recordId,
    required this.kind,
    required this.cursor,
    required Map<String, dynamic> payload,
    required this.contentTruncated,
  }) : payload = Map.unmodifiable(payload);

  final int sequence;
  final String recordId;
  final BattleLiveRecordKind kind;
  final String cursor;
  final Map<String, dynamic> payload;
  final bool contentTruncated;

  Map<String, dynamic> toJson() => {
    'schema_version': battleLiveCursorSchemaVersion,
    'cursor': cursor,
    'sequence': sequence,
    'record_id': recordId,
    'kind': kind.wireValue,
    kind.wireValue: payload,
    'content_truncated': contentTruncated,
  };
}

class BattleLiveReplayReference {
  const BattleLiveReplayReference(this.replayId);

  final String replayId;

  Map<String, dynamic> toJson() => {'replay_id': replayId, 'available': true};
}

class BattleLiveTruncation {
  const BattleLiveTruncation({
    required this.source,
    required this.pageLimit,
    required this.payloadLimit,
    required this.fieldLimit,
  });

  final bool source;
  final bool pageLimit;
  final bool payloadLimit;
  final bool fieldLimit;

  bool get any => source || pageLimit || payloadLimit || fieldLimit;

  Map<String, dynamic> toJson() => {
    'source': source,
    'page_limit': pageLimit,
    'payload_limit': payloadLimit,
    'field_limit': fieldLimit,
  };
}

class BattleLivePage {
  BattleLivePage({
    required this.streamId,
    required this.status,
    required List<BattleLivePublicItem> items,
    required this.nextCursor,
    required this.hasMore,
    required this.truncation,
    required this.pageLimit,
    required this.maximumPayloadBytes,
    required this.replay,
    required this.replayPending,
    required this.replayAlreadyDelivered,
    required this.terminalReason,
  }) : items = List.unmodifiable(items);

  final String streamId;
  final BattleLiveStatus status;
  final List<BattleLivePublicItem> items;
  final String nextCursor;
  final bool hasMore;
  final BattleLiveTruncation truncation;
  final int pageLimit;
  final int maximumPayloadBytes;
  final BattleLiveReplayReference? replay;
  final bool replayPending;
  final bool replayAlreadyDelivered;
  final String? terminalReason;

  Map<String, dynamic> toJson() => {
    'schema_version': battleLiveCursorSchemaVersion,
    'transport': battleLivePollingTransport,
    'stream_id': streamId,
    'status': status.wireValue,
    'is_terminal': status.isTerminal,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'truncated': truncation.any,
    'truncation': truncation.toJson(),
    'limits': {'page': pageLimit, 'payload_bytes': maximumPayloadBytes},
    'replay_pending': replayPending,
    'replay_already_delivered': replayAlreadyDelivered,
    if (replay != null) 'replay': replay!.toJson(),
  };
}

class BattleLiveCursorContract {
  BattleLiveCursorContract({
    required List<int> cursorSigningKey,
    this.defaultPageLimit = battleLiveDefaultPageLimit,
    this.maximumPageLimit = battleLiveMaximumPageLimit,
    this.maximumPayloadBytes = battleLiveDefaultMaximumPayloadBytes,
    this.maximumPublicStringRunes = 2048,
    this.maximumPublicCollectionEntries = 64,
  }) : _cursorMac = Hmac(sha256, List<int>.from(cursorSigningKey)) {
    if (cursorSigningKey.length < 32) {
      throw ArgumentError.value(
        cursorSigningKey.length,
        'cursorSigningKey',
        'must contain at least 32 bytes',
      );
    }
    if (defaultPageLimit < 1 || defaultPageLimit > maximumPageLimit) {
      throw ArgumentError.value(
        defaultPageLimit,
        'defaultPageLimit',
        'must be between 1 and maximumPageLimit',
      );
    }
    if (maximumPageLimit < 1 || maximumPageLimit > 1000) {
      throw ArgumentError.value(
        maximumPageLimit,
        'maximumPageLimit',
        'must be between 1 and 1000',
      );
    }
    if (maximumPayloadBytes < 1024) {
      throw ArgumentError.value(
        maximumPayloadBytes,
        'maximumPayloadBytes',
        'must be at least 1024',
      );
    }
    if (maximumPublicStringRunes < 1 || maximumPublicCollectionEntries < 1) {
      throw ArgumentError('Public field limits must be positive.');
    }
  }

  final Hmac _cursorMac;
  final int defaultPageLimit;
  final int maximumPageLimit;
  final int maximumPayloadBytes;
  final int maximumPublicStringRunes;
  final int maximumPublicCollectionEntries;

  List<BattleLiveSourceRecord> sanitizeRecordsForStorage(
    Iterable<BattleLiveSourceRecord> records,
  ) {
    return _prepareRecords(records)
        .map(
          (record) => switch (record.kind) {
            BattleLiveRecordKind.event => BattleLiveSourceRecord.event(
              sequence: record.sequence,
              recordId: record.recordId,
              event: record.payload,
              contentTruncated: record.contentTruncated,
            ),
            BattleLiveRecordKind.snapshot => BattleLiveSourceRecord.snapshot(
              sequence: record.sequence,
              recordId: record.recordId,
              snapshot: record.payload,
              contentTruncated: record.contentTruncated,
            ),
          },
        )
        .toList(growable: false);
  }

  BattleLivePage buildPage({
    required String streamId,
    required BattleLiveStatus status,
    required Iterable<BattleLiveSourceRecord> records,
    String? cursor,
    int? requestedLimit,
    String? replayId,
    String? terminalReason,
    bool sourceTruncated = false,
  }) {
    _validateIdentifier(streamId, code: 'invalid_stream_id');
    if (replayId != null) {
      _validateIdentifier(replayId, code: 'invalid_replay_id');
    }
    if (!status.isTerminal && replayId != null) {
      throw const BattleLiveContractException(
        'replay_requires_terminal_status',
      );
    }
    if (!status.isTerminal && terminalReason != null) {
      throw const BattleLiveContractException(
        'terminal_reason_requires_terminal_status',
      );
    }
    if (terminalReason != null &&
        !_publicTerminalReasonPattern.hasMatch(terminalReason)) {
      throw const BattleLiveContractException('invalid_terminal_reason');
    }

    final limit = _pageLimit(requestedLimit);
    final cursorState =
        cursor == null
            ? const _BattleLiveCursorState(
              afterSequence: -1,
              replayDelivered: false,
            )
            : _decodeCursor(cursor, expectedStreamId: streamId);
    final prepared = _prepareRecords(records);
    final available = prepared
        .where((record) => record.sequence > cursorState.afterSequence)
        .toList(growable: false);
    final initialCount = math.min(limit, available.length);
    var selected = available.take(initialCount).toList(growable: true);
    var payloadLimitApplied = false;
    var forcedSkeleton = false;
    var skeletonWasTried = false;

    while (true) {
      final hasMoreRecords = available.length > selected.length;
      final includeReplay =
          status.isTerminal &&
          !hasMoreRecords &&
          replayId != null &&
          !cursorState.replayDelivered;
      final replayDelivered = cursorState.replayDelivered || includeReplay;
      final afterSequence =
          selected.isEmpty ? cursorState.afterSequence : selected.last.sequence;
      final nextCursor = _encodeCursor(
        streamId: streamId,
        state: _BattleLiveCursorState(
          afterSequence: afterSequence,
          replayDelivered: replayDelivered,
        ),
      );
      final items = selected
          .map(
            (record) => BattleLivePublicItem(
              sequence: record.sequence,
              recordId: record.recordId,
              kind: record.kind,
              cursor: _encodeCursor(
                streamId: streamId,
                state: _BattleLiveCursorState(
                  afterSequence: record.sequence,
                  replayDelivered: cursorState.replayDelivered,
                ),
              ),
              payload: record.payload,
              contentTruncated: record.contentTruncated || forcedSkeleton,
            ),
          )
          .toList(growable: false);
      final page = BattleLivePage(
        streamId: streamId,
        status: status,
        items: items,
        nextCursor: nextCursor,
        hasMore: hasMoreRecords,
        truncation: BattleLiveTruncation(
          source: sourceTruncated,
          pageLimit: available.length > limit,
          payloadLimit: payloadLimitApplied,
          fieldLimit:
              forcedSkeleton ||
              selected.any((record) => record.contentTruncated),
        ),
        pageLimit: limit,
        maximumPayloadBytes: maximumPayloadBytes,
        replay: includeReplay ? BattleLiveReplayReference(replayId) : null,
        replayPending:
            status.isTerminal && replayId != null && !replayDelivered,
        replayAlreadyDelivered: cursorState.replayDelivered,
        terminalReason: terminalReason,
      );

      if (_encodedBytes(page) <= maximumPayloadBytes) {
        if (selected.isEmpty && available.isNotEmpty && !skeletonWasTried) {
          skeletonWasTried = true;
          forcedSkeleton = true;
          selected = [available.first.asSkeleton()];
          continue;
        }
        return page;
      }

      payloadLimitApplied = true;
      if (selected.isNotEmpty) {
        selected.removeLast();
        if (forcedSkeleton) {
          throw const BattleLiveContractException('payload_limit_too_small');
        }
        continue;
      }

      if (available.isNotEmpty && !skeletonWasTried) {
        skeletonWasTried = true;
        forcedSkeleton = true;
        selected = [available.first.asSkeleton()];
        continue;
      }
      throw const BattleLiveContractException('payload_limit_too_small');
    }
  }

  int _pageLimit(int? requested) {
    final value = requested ?? defaultPageLimit;
    if (value < 1) {
      throw const BattleLiveContractException('invalid_page_limit');
    }
    return math.min(value, maximumPageLimit);
  }

  List<_PreparedBattleLiveRecord> _prepareRecords(
    Iterable<BattleLiveSourceRecord> records,
  ) {
    final bySequence = <int, _PreparedBattleLiveRecord>{};
    final sequenceByRecordId = <String, int>{};

    for (final record in records) {
      if (record.sequence < 0) {
        throw const BattleLiveContractException('invalid_record_sequence');
      }
      _validateIdentifier(record.recordId, code: 'invalid_record_id');
      final previousSequence = sequenceByRecordId[record.recordId];
      if (previousSequence != null && previousSequence != record.sequence) {
        throw const BattleLiveContractException('record_id_sequence_conflict');
      }

      final publicPayload = switch (record.kind) {
        BattleLiveRecordKind.event => _publicEvent(record.payload),
        BattleLiveRecordKind.snapshot => _publicSnapshot(record.payload),
      };
      final prepared = _PreparedBattleLiveRecord(
        sequence: record.sequence,
        recordId: record.recordId,
        kind: record.kind,
        payload: publicPayload.value,
        contentTruncated: record.contentTruncated || publicPayload.truncated,
      );
      final existing = bySequence[record.sequence];
      if (existing != null) {
        if (!existing.hasSamePublicContent(prepared)) {
          throw const BattleLiveContractException('record_sequence_conflict');
        }
        continue;
      }
      bySequence[record.sequence] = prepared;
      sequenceByRecordId[record.recordId] = record.sequence;
    }

    final prepared = bySequence.values.toList(growable: false);
    prepared.sort((left, right) => left.sequence.compareTo(right.sequence));
    return prepared;
  }

  _PublicValue<Map<String, dynamic>> _publicEvent(Map<String, dynamic> source) {
    final type = _string(source['event_type'] ?? source['type']);
    final normalizedType = type?.trim().toLowerCase();
    if (normalizedType == null || !_publicEventTypes.contains(normalizedType)) {
      return const _PublicValue(<String, dynamic>{}, false);
    }

    final builder = _PublicMapBuilder(this);
    builder.literal('event_type', normalizedType);
    builder.string('event_id', source['event_id']);
    builder.integer('turn', source['turn']);
    builder.string('phase', source['phase']);
    builder.string('step', source['step']);
    builder.string('actor', source['actor']);
    builder.string('actor_side', source['actor_side']);
    builder.string('subject_deck_key', source['subject_deck_key']);
    builder.string('target_side', source['target_side']);
    builder.string('severity', source['severity']);
    builder.integer('amount', source['amount']);
    builder.integer('damage', source['damage']);
    builder.integer('life_after', source['life_after']);
    builder.boolean('tapped', source['tapped']);

    final details = _stringMap(source['details']);
    final hasExplicitPublicVisibility =
        source['publicly_visible'] == true ||
        _string(source['visibility']) == 'public' ||
        _string(details?['visibility']) == 'public';
    final identityIsPublic =
        _alwaysPublicIdentityEventTypes.contains(normalizedType) ||
        (_explicitPublicIdentityEventTypes.contains(normalizedType) &&
            hasExplicitPublicVisibility);
    final messageIsPublic =
        _alwaysPublicMessageEventTypes.contains(normalizedType) ||
        (_explicitPublicIdentityEventTypes.contains(normalizedType) &&
            hasExplicitPublicVisibility);
    if (identityIsPublic) {
      builder.string('card_name', source['card_name']);
    }
    if (messageIsPublic) {
      builder.string('message', source['message']);
    }
    if (details != null) {
      final publicDetails = _publicEventDetails(
        details,
        includeIdentity: identityIsPublic,
      );
      builder.nested('details', publicDetails);
    }
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicEventDetails(
    Map<String, dynamic> source, {
    required bool includeIdentity,
  }) {
    final builder = _PublicMapBuilder(this);
    if (includeIdentity) {
      builder.string('card_name', source['card_name']);
      builder.string('source_card_name', source['source_card_name']);
      builder.string('target_card_name', source['target_card_name']);
      builder.string('object_name', source['object_name']);
    }
    builder.string('zone_from', source['zone_from']);
    builder.string('zone_to', source['zone_to']);
    builder.string('counter_type', source['counter_type']);
    builder.string('player_side', source['player_side']);
    builder.string('target_side', source['target_side']);
    builder.string('defender_side', source['defender_side']);
    builder.integer('amount', source['amount']);
    builder.integer('damage', source['damage']);
    builder.integer('life_before', source['life_before']);
    builder.integer('life_after', source['life_after']);
    builder.integer('counter_delta', source['counter_delta']);
    builder.boolean('is_commander', source['is_commander']);
    builder.boolean('tapped', source['tapped']);
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicSnapshot(
    Map<String, dynamic> source,
  ) {
    final builder = _PublicMapBuilder(this);
    builder.string('snapshot_id', source['snapshot_id']);
    builder.integer('index', source['index']);
    builder.integer('turn', source['turn']);
    builder.string('phase', source['phase']);
    builder.string('step', source['step']);
    builder.string('action', source['action']);
    builder.string('active_player', source['active_player']);
    builder.string('priority_player', source['priority_player']);
    builder.boolean('final', source['final']);
    builder.listOfMaps('players', source['players'], _publicSnapshotPlayer);
    builder.listOfMaps('stack', source['stack'], _publicStackObject);
    builder.listOfMaps('combat', source['combat'], _publicCombatGroup);
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicSnapshotPlayer(
    Map<String, dynamic> source,
  ) {
    final builder = _PublicMapBuilder(this);
    builder.string('deck_key', source['deck_key']);
    builder.string('name', source['name']);
    builder.integer('life', source['life']);
    builder.integer('mana', source['mana']);
    builder.integer('mana_available', source['mana_available']);
    builder.integer('hand_size', source['hand_size']);
    builder.integer('library_size', source['library_size']);
    builder.integer('battlefield_count', source['battlefield_count']);
    builder.integer('graveyard_size', source['graveyard_size']);
    builder.integer('exile_size', source['exile_size']);
    builder.integer('command_size', source['command_size']);
    builder.integer('lands', source['lands']);
    builder.boolean('has_left', source['has_left']);
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicStackObject(
    Map<String, dynamic> source,
  ) {
    final builder = _PublicMapBuilder(this);
    builder.string('object_id', source['object_id']);
    builder.string('name', source['name']);
    builder.string('card_name', source['card_name']);
    builder.string('object_type', source['object_type']);
    builder.string('controller_side', source['controller_side']);
    builder.string('ability_type', source['ability_type']);
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicCombatGroup(
    Map<String, dynamic> source,
  ) {
    final builder = _PublicMapBuilder(this);
    builder.string('defender_side', source['defender_side']);
    builder.string('defender_name', source['defender_name']);
    builder.boolean('blocked', source['blocked']);
    builder.listOfMaps('attackers', source['attackers'], _publicCombatObject);
    builder.listOfMaps('blockers', source['blockers'], _publicCombatObject);
    return builder.build();
  }

  _PublicValue<Map<String, dynamic>> _publicCombatObject(
    Map<String, dynamic> source,
  ) {
    final builder = _PublicMapBuilder(this);
    builder.string('object_id', source['object_id']);
    builder.string('name', source['name']);
    builder.string('card_name', source['card_name']);
    builder.string('controller_side', source['controller_side']);
    builder.string('power', source['power']);
    builder.string('toughness', source['toughness']);
    builder.integer('damage', source['damage']);
    builder.boolean('tapped', source['tapped']);
    return builder.build();
  }

  String _encodeCursor({
    required String streamId,
    required _BattleLiveCursorState state,
  }) {
    final body = _withoutPadding(
      base64Url.encode(
        utf8.encode(
          jsonEncode({
            'schema': battleLiveCursorSchemaVersion,
            'version': 1,
            'stream': streamId,
            'after': state.afterSequence,
            'replay_delivered': state.replayDelivered,
          }),
        ),
      ),
    );
    final signature = _withoutPadding(
      base64Url.encode(_cursorMac.convert(utf8.encode(body)).bytes),
    );
    return 'blc1.$body.$signature';
  }

  _BattleLiveCursorState _decodeCursor(
    String cursor, {
    required String expectedStreamId,
  }) {
    if (cursor.length > 2048) {
      throw const BattleLiveContractException('invalid_cursor');
    }
    final parts = cursor.split('.');
    if (parts.length != 3 || parts.first != 'blc1') {
      throw const BattleLiveContractException('invalid_cursor');
    }
    final expectedSignature = _cursorMac.convert(utf8.encode(parts[1])).bytes;
    late final List<int> actualSignature;
    late final Object decoded;
    try {
      actualSignature = base64Url.decode(base64Url.normalize(parts[2]));
      decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } on Object {
      throw const BattleLiveContractException('invalid_cursor');
    }
    if (!_constantTimeEquals(actualSignature, expectedSignature) ||
        decoded is! Map) {
      throw const BattleLiveContractException('invalid_cursor');
    }
    final payload = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    if (payload.length != 5 ||
        payload['schema'] != battleLiveCursorSchemaVersion ||
        payload['version'] != 1 ||
        payload['stream'] is! String ||
        payload['after'] is! int ||
        payload['replay_delivered'] is! bool) {
      throw const BattleLiveContractException('invalid_cursor');
    }
    if (payload['stream'] != expectedStreamId) {
      throw const BattleLiveContractException('cursor_stream_mismatch');
    }
    final afterSequence = payload['after'] as int;
    if (afterSequence < -1) {
      throw const BattleLiveContractException('invalid_cursor');
    }
    return _BattleLiveCursorState(
      afterSequence: afterSequence,
      replayDelivered: payload['replay_delivered'] as bool,
    );
  }

  _PublicValue<String?> _boundedString(Object? value) {
    final source = _string(value);
    if (source == null) return const _PublicValue(null, false);
    final runes = source.runes;
    if (runes.length <= maximumPublicStringRunes) {
      return _PublicValue(source, false);
    }
    return _PublicValue(
      String.fromCharCodes(runes.take(maximumPublicStringRunes)),
      true,
    );
  }

  int _encodedBytes(BattleLivePage page) =>
      utf8.encode(jsonEncode(page.toJson())).length;
}

class _PublicMapBuilder {
  _PublicMapBuilder(this.contract);

  final BattleLiveCursorContract contract;
  final Map<String, dynamic> _value = {};
  bool _truncated = false;

  void literal(String key, Object value) {
    _value[key] = value;
  }

  void string(String key, Object? source) {
    final bounded = contract._boundedString(source);
    if (bounded.value == null) return;
    _value[key] = bounded.value;
    _truncated = _truncated || bounded.truncated;
  }

  void integer(String key, Object? source) {
    if (source is int) _value[key] = source;
  }

  void boolean(String key, Object? source) {
    if (source is bool) _value[key] = source;
  }

  void nested(String key, _PublicValue<Map<String, dynamic>> nested) {
    if (nested.value.isNotEmpty) _value[key] = nested.value;
    _truncated = _truncated || nested.truncated;
  }

  void listOfMaps(
    String key,
    Object? source,
    _PublicValue<Map<String, dynamic>> Function(Map<String, dynamic>) map,
  ) {
    if (source is! List) return;
    final entries = <Map<String, dynamic>>[];
    final takeCount = math.min(
      source.length,
      contract.maximumPublicCollectionEntries,
    );
    if (source.length > takeCount) _truncated = true;
    for (final item in source.take(takeCount)) {
      final sourceMap = _stringMap(item);
      if (sourceMap == null) continue;
      final publicValue = map(sourceMap);
      entries.add(publicValue.value);
      _truncated = _truncated || publicValue.truncated;
    }
    _value[key] = List.unmodifiable(entries);
  }

  _PublicValue<Map<String, dynamic>> build() =>
      _PublicValue(Map.unmodifiable(_value), _truncated);
}

class _PublicValue<T> {
  const _PublicValue(this.value, this.truncated);

  final T value;
  final bool truncated;
}

class _PreparedBattleLiveRecord {
  _PreparedBattleLiveRecord({
    required this.sequence,
    required this.recordId,
    required this.kind,
    required Map<String, dynamic> payload,
    required this.contentTruncated,
  }) : payload = Map.unmodifiable(payload);

  final int sequence;
  final String recordId;
  final BattleLiveRecordKind kind;
  final Map<String, dynamic> payload;
  final bool contentTruncated;

  bool hasSamePublicContent(_PreparedBattleLiveRecord other) =>
      recordId == other.recordId &&
      kind == other.kind &&
      contentTruncated == other.contentTruncated &&
      jsonEncode(payload) == jsonEncode(other.payload);

  _PreparedBattleLiveRecord asSkeleton() => _PreparedBattleLiveRecord(
    sequence: sequence,
    recordId: recordId,
    kind: kind,
    payload: const <String, dynamic>{},
    contentTruncated: true,
  );
}

class _BattleLiveCursorState {
  const _BattleLiveCursorState({
    required this.afterSequence,
    required this.replayDelivered,
  });

  final int afterSequence;
  final bool replayDelivered;
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String? _string(Object? value) {
  if (value is! String) return null;
  return value;
}

String _withoutPadding(String value) => value.replaceAll('=', '');

bool _constantTimeEquals(List<int> left, List<int> right) {
  var difference = left.length ^ right.length;
  final length = math.max(left.length, right.length);
  for (var index = 0; index < length; index += 1) {
    final leftByte = index < left.length ? left[index] : 0;
    final rightByte = index < right.length ? right[index] : 0;
    difference |= leftByte ^ rightByte;
  }
  return difference == 0;
}

void _validateIdentifier(String value, {required String code}) {
  if (!_publicIdentifierPattern.hasMatch(value)) {
    throw BattleLiveContractException(code);
  }
}

final _publicIdentifierPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');
final _publicTerminalReasonPattern = RegExp(r'^[a-z0-9][a-z0-9_:-]{0,127}$');

const _publicEventTypes = <String>{
  'ability_activated',
  'attacker_declared',
  'battlefield_entry',
  'blocker_declared',
  'card_draw',
  'card_played',
  'combat_damage',
  'commander_cast',
  'counter_change',
  'damage',
  'game_started',
  'land_played',
  'life_change',
  'life_gain',
  'life_loss',
  'phase_changed',
  'resolve',
  'spell_cast',
  'stack_entry',
  'tap_change',
  'turn_started',
  'zone_transition',
};

const _alwaysPublicIdentityEventTypes = <String>{
  'ability_activated',
  'attacker_declared',
  'battlefield_entry',
  'blocker_declared',
  'card_played',
  'combat_damage',
  'commander_cast',
  'counter_change',
  'damage',
  'land_played',
  'life_change',
  'life_gain',
  'life_loss',
  'resolve',
  'spell_cast',
  'stack_entry',
  'tap_change',
};

const _alwaysPublicMessageEventTypes = <String>{
  ..._alwaysPublicIdentityEventTypes,
  'game_started',
  'phase_changed',
  'turn_started',
};

const _explicitPublicIdentityEventTypes = <String>{
  'card_draw',
  'zone_transition',
};
