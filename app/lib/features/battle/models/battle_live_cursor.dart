import 'dart:collection';

const battleLiveCursorSchemaVersion = 'battle_live_cursor_v1';
const battleLivePollingTransport = 'polling_long_polling';

class BattleLiveCursorException implements Exception {
  const BattleLiveCursorException(this.code);

  final String code;

  @override
  String toString() => 'BattleLiveCursorException($code)';
}

enum BattleLiveStatus {
  queued('queued', false),
  claimed('claimed', false),
  running('running', false),
  cancelPending('cancel_pending', false),
  completed('completed', true),
  censored('censored', true),
  timeout('timeout', true),
  coverageError('coverage_error', true),
  engineError('engine_error', true),
  cancelled('cancelled', true),
  persistenceError('persistence_error', true),
  interrupted('interrupted', true);

  const BattleLiveStatus(this.wireValue, this.isTerminal);

  final String wireValue;
  final bool isTerminal;

  static BattleLiveStatus parse(Object? value) {
    if (value is! String) {
      throw const BattleLiveCursorException('invalid_status');
    }
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    throw const BattleLiveCursorException('invalid_status');
  }
}

enum BattleLiveRecordKind {
  event('event'),
  snapshot('snapshot');

  const BattleLiveRecordKind(this.wireValue);

  final String wireValue;

  static BattleLiveRecordKind parse(Object? value) {
    if (value is! String) {
      throw const BattleLiveCursorException('invalid_record_kind');
    }
    for (final kind in values) {
      if (kind.wireValue == value) return kind;
    }
    throw const BattleLiveCursorException('invalid_record_kind');
  }
}

class BattleLiveRecord {
  BattleLiveRecord._({
    required this.cursor,
    required this.sequence,
    required this.recordId,
    required this.kind,
    required Map<String, dynamic> payload,
    required this.contentTruncated,
  }) : payload = UnmodifiableMapView(payload);

  final String cursor;
  final int sequence;
  final String recordId;
  final BattleLiveRecordKind kind;
  final Map<String, dynamic> payload;
  final bool contentTruncated;

  factory BattleLiveRecord.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _recordKeys, 'unknown_record_field');
    _requireSchema(json);

    final cursor = _requireCursor(json['cursor']);
    final sequence = _requireInt(json['sequence'], 'invalid_record_sequence');
    if (sequence < 0) {
      throw const BattleLiveCursorException('invalid_record_sequence');
    }
    final recordId = _requireIdentifier(json['record_id'], 'invalid_record_id');
    final kind = BattleLiveRecordKind.parse(json['kind']);
    final contentTruncated = _requireBool(
      json['content_truncated'],
      'invalid_content_truncated',
    );
    final payloadKey = kind.wireValue;
    final otherPayloadKey = kind == BattleLiveRecordKind.event
        ? BattleLiveRecordKind.snapshot.wireValue
        : BattleLiveRecordKind.event.wireValue;
    if (json.containsKey(otherPayloadKey)) {
      throw const BattleLiveCursorException('record_payload_kind_mismatch');
    }
    final payload = _requireMap(json[payloadKey], 'invalid_record_payload');
    final publicPayload = kind == BattleLiveRecordKind.event
        ? _parsePublicEvent(payload)
        : _parsePublicSnapshot(payload);

    return BattleLiveRecord._(
      cursor: cursor,
      sequence: sequence,
      recordId: recordId,
      kind: kind,
      payload: publicPayload,
      contentTruncated: contentTruncated,
    );
  }

  bool hasSameIdentityAndContent(BattleLiveRecord other) =>
      cursor == other.cursor &&
      sequence == other.sequence &&
      recordId == other.recordId &&
      kind == other.kind &&
      contentTruncated == other.contentTruncated &&
      _deepEquals(payload, other.payload);
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

  factory BattleLiveTruncation.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _truncationKeys, 'unknown_truncation_field');
    return BattleLiveTruncation(
      source: _requireBool(json['source'], 'invalid_truncation'),
      pageLimit: _requireBool(json['page_limit'], 'invalid_truncation'),
      payloadLimit: _requireBool(json['payload_limit'], 'invalid_truncation'),
      fieldLimit: _requireBool(json['field_limit'], 'invalid_truncation'),
    );
  }
}

class BattleLiveReplayReference {
  const BattleLiveReplayReference({required this.replayId});

  final String replayId;

  factory BattleLiveReplayReference.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _replayKeys, 'unknown_replay_field');
    if (json['available'] != true) {
      throw const BattleLiveCursorException('replay_not_available');
    }
    return BattleLiveReplayReference(
      replayId: _requireIdentifier(json['replay_id'], 'invalid_replay_id'),
    );
  }
}

