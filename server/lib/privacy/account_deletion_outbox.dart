import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../battle/interactive_battle_contract.dart'
    show interactiveBattleMaximumTtlSeconds;
import 'hermes_learning_purge.dart';

/// D-68 (BT-PRIV-002): o outbox da exclusão avisa os lugares fora do
/// PostgreSQL que guardam dado da conta excluída, com recibo por consumidor,
/// lease e nova tentativa.
///
/// A exclusão (`UserDataPrivacyService.deleteAndAnonymizeAccount`) grava uma
/// linha por consumidor na mesma transação em que grava o recibo, e o job
/// `manaloom_account_deletion_outbox` do agendador de ops consome as linhas
/// sem depender de capability. A linha não guarda o titular: aponta para o
/// recibo, que não tem identificador, e leva os decks como o mesmo HMAC dos
/// tombstones (`privacy_deleted_deck_tombstones`), nunca como UUID cru.
const accountDeletionOutboxContract = 'account_deletion_outbox_v1';

/// Marcador da linha de recibo que o job escreve no stdout.
const accountDeletionOutboxReceiptMarker = 'MANALOOM_ACCOUNT_DELETION_OUTBOX';
const accountDeletionOutboxReceiptSchema = 'account_deletion_outbox_run_v1';

/// Como o job conclui a obrigação de um consumidor.
enum AccountDeletionOutboxHandling {
  /// Conclui quando passou, desde a exclusão, o teto de vida do dado no
  /// consumidor.
  expiresByTtl,

  /// Conclui na primeira execução: o consumidor não guarda identificador da
  /// conta.
  holdsNoAccountIdentifier,

  /// Conclui depois de apagar do consumidor o dado dos decks apagados. Acha os
  /// decks pelo HMAC dos tombstones (BT-PRIV-002, [HermesLearningPurge]).
  purgesByTombstoneSweep,

  /// Ainda não há como concluir. A linha fica aberta, com o motivo em
  /// `last_error_code`, sem gastar tentativa.
  blocked,
}

/// Um lugar fora do PostgreSQL que precisa saber da exclusão.
class AccountDeletionOutboxConsumer {
  const AccountDeletionOutboxConsumer({
    required this.name,
    required this.handling,
    required this.code,
    this.carriesDeckTokens = false,
    this.firstAttemptDelay = Duration.zero,
  });

  /// Valor da coluna `consumer` (CHECK da migration 060).
  final String name;
  final AccountDeletionOutboxHandling handling;

  /// Por que a obrigação termina (vai para o recibo da execução) ou, no
  /// consumidor bloqueado, o que falta (vai para `last_error_code`).
  final String code;

  /// Só quem precisa achar os decks apagados recebe os tokens HMAC deles.
  final bool carriesDeckTokens;

  /// A primeira tentativa é o fim da exclusão mais este prazo.
  final Duration firstAttemptDelay;
}

/// O `EndpointCache` não deixa entrada valer mais de 24 h (`maxTtl`), e a
/// vencida sai da memória no primeiro acesso depois de 1 min
/// (`sweepInterval`). Os 5 min cobrem essa varredura.
const endpointCacheOutboxDelay = Duration(hours: 24, minutes: 5);

/// Quanto o sidecar de Jogar contra IA guarda uma sessão terminal na memória
/// (`TERMINAL_RETENTION_MS` em `InteractiveBattleRegistry.java`).
const interactiveBattleSidecarTerminalRetentionSeconds = 10 * 60;

/// D-77: o sidecar é dado como limpo depois do tempo máximo da sessão
/// ([interactiveBattleMaximumTtlSeconds], 7200 s) mais a retenção terminal
/// (10 min), contados da exclusão. Não há rota de confirmação.
const interactiveBattleSidecarOutboxDelay = Duration(
  seconds:
      interactiveBattleMaximumTtlSeconds +
      interactiveBattleSidecarTerminalRetentionSeconds,
);

