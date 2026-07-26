import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai/battle_engine_config.dart';
import 'battle_live_cursor_contract.dart';

const externalBattleLiveSourceSchema = 'external_battle_live_source_v1';
const battleLiveMaximumSourceRecords = 20000;
const battleLiveSourcePageLimit = 200;
const battleLiveMaximumSourcePayloadBytes = 8 * 1024 * 1024;

final RegExp battleLiveSourceRequestIdPattern = RegExp(
  r'^[A-Za-z0-9_-]{1,80}$',
);

class BattleLiveSourceException implements Exception {
  const BattleLiveSourceException(
    this.code, {
    this.statusCode,
    this.retryable = false,
  });

  final String code;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() => 'BattleLiveSourceException($code)';
}

class BattleLiveSourceSnapshot {
  BattleLiveSourceSnapshot({
    required this.requestId,
    required this.status,
    required this.terminal,
    required this.sourceTruncated,
    required this.sourceProcessId,
    required this.afterSequence,
    required this.nextAfterSequence,
    required this.hasMore,
    required this.totalRecordCount,
    required List<BattleLiveSourceRecord> records,
    this.terminalReason,
  }) : records = List.unmodifiable(records);

  final String requestId;
  final BattleLiveStatus status;
  final bool terminal;
  final bool sourceTruncated;
  final String sourceProcessId;
  final int afterSequence;
  final int nextAfterSequence;
  final bool hasMore;
  final int totalRecordCount;
  final List<BattleLiveSourceRecord> records;
  final String? terminalReason;
}

abstract interface class BattleLiveSource {
  Future<BattleLiveSourceSnapshot> read(
    String requestId, {
    int afterSequence = -1,
    int limit = battleLiveSourcePageLimit,
  });

  void close();
}

class XmageBattleLiveSource implements BattleLiveSource {
  XmageBattleLiveSource({
    required String baseUrl,
    required ExternalBattleEngineIdentity expectedIdentity,
    http.Client? client,
    this.timeout = const Duration(seconds: 2),
    this.maximumPayloadBytes = battleLiveMaximumSourcePayloadBytes,
  }) : _baseUri = _validatedBaseUri(baseUrl),
       _expectedIdentity = expectedIdentity,
       _client = client ?? http.Client() {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    if (maximumPayloadBytes < 1024) {
      throw ArgumentError.value(
        maximumPayloadBytes,
        'maximumPayloadBytes',
        'Must be at least 1024.',
      );
    }
  }

  final Uri _baseUri;
  final ExternalBattleEngineIdentity _expectedIdentity;
  final http.Client _client;
  final Duration timeout;
  final int maximumPayloadBytes;

  void close() => _client.close();