class BattleLivePage {
  BattleLivePage._({
    required this.streamId,
    required this.status,
    required List<BattleLiveRecord> items,
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
  final List<BattleLiveRecord> items;
  final String nextCursor;
  final bool hasMore;
  final BattleLiveTruncation truncation;
  final int pageLimit;
  final int maximumPayloadBytes;
  final BattleLiveReplayReference? replay;
  final bool replayPending;
  final bool replayAlreadyDelivered;
  final String? terminalReason;

  bool get isTerminal => status.isTerminal;

  factory BattleLivePage.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _pageKeys, 'unknown_page_field');
    _requireSchema(json);
    if (json['transport'] != battleLivePollingTransport) {
      throw const BattleLiveCursorException('invalid_transport');
    }

    final streamId = _requireIdentifier(json['stream_id'], 'invalid_stream_id');
    final status = BattleLiveStatus.parse(json['status']);
    final isTerminal = _requireBool(
      json['is_terminal'],
      'invalid_terminal_flag',
    );
    if (isTerminal != status.isTerminal) {
      throw const BattleLiveCursorException('terminal_status_mismatch');
    }

    final terminalReason = _optionalString(json['terminal_reason']);
    if (!status.isTerminal && terminalReason != null) {
      throw const BattleLiveCursorException(
        'terminal_reason_requires_terminal_status',
      );
    }
    if (terminalReason != null &&
        !_terminalReasonPattern.hasMatch(terminalReason)) {
      throw const BattleLiveCursorException('invalid_terminal_reason');
    }

    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const BattleLiveCursorException('invalid_items');
    }
    final items = rawItems
        .map(
          (item) =>
              BattleLiveRecord.fromJson(_requireMap(item, 'invalid_item')),
        )
        .toList(growable: false);
    final itemCount = _requireInt(json['item_count'], 'invalid_item_count');
    if (itemCount != rawItems.length) {
      throw const BattleLiveCursorException('item_count_mismatch');
    }

    for (var index = 1; index < items.length; index += 1) {
      if (items[index].sequence < items[index - 1].sequence) {
        throw const BattleLiveCursorException('non_monotonic_page');
      }
    }

    final nextCursor = _requireCursor(json['next_cursor']);
    final hasMore = _requireBool(json['has_more'], 'invalid_has_more');
    if (hasMore && items.isEmpty) {
      throw const BattleLiveCursorException('empty_page_with_more');
    }
    final truncation = BattleLiveTruncation.fromJson(
      _requireMap(json['truncation'], 'invalid_truncation'),
    );
    final truncated = _requireBool(json['truncated'], 'invalid_truncated');
    if (truncated != truncation.any) {
      throw const BattleLiveCursorException('truncation_mismatch');
    }

    final limits = _requireMap(json['limits'], 'invalid_limits');
    _requireOnlyKeys(limits, _limitKeys, 'unknown_limit_field');
    final pageLimit = _requireInt(limits['page'], 'invalid_page_limit');
    final maximumPayloadBytes = _requireInt(
      limits['payload_bytes'],
      'invalid_payload_limit',
    );
    if (pageLimit < 1 ||
        pageLimit > 1000 ||
        maximumPayloadBytes < 1024 ||
        items.length > pageLimit) {
      throw const BattleLiveCursorException('invalid_limits');
    }

    final replayPending = _requireBool(
      json['replay_pending'],
      'invalid_replay_pending',
    );
    final replayAlreadyDelivered = _requireBool(
      json['replay_already_delivered'],
      'invalid_replay_already_delivered',
    );
    final replayJson = json['replay'];
    final replay = replayJson == null
        ? null
        : BattleLiveReplayReference.fromJson(
            _requireMap(replayJson, 'invalid_replay'),
          );
    if (!status.isTerminal &&
        (replay != null || replayPending || replayAlreadyDelivered)) {
      throw const BattleLiveCursorException('replay_requires_terminal_status');
    }
    if (replay != null &&
        (hasMore || replayPending || replayAlreadyDelivered)) {
      throw const BattleLiveCursorException('invalid_replay_delivery_state');
    }
    if (replayPending && replayAlreadyDelivered) {
      throw const BattleLiveCursorException('invalid_replay_delivery_state');
    }

    return BattleLivePage._(
      streamId: streamId,
      status: status,
      items: items,
      nextCursor: nextCursor,
      hasMore: hasMore,
      truncation: truncation,
      pageLimit: pageLimit,
      maximumPayloadBytes: maximumPayloadBytes,
      replay: replay,
      replayPending: replayPending,
      replayAlreadyDelivered: replayAlreadyDelivered,
      terminalReason: terminalReason,
    );
  }
}

