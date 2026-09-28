import 'dart:convert';

import 'package:postgres/postgres.dart';

/// D-70 (BT-PRIV-002): a limpeza por prazo roda sem depender de capability,
/// sob o contrato `retention_cleanup_apply_v1`, e apaga só o que o inventário
/// de retenção manda (`docs/privacy/data_retention_inventory.json`, seção
/// `retention_cleanup`).
///
/// Desligada por padrão. O agendado (`manaloom_ai_runtime_cleanup` no daemon
/// de ops) só apaga depois que uma execução supervisionada, com
/// `MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL`, ativou o
/// contrato em `sync_state`; até lá, conta o que apagaria e deixa o recibo.
/// Ligar em produção é decisão do dono.
const retentionCleanupJobName = 'manaloom_ai_runtime_cleanup';
const retentionCleanupContract = 'retention_cleanup_apply_v1';
const retentionCleanupReceiptMarker = 'MANALOOM_RETENTION_CLEANUP';
const retentionCleanupReceiptSchema = 'retention_cleanup_run_v1';

/// Chave em `sync_state`: o nome do contrato quando ativo, senão `inactive`.
const retentionCleanupStateKey = 'retention_cleanup_apply_contract';
const retentionCleanupInactive = 'inactive';

const retentionCleanupWriteApprovalEnvironment =
    'MANALOOM_CONFIRM_POSTGRES_WRITES';
const retentionCleanupWriteApprovalValue = 'I_HAVE_EXPLICIT_APPROVAL';

enum RetentionCleanupMode {
  /// O daemon: apaga só com o contrato ativo; senão só conta.
  scheduled('scheduled'),

  /// Supervisionada: apaga e registra a ativação na mesma transação.
  activate('activate'),

  /// Supervisionada: registra a pausa; nada é apagado.
  deactivate('deactivate'),

  /// Só leitura: conta o que apagaria.
  dryRun('dry-run');

  const RetentionCleanupMode(this.wireName);
  final String wireName;

  static RetentionCleanupMode? parse(String value) {
    for (final mode in values) {
      if (mode.wireName == value) return mode;
    }
    return null;
  }

  bool get requiresWriteApproval =>
      this == RetentionCleanupMode.activate ||
      this == RetentionCleanupMode.deactivate;
}

/// Um prazo do inventário. O filtro é SQL fixo do código, nunca entrada.
///
/// A regra apaga a linha vencida, ou, com [redactSet], só apaga o campo
/// com prazo dela (D-29: o prompt bruto e o texto de descrição do ledger
/// saem em 30 dias; a linha fica). [sessionSetting] marca a transação para
/// a redação que um gatilho só aceita assim (o ledger é só de acréscimo).
/// O prazo conta de [ageColumn] (`created_at`, ou `deleted_at` na lixeira de
/// decks da D-30).
class RetentionCleanupRule {
  const RetentionCleanupRule({
    required this.id,
    required this.table,
    required this.maxAge,
    this.filter,
    this.redactSet,
    this.sessionSetting,
    this.ageColumn = 'created_at',
  });

  final String id;
  final String table;
  final Duration maxAge;
  final String? filter;

  /// A coluna de onde o prazo conta.
  final String ageColumn;

  /// `SET` da redação (SQL fixo do código); nulo para regra que apaga.
  final String? redactSet;

  /// (nome, valor) do `set_config` local que a redação precisa.
  final (String, String)? sessionSetting;

  bool get isRedaction => redactSet != null;

  String get _where =>
      '${filter == null ? '' : '$filter AND '}'
      '$ageColumn < CURRENT_TIMESTAMP - '
      'make_interval(mins => ${maxAge.inMinutes})';

  String get countSql => 'SELECT COUNT(*)::int FROM $table WHERE $_where';
  String get deleteSql => 'DELETE FROM $table WHERE $_where';
  String get redactSql => 'UPDATE $table SET $redactSet WHERE $_where';
}

