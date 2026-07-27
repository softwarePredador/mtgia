import 'dart:convert';
import 'dart:io';

import 'package:server/battle/battle_live_cursor_contract.dart';
import 'package:test/test.dart';

const _deepEventCount = 20000;
const _syntheticStreams = 64;
const _sourceEventsPerStream = 200;
const _requestedApiPage = 100;
const _payloadBudgetBytes = 128 * 1024;
const _aggregatePayloadBudgetBytes = 8 * 1024 * 1024;
const _rssDeltaBudgetBytes = 256 * 1024 * 1024;
const _deepP95BudgetMs = 5000;
const _streamP95BudgetMs = 750;
const _aggregateElapsedBudgetMs = 15000;
const _sampleCount = 5;

void main() {
  test(
    'BL6-06 bounds deep history and 64-stream synthetic live fanout',
    () async {
      final initialRss = ProcessInfo.currentRss;
      final contract = BattleLiveCursorContract(
        cursorSigningKey: utf8.encode(
          'battle-local-load-homologation-key-20260726',
        ),
      );
      final deepRecords = _records(_deepEventCount);
      final deepSamplesUs = <int>[];

      for (var sample = 0; sample < _sampleCount; sample++) {
        final stopwatch = Stopwatch()..start();
        final page = contract.buildPage(
          streamId: 'deep-stream',
          status: BattleLiveStatus.running,
          records: deepRecords,
          requestedLimit: _requestedApiPage,
        );
        stopwatch.stop();
        deepSamplesUs.add(stopwatch.elapsedMicroseconds);
        _expectBoundedPage(page);
        expect(page.items, hasLength(_requestedApiPage));
        expect(page.hasMore, isTrue);
      }

      final sourceRecords = _records(_sourceEventsPerStream);
      final streamSamplesUs = <int>[];
      final encodedPayloadSizes = <int>[];
      final aggregateStopwatch = Stopwatch()..start();

      final pages = await Future.wait([
        for (var stream = 0; stream < _syntheticStreams; stream++)
          Future(() {
            final stopwatch = Stopwatch()..start();
            final page = contract.buildPage(
              streamId: 'stream-$stream',
              status: BattleLiveStatus.running,
              records: sourceRecords,
              requestedLimit: _requestedApiPage,
            );
            stopwatch.stop();
            streamSamplesUs.add(stopwatch.elapsedMicroseconds);
            encodedPayloadSizes.add(
              utf8.encode(jsonEncode(page.toJson())).length,
            );
            return page;
          }),
      ]);
      aggregateStopwatch.stop();

      expect(pages, hasLength(_syntheticStreams));
      for (final page in pages) {
        _expectBoundedPage(page);
        expect(page.items, hasLength(_requestedApiPage));
        expect(page.hasMore, isTrue);
      }

      deepSamplesUs.sort();
      streamSamplesUs.sort();
      final deepP50Us = _percentile(deepSamplesUs, 0.50);
      final deepP95Us = _percentile(deepSamplesUs, 0.95);
      final streamP50Us = _percentile(streamSamplesUs, 0.50);
      final streamP95Us = _percentile(streamSamplesUs, 0.95);
      final aggregatePayloadBytes = encodedPayloadSizes.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      final rawRssDeltaBytes = ProcessInfo.currentRss - initialRss;
      final rssDeltaBytes = rawRssDeltaBytes < 0 ? 0 : rawRssDeltaBytes;

      expect(
        deepP95Us,
        lessThanOrEqualTo(_deepP95BudgetMs * 1000),
        reason: '20k-event contract preparation exceeded local p95 budget',
      );
      expect(
        streamP95Us,
        lessThanOrEqualTo(_streamP95BudgetMs * 1000),
        reason: 'synthetic per-stream page exceeded local p95 budget',
      );
      expect(
        aggregateStopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(_aggregateElapsedBudgetMs),
        reason: '64-stream synthetic fanout exceeded local elapsed budget',
      );
      expect(
        aggregatePayloadBytes,
        lessThanOrEqualTo(_aggregatePayloadBudgetBytes),
      );
      expect(
        rssDeltaBytes,
        lessThanOrEqualTo(_rssDeltaBudgetBytes),
        reason: 'synthetic harness exceeded the bounded host RSS delta',
      );

      final result = {
        'schema': 'battle_live_local_load_homologation_v1',
        'classification': 'synthetic_host_preflight_not_target_load_proof',
        'fixture': {
          'deep_events': _deepEventCount,
          'streams': _syntheticStreams,
          'source_events_per_stream': _sourceEventsPerStream,
          'api_page_limit': _requestedApiPage,
        },
        'budgets': {
          'deep_p95_ms': _deepP95BudgetMs,
          'stream_p95_ms': _streamP95BudgetMs,
          'aggregate_elapsed_ms': _aggregateElapsedBudgetMs,
          'page_payload_bytes': _payloadBudgetBytes,
          'aggregate_payload_bytes': _aggregatePayloadBudgetBytes,
          'rss_delta_bytes': _rssDeltaBudgetBytes,
        },
        'measurements': {
          'deep_p50_us': deepP50Us,
          'deep_p95_us': deepP95Us,
          'stream_p50_us': streamP50Us,
          'stream_p95_us': streamP95Us,
          'aggregate_elapsed_ms': aggregateStopwatch.elapsedMilliseconds,
          'maximum_page_payload_bytes': encodedPayloadSizes.reduce(
            (left, right) => left > right ? left : right,
          ),
          'aggregate_payload_bytes': aggregatePayloadBytes,
          'rss_delta_bytes': rssDeltaBytes,
        },
        'blocked_proofs': const [
          'real_concurrent_sockets',
          'target_cpu_profile',
          'target_rss_profile',
          'production_sidecar',
        ],
      };
      // ignore: avoid_print
      print('BATTLE_LIVE_LOCAL_LOAD ${jsonEncode(result)}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

void _expectBoundedPage(BattleLivePage page) {
  final encodedBytes = utf8.encode(jsonEncode(page.toJson())).length;
  expect(page.pageLimit, _requestedApiPage);
  expect(page.items.length, lessThanOrEqualTo(_requestedApiPage));
  expect(page.maximumPayloadBytes, _payloadBudgetBytes);
  expect(encodedBytes, lessThanOrEqualTo(_payloadBudgetBytes));
}

List<BattleLiveSourceRecord> _records(int count) => List.generate(
  count,
  (index) => BattleLiveSourceRecord.event(
    sequence: index,
    recordId: 'event-$index',
    event: {
      'event_type': index.isEven ? 'spell_cast' : 'life_change',
      'event_id': 'event-$index',
      'turn': (index ~/ 20) + 1,
      'actor_side': index.isEven ? 'deck_a' : 'deck_b',
      'subject_deck_key': index.isEven ? 'deck_a' : 'deck_b',
      'card_name': index.isEven ? 'Sol Ring' : 'Forest',
      'message': 'Public battle event $index',
      'amount': index % 5,
    },
  ),
  growable: false,
);

int _percentile(List<int> sortedValues, double percentile) {
  final index = ((sortedValues.length - 1) * percentile).ceil();
  return sortedValues[index];
}