/// A lista fechada da D-68, na ordem do CHECK da migration 060.
const accountDeletionOutboxConsumers = <AccountDeletionOutboxConsumer>[
  // BT-PRIV-002: o job abre o knowledge.db (HERMES_KNOWLEDGE_DB), acha no
  // PostgreSQL, pelo HMAC dos tombstones, os ids de deck apagados que o arquivo
  // guarda e apaga os eventos e as cópias sob o lock de escrita do SQLite
  // (HermesLearningPurge). Os tokens da linha servem para conferir que nenhum
  // deck desta exclusão ficou.
  AccountDeletionOutboxConsumer(
    name: 'hermes_learning_sqlite',
    handling: AccountDeletionOutboxHandling.purgesByTombstoneSweep,
    code: hermesLearningPurgeCode,
    carriesDeckTokens: true,
  ),
  // D-77: fecha pelo tempo, como o endpoint_cache. Sem rota de confirmação,
  // os tokens de deck não teriam uso e não vão para esta linha.
  AccountDeletionOutboxConsumer(
    name: 'interactive_battle_sidecar',
    handling: AccountDeletionOutboxHandling.expiresByTtl,
    code: 'expired_by_max_session_lifetime',
    firstAttemptDelay: interactiveBattleSidecarOutboxDelay,
  ),
  AccountDeletionOutboxConsumer(
    name: 'endpoint_cache',
    handling: AccountDeletionOutboxHandling.expiresByTtl,
    code: 'expired_by_24h_cache_cap',
    firstAttemptDelay: endpointCacheOutboxDelay,
  ),
  // Desde o BT-PRIV-002, nenhum evento do servidor leva o usuário, e todo
  // UUID vira :id no beforeSend. O Sentry do app é da raia do app.
  AccountDeletionOutboxConsumer(
    name: 'sentry',
    handling: AccountDeletionOutboxHandling.holdsNoAccountIdentifier,
    code: 'server_events_carry_no_user_id',
  ),
  // Depende da rotação de 30 dias da D-69, ainda não aplicada.
  AccountDeletionOutboxConsumer(
    name: 'backups',
    handling: AccountDeletionOutboxHandling.blocked,
    code: 'blocked_backup_rotation_not_applied',
  ),
];

/// Grava uma linha por consumidor para o recibo [receiptId], dentro da
/// transação da exclusão: se o INSERT falhar, a exclusão inteira volta.
Future<void> enqueueAccountDeletionOutbox(
  Session session, {
  required String receiptId,
  required int keyVersion,
  required List<String> deckTokens,
  required DateTime completedAt,
}) async {
  await session.execute(
    Sql.named('''
      INSERT INTO account_deletion_outbox (
        receipt_id, consumer, key_version, deck_tokens,
        next_attempt_at, created_at, updated_at
      )
      SELECT
        CAST(@receiptId AS uuid),
        plan.consumer,
        CAST(@keyVersion AS smallint),
        CASE
          WHEN plan.carries_deck_tokens THEN CAST(@deckTokens AS text[])
          ELSE ARRAY[]::text[]
        END,
        CAST(@completedAt AS timestamptz)
          + make_interval(secs => plan.delay_seconds),
        CAST(@completedAt AS timestamptz),
        CAST(@completedAt AS timestamptz)
      FROM unnest(
        CAST(@consumers AS text[]),
        CAST(@carriesDeckTokens AS boolean[]),
        CAST(@delaySeconds AS integer[])
      ) AS plan(consumer, carries_deck_tokens, delay_seconds)
    '''),
    parameters: {
      'receiptId': receiptId,
      'keyVersion': keyVersion,
      'deckTokens': deckTokens,
      'completedAt': completedAt,
      ..._consumerPlanParameters(),
    },
  );
}

/// O plano de cada consumidor como listas paralelas, para o `unnest` do
/// INSERT da exclusão e da reconciliação.
Map<String, Object> _consumerPlanParameters() => {
  'consumers': [
    for (final consumer in accountDeletionOutboxConsumers) consumer.name,
  ],
  'carriesDeckTokens': [
    for (final consumer in accountDeletionOutboxConsumers)
      consumer.carriesDeckTokens,
  ],
  'delaySeconds': [
    for (final consumer in accountDeletionOutboxConsumers)
      consumer.firstAttemptDelay.inSeconds,
  ],
};