/// Os prazos que o inventário manda aplicar, na ordem do recibo. O teste
/// `retention_cleanup_test.dart` cruza esta lista com a seção
/// `retention_cleanup` do inventário, nos dois sentidos.
const retentionCleanupRules = <RetentionCleanupRule>[
  RetentionCleanupRule(
    id: 'ai_optimize_fallback_telemetry_180d',
    table: 'ai_optimize_fallback_telemetry',
    maxAge: Duration(days: 180),
  ),
  RetentionCleanupRule(
    id: 'ai_logs_180d',
    table: 'ai_logs',
    maxAge: Duration(days: 180),
    filter: "endpoint NOT LIKE 'plan-reservation:%'",
  ),
  RetentionCleanupRule(
    id: 'ai_logs_unconfirmed_plan_reservation_10min',
    table: 'ai_logs',
    maxAge: Duration(minutes: 10),
    filter: "endpoint LIKE 'plan-reservation:%' AND success = FALSE",
  ),
  RetentionCleanupRule(
    id: 'rate_limit_events_24h',
    table: 'rate_limit_events',
    maxAge: Duration(hours: 24),
  ),
  RetentionCleanupRule(
    id: 'ai_generate_jobs_24h',
    table: 'ai_generate_jobs',
    maxAge: Duration(hours: 24),
  ),
  RetentionCleanupRule(
    id: 'ai_optimize_jobs_24h',
    table: 'ai_optimize_jobs',
    maxAge: Duration(hours: 24),
  ),
  // D-29 (DCK-P0-04): o prompt bruto do Generate e a impressão que
  // deriva dele saem em 30 dias; o pedido fica, com o resultado.
  RetentionCleanupRule(
    id: 'ai_generate_requests_prompt_30d',
    table: 'ai_generate_requests',
    maxAge: Duration(days: 30),
    filter: 'prompt IS NOT NULL',
    redactSet:
        'prompt = NULL, request_fingerprint = NULL, '
        'prompt_purged_at = CURRENT_TIMESTAMP, '
        'updated_at = CURRENT_TIMESTAMP',
  ),
  // D-29 (DCK-P0-04): o texto de descrição copiado no ledger de mudanças
  // sai em 30 dias (a descrição pode trazer o prompt que o app antigo
  // gravava ali); fica só que a descrição mudou.
  RetentionCleanupRule(
    id: 'deck_change_events_description_30d',
    table: 'deck_change_events',
    maxAge: Duration(days: 30),
    filter:
        "description_redacted_at IS NULL AND (metadata_before ? 'description' "
        "OR metadata_after ? 'description')",
    redactSet:
        "metadata_before = CASE WHEN metadata_before ? 'description' "
        "THEN jsonb_set(metadata_before, '{description}', 'null'::jsonb) "
        'ELSE metadata_before END, '
        "metadata_after = CASE WHEN metadata_after ? 'description' "
        "THEN jsonb_set(metadata_after, '{description}', 'null'::jsonb) "
        'ELSE metadata_after END, '
        'description_redacted_at = CURRENT_TIMESTAMP',
    sessionSetting: ('manaloom.deck_ledger_redaction', 'd29_prompt_retention'),
  ),
  // D-30 (DCK-P0-06): deck com mais de 30 dias na lixeira sai de vez. Antes
  // dele, na mesma transação, as cópias que não pendem do deck por chave
  // estrangeira em cascata: os relatórios (despublicados desde a ida para a
  // lixeira) e os eventos de aprendizado.
  RetentionCleanupRule(
    id: 'shared_deck_reports_trashed_deck_30d',
    table: 'shared_deck_reports',
    maxAge: Duration(days: 30),
    filter: 'deck_id IN ($_decksTrashedOver30Days)',
  ),
  RetentionCleanupRule(
    id: 'deck_learning_events_trashed_deck_30d',
    table: 'deck_learning_events',
    maxAge: Duration(days: 30),
    filter: 'deck_id IN ($_decksTrashedOver30Days)',
  ),
  // A cascata leva cartas, ledger, notas, comentários, confrontos e o resto
  // que pende do deck; as referências com SET NULL ficam sem o deck, como
  // no DELETE de antes da lixeira.
  RetentionCleanupRule(
    id: 'decks_trash_30d',
    table: 'decks',
    maxAge: Duration(days: 30),
    filter: 'deleted_at IS NOT NULL',
    ageColumn: 'deleted_at',
  ),
];

/// Decks com mais de 30 dias na lixeira (D-30), para as regras das cópias
/// que saem antes do deck.
const _decksTrashedOver30Days =
    'SELECT id FROM decks WHERE deleted_at IS NOT NULL AND '
    'deleted_at < CURRENT_TIMESTAMP - make_interval(mins => 43200)';

/// Lê `--mode <modo>` (ou `--mode=<modo>`), `--dry-run` e `--output-dir`.
/// Qualquer outra coisa, inclusive as flags de prazo antigas
/// (`--retention-days` e afins), devolve nulo: os prazos vêm só do
/// inventário.
(RetentionCleanupMode, String?)? parseRetentionCleanupArguments(
  List<String> args,
) {
  var mode = RetentionCleanupMode.scheduled;
  String? outputDir;
  var index = 0;
  while (index < args.length) {
    final arg = args[index];
    if (arg == '--dry-run') {
      mode = RetentionCleanupMode.dryRun;
      index += 1;
      continue;
    }
    final separator = arg.indexOf('=');
    final name = separator < 0 ? arg : arg.substring(0, separator);
    final inline = separator < 0 ? null : arg.substring(separator + 1);
    final value = inline ?? (index + 1 < args.length ? args[index + 1] : null);
    if (value == null) return null;
    index += inline == null ? 2 : 1;
    switch (name) {
      case '--mode':
        final parsed = RetentionCleanupMode.parse(value);
        if (parsed == null) return null;
        mode = parsed;
      case '--output-dir':
        outputDir = value;
      default:
        return null;
    }
  }
  return (mode, outputDir);
}

/// Modo supervisionado sem a aprovação explícita no ambiente.
class RetentionCleanupRefused implements Exception {
  const RetentionCleanupRefused(this.mode);
  final RetentionCleanupMode mode;

