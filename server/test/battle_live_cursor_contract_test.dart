import 'dart:convert';

import 'package:server/battle/battle_live_cursor_contract.dart';
import 'package:test/test.dart';

void main() {
  group('battle_live_cursor_v1 public allowlist', () {
    test('rebuilds nested events and snapshots from public fields only', () {
      final page = _contract().buildPage(
        streamId: 'job-1',
        status: BattleLiveStatus.running,
        records: [
          BattleLiveSourceRecord.event(
            sequence: 0,
            recordId: 'event-1',
            event: const {
              'event_type': 'spell_cast',
              'turn': 2,
              'actor_side': 'deck_a',
              'card_name': 'Library of Alexandria',
              'message':
                  'Library of Alexandria is public; hand, options and '
                  'rationale are words in this public message.',
              'details': {
                'amount': 1,
                'zone_from': 'battlefield',
                'zone_to': 'graveyard',
                'options': ['Private option'],
                'rationale': 'Private rationale',
                'nested_private': {
                  'hand': ['Secret Hand Card'],
                },
              },
              'hand': ['Secret Hand Card'],
              'library': ['Hidden Library Card'],
              'options': ['Private option'],
              'rationale': 'Private rationale',
            },
          ),
          BattleLiveSourceRecord.snapshot(
            sequence: 1,
            recordId: 'snapshot-1',
            snapshot: const {
              'snapshot_id': 'snapshot-visible-1',
              'turn': 2,
              'phase': 'main',
              'players': [
                {
                  'deck_key': 'deck_a',
                  'name': 'Player A',
                  'life': 38,
                  'hand_size': 6,
                  'library_size': 91,
                  'hand': ['Secret Hand Card'],
                  'library': ['Hidden Library Card'],
                  'available_options': ['Private option'],
                  'decision_rationale': 'Private rationale',
                },
              ],
              'stack': [
                {
                  'object_id': 'stack-1',
                  'name': 'Lightning Bolt',
                  'controller_side': 'deck_a',
                  'options': ['Private option'],
                  'rationale': 'Private rationale',
                },
              ],
              'private_state': {
                'hand': ['Secret Hand Card'],
              },
            },
          ),
          BattleLiveSourceRecord.event(
            sequence: 2,
            recordId: 'event-private-draw',
            event: const {
              'event_type': 'card_draw',
              'actor_side': 'deck_a',
              'card_name': 'Private Drawn Card',
              'message': 'Player A drew Private Drawn Card',
              'details': {
                'card_name': 'Private Drawn Card',
                'zone_from': 'library',
                'zone_to': 'hand',
              },
            },
          ),
          BattleLiveSourceRecord.event(
            sequence: 3,
            recordId: 'event-public-reveal',
            event: const {
              'event_type': 'zone_transition',
              'visibility': 'public',
              'card_name': 'Revealed Public Card',
              'message': 'Revealed Public Card moved from library.',
              'details': {
                'visibility': 'public',
                'card_name': 'Revealed Public Card',
                'zone_from': 'library',
                'zone_to': 'exile',
              },
            },
          ),
        ],
      );

      final json = page.toJson();
      final event = (json['items'] as List).first as Map<String, dynamic>;
      final eventPayload = event['event'] as Map<String, dynamic>;
      final snapshot = (json['items'] as List)[1] as Map<String, dynamic>;
      final snapshotPayload = snapshot['snapshot'] as Map<String, dynamic>;
      final player =
          (snapshotPayload['players'] as List).single as Map<String, dynamic>;

      expect(json['schema_version'], battleLiveCursorSchemaVersion);
      expect(json['transport'], battleLivePollingTransport);
      expect(event['schema_version'], battleLiveCursorSchemaVersion);
      expect(event['cursor'], startsWith('blc1.'));
      expect(eventPayload['card_name'], 'Library of Alexandria');
      expect(
        eventPayload['message'],
        'Library of Alexandria is public; hand, options and '
        'rationale are words in this public message.',
      );
      expect(eventPayload['details'], {
        'zone_from': 'battlefield',
        'zone_to': 'graveyard',
        'amount': 1,
      });
      expect(player['hand_size'], 6);
      expect(player['library_size'], 91);
      expect(
        (snapshotPayload['stack'] as List).single,
        containsPair('name', 'Lightning Bolt'),
      );
      final privateDraw =
          ((json['items'] as List)[2] as Map<String, dynamic>)['event']
              as Map<String, dynamic>;
      final publicReveal =
          ((json['items'] as List)[3] as Map<String, dynamic>)['event']
              as Map<String, dynamic>;
      expect(privateDraw, isNot(contains('card_name')));
      expect(privateDraw, isNot(contains('message')));
      expect(privateDraw['details'], {
        'zone_from': 'library',
        'zone_to': 'hand',
      });
      expect(publicReveal['card_name'], 'Revealed Public Card');
      expect(
        publicReveal['message'],
        'Revealed Public Card moved from library.',
      );

      final allKeys = _nestedKeys(json).toSet();
      expect(allKeys, isNot(contains('hand')));
      expect(allKeys, isNot(contains('library')));
      expect(allKeys, isNot(contains('options')));
      expect(allKeys, isNot(contains('available_options')));
      expect(allKeys, isNot(contains('rationale')));
      expect(allKeys, isNot(contains('decision_rationale')));
      expect(allKeys, isNot(contains('private_state')));

      final encoded = jsonEncode(json);
      expect(encoded, isNot(contains('Secret Hand Card')));
      expect(encoded, isNot(contains('Hidden Library Card')));
      expect(encoded, isNot(contains('Private option')));
      expect(encoded, isNot(contains('Private rationale')));
      expect(encoded, isNot(contains('Private Drawn Card')));
    });

    test('unknown event types cannot smuggle arbitrary event content', () {
      final page = _contract().buildPage(
        streamId: 'job-unknown',
        status: BattleLiveStatus.running,
        records: [
          BattleLiveSourceRecord.event(
            sequence: 0,
            recordId: 'event-unknown',
            event: const {
              'event_type': 'internal_debug_dump',
              'message': 'Secret Hand Card',
              'card_name': 'Hidden Library Card',
            },
          ),
        ],
      );

      expect(page.items.single.payload, isEmpty);
      expect(jsonEncode(page.toJson()), isNot(contains('Secret Hand Card')));
      expect(jsonEncode(page.toJson()), isNot(contains('Hidden Library Card')));
    });
  });

  group('battle_live_cursor_v1 cursor and reconnection', () {
    test('rejects malformed, tampered and cross-stream cursors', () {
      final contract = _contract();
      final first = contract.buildPage(
        streamId: 'job-cursor',
        status: BattleLiveStatus.running,
        records: [_event(0)],
      );
      final cursor = first.nextCursor;
      final tampered =
          '${cursor.substring(0, cursor.length - 1)}'
          '${cursor.endsWith('A') ? 'B' : 'A'}';

      expect(
        () => contract.buildPage(
          streamId: 'job-cursor',
          status: BattleLiveStatus.running,
          records: [_event(0)],
          cursor: 'not-a-cursor',
        ),
        throwsA(_contractError('invalid_cursor')),
      );
      expect(
        () => contract.buildPage(
          streamId: 'job-cursor',
          status: BattleLiveStatus.running,
          records: [_event(0)],
          cursor: tampered,
        ),
        throwsA(_contractError('invalid_cursor')),
      );
      expect(
        () => contract.buildPage(
          streamId: 'another-job',
          status: BattleLiveStatus.running,
          records: [_event(0)],
          cursor: cursor,
        ),
        throwsA(_contractError('cursor_stream_mismatch')),
      );
    });

    test('deduplicates records and does not redeliver replay after cursor', () {
      final contract = _contract();
      final records = [_event(0), _event(0), _event(1)];

      final first = contract.buildPage(
        streamId: 'job-reconnect',
        status: BattleLiveStatus.running,
        records: records,
        requestedLimit: 1,
      );
      expect(first.items.map((item) => item.sequence), [0]);
      expect(first.hasMore, isTrue);
      expect(first.items.map((item) => item.cursor).toSet(), hasLength(1));

      final second = contract.buildPage(
        streamId: 'job-reconnect',
        status: BattleLiveStatus.completed,
        records: records,
        cursor: first.nextCursor,
        requestedLimit: 10,
        replayId: 'replay-final-1',
      );
      expect(second.items.map((item) => item.sequence), [1]);
      expect(second.replay?.replayId, 'replay-final-1');
      expect(second.replayPending, isFalse);
      expect(second.items.single.cursor, isNot(second.nextCursor));

      final reconnected = contract.buildPage(
        streamId: 'job-reconnect',
        status: BattleLiveStatus.completed,
        records: records,
        cursor: second.nextCursor,
        requestedLimit: 10,
        replayId: 'replay-final-1',
      );
      expect(reconnected.items, isEmpty);
      expect(reconnected.replay, isNull);
      expect(reconnected.replayAlreadyDelivered, isTrue);
      expect(reconnected.hasMore, isFalse);
      expect(reconnected.nextCursor, second.nextCursor);
    });

    test('fails closed for conflicting duplicate identities', () {
      final contract = _contract();

      expect(
        () => contract.buildPage(
          streamId: 'job-conflict',
          status: BattleLiveStatus.running,
          records: [
            _event(0),
            BattleLiveSourceRecord.event(
              sequence: 0,
              recordId: 'event-0',
              event: const {'event_type': 'damage', 'damage': 7},
            ),
          ],
        ),
        throwsA(_contractError('record_sequence_conflict')),
      );
      expect(
        () => contract.buildPage(
          streamId: 'job-conflict',
          status: BattleLiveStatus.running,
          records: [
            _event(0),
            BattleLiveSourceRecord.event(
              sequence: 1,
              recordId: 'event-0',
              event: const {'event_type': 'spell_cast'},
            ),
          ],
        ),
        throwsA(_contractError('record_id_sequence_conflict')),
      );
    });
  });

  group('battle_live_cursor_v1 terminal and limits', () {
    test('makes active and every terminal status explicit', () {
      for (final status in BattleLiveStatus.values) {
        final page = _contract().buildPage(
          streamId: 'job-${status.wireValue}',
          status: status,
          records: const [],
          terminalReason: status.isTerminal ? 'terminal_reason' : null,
        );

        expect(page.toJson()['status'], status.wireValue);
        expect(page.toJson()['is_terminal'], status.isTerminal);
      }
    });

    test('does not expose a replay or terminal reason while active', () {
      final contract = _contract();

      expect(
        () => contract.buildPage(
          streamId: 'job-active',
          status: BattleLiveStatus.running,
          records: const [],
          replayId: 'replay-too-early',
        ),
        throwsA(_contractError('replay_requires_terminal_status')),
      );
      expect(
        () => contract.buildPage(
          streamId: 'job-active',
          status: BattleLiveStatus.queued,
          records: const [],
          terminalReason: 'not terminal',
        ),
        throwsA(_contractError('terminal_reason_requires_terminal_status')),
      );
      expect(
        () => contract.buildPage(
          streamId: 'job-terminal',
          status: BattleLiveStatus.engineError,
          records: const [],
          terminalReason: 'free-form private rationale',
        ),
        throwsA(_contractError('invalid_terminal_reason')),
      );
    });

    test('enforces page limit and resumes without duplicate sequences', () {
      final contract = BattleLiveCursorContract(
        cursorSigningKey: _signingKey,
        defaultPageLimit: 2,
        maximumPageLimit: 2,
      );
      final records = [_event(0), _event(1), _event(2)];

      final first = contract.buildPage(
        streamId: 'job-pages',
        status: BattleLiveStatus.running,
        records: records,
        requestedLimit: 999,
      );
      expect(first.items.map((item) => item.sequence), [0, 1]);
      expect(first.pageLimit, 2);
      expect(first.hasMore, isTrue);
      expect(first.truncation.pageLimit, isTrue);

      final second = contract.buildPage(
        streamId: 'job-pages',
        status: BattleLiveStatus.running,
        records: records,
        cursor: first.nextCursor,
      );
      expect(second.items.map((item) => item.sequence), [2]);
      expect(second.hasMore, isFalse);
    });

    test('bounds strings, collections and the encoded page payload', () {
      final contract = BattleLiveCursorContract(
        cursorSigningKey: _signingKey,
        defaultPageLimit: 10,
        maximumPageLimit: 10,
        maximumPayloadBytes: 1600,
        maximumPublicStringRunes: 1000,
        maximumPublicCollectionEntries: 2,
      );
      final records = [
        for (var index = 0; index < 3; index += 1)
          BattleLiveSourceRecord.event(
            sequence: index,
            recordId: 'event-long-$index',
            event: {'event_type': 'spell_cast', 'message': 'x' * 1000},
          ),
      ];

      final page = contract.buildPage(
        streamId: 'job-payload',
        status: BattleLiveStatus.running,
        records: records,
        requestedLimit: 10,
        sourceTruncated: true,
      );
      final encodedBytes = utf8.encode(jsonEncode(page.toJson())).length;

      expect(encodedBytes, lessThanOrEqualTo(1600));
      expect(page.items, hasLength(1));
      expect(page.items.single.contentTruncated, isTrue);
      expect(page.items.single.payload, isEmpty);
      expect(page.hasMore, isTrue);
      expect(page.truncation.payloadLimit, isTrue);
      expect(page.truncation.fieldLimit, isTrue);
      expect(page.truncation.source, isTrue);
      expect(page.toJson()['truncated'], isTrue);
    });

    test('marks field and collection truncation without filtering text', () {
      final contract = BattleLiveCursorContract(
        cursorSigningKey: _signingKey,
        maximumPublicStringRunes: 8,
        maximumPublicCollectionEntries: 1,
      );
      final page = contract.buildPage(
        streamId: 'job-fields',
        status: BattleLiveStatus.running,
        records: [
          BattleLiveSourceRecord.snapshot(
            sequence: 0,
            recordId: 'snapshot-fields',
            snapshot: const {
              'phase': 'Library hand options rationale',
              'players': [
                {'deck_key': 'deck_a', 'life': 40},
                {'deck_key': 'deck_b', 'life': 40},
              ],
            },
          ),
        ],
      );

      expect(page.items.single.payload['phase'], 'Library ');
      expect(page.items.single.payload['players'], hasLength(1));
      expect(page.items.single.contentTruncated, isTrue);
      expect(page.truncation.fieldLimit, isTrue);
    });
  });
}

final _signingKey = List<int>.generate(32, (index) => index + 1);

BattleLiveCursorContract _contract() =>
    BattleLiveCursorContract(cursorSigningKey: _signingKey);

BattleLiveSourceRecord _event(int sequence) => BattleLiveSourceRecord.event(
  sequence: sequence,
  recordId: 'event-$sequence',
  event: {
    'event_type': 'spell_cast',
    'turn': sequence + 1,
    'card_name': 'Card $sequence',
  },
);

Matcher _contractError(String code) => isA<BattleLiveContractException>()
    .having((error) => error.code, 'code', code);

Iterable<String> _nestedKeys(Object? value) sync* {
  if (value is Map) {
    for (final entry in value.entries) {
      yield entry.key.toString();
      yield* _nestedKeys(entry.value);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      yield* _nestedKeys(item);
    }
  }
}