  @override
  Future<BattleLiveSourceSnapshot> read(
    String requestId, {
    int afterSequence = -1,
    int limit = battleLiveSourcePageLimit,
  }) async {
    if (!battleLiveSourceRequestIdPattern.hasMatch(requestId) ||
        afterSequence < -1 ||
        limit < 1 ||
        limit > battleLiveSourcePageLimit) {
      throw const BattleLiveSourceException('invalid_request_id');
    }

    late final http.StreamedResponse streamed;
    try {
      streamed = await _client
          .send(
            http.Request(
              'GET',
              _baseUri
                  .resolve('/live/${Uri.encodeComponent(requestId)}')
                  .replace(
                    queryParameters: {
                      'after': '$afterSequence',
                      'limit': '$limit',
                    },
                  ),
            ),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const BattleLiveSourceException(
        'source_timeout',
        statusCode: 504,
        retryable: true,
      );
    } on http.ClientException {
      throw const BattleLiveSourceException(
        'source_transport_failed',
        retryable: true,
      );
    }

    late final List<int> bytes;
    try {
      bytes = await _boundedBody(streamed).timeout(timeout);
    } on TimeoutException {
      throw const BattleLiveSourceException(
        'source_timeout',
        statusCode: 504,
        retryable: true,
      );
    } on BattleLiveSourceException {
      rethrow;
    } on http.ClientException {
      throw const BattleLiveSourceException(
        'source_transport_failed',
        retryable: true,
      );
    }

    if (streamed.statusCode == 404) {
      throw const BattleLiveSourceException(
        'source_stream_not_found',
        statusCode: 404,
        retryable: true,
      );
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw BattleLiveSourceException(
        'source_http_error',
        statusCode: streamed.statusCode,
        retryable: streamed.statusCode >= 500,
      );
    }

    late final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException();
      body = decoded.map((key, value) => MapEntry(key.toString(), value));
    } on Object {
      throw const BattleLiveSourceException(
        'source_payload_invalid',
        statusCode: 502,
      );
    }

    final identityError = externalBattleIdentityValidationError(
      body,
      expected: _expectedIdentity,
    );
    if (identityError != null) {
      throw const BattleLiveSourceException(
        'source_identity_rejected',
        statusCode: 502,
      );
    }
    if (body['live_schema_version'] != externalBattleLiveSourceSchema ||
        body['request_id'] != requestId) {
      throw const BattleLiveSourceException(
        'source_correlation_rejected',
        statusCode: 502,
      );
    }

    final status = _sourceStatus(body['status']);
    final terminal = body['terminal'];
    final sourceTruncated = body['source_truncated'];
    final sourceProcessId = body['sidecar_process_id'];
    final rawRecords = body['records'];
    final pageRecordCount = body['page_record_count'];
    final totalRecordCount = body['record_count'];
    final responseAfterSequence = body['after_sequence'];
    final nextAfterSequence = body['next_after_sequence'];
    final hasMore = body['has_more'];
    if (terminal is! bool ||
        sourceTruncated is! bool ||
        sourceProcessId is! String ||
        sourceProcessId.trim().isEmpty ||
        sourceProcessId.length > 256 ||
        rawRecords is! List ||
        rawRecords.length > limit ||
        pageRecordCount is! int ||
        pageRecordCount != rawRecords.length ||
        totalRecordCount is! int ||
        totalRecordCount < rawRecords.length ||
        totalRecordCount > battleLiveMaximumSourceRecords ||
        responseAfterSequence != afterSequence ||
        nextAfterSequence is! int ||
        nextAfterSequence < afterSequence ||
        hasMore is! bool ||
        terminal != status.isTerminal) {
      throw const BattleLiveSourceException(
        'source_payload_invalid',
        statusCode: 502,
      );
    }
    if ((rawRecords.isEmpty && nextAfterSequence != afterSequence) ||
        (hasMore && rawRecords.isEmpty)) {
      throw const BattleLiveSourceException(
        'source_page_invalid',
        statusCode: 502,
      );
    }

    final records = <BattleLiveSourceRecord>[];
    var previousSequence = afterSequence;
    for (final rawRecord in rawRecords) {
      final rawMap = _stringMap(rawRecord);
      final sequence = rawMap?['sequence'];
      if (sequence is! int || sequence != previousSequence + 1) {
        throw const BattleLiveSourceException(
          'source_page_not_monotonic',
          statusCode: 502,
        );
      }
      previousSequence = sequence;
      final record = _normalizeRecord(rawRecord);
      if (record != null) records.add(record);
    }
    if (rawRecords.isNotEmpty && previousSequence != nextAfterSequence) {
      throw const BattleLiveSourceException(
        'source_page_cursor_mismatch',
        statusCode: 502,
      );
    }
    final expectedHasMore = nextAfterSequence + 1 < totalRecordCount;
    if (hasMore != expectedHasMore) {
      throw const BattleLiveSourceException(
        'source_page_cursor_mismatch',
        statusCode: 502,
      );
    }
    return BattleLiveSourceSnapshot(
      requestId: requestId,
      status: status,
      terminal: terminal,
      sourceTruncated: sourceTruncated,
      sourceProcessId: sourceProcessId,
      afterSequence: afterSequence,
      nextAfterSequence: nextAfterSequence,
      hasMore: hasMore,
      totalRecordCount: totalRecordCount,
      terminalReason: _sourceTerminalReason(
        body['terminal_reason'],
        status: status,
      ),
      records: records,
    );
  }

