import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_live_cursor.dart';

void main() {
  group('BattleLivePage parsing', () {
    test('parses the versioned polling page and public records', () {
      final page = BattleLivePage.fromJson(
        _pageJson(
          items: [
            _eventRecord(sequence: 1, recordId: 'event-1'),
            _snapshotRecord(sequence: 2, recordId: 'snapshot-2'),
          ],
        ),
      );

      expect(page.streamId, 'job-1');
      expect(page.status, BattleLiveStatus.running);
      expect(page.items, hasLength(2));
      expect(page.items.first.kind, BattleLiveRecordKind.event);
      expect(page.items.last.kind, BattleLiveRecordKind.snapshot);
      expect(page.isTerminal, isFalse);
    });

    test('rejects unknown schemas, statuses and fields', () {
      final unknownSchema = _pageJson()..['schema_version'] = 'live_v2';
      expect(
        () => BattleLivePage.fromJson(unknownSchema),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'unsupported_schema_version',
          ),
        ),
      );

      final unknownStatus = _pageJson()..['status'] = 'finished';
      expect(
        () => BattleLivePage.fromJson(unknownStatus),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'invalid_status',
          ),
        ),
      );

      final unexpectedSurface = _pageJson()..['coach_options'] = [];
      expect(
        () => BattleLivePage.fromJson(unexpectedSurface),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'unknown_page_field',
          ),
        ),
      );
    });

    test('fails closed when private zones or decision internals appear', () {
      final handLeak = _snapshotRecord(sequence: 1, recordId: 'snapshot-1');
      final snapshot = handLeak['snapshot'] as Map<String, dynamic>;
      final players = snapshot['players'] as List<dynamic>;
      (players.first as Map<String, dynamic>)['hand'] = ['Secret Card'];

      expect(
        () => BattleLivePage.fromJson(_pageJson(items: [handLeak])),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'private_or_unknown_player_field',
          ),
        ),
      );

      final decisionLeak = _eventRecord(sequence: 1, recordId: 'event-1');
      final event = decisionLeak['event'] as Map<String, dynamic>;
      event['options'] = ['Cast Secret Card'];
      event['rationale'] = 'hidden engine score';

      expect(
        () => BattleLivePage.fromJson(_pageJson(items: [decisionLeak])),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'private_or_unknown_event_field',
          ),
        ),
      );
    });

    test('validates terminal state and delivers the final replay once', () {
      final page = BattleLivePage.fromJson(
        _pageJson(
          status: 'completed',
          isTerminal: true,
          nextCursor: 'blc1.terminal.signature',
          terminalReason: 'completed',
          replay: const {'replay_id': 'replay-1', 'available': true},
        ),
      );

      expect(page.isTerminal, isTrue);
      expect(page.replay?.replayId, 'replay-1');
      expect(page.replayPending, isFalse);

      final invalid = _pageJson(
        status: 'running',
        replay: const {'replay_id': 'replay-1', 'available': true},
      );
      expect(
        () => BattleLivePage.fromJson(invalid),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'replay_requires_terminal_status',
          ),
        ),
      );
    });
  });

  group('BattleLiveSession reconnection', () {
    test('preserves cursor and deduplicates an identical record', () {
      final firstRecord = _eventRecord(sequence: 1, recordId: 'event-1');
      final firstPage = BattleLivePage.fromJson(
        _pageJson(items: [firstRecord], nextCursor: 'blc1.first.signature'),
      );
      final firstSession = const BattleLiveSession.empty().apply(firstPage);

      final secondPage = BattleLivePage.fromJson(
        _pageJson(
          items: [
            Map<String, dynamic>.from(firstRecord),
            _eventRecord(sequence: 2, recordId: 'event-2'),
          ],
          nextCursor: 'blc1.second.signature',
        ),
      );
      final resumed = firstSession.apply(secondPage);

      expect(firstSession.cursor, 'blc1.first.signature');
      expect(resumed.cursor, 'blc1.second.signature');
      expect(resumed.records.map((record) => record.recordId), [
        'event-1',
        'event-2',
      ]);
    });

    test('fails closed on sequence or record-id conflicts', () {
      final session = const BattleLiveSession.empty().apply(
        BattleLivePage.fromJson(
          _pageJson(
            items: [_eventRecord(sequence: 1, recordId: 'event-1')],
            nextCursor: 'blc1.first.signature',
          ),
        ),
      );

      final sameSequence = BattleLivePage.fromJson(
        _pageJson(
          items: [_eventRecord(sequence: 1, recordId: 'event-other')],
          nextCursor: 'blc1.conflict.signature',
        ),
      );
      expect(
        () => session.apply(sameSequence),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'record_identity_conflict',
          ),
        ),
      );

      final sameId = BattleLivePage.fromJson(
        _pageJson(
          items: [_eventRecord(sequence: 2, recordId: 'event-1')],
          nextCursor: 'blc1.conflict2.signature',
        ),
      );
      expect(
        () => session.apply(sameId),
        throwsA(
          isA<BattleLiveCursorException>().having(
            (error) => error.code,
            'code',
            'record_identity_conflict',
          ),
        ),
      );
    });

    test('reaches terminal replay after an active session', () {
      final running = const BattleLiveSession.empty().apply(
        BattleLivePage.fromJson(
          _pageJson(
            items: [_snapshotRecord(sequence: 1, recordId: 'snapshot-1')],
            nextCursor: 'blc1.running.signature',
          ),
        ),
      );
      final completed = running.apply(
        BattleLivePage.fromJson(
          _pageJson(
            status: 'completed',
            isTerminal: true,
            terminalReason: 'completed',
            nextCursor: 'blc1.completed.signature',
            replay: const {'replay_id': 'replay-1', 'available': true},
          ),
        ),
      );

      expect(completed.isTerminal, isTrue);
      expect(completed.replayId, 'replay-1');
      expect(completed.records, hasLength(1));
    });

    test('preserves explicit pagination and replay-pending state', () {
      final paged = const BattleLiveSession.empty().apply(
        BattleLivePage.fromJson(
          _pageJson(
            items: [_eventRecord(sequence: 1, recordId: 'event-1')],
            nextCursor: 'blc1.paged.signature',
            hasMore: true,
          ),
        ),
      );

      expect(paged.hasMore, isTrue);
      expect(paged.replayPending, isFalse);

      final pending = paged.apply(
        BattleLivePage.fromJson(
          _pageJson(
            status: 'completed',
            isTerminal: true,
            terminalReason: 'completed',
            nextCursor: 'blc1.pending.signature',
            replayPending: true,
          ),
        ),
      );

      expect(pending.hasMore, isFalse);
      expect(pending.replayPending, isTrue);

      final completed = pending.apply(
        BattleLivePage.fromJson(
          _pageJson(
            status: 'completed',
            isTerminal: true,
            terminalReason: 'completed',
            nextCursor: 'blc1.replay.signature',
            replay: const {'replay_id': 'replay-1', 'available': true},
          ),
        ),
      );

      expect(completed.replayPending, isFalse);
      expect(completed.replayId, 'replay-1');
    });
  });
}