class BattleLiveSession {
  BattleLiveSession._({
    required this.streamId,
    required this.cursor,
    required this.status,
    required List<BattleLiveRecord> records,
    required this.replayId,
    required this.terminalReason,
  }) : records = List.unmodifiable(records);

  const BattleLiveSession.empty()
    : streamId = null,
      cursor = null,
      status = null,
      records = const <BattleLiveRecord>[],
      replayId = null,
      terminalReason = null;

  final String? streamId;
  final String? cursor;
  final BattleLiveStatus? status;
  final List<BattleLiveRecord> records;
  final String? replayId;
  final String? terminalReason;

  bool get isTerminal => status?.isTerminal == true;

  BattleLiveSession apply(BattleLivePage page) {
    if (streamId != null && streamId != page.streamId) {
      throw const BattleLiveCursorException('stream_mismatch');
    }
    if (status?.isTerminal == true && page.status != status) {
      throw const BattleLiveCursorException('terminal_status_changed');
    }

    final nextRecords = List<BattleLiveRecord>.from(records);
    final bySequence = <int, BattleLiveRecord>{
      for (final record in records) record.sequence: record,
    };
    final byRecordId = <String, BattleLiveRecord>{
      for (final record in records) record.recordId: record,
    };
    var lastSequence = records.isEmpty ? -1 : records.last.sequence;
    var addedRecords = false;

    for (final item in page.items) {
      final sequenceMatch = bySequence[item.sequence];
      final idMatch = byRecordId[item.recordId];
      if (sequenceMatch != null || idMatch != null) {
        if (sequenceMatch == null ||
            idMatch == null ||
            !identical(sequenceMatch, idMatch) ||
            !sequenceMatch.hasSameIdentityAndContent(item)) {
          throw const BattleLiveCursorException('record_identity_conflict');
        }
        continue;
      }
      if (item.sequence <= lastSequence) {
        throw const BattleLiveCursorException('record_sequence_regression');
      }
      nextRecords.add(item);
      bySequence[item.sequence] = item;
      byRecordId[item.recordId] = item;
      lastSequence = item.sequence;
      addedRecords = true;
    }

    if (cursor != null && addedRecords && page.nextCursor == cursor) {
      throw const BattleLiveCursorException('cursor_did_not_advance');
    }

    var nextReplayId = replayId;
    final receivedReplayId = page.replay?.replayId;
    if (receivedReplayId != null) {
      if (nextReplayId != null && nextReplayId != receivedReplayId) {
        throw const BattleLiveCursorException('replay_identity_conflict');
      }
      nextReplayId = receivedReplayId;
    }
    if (page.replayAlreadyDelivered && nextReplayId == null) {
      throw const BattleLiveCursorException('replay_delivery_gap');
    }
    if (terminalReason != null &&
        page.terminalReason != null &&
        terminalReason != page.terminalReason) {
      throw const BattleLiveCursorException('terminal_reason_changed');
    }

    return BattleLiveSession._(
      streamId: page.streamId,
      cursor: page.nextCursor,
      status: page.status,
      records: nextRecords,
      replayId: nextReplayId,
      terminalReason: page.terminalReason ?? terminalReason,
    );
  }
}

Map<String, dynamic> _parsePublicEvent(Map<String, dynamic> json) {
  _requireOnlyKeys(json, _eventKeys, 'private_or_unknown_event_field');
  final eventType = json['event_type'];
  if (eventType != null &&
      (eventType is! String || !_publicEventTypes.contains(eventType))) {
    throw const BattleLiveCursorException('invalid_public_event_type');
  }
  _validateOptionalStringFields(json, _eventStringKeys);
  _validateOptionalIntFields(json, _eventIntKeys);
  _validateOptionalBoolFields(json, _eventBoolKeys);
  if (json['details'] != null) {
    final details = _requireMap(json['details'], 'invalid_event_details');
    _requireOnlyKeys(
      details,
      _eventDetailKeys,
      'private_or_unknown_event_detail_field',
    );
    _validateOptionalStringFields(details, _eventDetailStringKeys);
    _validateOptionalIntFields(details, _eventDetailIntKeys);
    _validateOptionalBoolFields(details, _eventDetailBoolKeys);
  }
  return _deepCopyMap(json);
}

