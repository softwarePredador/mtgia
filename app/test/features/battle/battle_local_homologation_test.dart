import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_live_cursor.dart';
import 'package:manaloom/features/battle/models/battle_post_report.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_live_spectator_screen.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';
import 'package:manaloom/features/battle/services/battle_post_report_service.dart';

const _historyItemCount = 100;
const _detailEventCount = 20000;
const _seriesReportCount = 10;
const _performanceSampleCount = 7;
const _slowNetworkDelay = Duration(milliseconds: 300);

const _vmBudgetsMs = <String, int>{
  'history_parse_100': 250,
  'detail_parse_20000': 2500,
  'scrub_scan_20000': 100,
  'filter_20000': 400,
  'series_summarize_10': 100,
};

const _webBudgetsMs = <String, int>{
  'history_parse_100': 500,
  'detail_parse_20000': 5000,
  'scrub_scan_20000': 250,
  'filter_20000': 800,
  'series_summarize_10': 250,
};

void main() {
  test(
    'BL4-03 records bounded p50/p95 for history, detail, scrub, filters and series',
    () {
      final budgets = kIsWeb ? _webBudgetsMs : _vmBudgetsMs;
      final historyPayloads = _historyPayloads();
      final detailPayload = _detailPayload();
      final parsedDetail = BattleReplayDetail.fromJson(detailPayload);
      final reports = _reports();
      final service = const BattlePostReportService();
      var blackHole = 0;

      final measurements = <String, _PercentileMeasurement>{
        'history_parse_100': _measure(
          name: 'history_parse_100',
          budgetMs: budgets['history_parse_100']!,
          action: () {
            final summaries = historyPayloads
                .map(BattleReplaySummary.fromJson)
                .toList(growable: false);
            blackHole += summaries.length + summaries.last.id.length;
          },
        ),
        'detail_parse_20000': _measure(
          name: 'detail_parse_20000',
          budgetMs: budgets['detail_parse_20000']!,
          action: () {
            final detail = BattleReplayDetail.fromJson(detailPayload);
            blackHole += detail.events.length + detail.summary.id.length;
          },
        ),
        'scrub_scan_20000': _measure(
          name: 'scrub_scan_20000',
          budgetMs: budgets['scrub_scan_20000']!,
          action: () {
            var checksum = 0;
            for (var index = 0; index < parsedDetail.events.length; index++) {
              final event = parsedDetail.events[index];
              checksum +=
                  (event.turn ?? 0) +
                  event.action.length +
                  event.message.length;
            }
            blackHole += checksum;
          },
        ),
        'filter_20000': _measure(
          name: 'filter_20000',
          budgetMs: budgets['filter_20000']!,
          action: () {
            final filtered = parsedDetail.events
                .where(
                  (event) =>
                      (event.turn ?? 0) >= 250 &&
                      event.actor == 'Player A' &&
                      event.action == 'casts',
                )
                .toList(growable: false);
            blackHole += filtered.length;
          },
        ),
        'series_summarize_10': _measure(
          name: 'series_summarize_10',
          budgetMs: budgets['series_summarize_10']!,
          action: () {
            final sample = service.summarize(reports);
            blackHole += sample.n + sample.subjectWins;
          },
        ),
      };

      expect(blackHole, isNonZero);
      for (final entry in measurements.entries) {
        expect(
          entry.value.p95Us,
          lessThanOrEqualTo(entry.value.budgetMs * 1000),
          reason:
              '${entry.key} p95=${entry.value.p95Us}us exceeded the local '
              'preflight budget ${entry.value.budgetMs}ms',
        );
      }

      final result = {
        'schema': 'battle_local_homologation_performance_v1',
        'scope': kIsWeb ? 'web_chrome_test_host' : 'flutter_test_host_vm',
        'classification': 'local_preflight_not_target_device_proof',
        'samples': _performanceSampleCount,
        'fixtures': {
          'history_items': _historyItemCount,
          'detail_events': _detailEventCount,
          'series_reports': _seriesReportCount,
        },
        'measurements': {
          for (final entry in measurements.entries)
            entry.key: entry.value.toJson(),
        },
        'blocked_proofs': const [
          'android_physical_target',
          'talkback',
          'production_network',
        ],
      };
      // The prefixed JSON line is intentionally machine-extractable for the
      // manual QA evidence without turning host timings into target claims.
      // ignore: avoid_print
      print('BATTLE_LOCAL_HOMOLOGATION ${jsonEncode(result)}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'BL6-07 slow network, offline retry and cursor resume remain bounded',
    (tester) async {
      final gateway = _HomologationJobGateway(
        job: _job(status: 'running', stage: 'running', current: 3),
        responses: [
          _DelayedLiveResponse(
            delay: _slowNetworkDelay,
            outcome: _page(
              items: [
                _eventRecord(
                  sequence: 1,
                  recordId: 'event-1',
                  message: 'Alice conjurou Sol Ring.',
                ),
              ],
              nextCursor: 'blc1.first.signature',
            ),
          ),
          const _DelayedLiveResponse(
            delay: _slowNetworkDelay,
            outcome: BattleJobGatewayException(
              code: 'battle_transport_unavailable',
              message: 'Não foi possível conectar ao Battle agora.',
            ),
          ),
          _DelayedLiveResponse(
            delay: _slowNetworkDelay,
            outcome: _page(
              items: [
                _eventRecord(
                  sequence: 1,
                  recordId: 'event-1',
                  message: 'Alice conjurou Sol Ring.',
                ),
                _eventRecord(
                  sequence: 2,
                  recordId: 'event-2',
                  message: 'Bob perdeu 2 pontos de vida.',
                ),
              ],
              nextCursor: 'blc1.recovered.signature',
            ),
          ),
        ],
      );

      await _pumpLiveScreen(tester, gateway);
      expect(gateway.activePolls, 1);
      expect(find.byKey(const Key('battle-live-record-event-1')), findsNothing);

      await tester.pump(_slowNetworkDelay - const Duration(milliseconds: 1));
      expect(find.byKey(const Key('battle-live-record-event-1')), findsNothing);
      expect(gateway.maximumConcurrentPolls, 1);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byKey(const Key('battle-live-record-event-1')), findsOne);
      expect(gateway.pollInputs.single.cursor, isNull);

      await tester.pump(const Duration(milliseconds: 100));
      expect(gateway.activePolls, 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        gateway.maximumConcurrentPolls,
        1,
        reason: 'a slow request must not create overlapping polls',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.byKey(const Key('battle-live-reconnect-banner')), findsOne);
      expect(find.byKey(const Key('battle-live-record-event-1')), findsOne);
      expect(gateway.pollInputs[1].cursor, 'blc1.first.signature');

      final retry = find.byKey(const Key('battle-live-inline-retry-button'));
      final retryWidget = tester.widget<TextButton>(retry);
      expect(
        retryWidget.focusNode?.hasFocus,
        isTrue,
        reason: 'offline recovery must move keyboard focus to reconnect',
      );

      await tester.tap(retry);
      await tester.pump();
      await tester.pump(_slowNetworkDelay);
      await tester.pump();

      expect(
        find.byKey(const Key('battle-live-reconnect-banner')),
        findsNothing,
      );
      expect(gateway.pollInputs[2].cursor, 'blc1.first.signature');
      expect(find.byKey(const Key('battle-live-record-event-1')), findsOne);
      expect(find.byKey(const Key('battle-live-record-event-2')), findsOne);
      expect(
        find.byKey(const Key('battle-live-record-event-1')),
        findsOne,
        reason: 'the replayed record must remain deduplicated after reconnect',
      );
      expect(gateway.maximumConcurrentPolls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'BL4-05 exposes semantics, keyboard and reduced motion at 200 percent text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final gateway = _HomologationJobGateway(
        job: _job(status: 'running', stage: 'running', current: 3),
        responses: [
          _DelayedLiveResponse(
            delay: Duration.zero,
            outcome: _page(
              items: [
                _eventRecord(
                  sequence: 1,
                  recordId: 'event-a11y-1',
                  message: 'Alice conjurou Sol Ring.',
                ),
              ],
            ),
          ),
        ],
      );

      await _pumpLiveScreen(
        tester,
        gateway,
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(
        find.byKey(const Key('battle-live-record-event-a11y-1')),
        findsOne,
      );

      final progressSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('battle-live-progress')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(progressSemantics.properties.label, 'Progresso do Battle');
      expect(
        progressSemantics.properties.value,
        'Em andamento: Simulação em curso',
      );
      expect(find.bySemanticsLabel('Pausar visualização'), findsOne);
      final reconnect = find.byKey(const Key('battle-live-refresh-button'));
      expect(find.byTooltip('Reconectar ao Battle'), findsOne);
      expect(tester.getSize(reconnect).shortestSide, greaterThanOrEqualTo(48));

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, Duration.zero);

      final keyboardFocus = tester.widget<Focus>(
        find.byKey(const Key('battle-live-keyboard-focus')),
      );
      keyboardFocus.focusNode?.requestFocus();
      await tester.pump();
      expect(keyboardFocus.focusNode?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.text('Pausa local'), findsOne);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );
}

_PercentileMeasurement _measure({
  required String name,
  required int budgetMs,
  required void Function() action,
}) {
  action();
  final samplesUs = <int>[];
  for (var index = 0; index < _performanceSampleCount; index++) {
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    samplesUs.add(stopwatch.elapsedMicroseconds);
  }
  samplesUs.sort();
  return _PercentileMeasurement(
    name: name,
    budgetMs: budgetMs,
    p50Us: _percentile(samplesUs, 0.50),
    p95Us: _percentile(samplesUs, 0.95),
    maxUs: samplesUs.last,
  );
}

int _percentile(List<int> sortedValues, double percentile) {
  final index = ((sortedValues.length - 1) * percentile).ceil();
  return sortedValues[index];
}

class _PercentileMeasurement {
  const _PercentileMeasurement({
    required this.name,
    required this.budgetMs,
    required this.p50Us,
    required this.p95Us,
    required this.maxUs,
  });

  final String name;
  final int budgetMs;
  final int p50Us;
  final int p95Us;
  final int maxUs;

  Map<String, Object> toJson() => {
    'name': name,
    'budget_ms': budgetMs,
    'p50_us': p50Us,
    'p95_us': p95Us,
    'max_us': maxUs,
    'within_budget': p95Us <= budgetMs * 1000,
  };
}

List<Map<String, dynamic>> _historyPayloads() => List.generate(
  _historyItemCount,
  (index) => {
    'id': 'replay-$index',
    'deck_id': 'deck-a',
    'opponent_deck_id': 'deck-b',
    'opponent_name': 'Opponent $index',
    'type': index.isEven ? 'battle' : 'matchup',
    'status': 'completed',
    'source': 'battle_simulations',
    'created_at':
        '2026-07-26T12:${(index % 60).toString().padLeft(2, '0')}:00Z',
    'turns': 12 + (index % 8),
    'event_count': _detailEventCount,
  },
  growable: false,
);

Map<String, dynamic> _detailPayload() => {
  'id': 'replay-performance',
  'deck_id': 'deck-a',
  'opponent_deck_id': 'deck-b',
  'type': 'battle',
  'status': 'completed',
  'source': 'battle_simulations',
  'events': List.generate(
    _detailEventCount,
    (index) => {
      'event_id': 'event-$index',
      'turn': (index ~/ 20) + 1,
      'phase': index.isEven ? 'main' : 'combat',
      'player': index.isEven ? 'Player A' : 'Player B',
      'action': index.isEven ? 'casts' : 'resolves',
      'message': 'Evento observado $index',
    },
    growable: false,
  ),
};

List<BattlePostReport> _reports() => List.generate(
  _seriesReportCount,
  (index) => BattlePostReport(
    replayId: 'report-$index',
    outcome: BattleReportOutcome.completed,
    completedResult: index.isEven
        ? BattleCompletedResult.subjectWin
        : BattleCompletedResult.opponentWin,
    turnCount: 10 + index,
    durationMs: 1000 + index,
    identity: BattleRunIdentity(
      subjectDeckId: 'deck-a',
      opponentDeckId: 'deck-b',
      subjectDeckRevision: 'revision-1',
      subjectDeckHash: null,
      opponentDeckHash: null,
      engine: 'xmage',
      engineCommit: 'engine-commit',
      timeoutMs: 40000,
      seed: index,
    ),
    reliability: const BattleReportReliability(
      learningSchemaVersion: 'external_battle_learning_v1',
      eventStreamCompleteness: 'best_effort_visible_state_lower_bound',
      absenceProvesNonuse: false,
      namedDrawIdentityAvailable: false,
      aiDecisionRationaleAvailable: false,
      combatActivityAvailable: true,
      decisionTraceAvailable: false,
      eventsTruncated: false,
      snapshotsTruncated: false,
    ),
    lifeCurve: const [],
    observedActivities: const [],
    observability: const {},
  ),
  growable: false,
);

class _DelayedLiveResponse {
  const _DelayedLiveResponse({required this.delay, required this.outcome});

  final Duration delay;
  final Object outcome;
}

class _HomologationJobGateway extends BattleJobGateway {
  _HomologationJobGateway({
    required BattleJob job,
    required List<_DelayedLiveResponse> responses,
  }) : _job = job,
       _responses = List.of(responses);

  final BattleJob _job;
  final List<_DelayedLiveResponse> _responses;
  final List<BattleLiveSession> pollInputs = [];
  int activePolls = 0;
  int maximumConcurrentPolls = 0;

  @override
  Future<BattleJob> get(String jobId) async => _job;

  @override
  Future<BattleLiveSession> pollLive({
    required String jobId,
    BattleLiveSession session = const BattleLiveSession.empty(),
    int limit = 50,
  }) async {
    pollInputs.add(session);
    activePolls += 1;
    if (activePolls > maximumConcurrentPolls) {
      maximumConcurrentPolls = activePolls;
    }
    try {
      if (_responses.isEmpty) return session;
      final response = _responses.removeAt(0);
      await Future<void>.delayed(response.delay);
      final outcome = response.outcome;
      if (outcome is BattleJobGatewayException) throw outcome;
      return session.apply(outcome as BattleLivePage);
    } finally {
      activePolls -= 1;
    }
  }
}

Future<void> _pumpLiveScreen(
  WidgetTester tester,
  _HomologationJobGateway gateway, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: BattleLiveSpectatorScreen(
          deckId: 'deck-a',
          jobId: 'job-1',
          gateway: gateway,
          featureEnabled: true,
          pollInterval: const Duration(milliseconds: 100),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

BattleJob _job({
  String status = 'queued',
  String stage = 'queued',
  int current = 0,
}) {
  final terminal = const {
    'completed',
    'censored',
    'timeout',
    'coverage_error',
    'engine_error',
    'cancelled',
    'persistence_error',
  }.contains(status);
  return BattleJob.fromJson({
    'schema_version': 'battle_job_v1',
    'job_id': 'job-1',
    'idempotency_key': 'attempt-1',
    'status': status,
    'stage': stage,
    'progress': {'current': current, 'total': 6, 'ratio': current / 6},
    'deck_a_id': 'deck-a',
    'deck_b_id': 'deck-b',
    'deck_hashes': {
      'schema_version': 'external_battle_deck_hash_v1',
      'algorithm': 'sha256',
      'deck_a': _hash('a'),
      'deck_b': _hash('b'),
    },
    'request_schema_version': battleJobRequestSchemaVersion,
    'request_hash': _hash('c'),
    'requested_engine': 'auto',
    'engine': null,
    'timeout_ms': 40000,
    'attempt_count': status == 'queued' ? 0 : 1,
    if (status != 'queued') 'attempt_id': 'attempt-run-1',
    'heartbeat_at': '2026-07-26T12:00:01Z',
    'created_at': '2026-07-26T12:00:00Z',
    'updated_at': '2026-07-26T12:00:01Z',
    if (terminal) 'finished_at': '2026-07-26T12:00:02Z',
    'can_cancel':
        status == 'queued' || status == 'claimed' || status == 'running',
    'can_resume': !terminal,
    'poll_url': '/ai/battle/jobs/job-1',
    'cancel_url': '/ai/battle/jobs/job-1',
  });
}

BattleLivePage _page({
  List<Map<String, dynamic>> items = const [],
  String nextCursor = 'blc1.next.signature',
}) {
  return BattleLivePage.fromJson({
    'schema_version': 'battle_live_cursor_v1',
    'transport': 'polling_long_polling',
    'stream_id': 'job-1',
    'status': 'running',
    'is_terminal': false,
    'items': items,
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': false,
    'truncated': false,
    'truncation': const {
      'source': false,
      'page_limit': false,
      'payload_limit': false,
      'field_limit': false,
    },
    'limits': const {'page': 50, 'payload_bytes': 131072},
    'replay_pending': false,
    'replay_already_delivered': false,
  });
}

Map<String, dynamic> _eventRecord({
  required int sequence,
  required String recordId,
  required String message,
}) {
  return {
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.event$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'event',
    'event': {
      'event_type': 'spell_cast',
      'event_id': recordId,
      'turn': 1,
      'actor_side': 'deck_a',
      'subject_deck_key': 'deck_a',
      'card_name': 'Sol Ring',
      'message': message,
    },
    'content_truncated': false,
  };
}

String _hash(String character) => List.filled(64, character).join();
