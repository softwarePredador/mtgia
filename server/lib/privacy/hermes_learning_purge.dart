import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'account_deletion_outbox.dart';

/// BT-PRIV-002: o consumidor `hermes_learning_sqlite` do outbox da exclusão
/// (D-68).
///
/// O knowledge.db do Hermes (imagem de ops, `HERMES_KNOWLEDGE_DB`) guarda ids
/// de deck do PostgreSQL em dois lugares: `user_learning_events`, escrito por
/// `server/bin/pull_learning_events.py`, e as cópias de deck que
/// `sync_pg_target_deck_to_hermes.py` grava. Na primeira linha vencida de uma
/// execução, o job faz a varredura:
///
/// 1. `hermes_learning_purge.py list` lê os ids que o arquivo guarda;
/// 2. o PostgreSQL diz quais deles são decks apagados. O HMAC do id, com cada
///    chave da `privacy_keyring`, precisa bater com um tombstone. A chave não
///    sai do banco;
/// 3. `hermes_learning_purge.py purge` apaga esses ids sob o lock de escrita
///    do SQLite. Depois, ainda sob o lock, lista de novo o que ficou;
/// 4. se o que ficou ainda tem deck apagado, repete, até
///    [HermesLearningPurge.maxRounds] vezes.
///
/// A varredura vale para todo deck apagado, não só para os da linha. Assim ela
/// também pega o que tenha sobrado de exclusões antigas. Depois, cada linha
/// confere que nenhum deck dela ficou no arquivo e fecha.
///
/// O alimentador pega o mesmo lock antes de conferir no PostgreSQL se o evento
/// ainda existe. Por isso, nada que ele grave depois da varredura é de deck
/// apagado.
const hermesLearningPurgeCode = 'purged_by_tombstone_sweep';

/// Não há knowledge.db no caminho configurado, mas a pasta existe: o Hermes
/// nunca guardou nada neste ambiente.
const hermesKnowledgeDbAbsentCode = 'hermes_knowledge_db_absent';

/// Caminho padrão do auxiliar, relativo a `server/` (onde o job roda).
const defaultHermesPurgeHelperScript = 'bin/hermes_learning_purge.py';

/// Onde está o knowledge.db e como chamar o auxiliar Python.
class HermesKnowledgeDbConfig {
  const HermesKnowledgeDbConfig({
    required this.path,
    this.pythonBin = 'python3',
    this.helperScript = defaultHermesPurgeHelperScript,
    this.helperTimeout = const Duration(minutes: 5),
  });

  /// Lê o ambiente do job. O `manaloom_ops_daemon.py` põe
  /// `HERMES_KNOWLEDGE_DB` em todo job.
  factory HermesKnowledgeDbConfig.fromEnvironment([
    Map<String, String>? environment,
  ]) {
    final env = environment ?? Platform.environment;
    String? value(String key) {
      final raw = env[key]?.trim();
      return raw == null || raw.isEmpty ? null : raw;
    }

    return HermesKnowledgeDbConfig(
      path: value('HERMES_KNOWLEDGE_DB') ?? value('MANALOOM_KNOWLEDGE_DB'),
      pythonBin: value('PYTHON_BIN') ?? 'python3',
      helperScript:
          value('MANALOOM_HERMES_PURGE_SCRIPT') ??
          defaultHermesPurgeHelperScript,
    );
  }

  /// `null`: o ambiente não diz onde está o knowledge.db.
  final String? path;
  final String pythonBin;
  final String helperScript;
  final Duration helperTimeout;
}

enum HermesPurgeStatus { ok, absent, busy, error }

/// Resposta de uma chamada ao auxiliar.
class HermesPurgeCall {
  const HermesPurgeCall(
    this.status, {
    this.deckIds = const [],
    this.counts = const {},
  });

  final HermesPurgeStatus status;

  /// `list`: os ids que o arquivo guarda. `purge`: os que ficaram, lidos sob o
  /// lock de escrita.
  final List<String> deckIds;

  /// `purge`: `events_deleted`, `decks_deleted`, `deck_cards_deleted`.
  final Map<String, int> counts;
}

/// Quem abre o SQLite. O padrão chama `hermes_learning_purge.py`; os testes
/// podem trocar.
abstract interface class HermesPurgeHelper {
  Future<HermesPurgeCall> list(String dbPath);
  Future<HermesPurgeCall> purge(String dbPath, List<String> deckIds);
}

