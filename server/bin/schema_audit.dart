// Auditoria somente leitura do schema (BT-DB-001).
//
// Compara um banco-alvo com um banco-base criado do zero pelas migrations
// (server/database_setup.sql mais as migrations, num PostgreSQL descartável)
// e grava as diferenças, classificadas em faltando, sobrando e divergente,
// em JSON e Markdown. Não apaga nem altera nada: as duas conexões rodam em
// transação READ ONLY e só leem o catálogo.
//
// Uso:
//   dart bin/schema_audit.dart \
//     --baseline postgres://postgres@127.0.0.1:55439/base \
//     --target postgres://postgres@127.0.0.1:55439/alvo \
//     --json auditoria.json --markdown auditoria.md
//
// Opções: --baseline-label, --target-label, --schemas public,outro,
// --allow-remote (host fora do loopback, sempre com TLS) e --fail-on-diff
// (sai 1 quando há diferença). Senha só por ambiente, em BASELINE_PGPASSWORD
// e TARGET_PGPASSWORD; URL com senha é recusada.
//
// O procedimento reproduzível completo (PostgreSQL descartável, base e alvo
// montado de um dump sem dados) está em scripts/manaloom_schema_audit.sh.

import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/schema_audit/schema_audit.dart';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    stderr.writeln(_usage);
    exitCode = 2;
    return;
  }

  final AuditTarget baselineTarget;
  final AuditTarget targetTarget;
  try {
    // As duas URLs são validadas antes de qualquer conexão.
    baselineTarget = parseAuditTarget(
      options.baseline,
      passwordEnvironment: 'BASELINE_PGPASSWORD',
      allowRemote: options.allowRemote,
    );
    targetTarget = parseAuditTarget(
      options.target,
      passwordEnvironment: 'TARGET_PGPASSWORD',
      allowRemote: options.allowRemote,
    );
  } on AuditUsageException catch (error) {
    stderr.writeln('schema_audit: ${error.message}');
    exitCode = 2;
    return;
  }

  final _InventoryRead baseline;
  final _InventoryRead target;
  try {
    baseline = await _readInventory(
      baselineTarget,
      label: options.baselineLabel,
      password: Platform.environment['BASELINE_PGPASSWORD'],
      schemas: options.schemas,
    );
    target = await _readInventory(
      targetTarget,
      label: options.targetLabel,
      password: Platform.environment['TARGET_PGPASSWORD'],
      schemas: options.schemas,
    );
  } on Object catch (error) {
    stderr.writeln(
      'schema_audit: falha ao ler o catálogo (${error.runtimeType}): $error',
    );
    exitCode = 3;
    return;
  }

  final report = compareSchemaInventories(
    baseline.inventory,
    target.inventory,
    generatedAt: DateTime.now().toUtc(),
    targetSchemaObjectCounts: target.schemaCounts,
  );
  await File(options.jsonPath).writeAsString(report.toJsonText());
  await File(options.markdownPath).writeAsString(report.toMarkdown());

  for (final entry in report.buckets.entries) {
    final counts = entry.value.counts();
    stdout.writeln(
      '${entry.key}: faltando=${counts['faltando']} '
      'sobrando=${counts['sobrando']} divergente=${counts['divergente']}',
    );
  }
  stdout
    ..writeln('json=${options.jsonPath}')
    ..writeln('markdown=${options.markdownPath}');
  if (options.failOnDiff && report.hasDifferences) exitCode = 1;
}

const _usage = '''
uso: dart bin/schema_audit.dart --baseline URL --target URL \\
       --json SAIDA.json --markdown SAIDA.md [--baseline-label NOME] \\
       [--target-label NOME] [--schemas s1,s2] [--allow-remote] [--fail-on-diff]
URL: postgres://usuario@host:porta/banco; senha só por BASELINE_PGPASSWORD e
TARGET_PGPASSWORD.''';

