import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_live_cursor_contract.dart';
import 'package:server/battle/battle_live_source_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reads one correlated page and normalizes only public XMage data',
    () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode(
            _body(
              records: [
                {
                  'sequence': 0,
                  'record_id': 'battle-job-1:e:0',
                  'kind': 'event',
                  'event': {
                    'action': 'zone_change',
                    'turn': 2,
                    'player': 'deck_a',
                    'card_name': 'Sol Ring',
                    'from_zone': 'battlefield',
                    'to_zone': 'graveyard',
                    'decision_options': ['private choice'],
                  },
                },
                {
                  'sequence': 1,
                  'record_id': 'battle-job-1:e:1',
                  'kind': 'event',
                  'event': {
                    'action': 'game_inform_personal',
                    'message': 'Secret Hand Card',
                  },
                },
                {
                  'sequence': 2,
                  'record_id': 'battle-job-1:s:2',
                  'kind': 'snapshot',
                  'snapshot': {
                    'index': 0,
                    'turn': 2,
                    'players': [
                      {
                        'name': 'deck_a',
                        'life': 40,
                        'hand': ['Secret Hand Card'],
                        'library': ['Hidden Library Card'],
                        'battlefield': [
                          {'name': 'Sol Ring'},
                          {'name': 'Island'},
                        ],
                        'graveyard': [
                          {'name': 'Public Graveyard Card'},
                        ],
                        'exile': const [],
                        'command': [
                          {'name': 'Public Commander'},
                        ],
                      },
                    ],
                    'stack': [
                      {'id': 'stack-1', 'name': 'Counterspell'},
                    ],
                  },
                },
              ],
            ),
          ),
          200,
        );
      });
      final source = XmageBattleLiveSource(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: client,
      );

      final snapshot = await source.read('battle-job-1', limit: 200);
      source.close();

      expect(requestedUri.path, '/live/battle-job-1');
      expect(requestedUri.queryParameters, {'after': '-1', 'limit': '200'});
      expect(snapshot.afterSequence, -1);
      expect(snapshot.nextAfterSequence, 2);
      expect(snapshot.hasMore, isFalse);
      expect(snapshot.totalRecordCount, 3);
      expect(
        snapshot.records,
        hasLength(2),
        reason: 'unknown callback dropped',
      );

      final event = snapshot.records.first.payload;
      expect(event['event_type'], 'zone_transition');
      expect(event['visibility'], 'public');
      expect(event['card_name'], 'Sol Ring');
      expect(event['details'], {
        'zone_from': 'battlefield',
        'zone_to': 'graveyard',
      });

      final player =
          (snapshot.records.last.payload['players'] as List).single
              as Map<String, dynamic>;
      expect(player['hand_size'], 1);
      expect(player['library_size'], 1);
      expect(player['battlefield_count'], 2);
      expect(player['graveyard_size'], 1);
      expect(player['command_size'], 1);
      final encoded = jsonEncode(
        snapshot.records.map((record) => record.payload).toList(),
      );
      expect(encoded, isNot(contains('Secret Hand Card')));
      expect(encoded, isNot(contains('Hidden Library Card')));
      expect(encoded, isNot(contains('Public Graveyard Card')));

      final public = BattleLiveCursorContract(
        cursorSigningKey: List<int>.filled(32, 7),
      ).sanitizeRecordsForStorage(snapshot.records);
      final publicEncoded = jsonEncode(
        public.map((record) => record.payload).toList(),
      );
      expect(public.first.payload['card_name'], 'Sol Ring');
      expect(publicEncoded, isNot(contains('Secret Hand Card')));
      expect(publicEncoded, isNot(contains('Hidden Library Card')));
      expect(publicEncoded, isNot(contains('Public Graveyard Card')));
    },
  );

  test('zone identity stays hidden unless both zones are public', () async {
    final source = _source(
      _body(
        records: [
          {
            'sequence': 0,
            'record_id': 'battle-job-1:e:0',
            'kind': 'event',
            'event': {
              'action': 'visible_zone_entry',
              'card_name': 'Revealed only by malformed source',
              'to_zone': 'battlefield',
            },
          },
        ],
      ),
    );

    final snapshot = await source.read('battle-job-1');
    source.close();
    final public = BattleLiveCursorContract(
      cursorSigningKey: List<int>.filled(32, 9),
    ).buildPage(
      streamId: 'job-1',
      status: BattleLiveStatus.running,
      records: snapshot.records,
    );

    expect(public.items.single.payload, isNot(contains('card_name')));
    expect(public.items.single.payload, isNot(contains('visibility')));
  });

  test(
    'rejects identity, request correlation, and non-monotonic pages',
    () async {
      final identityMismatch = _body(records: const [])
        ..['engine_commit'] = 'f' * 40;
      final requestMismatch = _body(records: const [])
        ..['request_id'] = 'another-request';
      final nonMonotonic = _body(
        records: [
          {
            'sequence': 1,
            'record_id': 'battle-job-1:s:1',
            'kind': 'snapshot',
            'snapshot': const {},
          },
          {
            'sequence': 0,
            'record_id': 'battle-job-1:s:0',
            'kind': 'snapshot',
            'snapshot': const {},
          },
        ],
      )..['next_after_sequence'] = 0;

      for (final fixture in [
        (identityMismatch, 'source_identity_rejected'),
        (requestMismatch, 'source_correlation_rejected'),
        (nonMonotonic, 'source_page_not_monotonic'),
      ]) {
        final source = _source(fixture.$1);
        await expectLater(
          source.read('battle-job-1'),
          throwsA(
            isA<BattleLiveSourceException>().having(
              (error) => error.code,
              'code',
              fixture.$2,
            ),
          ),
        );
        source.close();
      }
    },
  );

  test(
    'rejects oversized source identities and inconsistent page cursors',
    () async {
      final oversizedProcess = _body(records: const [])
        ..['sidecar_process_id'] = 'p' * 257;
      final oversizedRecord = _body(
        records: [
          {
            'sequence': 0,
            'record_id': 'r' * 129,
            'kind': 'snapshot',
            'snapshot': const {},
          },
        ],
      );
      final inconsistentHasMore =
          _body(
              records: [
                {
                  'sequence': 0,
                  'record_id': 'battle-job-1:s:0',
                  'kind': 'snapshot',
                  'snapshot': const {},
                },
              ],
            )
            ..['record_count'] = 2
            ..['has_more'] = false;

      for (final fixture in [
        (oversizedProcess, 'source_payload_invalid'),
        (oversizedRecord, 'source_record_invalid'),
        (inconsistentHasMore, 'source_page_cursor_mismatch'),
      ]) {
        final source = _source(fixture.$1);
        await expectLater(
          source.read('battle-job-1'),
          throwsA(
            isA<BattleLiveSourceException>().having(
              (error) => error.code,
              'code',
              fixture.$2,
            ),
          ),
        );
        source.close();
      }
    },
  );

  test(
    'bounds body, exposes retriable 404, and performs no internal retry',
    () async {
      var calls = 0;
      final missing = XmageBattleLiveSource(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient((_) async {
          calls += 1;
          return http.Response('{}', 404);
        }),
      );

      await expectLater(
        missing.read('battle-job-1'),
        throwsA(
          isA<BattleLiveSourceException>()
              .having((error) => error.code, 'code', 'source_stream_not_found')
              .having((error) => error.retryable, 'retryable', isTrue),
        ),
      );
      expect(calls, 1);
      missing.close();

      final oversizedBody = _body(records: const [])..['padding'] = 'x' * 2048;
      final oversized = XmageBattleLiveSource(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        maximumPayloadBytes: 1024,
        client: MockClient(
          (_) async => http.Response(jsonEncode(oversizedBody), 200),
        ),
      );
      await expectLater(
        oversized.read('battle-job-1'),
        throwsA(
          isA<BattleLiveSourceException>().having(
            (error) => error.code,
            'code',
            'source_payload_too_large',
          ),
        ),
      );
      oversized.close();
    },
  );
}