class ProcessHermesPurgeHelper implements HermesPurgeHelper {
  const ProcessHermesPurgeHelper(this.config);

  final HermesKnowledgeDbConfig config;

  @override
  Future<HermesPurgeCall> list(String dbPath) => _run('list', dbPath);

  @override
  Future<HermesPurgeCall> purge(String dbPath, List<String> deckIds) =>
      _run('purge', dbPath, input: jsonEncode({'deck_ids': deckIds}));

  Future<HermesPurgeCall> _run(
    String command,
    String dbPath, {
    String input = '',
  }) async {
    final Process process;
    try {
      process = await Process.start(config.pythonBin, [
        config.helperScript,
        command,
        '--db',
        dbPath,
      ]);
    } on ProcessException {
      return const HermesPurgeCall(HermesPurgeStatus.error);
    }
    final output = process.stdout.transform(utf8.decoder).join();
    // O auxiliar nunca põe id no stderr; o job não precisa dele.
    final errors = process.stderr.drain<void>();
    process.stdin.write(input);
    await process.stdin.close();
    final exitCode = await process.exitCode.timeout(
      config.helperTimeout,
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
    final text = await output;
    await errors;
    return switch (exitCode) {
      0 => _parse(command, text),
      3 => const HermesPurgeCall(HermesPurgeStatus.absent),
      4 => const HermesPurgeCall(HermesPurgeStatus.busy),
      _ => const HermesPurgeCall(HermesPurgeStatus.error),
    };
  }

  static HermesPurgeCall _parse(String command, String text) {
    try {
      final payload = jsonDecode(text) as Map<String, dynamic>;
      final key = command == 'list' ? 'deck_ids' : 'remaining_deck_ids';
      final ids = [for (final id in payload[key] as List) '$id'];
      final counts = <String, int>{
        for (final name in const [
          'events_deleted',
          'decks_deleted',
          'deck_cards_deleted',
        ])
          if (payload[name] is int) name: payload[name] as int,
      };
      return HermesPurgeCall(
        HermesPurgeStatus.ok,
        deckIds: ids,
        counts: counts,
      );
    } catch (_) {
      return const HermesPurgeCall(HermesPurgeStatus.error);
    }
  }
}

/// Dos [deckIds], quais são de deck apagado: o HMAC do id, com alguma chave da
/// `privacy_keyring`, bate com um tombstone. Devolve os ids como vieram.
Future<List<String>> deletedDeckIdsAmong(
  Session session,
  List<String> deckIds,
) async {
  if (deckIds.isEmpty) return const [];
  final result = await session.execute(
    Sql.named('''
      SELECT DISTINCT candidate.deck_id
      FROM unnest(CAST(@deckIds AS text[])) AS candidate(deck_id)
      CROSS JOIN privacy_keyring keyring
      JOIN privacy_deleted_deck_tombstones tombstone
        ON tombstone.key_version = keyring.key_version
       AND tombstone.deck_token = encode(
         hmac(
           convert_to(lower(candidate.deck_id), 'UTF8'),
           keyring.hmac_key,
           'sha256'
         ),
         'hex'
       )
      ORDER BY 1
    '''),
    parameters: {'deckIds': deckIds},
  );
  return [for (final row in result) row.single! as String];
}

/// Nenhum dos [remaining] é deck da linha [rowId]: o HMAC com a chave da linha
/// não bate com nenhum dos tokens dela.
Future<bool> outboxRowDecksAbsent(
  Session session,
  String rowId,
  List<String> remaining,
) async {
  if (remaining.isEmpty) return true;
  final result = await session.execute(
    Sql.named('''
      SELECT COUNT(*)::int
      FROM account_deletion_outbox outbox
      JOIN privacy_keyring keyring ON keyring.key_version = outbox.key_version
      CROSS JOIN unnest(CAST(@remaining AS text[])) AS remaining(deck_id)
      WHERE outbox.id = CAST(@id AS uuid)
        AND encode(
          hmac(
            convert_to(lower(remaining.deck_id), 'UTF8'),
            keyring.hmac_key,
            'sha256'
          ),
          'hex'
        ) = ANY(outbox.deck_tokens)
    '''),
    parameters: {'id': rowId, 'remaining': remaining},
  );
  return result.single.single == 0;
}

/// Quais dos ids são de deck apagado ([deletedDeckIdsAmong] no job).
typedef DeletedDeckMatcher =
    Future<List<String>> Function(Session session, List<String> deckIds);

/// Nenhum dos ids restantes é deck da linha ([outboxRowDecksAbsent] no job).
typedef OutboxRowDeckCheck =
    Future<bool> Function(
      Session session,
      String rowId,
      List<String> remaining,
    );

class _HermesSweep {
  const _HermesSweep.clean(this.remaining, this.counts)
    : failureCode = null,
      absent = false;
  const _HermesSweep.absent()
    : remaining = const [],
      counts = const {},
      failureCode = null,
      absent = true;
  const _HermesSweep.failed(this.failureCode)
    : remaining = const [],
      counts = const {},
      absent = false;