class _Options {
  _Options({
    required this.baseline,
    required this.target,
    required this.jsonPath,
    required this.markdownPath,
    required this.baselineLabel,
    required this.targetLabel,
    required this.schemas,
    required this.allowRemote,
    required this.failOnDiff,
  });

  final String baseline;
  final String target;
  final String jsonPath;
  final String markdownPath;
  final String baselineLabel;
  final String targetLabel;
  final Set<String>? schemas;
  final bool allowRemote;
  final bool failOnDiff;
}

class _InventoryRead {
  _InventoryRead(this.inventory, this.schemaCounts);

  final SchemaInventory inventory;
  final Map<String, Map<String, int>> schemaCounts;
}

_Options? _parseArgs(List<String> args) {
  const flags = {'--allow-remote', '--fail-on-diff'};
  const valued = {
    '--baseline',
    '--target',
    '--json',
    '--markdown',
    '--baseline-label',
    '--target-label',
    '--schemas',
  };
  final values = <String, String>{};
  final seenFlags = <String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (flags.contains(arg)) {
      seenFlags.add(arg);
    } else if (valued.contains(arg) && i + 1 < args.length) {
      values[arg] = args[++i];
    } else {
      return null;
    }
  }
  final baseline = values['--baseline'];
  final target = values['--target'];
  final jsonPath = values['--json'];
  final markdownPath = values['--markdown'];
  if (baseline == null ||
      target == null ||
      jsonPath == null ||
      markdownPath == null) {
    return null;
  }
  final schemas =
      values['--schemas']
          ?.split(',')
          .map((schema) => schema.trim())
          .where((schema) => schema.isNotEmpty)
          .toSet();
  return _Options(
    baseline: baseline,
    target: target,
    jsonPath: jsonPath,
    markdownPath: markdownPath,
    baselineLabel: values['--baseline-label'] ?? 'base',
    targetLabel: values['--target-label'] ?? 'alvo',
    schemas: schemas == null || schemas.isEmpty ? null : schemas,
    allowRemote: seenFlags.contains('--allow-remote'),
    failOnDiff: seenFlags.contains('--fail-on-diff'),
  );
}

Future<_InventoryRead> _readInventory(
  AuditTarget target, {
  required String label,
  required String? password,
  required Set<String>? schemas,
}) async {
  final connection = await Connection.open(
    Endpoint(
      host: target.host,
      port: target.port,
      database: target.database,
      username: target.username,
      password: password,
    ),
    settings: ConnectionSettings(
      sslMode: target.loopback ? SslMode.disable : SslMode.require,
    ),
  );
  try {
    return await connection.runTx(
      (session) => _inventory(session, label: label, schemas: schemas),
      settings: TransactionSettings(accessMode: AccessMode.readOnly),
    );
  } finally {
    await connection.close();
  }
}

/// Schemas do usuário: tudo fora de `pg_catalog`, `information_schema` e
/// dos schemas internos `pg_*` (toast, temporários).
const _userSchema = r'''
  n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname !~ '^pg_'
''';

