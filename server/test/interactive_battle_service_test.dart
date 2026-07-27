import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:server/battle/interactive_battle_service.dart';
import 'package:server/battle/interactive_battle_store.dart';
import 'package:test/test.dart';

void main() {
  test(
    'create persists attempt before opening one correlated runtime',
    () async {
      final store = _Store();
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      final result = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-service-1',
        ),
      );

      expect(result.created, isTrue);
      expect(result.session.status, InteractiveBattleStatus.waitingForAction);
      expect(result.session.attemptId, _attemptId);
      expect(runtime.createdRequests, hasLength(1));
      expect(
        runtime.createdRequests.single['request_hash'],
        result.session.requestHash,
      );
      expect(persistence.started, 1);
      expect(store.attachedAttemptId, _attemptId);
    },
  );

  test(
    'runtime hash divergence terminalizes fail closed and finishes attempt',
    () async {
      final store = _Store();
      final runtime = _Runtime(corruptRequestHash: true);
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      final result = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-service-corrupt',
        ),
      );

      expect(result.session.status, InteractiveBattleStatus.engineError);
      expect(
        result.session.errorCode,
        'interactive_battle_runtime_correlation_rejected',
      );
      expect(persistence.finishedStatuses, [
        InteractiveBattleStatus.engineError,
      ]);
    },
  );

  test(
    'attempt is closed when durable session attachment fails during start',
    () async {
      final store = _Store(failAttemptAttachment: true);
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      await expectLater(
        service.create(
          userId: _userId,
          input: const InteractiveBattleCreateInput(
            deckId: _deckAId,
            opponentDeckId: _deckBId,
            ttlSeconds: 600,
            promptTimeoutSeconds: 60,
            idempotencyKey: 'create-service-attach-failure',
          ),
        ),
        throwsA(
          isA<InteractiveBattleStartException>().having(
            (error) => error.session.status,
            'session status',
            InteractiveBattleStatus.persistenceError,
          ),
        ),
      );

      expect(runtime.createdRequests, isEmpty);
      expect(persistence.started, 1);
      expect(persistence.finishedStatuses, [
        InteractiveBattleStatus.persistenceError,
      ]);
    },
  );
}

InteractiveBattleService _service({
  required _Store store,
  required _Runtime runtime,
  required _Persistence persistence,
}) => InteractiveBattleService(
  configuration: const InteractiveBattleConfiguration(
    enabled: true,
    baseUrl: 'http://interactive-xmage:8080',
    identity: ExternalBattleEngineIdentity(
      engine: 'xmage',
      version: pinnedXmageVersion,
      commit: pinnedXmageCommit,
      aiProfile: 'computer_mad',
      telemetryField: 'normalizer_version',
      telemetryVersion: 'xmage_replay_normalizer_v2',
      seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
      deterministic: false,
    ),
    maximumActivePerUser: 1,
    maximumActiveGlobal: 4,
  ),
  store: store,
  deckStore: _DeckStore(),
  runtime: runtime,
  persistence: persistence,
);

class _DeckStore implements BattleJobStoreApi {
  @override
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async =>
      deckId == _deckAId
          ? _deckA
          : deckId == _deckBId
          ? _deckB
          : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runtime implements InteractiveBattleRuntime {
  _Runtime({this.corruptRequestHash = false});

  final bool corruptRequestHash;
  final List<Map<String, dynamic>> createdRequests = [];

  @override
  Future<InteractiveBattleRuntimeSnapshot> create(
    Map<String, dynamic> request,
  ) async {
    createdRequests.add(Map<String, dynamic>.from(request));
    return _snapshot(
      requestId: request['request_id'] as String,
      requestHash:
          corruptRequestHash ? 'f' * 64 : request['request_hash'] as String,
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Persistence implements InteractiveBattlePersistence {
  int started = 0;
  final List<InteractiveBattleStatus> finishedStatuses = [];

  @override
  Future<String> startAttempt({
    required String userId,
    required String deckAId,
    required String deckBId,
    required String requestId,
    required String requestHash,
    required String deckAHash,
    required String deckBHash,
    required int timeoutMs,
  }) async {
    started += 1;
    return _attemptId;
  }

  @override
  Future<void> finishAttempt({
    required String attemptId,
    required String userId,
    required InteractiveBattleStatus status,
    required Map<String, dynamic> result,
    String? replayId,
    String? reason,
    String? errorCode,
  }) async {
    finishedStatuses.add(status);
  }

  @override
  Future<String> persistReplay({
    required String deckAId,
    required String deckBId,
    required Map<String, dynamic> replay,
  }) async => _replayId;
}

class _Store implements InteractiveBattleStoreApi {
  _Store({this.failAttemptAttachment = false});

  final bool failAttemptAttachment;
  InteractiveBattleSession? current;
  String? attachedAttemptId;

  @override
  Future<InteractiveBattleCreateResult> create(
    InteractiveBattleCreateCommand command, {
    required int perUserActiveLimit,
    required int globalActiveLimit,
  }) async {
    current = _session(
      id: command.id,
      requestHash: command.requestHash,
      status: InteractiveBattleStatus.starting,
    );
    return InteractiveBattleCreateResult(session: current!, created: true);
  }

  @override
  Future<InteractiveBattleSession> attachAttempt({
    required String userId,
    required String id,
    required String attemptId,
  }) async {
    if (failAttemptAttachment) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_attempt_attach_failed',
      );
    }
    attachedAttemptId = attemptId;
    current = _copy(current!, attemptId: attemptId);
    return current!;
  }

  @override
  Future<InteractiveBattleSession> applyRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
    String? attemptId,
    String? replayId,
  }) async {
    current = _copy(
      current!,
      status: snapshot.status,
      stateVersion: snapshot.stateVersion,
      prompt: snapshot.prompt,
      privateState: snapshot.privateState,
      runtimeSessionId: snapshot.runtimeSessionId,
      attemptId: attemptId,
      replayId: replayId,
    );
    return current!;
  }