  final List<String> remaining;
  final Map<String, int> counts;
  final String? failureCode;
  final bool absent;
}

/// O handler do consumidor `hermes_learning_sqlite`. Uma varredura por
/// execução do job: a primeira linha dela faz a varredura, e as outras
/// reaproveitam o resultado e só conferem os próprios decks.
class HermesLearningPurge {
  HermesLearningPurge(
    this.config, {
    HermesPurgeHelper? helper,
    this.maxRounds = 3,
    DeletedDeckMatcher? matcher,
    OutboxRowDeckCheck? rowCheck,
  }) : helper = helper ?? ProcessHermesPurgeHelper(config),
       matcher = matcher ?? deletedDeckIdsAmong,
       rowCheck = rowCheck ?? outboxRowDecksAbsent;

  final HermesKnowledgeDbConfig config;
  final HermesPurgeHelper helper;
  final int maxRounds;
  final DeletedDeckMatcher matcher;
  final OutboxRowDeckCheck rowCheck;

  String? _runId;
  Future<_HermesSweep>? _sweep;
  bool _countsReported = false;

  Future<AccountDeletionOutboxOutcome> handle(
    Session session,
    AccountDeletionOutboxRow row,
  ) async {
    if (_runId != row.runId) {
      _runId = row.runId;
      _sweep = null;
      _countsReported = false;
    }
    final sweep = await (_sweep ??= _runSweep(session));
    final failure = sweep.failureCode;
    if (failure != null) return OutboxFailed(failure);
    if (sweep.absent) return const OutboxDone(hermesKnowledgeDbAbsentCode);
    if (!await rowCheck(session, row.id, sweep.remaining)) {
      return const OutboxFailed('hermes_purge_incomplete');
    }
    final counts = _countsReported ? const <String, int>{} : sweep.counts;
    _countsReported = true;
    return OutboxDone(hermesLearningPurgeCode, counts: counts);
  }

  Future<_HermesSweep> _runSweep(Session session) async {
    final path = config.path;
    if (path == null) {
      return const _HermesSweep.failed('hermes_knowledge_db_not_configured');
    }
    final file = File(path);
    if (!file.existsSync()) {
      return file.parent.existsSync()
          ? const _HermesSweep.absent()
          : const _HermesSweep.failed('hermes_knowledge_db_dir_missing');
    }
    final listed = await helper.list(path);
    switch (listed.status) {
      case HermesPurgeStatus.absent:
        return const _HermesSweep.absent();
      case HermesPurgeStatus.busy:
        return const _HermesSweep.failed('hermes_knowledge_db_busy');
      case HermesPurgeStatus.error:
        return const _HermesSweep.failed('hermes_purge_helper_error');
      case HermesPurgeStatus.ok:
        break;
    }
    var toDelete = await matcher(session, listed.deckIds);
    final counts = <String, int>{};
    // Mesmo sem nada a apagar, o purge roda: é ele que lista de novo sob o
    // lock de escrita, e só essa lista prova o estado do arquivo.
    for (var round = 0; round < maxRounds; round++) {
      final purged = await helper.purge(path, toDelete);
      switch (purged.status) {
        case HermesPurgeStatus.absent:
          return const _HermesSweep.absent();
        case HermesPurgeStatus.busy:
          return const _HermesSweep.failed('hermes_knowledge_db_busy');
        case HermesPurgeStatus.error:
          return const _HermesSweep.failed('hermes_purge_helper_error');
        case HermesPurgeStatus.ok:
          break;
      }
      purged.counts.forEach(
        (name, value) => counts[name] = (counts[name] ?? 0) + value,
      );
      toDelete = await matcher(session, purged.deckIds);
      if (toDelete.isEmpty) return _HermesSweep.clean(purged.deckIds, counts);
    }
    return const _HermesSweep.failed('hermes_purge_incomplete');
  }
}
