import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_live_cursor.dart';
import 'package:manaloom/features/battle/screens/battle_live_spectator_screen.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart'
    show captureVisualProof, resetVisualCaptureSurface;
import 'web_viewport_reset.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
  defaultValue: true,
);
const _sourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _profile = String.fromEnvironment(
  'MANALOOM_UI_PROOF_PROFILE',
  defaultValue: 'web_battle_live_1440x900',
);
const _runtimeTarget = String.fromEnvironment(
  'MANALOOM_UI_PROOF_TARGET',
  defaultValue: 'web_real_build',
);
const _deviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
  defaultValue: 'Chrome real release build',
);
const _proofWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 1440,
);
const _proofHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 900,
);

const _checkpoints = <String>[
  'battle_live_00_waiting',
  'battle_live_01_active_feed',
  'battle_live_02_recoverable_reconnect',
  'battle_live_03_timeout_terminal',
  'battle_live_04_completed_replay',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'Battle Live proves waiting, public feed, preserved reconnect and timeout',
    (tester) async {
      _expectRuntimeContract();
      _emitRuntimeContext();

      final gateway = _BattleLiveProofGateway.waiting();
      await _pumpSubject(tester, gateway);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-live-status-header')),
      );
      expect(find.byKey(const Key('battle-live-progress')), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('battle-live-progress')),
            )
            .value,
        isNull,
      );
      expect(find.textContaining('15 de 100'), findsNothing);
      expect(
        find.textContaining('Aguardando o primeiro estado'),
        findsOneWidget,
      );
      await _capture(binding, tester, _checkpoints[0]);

      gateway.showActiveFeed();
      await _pumpSubject(
        tester,
        gateway,
        key: const ValueKey('battle-live-active-proof'),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-live-record-event-spell-1')),
      );
      expect(find.text('Alice conjurou Sol Ring.'), findsOneWidget);
      expect(find.textContaining('Mão adversária'), findsNothing);
      await _capture(binding, tester, _checkpoints[1]);

      gateway.showRecoverableFailure();
      await tester.tap(find.byKey(const Key('battle-live-refresh-button')));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-live-reconnect-banner')),
      );
      expect(
        find.byKey(const Key('battle-live-record-event-spell-1')),
        findsOneWidget,
        reason: 'A reconnect failure must preserve the already received table.',
      );
      expect(find.textContaining('DioException'), findsNothing);
      await _capture(binding, tester, _checkpoints[2]);

      gateway.showTimeout();
      await tester.tap(
        find.byKey(const Key('battle-live-inline-retry-button')),
      );
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-live-new-attempt-button')),
      );
      await tester.ensureVisible(
        find.byKey(const Key('battle-live-new-attempt-button')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('limite de tempo'), findsOneWidget);
      expect(find.textContaining('XMage'), findsNothing);
      await _capture(binding, tester, _checkpoints[3]);
    },
  );

  testWidgets('Battle Live proves a completed replay action', (tester) async {
    resetVisualCaptureSurface();
    final gateway = _BattleLiveProofGateway.completed();
    String? openedReplayId;
    await _pumpSubject(
      tester,
      gateway,
      onOpenReplay: (replayId) => openedReplayId = replayId,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-live-open-replay-button')),
    );
    final replayButton = find.byKey(
      const Key('battle-live-open-replay-button'),
    );
    await tester.ensureVisible(replayButton);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Battle concluído e replay validado'), findsOneWidget);
    await _capture(binding, tester, _checkpoints[4]);
    await tester.ensureVisible(replayButton);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(replayButton);
    await tester.pump();
    expect(openedReplayId, 'replay-proof-1');
  });
}

void _expectRuntimeContract() {
  if (!_captureRuntimeProof) return;
  expect(
    _sourceDigest,
    matches(RegExp(r'^[0-9a-f]{64}$')),
    reason: 'Runtime evidence must be bound to the current UI source digest.',
  );
  expect(_profile, 'web_battle_live_1440x900');
  expect(_runtimeTarget, 'web_real_build');
  expect(_deviceContract.toLowerCase(), contains('chrome'));
}

void _emitRuntimeContext() {
  if (!_captureRuntimeProof) return;
  // The runner normalizes this marker after a successful release drive because
  // Web release builds may omit application print output. No private payload,
  // account, API coordinate or engine identity is included.
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'battle_live', 'source_digest': _sourceDigest, 'profile': _profile, 'runtime': 'flutter_drive', 'target': _runtimeTarget, 'device_contract': _deviceContract, 'required_checkpoints': _checkpoints})}',
  );
}