Future<_InventoryRead> _inventory(
  Session session, {
  required String label,
  required Set<String>? schemas,
}) async {
  await session.execute("SET LOCAL statement_timeout = '120s'");
  final database =
      (await session.execute('SELECT current_database()')).single.single!
          as String;
  final version =
      (await session.execute('SHOW server_version')).single.single! as String;
  bool inScope(String schema) => schemas == null || schemas.contains(schema);

  final allSchemas = <String>{
    for (final row in await session.execute(
      'SELECT n.nspname FROM pg_namespace n WHERE $_userSchema',
    ))
      if (inScope(row[0]! as String)) row[0]! as String,
  };

  final counts = <String, Map<String, int>>{};
  void count(String schema, String kind) {
    final bucket = counts.putIfAbsent(schema, () => <String, int>{});
    bucket[kind] = (bucket[kind] ?? 0) + 1;
  }

  final tables = <String>{};
  for (final row in await session.execute('''
    SELECT n.nspname, c.relname
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'p') AND $_userSchema
  ''')) {
    final schema = row[0]! as String;
    if (!inScope(schema)) continue;
    tables.add('$schema.${row[1]}');
    count(schema, 'tabelas');
  }

  final views = <String, String>{};
  for (final row in await session.execute('''
    SELECT n.nspname, c.relname, c.relkind::text, pg_get_viewdef(c.oid, true)
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('v', 'm') AND $_userSchema
  ''')) {
    final schema = row[0]! as String;
    if (!inScope(schema)) continue;
    final kind = row[2] == 'm' ? 'MATERIALIZED VIEW' : 'VIEW';
    views['$schema.${row[1]}'] = '$kind: ${row[3]}';
    count(schema, 'views');
  }

  final columns = <String, ColumnShape>{};
  for (final row in await session.execute('''
    SELECT n.nspname, c.relname, a.attname,
           format_type(a.atttypid, a.atttypmod), a.attnotnull,
           pg_get_expr(d.adbin, d.adrelid), a.attidentity::text,
           a.attgenerated::text
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
      AND $_userSchema
  ''')) {
    final schema = row[0]! as String;
    if (!inScope(schema)) continue;
    final identity = (row[6] as String?) ?? '';
    final generated = (row[7] as String?) ?? '';
    final expression = row[5] as String?;
    columns['$schema.${row[1]}.${row[2]}'] = ColumnShape(
      type: row[3]! as String,
      notNull: row[4]! as bool,
      defaultExpression:
          identity.isNotEmpty
              ? 'IDENTITY ${identity == 'a' ? 'ALWAYS' : 'BY DEFAULT'}'
              : generated.isNotEmpty
              ? 'GENERATED ALWAYS AS ($expression) STORED'
              : expression,
    );
    count(schema, 'colunas');
  }

  final foreignKeys = <String, ForeignKeyShape>{};
  for (final row in await session.execute('''
    SELECT n.nspname, c.relname, con.conname,
           pg_get_constraintdef(con.oid, true)
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE con.contype = 'f' AND $_userSchema
    ORDER BY 1, 2, 3
  ''')) {
    final schema = row[0]! as String;
    if (!inScope(schema)) continue;
    final definition = row[3]! as String;
    var key = foreignKeySignature('$schema.${row[1]}', definition);
    if (foreignKeys.containsKey(key)) key = '$key [duplicada: ${row[2]}]';
    foreignKeys[key] = ForeignKeyShape(
      name: row[2]! as String,
      definition: definition,
    );
    count(schema, 'chaves_estrangeiras');
  }

  final indexes = <String, IndexShape>{};
  for (final row in await session.execute('''
    SELECT n.nspname, t.relname, i.relname, pg_get_indexdef(i.oid)
    FROM pg_index x
    JOIN pg_class i ON i.oid = x.indexrelid
    JOIN pg_class t ON t.oid = x.indrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE $_userSchema
  ''')) {
    final schema = row[0]! as String;
    if (!inScope(schema)) continue;
    indexes['$schema.${row[2]}'] = IndexShape(
      table: '$schema.${row[1]}',
      definition: normalizeIndexDefinition(row[3]! as String),
    );
    count(schema, 'indices');
  }

  Map<String, String>? migrations;
  final ledgerExists =
      (await session.execute(
        "SELECT to_regclass('public.schema_migrations') IS NOT NULL",
      )).single.single ==
      true;
  if (ledgerExists && inScope('public')) {
    migrations = {
      for (final row in await session.execute(
        'SELECT version::text, name::text FROM public.schema_migrations',
      ))
        row[0]! as String: row[1]! as String,
    };
  }

  return _InventoryRead(
    SchemaInventory(
      label: label,
      database: database,
      serverVersion: version,
      schemas: allSchemas,
      tables: tables,
      views: views,
      columns: columns,
      foreignKeys: foreignKeys,
      indexes: indexes,
      migrations: migrations,
    ),
    counts,
  );
}