  @override
  Future<InteractiveBattleSession> terminalize({
    required String userId,
    required String id,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  }) async {
    current = _copy(
      current!,
      status: status,
      terminalReason: reason,
      errorCode: errorCode,
    );
    return current!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InteractiveBattleSession _session({
  required String id,
  required String requestHash,
  required InteractiveBattleStatus status,
}) {
  final now = DateTime.parse('2026-07-27T12:00:00Z');
  return InteractiveBattleSession(
    id: id,
    userId: _userId,
    status: status,
    stateVersion: 0,
    deckAId: _deckAId,
    deckBId: _deckBId,
    deckAHash: _deckAHash,
    deckBHash: _deckBHash,
    requestHash: requestHash,
    ttlSeconds: 600,
    expiresAt: now.add(const Duration(minutes: 10)),
    lastActivityAt: now,
    createdAt: now,
    updatedAt: now,
    privateState: const {},
  );
}

InteractiveBattleSession _copy(
  InteractiveBattleSession source, {
  InteractiveBattleStatus? status,
  int? stateVersion,
  InteractiveBattlePrompt? prompt,
  Map<String, dynamic>? privateState,
  String? runtimeSessionId,
  String? attemptId,
  String? replayId,
  String? terminalReason,
  String? errorCode,
}) => InteractiveBattleSession(
  id: source.id,
  userId: source.userId,
  status: status ?? source.status,
  stateVersion: stateVersion ?? source.stateVersion,
  deckAId: source.deckAId,
  deckBId: source.deckBId,
  deckAHash: source.deckAHash,
  deckBHash: source.deckBHash,
  requestHash: source.requestHash,
  ttlSeconds: source.ttlSeconds,
  expiresAt: source.expiresAt,
  lastActivityAt: source.lastActivityAt,
  createdAt: source.createdAt,
  updatedAt: source.updatedAt,
  privateState: privateState ?? source.privateState,
  prompt: prompt ?? source.prompt,
  engineVersion: source.engineVersion,
  engineCommit: source.engineCommit,
  engineBuild: source.engineBuild,
  engineProcessId: source.engineProcessId,
  engineProcessStartedAt: source.engineProcessStartedAt,
  runtimeSessionId: runtimeSessionId ?? source.runtimeSessionId,
  attemptId: attemptId ?? source.attemptId,
  replayId: replayId ?? source.replayId,
  terminalReason: terminalReason ?? source.terminalReason,
  errorCode: errorCode ?? source.errorCode,
  startedAt: source.startedAt,
  finishedAt: status?.isTerminal == true ? DateTime.now().toUtc() : null,
);

InteractiveBattleRuntimeSnapshot _snapshot({
  required String requestId,
  required String requestHash,
}) => InteractiveBattleRuntimeSnapshot(
  runtimeSessionId: 'ibsrt_abcdefghijklmnop',
  requestId: requestId,
  requestHash: requestHash,
  status: InteractiveBattleStatus.waitingForAction,
  stateVersion: 4,
  privateState: const {
    'schema_version': interactiveBattlePrivateStateSchema,
    'own_hand': [],
    'players': [],
  },
  prompt: InteractiveBattlePrompt(
    id: 'p_abcdefghijklmnop',
    stateVersion: 4,
    kind: 'mulligan',
    inputMode: 'options',
    title: 'Mulligan',
    message: 'Manter?',
    deadlineAt: DateTime.parse('2026-07-27T12:01:00Z'),
    options: const [
      InteractiveBattlePromptOption(
        id: 'o_abcdefghijklmnop',
        label: 'Manter',
        role: 'keep',
      ),
    ],
  ),
  engineVersion: pinnedXmageVersion,
  engineCommit: pinnedXmageCommit,
  engineBuild: 'xmage-sidecar-v2@$pinnedXmageCommit',
  engineProcessId: 'process-1',
  engineProcessStartedAt: DateTime.parse('2026-07-27T11:59:00Z'),
  lastActivityAt: DateTime.parse('2026-07-27T12:00:01Z'),
);

const _deckA = BattleJobDeckSnapshot(
  id: _deckAId,
  name: 'Deck A',
  cards: [
    {'name': 'Isamaru', 'quantity': 1, 'is_commander': true},
    {'name': 'Plains', 'quantity': 99, 'is_commander': false},
  ],
  hash: _deckAHash,
);
const _deckB = BattleJobDeckSnapshot(
  id: _deckBId,
  name: 'Deck B',
  cards: [
    {'name': 'Krenko', 'quantity': 1, 'is_commander': true},
    {'name': 'Mountain', 'quantity': 99, 'is_commander': false},
  ],
  hash: _deckBHash,
);
const _userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _deckAId = '11111111-1111-4111-8111-111111111111';
const _deckBId = '22222222-2222-4222-8222-222222222222';
const _attemptId = '33333333-3333-4333-8333-333333333333';
const _replayId = '44444444-4444-4444-8444-444444444444';
const _deckAHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _deckBHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
