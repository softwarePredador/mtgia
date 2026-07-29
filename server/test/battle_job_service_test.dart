import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_service.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:test/test.dart';

const _userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _deckAId = '11111111-1111-4111-8111-111111111111';
const _deckBId = '22222222-2222-4222-8222-222222222222';

void main() {
  test(
    'freezes owner/public decks and sends deterministic job evidence',
    () async {
      final store = _FakeStore(
        snapshots: {
          _deckAId: _commanderDeck(_deckAId, hash: 'a' * 64),
          _deckBId: _commanderDeck(_deckBId, hash: 'b' * 64),
        },
      );
      const quota = BattleJobQuotaPolicy(
        perUserActiveLimit: 2,
        globalActiveLimit: 8,
      );
      final service = BattleJobService(store, quotaPolicy: quota);
      final input = BattleJobCreateInput.parse({
        'deck_id': _deckAId,
        'opponent_deck_id': _deckBId,
        'engine': 'native',
        'seed': 77,
        'idempotency_key': 'stable-request',
      });

      await service.create(userId: _userId, input: input);
      await service.create(userId: _userId, input: input);

      expect(store.loads, [
        '$_userId:$_deckAId:false',
        '$_userId:$_deckBId:true',
        '$_userId:$_deckAId:false',
        '$_userId:$_deckBId:true',
      ]);
      expect(store.quotas, everyElement(same(quota)));
      expect(store.commands, hasLength(2));
      final first = store.commands.first;
      final second = store.commands.last;
      expect(first.idempotencyKey, 'stable-request');
      expect(first.requestedEngine, 'native');
      expect(first.engineLane, 'native');
      expect(first.requestPayload['seed'], 77);
      expect(first.requestPayload['deck_a'], first.deckA.payload);
      expect(first.requestPayload['deck_b'], first.deckB.payload);
      expect(first.requestPayload['request_hash'], first.requestHash);
      expect(
        first.requestPayload['request_schema_version'],
        battleJobRequestSchema,
      );
      expect(
        first.requestPayload['request_id'],
        matches(RegExp(r'^battle-job-[A-Za-z0-9_-]{36}$')),
      );
      expect(first.requestPayload['request_id'], isNot(contains(':')));
      expect(
        canonicalBattleJobRequestHash(first.requestPayload),
        first.requestHash,
      );
      expect(first.requestFingerprint, second.requestFingerprint);
    },
  );

  test('rejects decks that are not exactly Commander 100/1', () async {
    final invalid = BattleJobDeckSnapshot(
      id: _deckAId,
      name: 'Invalid',
      format: 'commander',
      validationState: 'validated',
      validationReasons: const [],
      cards: const [
        {'name': 'Commander', 'quantity': 1, 'is_commander': true},
        {'name': 'Main', 'quantity': 98, 'is_commander': false},
      ],
      hash: 'a' * 64,
    );
    final store = _FakeStore(
      snapshots: {
        _deckAId: invalid,
        _deckBId: _commanderDeck(_deckBId, hash: 'b' * 64),
      },
    );
    final service = BattleJobService(store);
    final input = BattleJobCreateInput.parse({
      'deck_id': _deckAId,
      'opponent_deck_id': _deckBId,
    });

    await expectLater(
      service.create(userId: _userId, input: input),
      throwsA(
        isA<BattleJobValidationException>().having(
          (error) => error.code,
          'code',
          'battle_job_deck_invalid',
        ),
      ),
    );
    expect(store.commands, isEmpty);
  });

  test(
    'rejects direct jobs for decks not validated by the product gate',
    () async {
      final store = _FakeStore(
        snapshots: {
          _deckAId: _commanderDeck(
            _deckAId,
            hash: 'a' * 64,
            validationState: 'unknown',
          ),
          _deckBId: _commanderDeck(_deckBId, hash: 'b' * 64),
        },
      );
      final input = BattleJobCreateInput.parse({
        'deck_id': _deckAId,
        'opponent_deck_id': _deckBId,
      });

      await expectLater(
        BattleJobService(store).create(userId: _userId, input: input),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'battle_job_deck_validation_required',
          ),
        ),
      );
      expect(store.commands, isEmpty);
    },
  );

  test('fails closed when either scoped deck is unavailable', () async {
    final service = BattleJobService(_FakeStore(snapshots: const {}));
    final input = BattleJobCreateInput.parse({
      'deck_id': _deckAId,
      'opponent_deck_id': _deckBId,
    });

    await expectLater(
      service.create(userId: _userId, input: input),
      throwsA(isA<BattleJobNotFoundException>()),
    );
  });
}

class _FakeStore implements BattleJobStoreApi {
  _FakeStore({required this.snapshots});

  final Map<String, BattleJobDeckSnapshot> snapshots;
  final List<String> loads = [];
  final List<BattleJobCreateCommand> commands = [];
  final List<BattleJobQuotaPolicy> quotas = [];

  @override
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async {
    loads.add('$userId:$deckId:$allowPublic');
    return snapshots[deckId];
  }

  @override
  Future<BattleJobCreateResult> create(
    BattleJobCreateCommand command, {
    required BattleJobQuotaPolicy quota,
  }) async {
    commands.add(command);
    quotas.add(quota);
    return BattleJobCreateResult(job: _jobFromCommand(command), created: true);
  }

  @override
  Future<BattleJob?> get(String userId, String id) async => null;

  @override
  Future<List<BattleJob>> list(
    String userId, {
    BattleJobListFilter filter = const BattleJobListFilter(),
  }) async => const [];

  @override
  Future<BattleJobCancelResult?> cancel(String userId, String id) async => null;
}

BattleJobDeckSnapshot _commanderDeck(
  String id, {
  required String hash,
  String validationState = 'validated',
}) {
  return BattleJobDeckSnapshot(
    id: id,
    name: 'Deck $id',
    format: 'commander',
    validationState: validationState,
    validationReasons:
        validationState == 'validated'
            ? const []
            : const ['validation_not_recorded'],
    cards: const [
      {'name': 'Commander', 'quantity': 1, 'is_commander': true},
      {'name': 'Main cards', 'quantity': 99, 'is_commander': false},
    ],
    hash: hash,
  );
}

BattleJob _jobFromCommand(BattleJobCreateCommand command) {
  final now = DateTime.utc(2026, 7, 26);
  return BattleJob(
    id: command.id,
    userId: command.userId,
    status: BattleJobStatus.queued,
    stage: 'queued',
    progressCurrent: 0,
    progressTotal: 100,
    deckAId: command.deckA.id,
    deckBId: command.deckB.id,
    deckHashSchema: 'external_battle_deck_hash_v1',
    deckAHash: command.deckA.hash,
    deckBHash: command.deckB.hash,
    requestSchemaVersion: battleJobRequestSchema,
    requestHash: command.requestHash,
    requestPayload: command.requestPayload,
    requestedEngine: command.requestedEngine,
    engineLane: command.engineLane,
    timeoutMs: command.timeoutMs,
    attemptCount: 0,
    idempotencyKey: command.idempotencyKey,
    requestFingerprint: command.requestFingerprint,
    createdAt: now,
    updatedAt: now,
  );
}