Future<void> _pumpSubject(
  WidgetTester tester,
  BattleJobGateway gateway, {
  Key? key,
  ValueChanged<String>? onOpenReplay,
}) async {
  if (kIsWeb) {
    await tester.binding.setSurfaceSize(
      Size(_proofWidth.toDouble(), _proofHeight.toDouble()),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: BattleLiveSpectatorScreen(
        key: key,
        deckId: 'deck-proof-a',
        jobId: 'job-proof-1',
        gateway: gateway,
        featureEnabled: true,
        pollInterval: const Duration(hours: 1),
        onOpenReplay: onOpenReplay,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint,
) async {
  resetBrowserViewport();
  for (var frame = 0; frame < 2; frame += 1) {
    _resetFlutterScrollables(tester);
    await tester.pump(const Duration(milliseconds: 60));
  }
  expect(tester.takeException(), isNull, reason: 'Before $checkpoint');
  expectNoRawTechnicalErrorText(tester);
  if (_captureRuntimeProof) {
    await captureVisualProof(
      binding,
      tester,
      checkpoint,
      beforeTakeScreenshot: () async {
        // Normalize after the helper's settle and surface conversion. A newly
        // enabled control can otherwise make Chrome retain a stale focus
        // scroll between checkpoints.
        resetBrowserViewport();
        _resetFlutterScrollables(tester);
        await tester.pump();
      },
    );
  }
  expect(tester.takeException(), isNull, reason: 'After $checkpoint');
}

void _resetFlutterScrollables(WidgetTester tester) {
  final scrollables = find.byType(Scrollable);
  final count = scrollables.evaluate().length;
  for (var index = 0; index < count; index += 1) {
    final state = tester.state<ScrollableState>(scrollables.at(index));
    state.position.jumpTo(state.position.minScrollExtent);
  }
}

enum _ProofState { waiting, active, recoverableFailure, timeout, completed }

class _BattleLiveProofGateway extends BattleJobGateway {
  _BattleLiveProofGateway.waiting() : _state = _ProofState.waiting;

  _BattleLiveProofGateway.completed() : _state = _ProofState.completed;

  _ProofState _state;

  void showActiveFeed() => _state = _ProofState.active;

  void showRecoverableFailure() => _state = _ProofState.recoverableFailure;

  void showTimeout() => _state = _ProofState.timeout;

  @override
  Future<BattleJob> get(String jobId) async => switch (_state) {
    _ProofState.waiting => _job(stage: 'starting_engine'),
    _ProofState.active ||
    _ProofState.recoverableFailure => _job(stage: 'running'),
    _ProofState.timeout => _job(
      status: 'timeout',
      stage: 'timeout',
      terminalReason: 'battle_job_timeout',
      errorCode: 'battle_job_timeout',
    ),
    _ProofState.completed => _job(
      status: 'completed',
      stage: 'completed',
      replayId: 'replay-proof-1',
      terminalReason: 'completed',
    ),
  };

  @override
  Future<BattleLiveSession> pollLive({
    required String jobId,
    BattleLiveSession session = const BattleLiveSession.empty(),
    int limit = 50,
  }) async => switch (_state) {
    _ProofState.waiting => throw const BattleJobGatewayException(
      code: 'battle_job_conflict',
      message: 'Engine assignment is still in progress.',
      statusCode: 409,
    ),
    _ProofState.active => session.apply(
      _page(
        status: 'running',
        items: [
          _eventRecord(
            sequence: 1,
            recordId: 'event-spell-1',
            message: 'Alice conjurou Sol Ring.',
          ),
          _snapshotRecord(sequence: 2, recordId: 'snapshot-main-2'),
        ],
        nextCursor: 'blc1.active.signature',
      ),
    ),
    _ProofState.recoverableFailure => throw const BattleJobGatewayException(
      code: 'battle_transport_unavailable',
      message: 'Não foi possível atualizar o Battle agora.',
    ),
    _ProofState.timeout => session.apply(
      _page(
        status: 'timeout',
        terminalReason: 'battle_job_timeout',
        nextCursor: 'blc1.timeout.signature',
      ),
    ),
    _ProofState.completed => session.apply(
      _page(
        status: 'completed',
        terminalReason: 'completed',
        items: [
          _eventRecord(
            sequence: 1,
            recordId: 'event-spell-1',
            message: 'Alice conjurou Sol Ring.',
          ),
          _snapshotRecord(sequence: 2, recordId: 'snapshot-main-2'),
        ],
        nextCursor: 'blc1.completed.signature',
        replay: const <String, Object>{
          'replay_id': 'replay-proof-1',
          'available': true,
        },
      ),
    ),
  };
}

BattleJob _job({
  String status = 'running',
  String stage = 'running',
  String? replayId,
  String? terminalReason,
  String? errorCode,
}) {
  final terminal = const <String>{
    'completed',
    'censored',
    'timeout',
    'coverage_error',
    'engine_error',
    'cancelled',
    'persistence_error',
  }.contains(status);
  const createdAt = '2099-01-01T00:00:00Z';
  const activeUpdatedAt = '2099-01-01T00:00:04Z';
  const finishedAt = '2099-01-01T00:01:10Z';
  final current = terminal ? 100 : 15;
  return BattleJob.fromJson(<String, dynamic>{
    'schema_version': battleJobSchemaVersion,
    'job_id': 'job-proof-1',
    'idempotency_key': 'proof-attempt-1',
    'status': status,
    'stage': stage,
    'progress': <String, Object>{
      'current': current,
      'total': 100,
      'ratio': current / 100,
    },
    'deck_a_id': 'deck-proof-a',
    'deck_b_id': 'deck-proof-b',
    'deck_hashes': <String, Object>{
      'schema_version': externalBattleDeckHashSchemaVersion,
      'algorithm': 'sha256',
      'deck_a': _hash('a'),
      'deck_b': _hash('b'),
    },
    'request_schema_version': battleJobRequestSchemaVersion,
    'request_hash': _hash('c'),
    'requested_engine': 'auto',
    'engine': null,
    'timeout_ms': battleJobDefaultTimeoutMs,
    'attempt_count': 1,
    'attempt_id': 'proof-attempt-run-1',
    if (replayId != null) 'replay_id': replayId,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    if (errorCode != null) 'error_code': errorCode,
    'started_at': createdAt,
    'heartbeat_at': activeUpdatedAt,
    'created_at': createdAt,
    'updated_at': terminal ? finishedAt : activeUpdatedAt,
    if (terminal) 'finished_at': finishedAt,
    'can_cancel': !terminal,
    'can_resume': !terminal,
    'poll_url': '/ai/battle/jobs/job-proof-1',
    'cancel_url': '/ai/battle/jobs/job-proof-1',
  });
}

BattleLivePage _page({
  required String status,
  String? terminalReason,
  List<Map<String, dynamic>> items = const <Map<String, dynamic>>[],
  required String nextCursor,
  Map<String, Object>? replay,
}) {
  final terminal = const <String>{
    'completed',
    'censored',
    'timeout',
    'coverage_error',
    'engine_error',
    'cancelled',
    'persistence_error',
    'interrupted',
  }.contains(status);
  return BattleLivePage.fromJson(<String, dynamic>{
    'schema_version': battleLiveCursorSchemaVersion,
    'transport': battleLivePollingTransport,
    'stream_id': 'job-proof-1',
    'status': status,
    'is_terminal': terminal,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    'items': items,
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': false,
    'truncated': false,
    'truncation': const <String, bool>{
      'source': false,
      'page_limit': false,
      'payload_limit': false,
      'field_limit': false,
    },
    'limits': const <String, int>{'page': 50, 'payload_bytes': 131072},
    'replay_pending': false,
    'replay_already_delivered': false,
    if (replay != null) 'replay': replay,
  });
}

Map<String, dynamic> _eventRecord({
  required int sequence,
  required String recordId,
  required String message,
}) => <String, dynamic>{
  'schema_version': battleLiveCursorSchemaVersion,
  'cursor': 'blc1.event$sequence.signature',
  'sequence': sequence,
  'record_id': recordId,
  'kind': 'event',
  'event': <String, Object>{
    'event_type': 'spell_cast',
    'event_id': recordId,
    'turn': 2,
    'actor_side': 'deck_a',
    'subject_deck_key': 'deck_a',
    'card_name': 'Sol Ring',
    'message': message,
  },
  'content_truncated': false,
};

Map<String, dynamic> _snapshotRecord({
  required int sequence,
  required String recordId,
}) => <String, dynamic>{
  'schema_version': battleLiveCursorSchemaVersion,
  'cursor': 'blc1.snapshot$sequence.signature',
  'sequence': sequence,
  'record_id': recordId,
  'kind': 'snapshot',
  'snapshot': <String, Object>{
    'snapshot_id': recordId,
    'index': sequence,
    'turn': 2,
    'phase': 'main',
    'step': 'precombat',
    'players': <Map<String, Object>>[
      <String, Object>{
        'deck_key': 'deck_a',
        'name': 'Alice',
        'life': 40,
        'hand_size': 6,
        'library_size': 91,
        'battlefield_count': 2,
        'graveyard_size': 0,
        'mana_available': 1,
      },
      <String, Object>{
        'deck_key': 'deck_b',
        'name': 'Bob',
        'life': 38,
        'hand_size': 7,
        'library_size': 92,
        'battlefield_count': 1,
        'graveyard_size': 1,
        'mana_available': 0,
      },
    ],
    'stack': const <Object>[],
    'combat': const <Object>[],
  },
  'content_truncated': false,
};

String _hash(String character) => List<String>.filled(64, character).join();
