import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_live_cursor.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_live_spectator_screen.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeBattleJobGateway extends BattleJobGateway {
  _FakeBattleJobGateway({
    required BattleJob job,
    List<BattleJob> jobResponses = const [],
    List<Object> liveResponses = const [],
    BattleJobCancellation? cancellation,
    List<BattleJob>? listedJobs,
    BattleJobCreation? creation,
  }) : _job = job,
       _jobResponses = List<BattleJob>.from(jobResponses),
       _liveResponses = List<Object>.from(liveResponses),
       _cancellation = cancellation,
       _listedJobs = listedJobs ?? const [],
       _creation = creation;

  BattleJob _job;
  final List<BattleJob> _jobResponses;
  final List<Object> _liveResponses;
  final BattleJobCancellation? _cancellation;
  final List<BattleJob> _listedJobs;
  final BattleJobCreation? _creation;
  final List<BattleLiveSession> pollInputs = [];
  int getCalls = 0;
  int pollCalls = 0;
  int cancelCalls = 0;
  int listCalls = 0;
  int createCalls = 0;
  BattleJobCreateRequest? lastCreateRequest;

  @override
  Future<List<BattleJob>> list({
    int limit = 20,
    BattleJobStatus? status,
    String? deckId,
  }) async {
    listCalls += 1;
    return _listedJobs;
  }

  @override
  Future<BattleJobCreation> create(BattleJobCreateRequest request) async {
    createCalls += 1;
    lastCreateRequest = request;
    final result = _creation;
    if (result == null) throw StateError('Creation response not configured');
    return result;
  }

  @override
  Future<BattleJob> get(String jobId) async {
    getCalls += 1;
    if (_jobResponses.isNotEmpty) {
      _job = _jobResponses.removeAt(0);
    }
    return _job;
  }

  @override
  Future<BattleLiveSession> pollLive({
    required String jobId,
    BattleLiveSession session = const BattleLiveSession.empty(),
    int limit = 50,
  }) async {
    pollCalls += 1;
    pollInputs.add(session);
    if (_liveResponses.isEmpty) return session;
    final response = _liveResponses.removeAt(0);
    if (response is BattleJobGatewayException) throw response;
    return session.apply(response as BattleLivePage);
  }

  @override
  Future<BattleJobCancellation> cancel(String jobId) async {
    cancelCalls += 1;
    final result = _cancellation;
    if (result == null) {
      throw StateError('Cancellation response not configured');
    }
    _job = result.job;
    return result;
  }
}

class _BattleReplayGatewayStub extends BattleReplayGateway {
  @override
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async {
    return const [
      BattleOpponentDeck(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Mesa adversária',
        format: 'commander',
        source: BattleOpponentDeckSource.own,
        commanderName: 'Atraxa',
        cardCount: 100,
      ),
    ];
  }

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async =>
      const [];