Map<String, dynamic> _pageJson({
  String status = 'running',
  bool isTerminal = false,
  List<Map<String, dynamic>> items = const [],
  String nextCursor = 'blc1.next.signature',
  String? terminalReason,
  Map<String, dynamic>? replay,
  bool replayPending = false,
  bool hasMore = false,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'transport': 'polling_long_polling',
    'stream_id': 'job-1',
    'status': status,
    'is_terminal': isTerminal,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    'items': items,
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'truncated': false,
    'truncation': const {
      'source': false,
      'page_limit': false,
      'payload_limit': false,
      'field_limit': false,
    },
    'limits': const {'page': 50, 'payload_bytes': 131072},
    'replay_pending': replayPending,
    'replay_already_delivered': false,
    if (replay != null) 'replay': replay,
  };
}

Map<String, dynamic> _eventRecord({
  required int sequence,
  required String recordId,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.item$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'event',
    'event': {
      'event_type': 'spell_cast',
      'event_id': recordId,
      'turn': 2,
      'actor_side': 'deck_a',
      'subject_deck_key': 'deck_a',
      'card_name': 'Arcane Signet',
      'details': const {
        'card_name': 'Arcane Signet',
        'zone_from': 'hand',
        'zone_to': 'stack',
      },
    },
    'content_truncated': false,
  };
}

Map<String, dynamic> _snapshotRecord({
  required int sequence,
  required String recordId,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.item$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'snapshot',
    'snapshot': {
      'snapshot_id': recordId,
      'index': sequence,
      'turn': 2,
      'phase': 'main',
      'active_player': 'deck_a',
      'players': [
        {
          'deck_key': 'deck_a',
          'name': 'You',
          'life': 40,
          'hand_size': 6,
          'library_size': 92,
          'battlefield_count': 2,
          'graveyard_size': 0,
          'exile_size': 0,
          'command_size': 1,
        },
        {
          'deck_key': 'deck_b',
          'name': 'Opponent',
          'life': 40,
          'hand_size': 7,
          'library_size': 92,
          'battlefield_count': 1,
          'graveyard_size': 0,
          'exile_size': 0,
          'command_size': 1,
        },
      ],
      'stack': const <Map<String, dynamic>>[],
      'combat': const <Map<String, dynamic>>[],
    },
    'content_truncated': false,
  };
}