  Future<List<int>> _boundedBody(http.StreamedResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maximumPayloadBytes) {
        throw const BattleLiveSourceException(
          'source_payload_too_large',
          statusCode: 502,
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }
}

BattleLiveSourceRecord? _normalizeRecord(Object? raw) {
  final row = _stringMap(raw);
  if (row == null) {
    throw const BattleLiveSourceException(
      'source_record_invalid',
      statusCode: 502,
    );
  }
  final sequence = row['sequence'];
  final recordId = row['record_id'];
  final kind = row['kind'];
  if (sequence is! int ||
      sequence < 0 ||
      recordId is! String ||
      recordId.trim().isEmpty ||
      recordId.length > 128 ||
      kind is! String) {
    throw const BattleLiveSourceException(
      'source_record_invalid',
      statusCode: 502,
    );
  }

  if (kind == 'event') {
    final event = _stringMap(row['event']);
    if (event == null) {
      throw const BattleLiveSourceException(
        'source_record_invalid',
        statusCode: 502,
      );
    }
    final normalized = normalizeXmageBattleLiveEvent(event);
    if (normalized == null) return null;
    return BattleLiveSourceRecord.event(
      sequence: sequence,
      recordId: recordId,
      event: normalized,
    );
  }
  if (kind == 'snapshot') {
    final snapshot = _stringMap(row['snapshot']);
    if (snapshot == null) {
      throw const BattleLiveSourceException(
        'source_record_invalid',
        statusCode: 502,
      );
    }
    return BattleLiveSourceRecord.snapshot(
      sequence: sequence,
      recordId: recordId,
      snapshot: normalizeXmageBattleLiveSnapshot(snapshot),
    );
  }
  throw const BattleLiveSourceException(
    'source_record_kind_invalid',
    statusCode: 502,
  );
}

Map<String, dynamic>? normalizeXmageBattleLiveEvent(
  Map<String, dynamic> source,
) {
  final action = source['action']?.toString().trim().toLowerCase();
  final eventType = switch (action) {
    'zone_change' ||
    'visible_zone_entry' ||
    'visible_zone_exit' => 'zone_transition',
    'tap_change' => 'tap_change',
    'life_change' => 'life_change',
    'attacker_declared' => 'attacker_declared',
    'blocker_declared' => 'blocker_declared',
    'battlefield_entry' => 'battlefield_entry',
    'stack_entry' => 'stack_entry',
    _ => null,
  };
  if (eventType == null) return null;

  final result = <String, dynamic>{'event_type': eventType};
  _copyInt(result, 'turn', source['turn']);
  _copyString(result, 'phase', source['phase']);
  _copyString(result, 'step', source['step']);
  _copyString(result, 'actor', source['player'] ?? source['active_player']);
  final side = _deckSide(source['player'] ?? source['active_player']);
  if (side != null) {
    result['actor_side'] = side;
    result['subject_deck_key'] = side;
  }

  final details = <String, dynamic>{};
  final fromZone = _normalizedZone(source['from_zone']);
  final toZone = _normalizedZone(source['to_zone']);
  if (fromZone != null) details['zone_from'] = fromZone;
  if (toZone != null) details['zone_to'] = toZone;

  final identityIsPublic =
      eventType != 'zone_transition' ||
      (fromZone != null &&
          toZone != null &&
          _publicZones.contains(fromZone) &&
          _publicZones.contains(toZone));
  if (identityIsPublic) {
    _copyString(result, 'card_name', source['card_name']);
    if (eventType == 'zone_transition') result['visibility'] = 'public';
  }

  if (eventType == 'tap_change' && source['to'] is bool) {
    result['tapped'] = source['to'];
    details['tapped'] = source['to'];
  }
  if (eventType == 'life_change') {
    final before = source['from'];
    final after = source['to'];
    if (before is int) details['life_before'] = before;
    if (after is int) {
      details['life_after'] = after;
      result['life_after'] = after;
    }
    if (before is int && after is int) result['amount'] = after - before;
  }
  _copyString(details, 'defender_side', _deckSide(source['defender_name']));
  if (details.isNotEmpty) result['details'] = details;
  return result;
}

Map<String, dynamic> normalizeXmageBattleLiveSnapshot(
  Map<String, dynamic> source,
) {
  final result = <String, dynamic>{};
  _copyString(result, 'snapshot_id', source['snapshot_id']);
  _copyInt(result, 'index', source['index']);
  _copyInt(result, 'turn', source['turn']);
  _copyString(result, 'phase', source['phase']);
  _copyString(result, 'step', source['step']);
  _copyString(result, 'action', source['action']);
  _copyString(result, 'active_player', source['active_player']);
  _copyString(result, 'priority_player', source['priority_player']);
  _copyBool(result, 'final', source['final']);

  final players = source['players'];
  if (players is List) {
    result['players'] = players
        .map(_stringMap)
        .whereType<Map<String, dynamic>>()
        .map(_normalizeXmagePlayer)
        .toList(growable: false);
  }
  final stack = source['stack'];
  if (stack is List) {
    result['stack'] = stack
        .map(_stringMap)
        .whereType<Map<String, dynamic>>()
        .map(_normalizeXmageStackObject)
        .toList(growable: false);
  }
  final combat = source['combat'];
  if (combat is List) {
    result['combat'] = combat
        .map(_stringMap)
        .whereType<Map<String, dynamic>>()
        .map(_normalizeXmageCombatGroup)
        .toList(growable: false);
  }
  return result;
}

Map<String, dynamic> _normalizeXmagePlayer(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  final side = _deckSide(source['deck_key'] ?? source['name']);
  if (side != null) result['deck_key'] = side;
  _copyString(result, 'name', source['name']);
  for (final key in const ['life', 'mana', 'mana_available', 'lands']) {
    _copyInt(result, key, source[key]);
  }
  _copyBool(result, 'has_left', source['has_left']);
  _copyZoneCount(
    result,
    source,
    countKey: 'hand_size',
    aliases: const ['hand_size', 'hand_count'],
    listKey: 'hand',
  );
  _copyZoneCount(
    result,
    source,
    countKey: 'library_size',
    aliases: const ['library_size', 'library_count'],
    listKey: 'library',
  );
  _copyZoneCount(
    result,
    source,
    countKey: 'battlefield_count',
    aliases: const ['battlefield_count'],
    listKey: 'battlefield',
  );
  _copyZoneCount(
    result,
    source,
    countKey: 'graveyard_size',
    aliases: const ['graveyard_size', 'graveyard_count'],
    listKey: 'graveyard',
  );
  _copyZoneCount(
    result,
    source,
    countKey: 'exile_size',
    aliases: const ['exile_size', 'exile_count'],
    listKey: 'exile',
  );
  _copyZoneCount(
    result,
    source,
    countKey: 'command_size',
    aliases: const ['command_size', 'command_count'],
    listKey: 'command',
  );
  return result;
}

Map<String, dynamic> _normalizeXmageStackObject(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  _copyString(result, 'object_id', source['object_id'] ?? source['id']);
  _copyString(result, 'name', source['name']);
  _copyString(result, 'card_name', source['card_name'] ?? source['name']);
  _copyString(result, 'object_type', source['object_type']);
  _copyString(result, 'ability_type', source['ability_type']);
  final side = _deckSide(
    source['controller_side'] ?? source['controller'] ?? source['player'],
  );
  if (side != null) result['controller_side'] = side;
  return result;
}

Map<String, dynamic> _normalizeXmageCombatGroup(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  final defenderSide = _deckSide(
    source['defender_side'] ?? source['defender_name'],
  );
  if (defenderSide != null) result['defender_side'] = defenderSide;
  _copyString(result, 'defender_name', source['defender_name']);
  _copyBool(result, 'blocked', source['blocked']);
  for (final role in const ['attackers', 'blockers']) {
    final cards = source[role];
    if (cards is List) {
      result[role] = cards
          .map(_stringMap)
          .whereType<Map<String, dynamic>>()
          .map(_normalizeXmageCombatObject)
          .toList(growable: false);
    }
  }
  return result;
}

Map<String, dynamic> _normalizeXmageCombatObject(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  _copyString(result, 'object_id', source['object_id'] ?? source['id']);
  _copyString(result, 'name', source['name']);
  _copyString(result, 'card_name', source['card_name'] ?? source['name']);
  _copyString(result, 'power', source['power']);
  _copyString(result, 'toughness', source['toughness']);
  _copyInt(result, 'damage', source['damage']);
  _copyBool(result, 'tapped', source['tapped']);
  final side = _deckSide(
    source['controller_side'] ?? source['controller'] ?? source['player'],
  );
  if (side != null) result['controller_side'] = side;
  return result;
}

BattleLiveStatus _sourceStatus(Object? raw) {
  return switch (raw) {
    'running' => BattleLiveStatus.running,
    'completed' => BattleLiveStatus.completed,
    'censored' => BattleLiveStatus.censored,
    'timeout' => BattleLiveStatus.timeout,
    'coverage_error' => BattleLiveStatus.coverageError,
    'engine_error' => BattleLiveStatus.engineError,
    'cancelled' => BattleLiveStatus.cancelled,
    'interrupted' => BattleLiveStatus.interrupted,
    _ =>
      throw const BattleLiveSourceException(
        'source_status_invalid',
        statusCode: 502,
      ),
  };
}

String? _sourceTerminalReason(Object? raw, {required BattleLiveStatus status}) {
  if (!status.isTerminal) return null;
  final value = raw?.toString().trim().toLowerCase();
  if (value != null && _publicSourceTerminalReasons.contains(value)) {
    return value;
  }
  return 'source_${status.wireValue}';
}

String? _deckSide(Object? raw) {
  final value = raw?.toString().trim().toLowerCase();
  return value == 'deck_a' || value == 'deck_b' ? value : null;
}

String? _normalizedZone(Object? raw) {
  final value = raw?.toString().trim().toLowerCase();
  return value == null || value.isEmpty ? null : value;
}

void _copyString(Map<String, dynamic> target, String key, Object? value) {
  if (value is String && value.trim().isNotEmpty) target[key] = value.trim();
}

void _copyInt(Map<String, dynamic> target, String key, Object? value) {
  if (value is int) target[key] = value;
}

void _copyBool(Map<String, dynamic> target, String key, Object? value) {
  if (value is bool) target[key] = value;
}

void _copyZoneCount(
  Map<String, dynamic> target,
  Map<String, dynamic> source, {
  required String countKey,
  required List<String> aliases,
  required String listKey,
}) {
  for (final alias in aliases) {
    final value = source[alias];
    if (value is int && value >= 0) {
      target[countKey] = value;
      return;
    }
  }
  final values = source[listKey];
  if (values is List) target[countKey] = values.length;
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Uri _validatedBaseUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasScheme ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw ArgumentError.value(value, 'baseUrl', 'Must be an HTTP(S) URL.');
  }
  return uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));
}

const _publicZones = <String>{
  'battlefield',
  'graveyard',
  'exile',
  'command',
  'stack',
};

const _publicSourceTerminalReasons = <String>{
  'engine_completed',
  'engine_censored',
  'simulation_timeout',
  'xmage_coverage_incomplete',
  'simulation_failed',
  'cancelled',
  'interrupted',
};