  @override
  String toString() =>
      'retention cleanup: --mode ${mode.wireName} exige '
      '$retentionCleanupWriteApprovalEnvironment='
      '$retentionCleanupWriteApprovalValue.';
}

/// Uma execução da limpeza. Devolve o recibo, sem identificador de pessoa:
/// só contagens por regra.
class RetentionCleanupRunner {
  RetentionCleanupRunner(this.pool);

  final Pool pool;

  Future<Map<String, dynamic>> run({
    required RetentionCleanupMode mode,
    required String runId,
    required Map<String, String> environment,
  }) async {
    final startedAt = DateTime.now().toUtc();
    if (mode.requiresWriteApproval &&
        environment[retentionCleanupWriteApprovalEnvironment] !=
            retentionCleanupWriteApprovalValue) {
      throw RetentionCleanupRefused(mode);
    }

    final outcome = switch (mode) {
      RetentionCleanupMode.dryRun => await _count(),
      RetentionCleanupMode.deactivate => await _deactivate(),
      RetentionCleanupMode.activate => await _apply(
        activate: true,
        activeBefore: await _isActive(),
      ),
      RetentionCleanupMode.scheduled =>
        await _isActive()
            ? await _apply(activate: false, activeBefore: true)
            : await _count(),
    };

    return {
      'schema': retentionCleanupReceiptSchema,
      'contract': retentionCleanupContract,
      'job': retentionCleanupJobName,
      'run_id': runId,
      'mode': mode.wireName,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      ...outcome,
    };
  }

  Future<bool> _isActive() async {
    final result = await pool.execute(
      Sql.named('SELECT value FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
    return result.isNotEmpty &&
        result.single.single == retentionCleanupContract;
  }

  Future<Map<String, dynamic>> _count() async {
    final active = await _isActive();
    final rules = await pool.runTx((session) async {
      return [
        for (final rule in retentionCleanupRules)
          _ruleReceipt(
            rule,
            eligible:
                (await session.execute(rule.countSql)).single.single! as int,
            deleted: 0,
          ),
      ];
    }, settings: TransactionSettings(accessMode: AccessMode.readOnly));
    return {
      'status': 'ok',
      'activation': active ? 'active' : retentionCleanupInactive,
      'applied': false,
      'rules': rules,
    };
  }

  Future<Map<String, dynamic>> _deactivate() async {
    await pool.execute(
      Sql.named(_writeStateSql),
      parameters: {
        'key': retentionCleanupStateKey,
        'value': retentionCleanupInactive,
      },
    );
    return {
      'status': 'ok',
      'activation': retentionCleanupInactive,
      'applied': false,
      'rules': const <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>> _apply({
    required bool activate,
    required bool activeBefore,
  }) async {
    return pool.runTx((session) async {
      final locked = await session.execute(
        "SELECT pg_try_advisory_xact_lock(hashtext('$retentionCleanupContract'))",
      );
      if (locked.single.single != true) {
        return {
          'status': 'busy',
          'activation': activeBefore ? 'active' : retentionCleanupInactive,
          'applied': false,
          'rules': const <Map<String, dynamic>>[],
        };
      }
      final rules = <Map<String, dynamic>>[];
      for (final rule in retentionCleanupRules) {
        final eligible =
            (await session.execute(rule.countSql)).single.single! as int;
        if (rule.isRedaction) {
          final setting = rule.sessionSetting;
          if (setting != null) {
            await session.execute(
              Sql.named('SELECT set_config(@name, @value, true)'),
              parameters: {'name': setting.$1, 'value': setting.$2},
            );
          }
          final redacted = await session.execute(rule.redactSql);
          rules.add(
            _ruleReceipt(
              rule,
              eligible: eligible,
              deleted: 0,
              redacted: redacted.affectedRows,
            ),
          );
          continue;
        }
        final deleted = await session.execute(rule.deleteSql);
        rules.add(
          _ruleReceipt(rule, eligible: eligible, deleted: deleted.affectedRows),
        );
      }
      if (activate) {
        await session.execute(
          Sql.named(_writeStateSql),
          parameters: {
            'key': retentionCleanupStateKey,
            'value': retentionCleanupContract,
          },
        );
      }
      return {
        'status': 'ok',
        'activation': 'active',
        'applied': true,
        'rules': rules,
      };
    });
  }

  static const _writeStateSql = '''
    INSERT INTO sync_state (key, value, updated_at)
    VALUES (@key, @value, CURRENT_TIMESTAMP)
    ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at
  ''';

  static Map<String, dynamic> _ruleReceipt(
    RetentionCleanupRule rule, {
    required int eligible,
    required int deleted,
    int redacted = 0,
  }) => {
    'id': rule.id,
    'table': rule.table,
    'max_age_minutes': rule.maxAge.inMinutes,
    'action': rule.isRedaction ? 'redact' : 'delete',
    'eligible': eligible,
    'deleted': deleted,
    if (rule.isRedaction) 'redacted': redacted,
  };
}

/// A linha de recibo que o job escreve no stdout.
String retentionCleanupReceiptLine(Map<String, dynamic> receipt) =>
    '$retentionCleanupReceiptMarker ${jsonEncode(receipt)}';