  @override
  Future<BattleReplayPageResult> listReplayPage(
    String deckId, {
    String? cursor,
    int limit = 30,
  }) async {
    return const BattleReplayPageResult(
      items: [],
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('Battle live locations are canonical and URL-safe', () {
    expect(
      battleLiveRouteLocation('deck id/with slash', 'job id/with slash'),
      '/decks/deck%20id%2Fwith%20slash/battle-live/'
      'job%20id%2Fwith%20slash',
    );
    expect(
      battleReplayDetailRouteLocation('deck id', 'replay/id'),
      '/decks/deck%20id/battle-replays?replay=replay%2Fid',
    );
  });

  testWidgets('fails closed without contacting the jobs API', (tester) async {
    final gateway = _FakeBattleJobGateway(job: _job());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleLiveSpectatorScreen(
          deckId: 'deck-a',
          jobId: 'job-1',
          gateway: gateway,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('battle-live-disabled-state')), findsOneWidget);
    expect(
      find.text('Somente acompanhamento — você não controla a partida'),
      findsOneWidget,
    );
    expect(gateway.getCalls, 0);
    expect(gateway.pollCalls, 0);
  });

  testWidgets(
    'treats an early auto-engine 409 as transient and recovers live records',
    (tester) async {
      final waitingJob = _job(
        status: 'running',
        stage: 'running',
        current: 15,
        total: 100,
      );
      final liveJob = _job(
        status: 'running',
        stage: 'running',
        current: 20,
        total: 100,
        engine: 'xmage',
      );
      final gateway = _FakeBattleJobGateway(
        job: liveJob,
        jobResponses: [waitingJob, liveJob],
        liveResponses: [
          const BattleJobGatewayException(
            code: 'battle_job_conflict',
            message: 'Conflict',
            statusCode: 409,
          ),
          _page(
            items: [
              _eventRecord(
                sequence: 1,
                recordId: 'event-recovered',
                message: 'A partida começou.',
              ),
            ],
          ),
        ],
      );

      await _pumpLiveScreen(tester, gateway);

      expect(
        find.byKey(const Key('battle-live-visual-feed-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('battle-live-reconnect-banner')),
        findsNothing,
      );
      expect(find.textContaining('XMage'), findsNothing);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();

      expect(gateway.getCalls, greaterThanOrEqualTo(2));
      expect(gateway.pollCalls, 2);
      expect(
        find.byKey(const Key('battle-live-record-event-recovered')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-live-visual-feed-unavailable')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('shows unavailable feed only for a known unsupported engine', (
    tester,
  ) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(
        status: 'running',
        stage: 'running',
        current: 2,
        engine: 'forge',
      ),
    );

    await _pumpLiveScreen(tester, gateway);

    expect(
      find.byKey(const Key('battle-live-visual-feed-unavailable')),
      findsOneWidget,
    );
    expect(gateway.pollCalls, 0);
    expect(find.textContaining('XMage'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows honest indeterminate progress while the job is active', (
    tester,
  ) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(
        status: 'running',
        stage: 'starting_engine',
        current: 15,
        total: 100,
      ),
      liveResponses: [_page()],
    );

    await _pumpLiveScreen(tester, gateway);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('battle-live-progress')),
    );
    expect(indicator.value, isNull);
    expect(find.textContaining('15 de 100'), findsNothing);
    expect(find.textContaining('15 por cento'), findsNothing);
    expect(find.textContaining('Iniciando a simulação'), findsOneWidget);
    expect(find.textContaining('Tempo decorrido:'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('creates a live job from the single opponent simulation action', (
    tester,
  ) async {
    final queuedJob = _job();
    final jobGateway = _FakeBattleJobGateway(
      job: queuedJob,
      listedJobs: [queuedJob],
      creation: BattleJobCreation(job: queuedJob, created: true),
    );
    final replayGateway = _BattleReplayGatewayStub();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BattleReplaysScreen(
            deckId: 'deck-a',
            gateway: replayGateway,
            jobGateway: jobGateway,
            battleLiveEnabled: true,
          ),
        ),
        GoRoute(
          path: '/decks/:id/battle-live/:jobId',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Text(
                'Espectador aberto',
                key: Key('battle-live-route-target'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.darkTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-run-battle-button')), findsOneWidget);
    expect(find.byKey(const Key('battle-run-live-button')), findsNothing);
    expect(find.byKey(const Key('battle-live-job-job-1')), findsOneWidget);
    expect(jobGateway.listCalls, 1);

    await tester.tap(find.byKey(const Key('battle-run-battle-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('battle-opponent-deck-11111111-1111-4111-8111-111111111111'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pumpAndSettle();

    expect(jobGateway.createCalls, 1);
    expect(jobGateway.lastCreateRequest?.deckId, 'deck-a');
    expect(
      jobGateway.lastCreateRequest?.setup.opponentDeckId,
      '11111111-1111-4111-8111-111111111111',
    );
    expect(find.byKey(const Key('battle-live-route-target')), findsOneWidget);
  });

  testWidgets(
    'keeps polling while locally paused and resumes from cursor without duplicates',
    (tester) async {
      final firstEvent = _eventRecord(
        sequence: 1,
        recordId: 'event-1',
        message: 'Alice conjurou Sol Ring.',
      );
      final firstSnapshot = _snapshotRecord(
        sequence: 2,
        recordId: 'snapshot-2',
      );
      final gateway = _FakeBattleJobGateway(
        job: _job(status: 'running', stage: 'running', current: 2),
        liveResponses: [
          _page(
            items: [firstEvent, firstSnapshot],
            nextCursor: 'blc1.first.signature',
          ),
          _page(
            items: [
              Map<String, dynamic>.from(firstEvent),
              Map<String, dynamic>.from(firstSnapshot),
              _eventRecord(
                sequence: 3,
                recordId: 'event-3',
                message: 'Bob jogou Forest.',
              ),
            ],
            nextCursor: 'blc1.second.signature',
          ),
        ],
      );

      await _pumpLiveScreen(tester, gateway);
      expect(
        find.byKey(const Key('battle-live-record-event-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('battle-live-record-event-3')), findsNothing);

      await tester.tap(find.byKey(const Key('battle-live-pause-button')));
      await tester.pump();
      expect(find.text('Pausa local'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();

      expect(gateway.pollCalls, 2);
      expect(gateway.pollInputs.last.cursor, 'blc1.first.signature');
      expect(
        find.byKey(const Key('battle-live-record-event-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('battle-live-record-event-3')), findsNothing);
      expect(find.text('Ver 1 novo registro'), findsOneWidget);

      await tester.tap(find.byKey(const Key('battle-live-jump-latest-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('battle-live-record-event-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-live-record-event-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-live-record-event-1')),
        findsOneWidget,
        reason: 'the repeated cursor page must not duplicate event-1',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('preserves received state through offline retry', (tester) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(status: 'running', stage: 'running', current: 3),
      liveResponses: [
        _page(
          items: [
            _eventRecord(
              sequence: 1,
              recordId: 'event-1',
              message: 'Alice conjurou Sol Ring.',
            ),
          ],
          nextCursor: 'blc1.first.signature',
        ),
        const BattleJobGatewayException(
          code: 'battle_transport_unavailable',
          message: 'Não foi possível conectar ao Battle agora.',
        ),
        _page(
          items: [
            _eventRecord(
              sequence: 2,
              recordId: 'event-2',
              message: 'Bob perdeu 2 pontos de vida.',
            ),
          ],
          nextCursor: 'blc1.recovered.signature',
        ),
      ],
    );

    await _pumpLiveScreen(tester, gateway);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(
      find.byKey(const Key('battle-live-reconnect-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('battle-live-record-event-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('battle-live-inline-retry-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('battle-live-reconnect-banner')), findsNothing);
    expect(gateway.pollInputs.last.cursor, 'blc1.first.signature');
    expect(find.byKey(const Key('battle-live-record-event-1')), findsOneWidget);
    expect(find.byKey(const Key('battle-live-record-event-2')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('requires explicit confirmation before cancelling', (
    tester,
  ) async {
    final cancelledJob = _job(
      status: 'cancelled',
      stage: 'cancelled',
      current: 2,
      terminalReason: 'cancelled',
    );
    final gateway = _FakeBattleJobGateway(
      job: _job(status: 'running', stage: 'running', current: 2),
      liveResponses: [_page()],
      cancellation: BattleJobCancellation(job: cancelledJob, accepted: true),
    );

    await _pumpLiveScreen(tester, gateway);
    await tester.tap(find.byKey(const Key('battle-live-cancel-button')));
    await tester.pump();

    expect(gateway.cancelCalls, 0);
    expect(
      find.byKey(const Key('battle-live-cancel-confirmation')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('battle-live-confirm-cancel-button')),
    );
    await tester.pump();
    await tester.pump();

    expect(gateway.cancelCalls, 1);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.byKey(const Key('battle-live-terminal-state')), findsOneWidget);
  });

  testWidgets('opens the persisted replay from a terminal job', (tester) async {
    String? openedReplayId;
    final gateway = _FakeBattleJobGateway(
      job: _job(
        status: 'completed',
        stage: 'completed',
        current: 6,
        replayId: 'replay-1',
        terminalReason: 'completed',
      ),
      liveResponses: [
        _page(
          status: 'completed',
          terminal: true,
          terminalReason: 'completed',
          nextCursor: 'blc1.terminal.signature',
          replay: const {'replay_id': 'replay-1', 'available': true},
        ),
      ],
    );

    await _pumpLiveScreen(
      tester,
      gateway,
      onOpenReplay: (replayId) => openedReplayId = replayId,
    );

    expect(find.byKey(const Key('battle-live-terminal-state')), findsOneWidget);
    final replayButton = find.byKey(
      const Key('battle-live-open-replay-button'),
    );
    await tester.ensureVisible(replayButton);
    await tester.pump();
    await tester.tap(replayButton);
    await tester.pump();

    expect(openedReplayId, 'replay-1');
  });

  testWidgets('keeps polling while a completed replay is still pending', (
    tester,
  ) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(status: 'running', stage: 'running', current: 5),
      liveResponses: [
        _page(
          status: 'completed',
          terminal: true,
          terminalReason: 'completed',
          nextCursor: 'blc1.pending.signature',
          replayPending: true,
        ),
        _page(
          status: 'completed',
          terminal: true,
          terminalReason: 'completed',
          nextCursor: 'blc1.finished.signature',
          replay: const {'replay_id': 'replay-1', 'available': true},
        ),
      ],
    );

    await _pumpLiveScreen(tester, gateway);
    expect(find.byKey(const Key('battle-live-replay-pending')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(gateway.pollCalls, 2);
    expect(gateway.pollInputs.last.cursor, 'blc1.pending.signature');
    expect(
      find.byKey(const Key('battle-live-open-replay-button')),
      findsOneWidget,
    );
  });

  testWidgets('drains every final live page before stopping', (tester) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(status: 'running', stage: 'running', current: 5),
      liveResponses: [
        _page(
          status: 'completed',
          terminal: true,
          terminalReason: 'completed',
          items: [
            _eventRecord(
              sequence: 1,
              recordId: 'event-final-1',
              message: 'Primeiro registro final.',
            ),
          ],
          nextCursor: 'blc1.final-page-one.signature',
          hasMore: true,
        ),
        _page(
          status: 'completed',
          terminal: true,
          terminalReason: 'completed',
          items: [
            _eventRecord(
              sequence: 2,
              recordId: 'event-final-2',
              message: 'Último registro final.',
            ),
          ],
          nextCursor: 'blc1.final-page-two.signature',
          replay: const {'replay_id': 'replay-1', 'available': true},
        ),
      ],
    );

    await _pumpLiveScreen(tester, gateway);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(gateway.pollCalls, 2);
    expect(gateway.pollInputs.last.cursor, 'blc1.final-page-one.signature');
    expect(
      find.byKey(const Key('battle-live-record-event-final-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-live-record-event-final-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-live-open-replay-button')),
      findsOneWidget,
    );
  });

  testWidgets('explains timeout without exposing the engine provider', (
    tester,
  ) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(
        status: 'timeout',
        stage: 'timeout',
        current: 6,
        terminalReason: 'xmage_battle_operational_failure',
        errorCode: 'xmage_timeout',
      ),
      liveResponses: [
        _page(
          status: 'timeout',
          terminal: true,
          terminalReason: 'xmage_battle_operational_failure',
        ),
      ],
    );

    await _pumpLiveScreen(tester, gateway);

    expect(
      find.textContaining('atingiu o limite de tempo antes de concluir'),
      findsOneWidget,
    );
    expect(find.textContaining('XMage'), findsNothing);
    expect(
      find.byKey(const Key('battle-live-new-attempt-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-live-back-replays-button')),
      findsOneWidget,
    );
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('battle-live-progress')),
    );
    expect(indicator.value, 1);
  });

  testWidgets('explains an operational failure with provider-neutral copy', (
    tester,
  ) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(
        status: 'engine_error',
        stage: 'engine_error',
        current: 6,
        terminalReason: 'xmage_battle_operational_failure',
      ),
      liveResponses: [
        _page(
          status: 'engine_error',
          terminal: true,
          terminalReason: 'xmage_battle_operational_failure',
        ),
      ],
    );

    await _pumpLiveScreen(tester, gateway);

    expect(find.textContaining('falha temporária do motor'), findsOneWidget);
    expect(find.textContaining('XMage'), findsNothing);
  });

  testWidgets('supports keyboard pause and reduced motion', (tester) async {
    final gateway = _FakeBattleJobGateway(
      job: _job(status: 'running', stage: 'running', current: 2),
      liveResponses: [
        _page(items: [_snapshotRecord(sequence: 1, recordId: 'snapshot-1')]),
      ],
    );

    await _pumpLiveScreen(tester, gateway, disableAnimations: true);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text('Pausa local'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final viewport in <Size>[
    const Size(390, 1000),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1440, 1000),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'remains usable at ${viewport.width.toInt()}px with 200 percent text',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final gateway = _FakeBattleJobGateway(
          job: _job(
            status: 'completed',
            stage: 'completed',
            current: 6,
            replayId: 'replay-1',
            terminalReason: 'completed',
          ),
          liveResponses: [
            _page(
              status: 'completed',
              terminal: true,
              terminalReason: 'completed',
              items: [
                _eventRecord(
                  sequence: 1,
                  recordId: 'event-1',
                  message: 'Alice conjurou Sol Ring.',
                ),
                _snapshotRecord(sequence: 2, recordId: 'snapshot-2'),
              ],
              nextCursor: 'blc1.terminal.signature',
              replay: const {'replay_id': 'replay-1', 'available': true},
            ),
          ],
        );

        await _pumpLiveScreen(
          tester,
          gateway,
          textScaler: const TextScaler.linear(2),
        );

        expect(find.byKey(const Key('battle-live-screen')), findsOneWidget);
        expect(
          find.byKey(
            Key(
              viewport.width >= AppTheme.breakpointExpanded
                  ? 'battle-live-wide-workspace'
                  : 'battle-live-stacked-workspace',
            ),
          ),
          findsOneWidget,
        );
        if (viewport == const Size(844, 390)) {
          final terminalAction = find.byKey(
            const Key('battle-live-terminal-state'),
          );
          final openReplay = find.byKey(
            const Key('battle-live-open-replay-button'),
          );
          expect(terminalAction, findsOneWidget);
          expect(openReplay, findsOneWidget);
          await tester.ensureVisible(openReplay);
          await tester.pump();
          expect(openReplay.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpLiveScreen(
  WidgetTester tester,
  _FakeBattleJobGateway gateway, {
  ValueChanged<String>? onOpenReplay,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        child: BattleLiveSpectatorScreen(
          deckId: 'deck-a',
          jobId: 'job-1',
          gateway: gateway,
          featureEnabled: true,
          pollInterval: const Duration(milliseconds: 100),
          onOpenReplay: onOpenReplay,
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
  int total = 6,
  String? engine,
  String? replayId,
  String? terminalReason,
  String? errorCode,
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
    'progress': {'current': current, 'total': total, 'ratio': current / total},
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
    'engine': engine,
    'timeout_ms': 120000,
    'attempt_count': status == 'queued' ? 0 : 1,
    if (status != 'queued') 'attempt_id': 'attempt-run-1',
    if (replayId != null) 'replay_id': replayId,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    if (errorCode != null) 'error_code': errorCode,
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
  String status = 'running',
  bool terminal = false,
  String? terminalReason,
  List<Map<String, dynamic>> items = const [],
  String nextCursor = 'blc1.next.signature',
  Map<String, dynamic>? replay,
  bool replayPending = false,
  bool hasMore = false,
}) {
  return BattleLivePage.fromJson({
    'schema_version': 'battle_live_cursor_v1',
    'transport': 'polling_long_polling',
    'stream_id': 'job-1',
    'status': status,
    'is_terminal': terminal,
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

Map<String, dynamic> _snapshotRecord({
  required int sequence,
  required String recordId,
}) {
  return {
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.snapshot$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'snapshot',
    'snapshot': {
      'snapshot_id': recordId,
      'index': sequence,
      'turn': 1,
      'phase': 'main',
      'step': 'precombat',
      'players': [
        {
          'deck_key': 'deck_a',
          'name': 'Alice',
          'life': 40,
          'hand_size': 7,
          'library_size': 92,
          'battlefield_count': 1,
          'graveyard_size': 0,
          'mana_available': 1,
        },
        {
          'deck_key': 'deck_b',
          'name': 'Bob',
          'life': 40,
          'hand_size': 7,
          'library_size': 92,
          'battlefield_count': 1,
          'graveyard_size': 0,
          'mana_available': 0,
        },
      ],
      'stack': const [],
      'combat': const [],
    },
    'content_truncated': false,
  };
}

String _hash(String character) => List.filled(64, character).join();