/// BT-PRIV-002: cria a linha que falta para cada (recibo, consumidor), como a
/// exclusão teria criado:
/// - `created_at` é a hora da exclusão (`completed_at` do recibo), e o prazo
///   de cada consumidor conta dela;
/// - os tokens são os tombstones gravados na mesma exclusão (mesmo
///   `deleted_at`), com a chave deles; sem deck, vai a chave ativa.
/// `ON CONFLICT` deixa a reconciliação idempotente e nunca toca linha que já
/// existe.
const _reconcileMissingRowsSql = '''
  WITH plan AS (
    SELECT *
    FROM unnest(
      CAST(@consumers AS text[]),
      CAST(@carriesDeckTokens AS boolean[]),
      CAST(@delaySeconds AS integer[])
    ) AS plan(consumer, carries_deck_tokens, delay_seconds)
  ), missing AS (
    SELECT receipt.id AS receipt_id,
           receipt.completed_at,
           plan.consumer,
           plan.carries_deck_tokens,
           plan.delay_seconds
    FROM account_deletion_receipts receipt
    CROSS JOIN plan
    WHERE NOT EXISTS (
      SELECT 1
      FROM account_deletion_outbox outbox
      WHERE outbox.receipt_id = receipt.id
        AND outbox.consumer = plan.consumer
    )
  ), deletion_key AS (
    SELECT DISTINCT ON (missing.receipt_id)
           missing.receipt_id,
           tombstone.key_version
    FROM missing
    JOIN privacy_deleted_deck_tombstones tombstone
      ON tombstone.deleted_at = missing.completed_at
    ORDER BY missing.receipt_id, tombstone.key_version DESC
  ), inserted AS (
    INSERT INTO account_deletion_outbox (
      receipt_id, consumer, key_version, deck_tokens,
      next_attempt_at, created_at, updated_at
    )
    SELECT
      missing.receipt_id,
      missing.consumer,
      COALESCE(deletion_key.key_version, active_key.key_version),
      CASE
        WHEN missing.carries_deck_tokens
          AND deletion_key.key_version IS NOT NULL
        THEN COALESCE(
          (
            SELECT array_agg(tombstone.deck_token ORDER BY tombstone.deck_token)
            FROM privacy_deleted_deck_tombstones tombstone
            WHERE tombstone.deleted_at = missing.completed_at
              AND tombstone.key_version = deletion_key.key_version
          ),
          ARRAY[]::text[]
        )
        ELSE ARRAY[]::text[]
      END,
      missing.completed_at + make_interval(secs => missing.delay_seconds),
      missing.completed_at,
      CURRENT_TIMESTAMP
    FROM missing
    LEFT JOIN deletion_key ON deletion_key.receipt_id = missing.receipt_id
    LEFT JOIN privacy_keyring active_key ON active_key.is_active
    WHERE COALESCE(deletion_key.key_version, active_key.key_version) IS NOT NULL
    ON CONFLICT (receipt_id, consumer) DO NOTHING
    RETURNING consumer
  )
  SELECT consumer, COUNT(*)::int
  FROM inserted
  GROUP BY consumer
''';

void _bump(Map<String, int> counters, String key, int by) {
  counters[key] = (counters[key] ?? 0) + by;
}

/// Uma linha reservada pelo job.
class AccountDeletionOutboxRow {
  AccountDeletionOutboxRow({
    required this.id,
    required this.consumer,
    required this.attempts,
    this.runId = '',
  });

  final String id;
  final String consumer;
  final int attempts;

  /// A execução do job que reservou a linha. Um handler que guarda estado
  /// entre linhas (a varredura do Hermes) recomeça quando ele muda.
  final String runId;
}

/// Resultado do tratamento de uma linha.
sealed class AccountDeletionOutboxOutcome {
  const AccountDeletionOutboxOutcome();
}

/// A obrigação do consumidor terminou.
class OutboxDone extends AccountDeletionOutboxOutcome {
  const OutboxDone(this.code, {this.counts = const {}});
  final String code;

