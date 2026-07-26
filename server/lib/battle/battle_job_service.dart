import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../ai/battle_engine_config.dart';
import 'battle_job_contract.dart';
import 'battle_request_correlation.dart';
import 'battle_job_store.dart';

class BattleJobService {
  const BattleJobService(
    this._store, {
    this.quotaPolicy = const BattleJobQuotaPolicy(),
  });

  final BattleJobStoreApi _store;
  final BattleJobQuotaPolicy quotaPolicy;

  Future<BattleJobCreateResult> create({
    required String userId,
    required BattleJobCreateInput input,
  }) async {
    final deckA = await _store.loadDeckSnapshot(
      userId: userId,
      deckId: input.deckId,
      allowPublic: false,
    );
    if (deckA == null) throw const BattleJobNotFoundException();
    final deckB = await _store.loadDeckSnapshot(
      userId: userId,
      deckId: input.opponentDeckId,
      allowPublic: true,
    );
    if (deckB == null) throw const BattleJobNotFoundException();
    _validateCommanderDeck(deckA, field: 'deck_id');
    _validateCommanderDeck(deckB, field: 'opponent_deck_id');

    final jobId = generateBattleJobUuid();
    final idempotencyKey = input.idempotencyKey ?? 'battle:$jobId';
    final seed = input.seed ?? _stableSeed(userId: userId, key: idempotencyKey);
    final requestPayload = <String, dynamic>{
      'request_schema_version': battleJobRequestSchema,
      // XMage's strict request correlation contract only permits
      // [A-Za-z0-9_-]{1,80}; keep this ID valid before any engine is selected.
      'request_id': 'battle-job-$jobId',
      'seed': seed,
      'timeout_ms': input.timeoutMs,
      'max_turns': input.maxTurns,
      'test_objective': input.testObjective,
      'focus_cards': input.focusCards,
      'force_focus_access_mode': input.forceFocusAccessMode,
      'same_lane': input.sameLane,
      'natural_sample': input.naturalSample,
      'requested_engine': input.requestedEngine,
      'deck_a': deckA.payload,
      'deck_b': deckB.payload,
      'deck_hashes': {
        'schema_version': externalBattleDeckHashSchema,
        'algorithm': 'sha256',
        'deck_a': deckA.hash,
        'deck_b': deckB.hash,
      },
    };
    final requestHash = canonicalBattleJobRequestHash(requestPayload);
    requestPayload['request_hash'] = requestHash;
    final requestFingerprint = _requestFingerprint(
      input: input,
      deckAHash: deckA.hash,
      deckBHash: deckB.hash,
      seed: seed,
    );

    return _store.create(
      BattleJobCreateCommand(
        id: jobId,
        userId: userId,
        deckA: deckA,
        deckB: deckB,
        idempotencyKey: idempotencyKey,
        requestFingerprint: requestFingerprint,
        requestHash: requestHash,
        requestPayload: requestPayload,
        requestedEngine: input.requestedEngine,
        engineLane: battleJobEngineLane(input.requestedEngine),
        timeoutMs: input.timeoutMs,
      ),
      quota: quotaPolicy,
    );
  }

  Future<List<BattleJob>> list(
    String userId, {
    BattleJobListFilter filter = const BattleJobListFilter(),
  }) => _store.list(userId, filter: filter);

  Future<BattleJob> get(String userId, String id) async {
    final job = await _store.get(userId, id);
    if (job == null) throw const BattleJobNotFoundException();
    return job;
  }

  Future<BattleJobCancelResult> cancel(String userId, String id) async {
    final result = await _store.cancel(userId, id);
    if (result == null) throw const BattleJobNotFoundException();
    return result;
  }
}

BattleJobListFilter parseBattleJobListFilter(Map<String, String> query) {
  const allowed = <String>{'limit', 'status', 'deck_id'};
  if (query.keys.any((key) => !allowed.contains(key))) {
    throw const BattleJobValidationException(
      'battle_job_list_query_invalid',
      'The Battle job list query contains an unsupported parameter.',
    );
  }
  final rawLimit = query['limit'];
  final limit = rawLimit == null ? 50 : int.tryParse(rawLimit);
  if (limit == null || limit < 1 || limit > 100) {
    throw const BattleJobValidationException(
      'battle_job_list_limit_invalid',
      'limit must be between 1 and 100.',
    );
  }

  BattleJobStatus? status;
  final rawStatus = query['status']?.trim();
  if (rawStatus != null && rawStatus.isNotEmpty) {
    for (final candidate in BattleJobStatus.values) {
      if (candidate.value == rawStatus) {
        status = candidate;
        break;
      }
    }
    if (status == null) {
      throw const BattleJobValidationException(
        'battle_job_list_status_invalid',
        'status is not part of battle_job_v1.',
      );
    }
  }

  final deckId = query['deck_id']?.trim();
  if (deckId != null &&
      (deckId.isEmpty || !battleJobUuidPattern.hasMatch(deckId))) {
    throw const BattleJobValidationException(
      'battle_job_list_deck_id_invalid',
      'deck_id must be a valid UUID.',
    );
  }
  return BattleJobListFilter(
    limit: limit,
    status: status,
    deckId: deckId?.toLowerCase(),
  );
}

void _validateCommanderDeck(
  BattleJobDeckSnapshot deck, {
  required String field,
}) {
  var cardCount = 0;
  var commanderCount = 0;
  for (final card in deck.cards) {
    final quantity = card['quantity'];
    if (quantity is! int || quantity < 1) {
      throw BattleJobValidationException(
        'battle_job_deck_invalid',
        '$field contains an invalid card quantity.',
      );
    }
    cardCount += quantity;
    if (card['is_commander'] == true) commanderCount += quantity;
  }
  if (cardCount != 100 || commanderCount != 1) {
    throw BattleJobValidationException(
      'battle_job_deck_invalid',
      '$field must contain exactly 100 cards and one commander.',
    );
  }
}

int _stableSeed({required String userId, required String key}) {
  final digest = sha256.convert(utf8.encode('$userId\n$key\n')).bytes;
  final value =
      (digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3];
  return value & 0x7fffffff;
}

String _requestFingerprint({
  required BattleJobCreateInput input,
  required String deckAHash,
  required String deckBHash,
  required int seed,
}) {
  final material = <String>[
    battleJobSchemaVersion,
    'deck_a=$deckAHash',
    'deck_b=$deckBHash',
    'engine=${input.requestedEngine}',
    'timeout_ms=${input.timeoutMs}',
    'max_turns=${input.maxTurns}',
    'seed=$seed',
    'test_objective=${input.testObjective}',
    'focus_cards=${input.focusCards.map(_encoded).join(',')}',
    'force_focus_access_mode=${input.forceFocusAccessMode}',
    'same_lane=${input.sameLane ? 1 : 0}',
    'natural_sample=${input.naturalSample ? 1 : 0}',
  ].join('\n');
  return sha256.convert(utf8.encode('$material\n')).toString();
}

String _encoded(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');