Map<String, dynamic> _parsePublicSnapshot(Map<String, dynamic> json) {
  _requireOnlyKeys(json, _snapshotKeys, 'private_or_unknown_snapshot_field');
  _validateOptionalStringFields(json, _snapshotStringKeys);
  _validateOptionalIntFields(json, _snapshotIntKeys);
  _validateOptionalBoolFields(json, _snapshotBoolKeys);
  _validateMapList(json, 'players', _parsePublicPlayer);
  _validateMapList(json, 'stack', _parsePublicStackObject);
  _validateMapList(json, 'combat', _parsePublicCombatGroup);
  return _deepCopyMap(json);
}

void _parsePublicPlayer(Map<String, dynamic> json) {
  _requireOnlyKeys(json, _playerKeys, 'private_or_unknown_player_field');
  _validateOptionalStringFields(json, _playerStringKeys);
  _validateOptionalIntFields(json, _playerIntKeys);
  _validateOptionalBoolFields(json, _playerBoolKeys);
}

void _parsePublicStackObject(Map<String, dynamic> json) {
  _requireOnlyKeys(json, _stackKeys, 'private_or_unknown_stack_field');
  _validateOptionalStringFields(json, _stackStringKeys);
}

void _parsePublicCombatGroup(Map<String, dynamic> json) {
  _requireOnlyKeys(json, _combatKeys, 'private_or_unknown_combat_field');
  _validateOptionalStringFields(json, _combatStringKeys);
  _validateOptionalBoolFields(json, _combatBoolKeys);
  _validateMapList(json, 'attackers', _parsePublicCombatObject);
  _validateMapList(json, 'blockers', _parsePublicCombatObject);
}

void _parsePublicCombatObject(Map<String, dynamic> json) {
  _requireOnlyKeys(
    json,
    _combatObjectKeys,
    'private_or_unknown_combat_object_field',
  );
  _validateOptionalStringFields(json, _combatObjectStringKeys);
  _validateOptionalIntFields(json, _combatObjectIntKeys);
  _validateOptionalBoolFields(json, _combatObjectBoolKeys);
}

void _validateMapList(
  Map<String, dynamic> json,
  String key,
  void Function(Map<String, dynamic>) validate,
) {
  final value = json[key];
  if (value == null) return;
  if (value is! List || value.length > 64) {
    throw const BattleLiveCursorException('invalid_public_collection');
  }
  for (final entry in value) {
    validate(_requireMap(entry, 'invalid_public_collection_entry'));
  }
}

void _validateOptionalStringFields(
  Map<String, dynamic> json,
  Set<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is! String || value.runes.length > 2048) {
      throw const BattleLiveCursorException('invalid_public_string');
    }
  }
}

void _validateOptionalIntFields(Map<String, dynamic> json, Set<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value is! int) {
      throw const BattleLiveCursorException('invalid_public_integer');
    }
  }
}

void _validateOptionalBoolFields(Map<String, dynamic> json, Set<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value is! bool) {
      throw const BattleLiveCursorException('invalid_public_boolean');
    }
  }
}

void _requireSchema(Map<String, dynamic> json) {
  if (json['schema_version'] != battleLiveCursorSchemaVersion) {
    throw const BattleLiveCursorException('unsupported_schema_version');
  }
}

void _requireOnlyKeys(
  Map<String, dynamic> json,
  Set<String> allowed,
  String code,
) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw BattleLiveCursorException(code);
  }
}