XmageBattleLiveSource _source(Map<String, dynamic> body) {
  return XmageBattleLiveSource(
    baseUrl: 'http://xmage.internal:8080',
    expectedIdentity: _identity,
    client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
  );
}

Map<String, dynamic> _body({required List<Map<String, dynamic>> records}) {
  return {
    'schema_version': externalBattleExecutionSchema,
    'live_schema_version': externalBattleLiveSourceSchema,
    'request_id': 'battle-job-1',
    'status': 'running',
    'terminal': false,
    'source_truncated': false,
    'records': records,
    'page_record_count': records.length,
    'record_count': records.length,
    'after_sequence': -1,
    'next_after_sequence':
        records.isEmpty ? -1 : records.last['sequence'] as int,
    'has_more': false,
    'engine': 'xmage',
    'engine_version': pinnedXmageVersion,
    'engine_commit': pinnedXmageCommit,
    'sidecar_protocol_version': externalBattleSidecarProtocol,
    'sidecar_build_identity': _identity.buildIdentity,
    'sidecar_process_id': 'xmage-process-1',
    'sidecar_started_at': '2026-07-26T12:00:00Z',
    'ai_profile': _identity.aiProfile,
    'normalizer_version': _identity.telemetryVersion,
    'seed_semantics': _identity.seedSemantics,
    'deterministic': false,
    'fallback_reason': 'none',
  };
}

const _identity = ExternalBattleEngineIdentity(
  engine: 'xmage',
  version: pinnedXmageVersion,
  commit: pinnedXmageCommit,
  aiProfile: 'computer_mad',
  telemetryField: 'normalizer_version',
  telemetryVersion: 'xmage_replay_normalizer_v2',
  seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
  deterministic: false,
);