  /// O que o consumidor apagou para concluir, só em contagens. Vai somado
  /// para o recibo da execução.
  final Map<String, int> counts;
}

/// Ainda não é hora: volta para a fila sem gastar tentativa, para quando a
/// linha completar [sinceCreated] de idade.
class OutboxNotYet extends AccountDeletionOutboxOutcome {
  const OutboxNotYet(this.sinceCreated);
  final Duration sinceCreated;
}

/// Falhou: nova tentativa depois do intervalo.
class OutboxFailed extends AccountDeletionOutboxOutcome {
  const OutboxFailed(this.code);
  final String code;
}

/// Trata uma linha reservada. Recebe a sessão da transação que vai fechar a
/// linha, para conferir o prazo com o relógio do banco.
typedef AccountDeletionOutboxHandler =
    Future<AccountDeletionOutboxOutcome> Function(
      Session session,
      AccountDeletionOutboxRow row,
    );

/// Os consumidores que o job já sabe concluir. Os bloqueados ficam de fora.
///
/// O knowledge.db do Hermes vem de [hermes] ou do ambiente
/// (`HERMES_KNOWLEDGE_DB`, que o agendador de ops põe em todo job).
Map<String, AccountDeletionOutboxHandler> defaultAccountDeletionOutboxHandlers({
  HermesKnowledgeDbConfig? hermes,
  HermesPurgeHelper? hermesHelper,
}) {
  final handlers = <String, AccountDeletionOutboxHandler>{};
  for (final consumer in accountDeletionOutboxConsumers) {
    switch (consumer.handling) {
      case AccountDeletionOutboxHandling.expiresByTtl:
        handlers[consumer.name] = (session, row) async {
          final result = await session.execute(
            Sql.named('''
              SELECT created_at + make_interval(secs => @delaySeconds)
                <= CURRENT_TIMESTAMP
              FROM account_deletion_outbox
              WHERE id = CAST(@id AS uuid)
            '''),
            parameters: {
              'id': row.id,
              'delaySeconds': consumer.firstAttemptDelay.inSeconds,
            },
          );
          return result.single.single == true
              ? OutboxDone(consumer.code)
              : OutboxNotYet(consumer.firstAttemptDelay);
        };
      case AccountDeletionOutboxHandling.holdsNoAccountIdentifier:
        handlers[consumer.name] =
            (session, row) async => OutboxDone(consumer.code);
      case AccountDeletionOutboxHandling.purgesByTombstoneSweep:
        handlers[consumer.name] =
            HermesLearningPurge(
              hermes ?? HermesKnowledgeDbConfig.fromEnvironment(),
              helper: hermesHelper,
            ).handle;
      case AccountDeletionOutboxHandling.blocked:
        break;
    }
  }
  return handlers;
}

/// Consome o outbox uma vez: reconcilia os recibos sem linha, marca os
/// bloqueados com o motivo, reserva as linhas vencidas dos consumidores
/// tratados (com lease), conclui ou agenda a nova tentativa e devolve o recibo
/// da execução, sem identificador.
class AccountDeletionOutboxWorker {
  AccountDeletionOutboxWorker(
    this.pool, {
    Map<String, AccountDeletionOutboxHandler>? handlers,
    this.batchSize = 200,
    this.lease = const Duration(minutes: 5),
    this.maxAttempts = 20,
    this.reconcileMissingRows = true,
  }) : handlers = handlers ?? defaultAccountDeletionOutboxHandlers();

  final Pool pool;
  final Map<String, AccountDeletionOutboxHandler> handlers;
  final int batchSize;
  final Duration lease;
  final int maxAttempts;

  /// BT-PRIV-002: cada execução cria, para todo recibo de exclusão, a linha de
  /// cada consumidor que ainda não existe. Cobre exclusões de antes da
  /// migration 060 e consumidor que entre depois.
  final bool reconcileMissingRows;

  /// Intervalo da nova tentativa: 2^tentativas minutos, até 24 h.
  static Duration retryDelay(int attempts) {
    final minutes = 1 << attempts.clamp(0, 11);
    const cap = Duration(hours: 24);
    final delay = Duration(minutes: minutes);
    return delay > cap ? cap : delay;
  }

