import 'package:postgres/postgres.dart';

/// BT-DB-002 e BT-DB-003: o preflight do runner de migrations, que roda antes
/// de qualquer DDL (inclusive antes de criar `schema_migrations`).
///
/// O banco é classificado pela história que ele registra (o ledger) contra a
/// lista de migrations deste código:
/// - [MigrationSourceProfile.semLedger]: não há `schema_migrations`, ou ela
///   está vazia, e `users` não tem contas. É o banco novo do bootstrap
///   (`server/database_setup.sql`).
/// - [MigrationSourceProfile.canonico]: toda versão do ledger existe neste
///   código com o mesmo nome, e as executadas formam um prefixo da lista:
///   nenhuma pendente é anterior à última executada.
/// - [MigrationSourceProfile.misto]: qualquer outra coisa. O runner para
///   antes de escrever.
///
/// A deriva conhecida da produção não é um perfil do runner (D-48): ela é
/// reconciliada pelas migrations e conferida, depois do upgrade, pelo ensaio
/// `scripts/manaloom_migration_rehearsal.py` contra a lista fechada
/// `server/config/schema_drift_allowlist.json`.
enum MigrationSourceProfile {
  semLedger('sem_ledger'),
  canonico('canonico'),
  misto('misto');

  const MigrationSourceProfile(this.code);

  final String code;
}

/// Uma migration pelo que o ledger guarda dela: número e nome.
typedef MigrationIdentity = ({String version, String name});

/// O que o preflight leu do banco, sem escrever nada.
class MigrationLedgerState {
  const MigrationLedgerState({
    required this.ledger,
    required this.userAccounts,
  });

  /// As linhas de `schema_migrations`, ou nulo quando a tabela não existe.
  final List<MigrationIdentity>? ledger;

  /// Contas em `users`, ou nulo quando a tabela não existe.
  final int? userAccounts;
}

class MigrationPreflightResult {
  const MigrationPreflightResult({
    required this.profile,
    required this.reasons,
    required this.executed,
    required this.pending,
    required this.codeCount,
    required this.latestInCode,
    required this.latestExecuted,
  });

  final MigrationSourceProfile profile;

  /// Por que o perfil é misto; vazio nos outros perfis.
  final List<String> reasons;

  /// Versões registradas no ledger, em ordem.
  final List<String> executed;

  /// Versões deste código que faltam no ledger, na ordem da lista.
  final List<String> pending;

  final int codeCount;
  final String? latestInCode;
  final String? latestExecuted;

  bool get accepted => profile != MigrationSourceProfile.misto;

  Map<String, Object?> toJson() => {
    'perfil': profile.code,
    'aceito': accepted,
    'motivos': reasons,
    'executadas': executed.length,
    'ultima_executada': latestExecuted,
    'pendentes': pending,
    'codigo': {'migrations': codeCount, 'ultima': latestInCode},
  };
}

/// Classifica o banco. [code] é a lista do runner, na ordem de aplicação.
MigrationPreflightResult classifyMigrationSource({
  required List<MigrationIdentity> code,
  required MigrationLedgerState state,
}) {
  final position = <String, int>{};
  for (var index = 0; index < code.length; index++) {
    final version = code[index].version;
    if (position.containsKey(version)) {
      throw StateError('a lista de migrations repete a versão $version');
    }
    if (index > 0 && version.compareTo(code[index - 1].version) <= 0) {
      throw StateError(
        'a lista de migrations não está em ordem: $version depois de '
        '${code[index - 1].version}',
      );
    }
    position[version] = index;
  }

  final ledger = [...?state.ledger]
    ..sort((a, b) => a.version.compareTo(b.version));
  final executed = {for (final row in ledger) row.version};
  final reasons = <String>[];

  if (ledger.isEmpty) {
    final accounts = state.userAccounts ?? 0;
    if (accounts > 0) {
      reasons.add(
        '${state.ledger == null ? 'schema_migrations não existe' : 'schema_migrations está vazia'}, '
        'mas users tem $accounts conta(s): não é o banco novo do bootstrap',
      );
    }
  }

  for (final row in ledger) {
    final index = position[row.version];
    if (index == null) {
      reasons.add(
        'a versão ${row.version} (${row.name}) está no ledger e não existe '
        'neste código',
      );
    } else if (code[index].name != row.name) {
      reasons.add(
        'a versão ${row.version} está no ledger como "${row.name}" e neste '
        'código como "${code[index].name}"',
      );
    }
  }

  final lastExecutedIndex = ledger
      .map((row) => position[row.version])
      .whereType<int>()
      .fold<int>(-1, (last, index) => index > last ? index : last);
  for (var index = 0; index < lastExecutedIndex; index++) {
    final migration = code[index];
    if (!executed.contains(migration.version)) {
      reasons.add(
        'a ${migration.version} (${migration.name}) está pendente, mas a '
        '${code[lastExecutedIndex].version}, posterior, já foi executada: o '
        'banco veio de outra linha de código',
      );
    }
  }

  final profile =
      reasons.isNotEmpty
          ? MigrationSourceProfile.misto
          : ledger.isEmpty
          ? MigrationSourceProfile.semLedger
          : MigrationSourceProfile.canonico;
  return MigrationPreflightResult(
    profile: profile,
    reasons: reasons,
    executed: [for (final row in ledger) row.version],
    pending: [
      for (final migration in code)
        if (!executed.contains(migration.version)) migration.version,
    ],
    codeCount: code.length,
    latestInCode: code.isEmpty ? null : code.last.version,
    latestExecuted: ledger.isEmpty ? null : ledger.last.version,
  );
}

/// Lê o ledger e as contas sem escrever: só consultas ao catálogo e SELECT.
Future<MigrationLedgerState> readMigrationLedgerState(Session session) async {
  final ledgerExists =
      (await session.execute(
        "SELECT to_regclass('public.schema_migrations') IS NOT NULL",
      )).single.single ==
      true;
  final ledger =
      ledgerExists
          ? [
            for (final row in await session.execute(
              'SELECT version::text, name::text FROM public.schema_migrations '
              'ORDER BY version',
            ))
              (version: row[0]! as String, name: row[1]! as String),
          ]
          : null;
  final usersExists =
      (await session.execute(
        "SELECT to_regclass('public.users') IS NOT NULL",
      )).single.single ==
      true;
  final accounts =
      usersExists
          ? (await session.execute(
                'SELECT COUNT(*)::int FROM public.users',
              )).single.single!
              as int
          : null;
  return MigrationLedgerState(ledger: ledger, userAccounts: accounts);
}

/// O preflight inteiro, numa transação READ ONLY.
Future<MigrationPreflightResult> runMigrationPreflight(
  Connection connection,
  List<MigrationIdentity> code,
) async {
  final state = await connection.runTx(
    readMigrationLedgerState,
    settings: TransactionSettings(accessMode: AccessMode.readOnly),
  );
  return classifyMigrationSource(code: code, state: state);
}