Map<String, dynamic> _requireMap(Object? value, String code) {
  if (value is! Map) throw BattleLiveCursorException(code);
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _requireIdentifier(Object? value, String code) {
  if (value is! String || !_identifierPattern.hasMatch(value)) {
    throw BattleLiveCursorException(code);
  }
  return value;
}

String _requireCursor(Object? value) {
  if (value is! String ||
      value.length > 2048 ||
      !_cursorPattern.hasMatch(value)) {
    throw const BattleLiveCursorException('invalid_cursor');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty || value.runes.length > 2048) {
    throw const BattleLiveCursorException('invalid_optional_string');
  }
  return value;
}

int _requireInt(Object? value, String code) {
  if (value is! int) throw BattleLiveCursorException(code);
  return value;
}

bool _requireBool(Object? value, String code) {
  if (value is! bool) throw BattleLiveCursorException(code);
  return value;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) =>
    Map.unmodifiable(
      source.map((key, value) => MapEntry(key, _deepCopy(value))),
    );

Object? _deepCopy(Object? value) {
  if (value is Map) {
    return Map.unmodifiable(
      value.map((key, nested) => MapEntry(key.toString(), _deepCopy(nested))),
    );
  }
  if (value is List) {
    return List.unmodifiable(value.map(_deepCopy));
  }
  return value;
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !_deepEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (!_deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}

final _identifierPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');
final _cursorPattern = RegExp(r'^blc1\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$');
final _terminalReasonPattern = RegExp(r'^[a-z0-9][a-z0-9_:-]{0,127}$');

const _pageKeys = <String>{
  'schema_version',
  'transport',
  'stream_id',
  'status',
  'is_terminal',
  'terminal_reason',
  'items',
  'item_count',
  'next_cursor',
  'has_more',
  'truncated',
  'truncation',
  'limits',
  'replay_pending',
  'replay_already_delivered',
  'replay',
};
const _recordKeys = <String>{
  'schema_version',
  'cursor',
  'sequence',
  'record_id',
  'kind',
  'event',
  'snapshot',
  'content_truncated',
};
const _truncationKeys = <String>{
  'source',
  'page_limit',
  'payload_limit',
  'field_limit',
};
const _limitKeys = <String>{'page', 'payload_bytes'};
const _replayKeys = <String>{'replay_id', 'available'};

const _eventKeys = <String>{
  'event_type',
  'event_id',
  'turn',
  'phase',
  'step',
  'actor',
  'actor_side',
  'subject_deck_key',
  'target_side',
  'severity',
  'amount',
  'damage',
  'life_after',
  'tapped',
  'card_name',
  'message',
  'details',
};
const _eventStringKeys = <String>{
  'event_type',
  'event_id',
  'phase',
  'step',
  'actor',
  'actor_side',
  'subject_deck_key',
  'target_side',
  'severity',
  'card_name',
  'message',
};
const _eventIntKeys = <String>{'turn', 'amount', 'damage', 'life_after'};
const _eventBoolKeys = <String>{'tapped'};
const _eventDetailKeys = <String>{
  'card_name',
  'source_card_name',
  'target_card_name',
  'object_name',
  'zone_from',
  'zone_to',
  'counter_type',
  'player_side',
  'target_side',
  'defender_side',
  'amount',
  'damage',
  'life_before',
  'life_after',
  'counter_delta',
  'is_commander',
  'tapped',
};
const _eventDetailStringKeys = <String>{
  'card_name',
  'source_card_name',
  'target_card_name',
  'object_name',
  'zone_from',
  'zone_to',
  'counter_type',
  'player_side',
  'target_side',
  'defender_side',
};
const _eventDetailIntKeys = <String>{
  'amount',
  'damage',
  'life_before',
  'life_after',
  'counter_delta',
};
const _eventDetailBoolKeys = <String>{'is_commander', 'tapped'};

const _snapshotKeys = <String>{
  'snapshot_id',
  'index',
  'turn',
  'phase',
  'step',
  'action',
  'active_player',
  'priority_player',
  'final',
  'players',
  'stack',
  'combat',
};
const _snapshotStringKeys = <String>{
  'snapshot_id',
  'phase',
  'step',
  'action',
  'active_player',
  'priority_player',
};
const _snapshotIntKeys = <String>{'index', 'turn'};
const _snapshotBoolKeys = <String>{'final'};

const _playerKeys = <String>{
  'deck_key',
  'name',
  'life',
  'mana',
  'mana_available',
  'hand_size',
  'library_size',
  'battlefield_count',
  'graveyard_size',
  'exile_size',
  'command_size',
  'lands',
  'has_left',
};
const _playerStringKeys = <String>{'deck_key', 'name'};
const _playerIntKeys = <String>{
  'life',
  'mana',
  'mana_available',
  'hand_size',
  'library_size',
  'battlefield_count',
  'graveyard_size',
  'exile_size',
  'command_size',
  'lands',
};
const _playerBoolKeys = <String>{'has_left'};

const _stackKeys = <String>{
  'object_id',
  'name',
  'card_name',
  'object_type',
  'controller_side',
  'ability_type',
};
const _stackStringKeys = _stackKeys;

const _combatKeys = <String>{
  'defender_side',
  'defender_name',
  'blocked',
  'attackers',
  'blockers',
};
const _combatStringKeys = <String>{'defender_side', 'defender_name'};
const _combatBoolKeys = <String>{'blocked'};
const _combatObjectKeys = <String>{
  'object_id',
  'name',
  'card_name',
  'controller_side',
  'power',
  'toughness',
  'damage',
  'tapped',
};
const _combatObjectStringKeys = <String>{
  'object_id',
  'name',
  'card_name',
  'controller_side',
  'power',
  'toughness',
};
const _combatObjectIntKeys = <String>{'damage'};
const _combatObjectBoolKeys = <String>{'tapped'};

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