  Future<Map<String, dynamic>> runOnce({required String runId}) async {
    final startedAt = DateTime.now().toUtc();
    final present = await pool.execute(
      "SELECT to_regclass('public.account_deletion_outbox') IS NOT NULL",
    );
    if (present.single.single != true) {
      throw const AccountDeletionOutboxMissing();
    }
    final leaseOwner = 'account-deletion-outbox:$runId';
    final perConsumer = <String, Map<String, Object?>>{
      for (final consumer in accountDeletionOutboxConsumers)
        consumer.name: {
          'handling': consumer.handling.name,
          'code': consumer.code,
          'reconciled': 0,
          'claimed': 0,
          'done': 0,
          'not_yet': 0,
          'failed': 0,
          'marked_blocked': 0,
          'done_by': <String, int>{},
          'failed_by': <String, int>{},
          'purged': <String, int>{},
        },
    };

    if (reconcileMissingRows) {
      final reconciled = await pool.execute(
        Sql.named(_reconcileMissingRowsSql),
        parameters: _consumerPlanParameters(),
      );
      for (final row in reconciled) {
        final counters = perConsumer[row[0]! as String];
        if (counters != null) counters['reconciled'] = row[1];
      }
    }

    for (final consumer in accountDeletionOutboxConsumers) {
      if (handlers.containsKey(consumer.name)) continue;
      final marked = await pool.execute(
        Sql.named('''
          UPDATE account_deletion_outbox
          SET last_error_code = @code,
              updated_at = CURRENT_TIMESTAMP
          WHERE consumer = @consumer
            AND status = 'pending'
            AND last_error_code IS DISTINCT FROM @code
        '''),
        parameters: {'consumer': consumer.name, 'code': consumer.code},
      );
      perConsumer[consumer.name]!['marked_blocked'] = marked.affectedRows;
    }

    final claimed = await pool.execute(
      Sql.named('''
        WITH due AS (
          SELECT id
          FROM account_deletion_outbox
          WHERE consumer = ANY(CAST(@consumers AS text[]))
            AND attempts < @maxAttempts
            AND (
              (status IN ('pending', 'failed')
                AND next_attempt_at <= CURRENT_TIMESTAMP)
              OR (status = 'processing'
                AND lease_expires_at <= CURRENT_TIMESTAMP)
            )
          ORDER BY next_attempt_at, id
          LIMIT @batchSize
          FOR UPDATE SKIP LOCKED
        )
        UPDATE account_deletion_outbox outbox
        SET status = 'processing',
            lease_owner = @leaseOwner,
            lease_expires_at =
              CURRENT_TIMESTAMP + make_interval(secs => @leaseSeconds),
            attempts = outbox.attempts + 1,
            updated_at = CURRENT_TIMESTAMP
        FROM due
        WHERE outbox.id = due.id
        RETURNING outbox.id::text, outbox.consumer, outbox.attempts
      '''),
      parameters: {
        'consumers': handlers.keys.toList(),
        'maxAttempts': maxAttempts,
        'batchSize': batchSize,
        'leaseOwner': leaseOwner,
        'leaseSeconds': lease.inSeconds,
      },
    );

    for (final raw in claimed) {
      final row = AccountDeletionOutboxRow(
        id: raw[0]! as String,
        consumer: raw[1]! as String,
        attempts: raw[2]! as int,
        runId: runId,
      );
      final counters = perConsumer[row.consumer]!;
      counters['claimed'] = (counters['claimed']! as int) + 1;
      // O handler roda na própria transação; a linha fecha depois, só se o
      // lease ainda for deste job. Entrega pelo menos uma vez: um handler
      // precisa aguentar repetição.
      AccountDeletionOutboxOutcome outcome;
      try {
        outcome = await pool.runTx(
          (session) => handlers[row.consumer]!(session, row),
        );
      } catch (_) {
        outcome = const OutboxFailed('handler_error');
      }
      final closed = await pool.execute(
        Sql.named(switch (outcome) {
          OutboxDone() => '''
            UPDATE account_deletion_outbox
            SET status = 'done',
                completed_at = CURRENT_TIMESTAMP,
                lease_owner = NULL,
                lease_expires_at = NULL,
                last_error_code = NULL,
                deck_tokens = ARRAY[]::text[],
                updated_at = CURRENT_TIMESTAMP
            WHERE id = CAST(@id AS uuid)
              AND status = 'processing'
              AND lease_owner = @leaseOwner
          ''',
          OutboxNotYet() => '''
            UPDATE account_deletion_outbox
            SET status = 'pending',
                attempts = GREATEST(attempts - 1, 0),
                next_attempt_at =
                  created_at + make_interval(secs => @notBeforeSeconds),
                lease_owner = NULL,
                lease_expires_at = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = CAST(@id AS uuid)
              AND status = 'processing'
              AND lease_owner = @leaseOwner
          ''',
          OutboxFailed() => '''
            UPDATE account_deletion_outbox
            SET status = 'failed',
                last_error_code = @code,
                next_attempt_at =
                  CURRENT_TIMESTAMP + make_interval(secs => @retrySeconds),
                lease_owner = NULL,
                lease_expires_at = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = CAST(@id AS uuid)
              AND status = 'processing'
              AND lease_owner = @leaseOwner
          ''',
        }),
        parameters: {
          'id': row.id,
          'leaseOwner': leaseOwner,
          if (outcome is OutboxFailed) ...{
            'code': outcome.code,
            'retrySeconds': retryDelay(row.attempts).inSeconds,
          },
          if (outcome is OutboxNotYet)
            'notBeforeSeconds': outcome.sinceCreated.inSeconds,
        },
      );
      final key =
          closed.affectedRows == 1
              ? switch (outcome) {
                OutboxDone() => 'done',
                OutboxNotYet() => 'not_yet',
                OutboxFailed() => 'failed',
              }
              : 'lease_lost';
      counters[key] = ((counters[key] as int?) ?? 0) + 1;
      // Recibo por consumidor: por que cada linha fechou ou falhou, e o que
      // o consumidor apagou (mesmo que outra execução feche a linha).
      if (closed.affectedRows == 1) {
        switch (outcome) {
          case OutboxDone(:final code):
            _bump(counters['done_by']! as Map<String, int>, code, 1);
          case OutboxFailed(:final code):
            _bump(counters['failed_by']! as Map<String, int>, code, 1);
          case OutboxNotYet():
            break;
        }
      }
      if (outcome case OutboxDone(:final counts)) {
        final purged = counters['purged']! as Map<String, int>;
        counts.forEach((name, value) => _bump(purged, name, value));
      }
    }

    final open = await pool.execute(
      Sql.named('''
        SELECT consumer,
               COUNT(*) FILTER (WHERE status <> 'done')::int AS open_rows,
               COUNT(*) FILTER (
                 WHERE status <> 'done' AND attempts >= @maxAttempts
               )::int AS exhausted
        FROM account_deletion_outbox
        GROUP BY consumer
      '''),
      parameters: {'maxAttempts': maxAttempts},
    );
    for (final row in open) {
      final counters = perConsumer[row[0]! as String];
      if (counters == null) continue;
      counters['open_rows'] = row[1];
      counters['exhausted'] = row[2];
    }
    for (final counters in perConsumer.values) {
      counters.putIfAbsent('open_rows', () => 0);
      counters.putIfAbsent('exhausted', () => 0);
    }

    return {
      'schema': accountDeletionOutboxReceiptSchema,
      'contract': accountDeletionOutboxContract,
      'run_id': runId,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'ok',
      'consumers': perConsumer,
    };
  }
}

/// A tabela do outbox não existe: a migration 060 não foi aplicada.
class AccountDeletionOutboxMissing implements Exception {
  const AccountDeletionOutboxMissing();

  @override
  String toString() =>
      'account_deletion_outbox ausente: a migration 060 não foi aplicada.';
}

/// A linha de recibo que o job escreve no stdout.
String accountDeletionOutboxReceiptLine(Map<String, dynamic> receipt) =>
    '$accountDeletionOutboxReceiptMarker ${jsonEncode(receipt)}';
