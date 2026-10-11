import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// Banco descartável para os scripts do lote de deploy (`server/sql/lote/`).
///
/// Os testes de banco recebem em `DB_*` um PostgreSQL descartável em loopback,
/// migrado do zero (`database_setup.sql` e `bin/migrate.dart`). Cada cenário roda
/// numa cópia dele (`CREATE DATABASE ... TEMPLATE`), apagada no fim, porque a
/// gravação dos scripts do lote (`-v aplicar=1`) faz `COMMIT` de verdade. O script
/// roda pelo `psql`, com os mesmos argumentos do lote, e nunca por uma reescrita em
/// Dart. Sem `-v aplicar=1`, o script é a prévia: faz tudo e desfaz (`ROLLBACK`).
///
/// Requer `RUN_LOTE_DB_TESTS=1`; o `psql` vem de `MANALOOM_PSQL_BIN` ou do PATH.
class LoteDatabase {
  LoteDatabase._(this._template);

  static const flag = 'RUN_LOTE_DB_TESTS';
  static bool get enabled => Platform.environment[flag] == '1';
  static String get skipReason =>
      'Requer $flag=1 e PostgreSQL descartavel isolado em loopback.';

  final String _template;
  var _sequence = 0;

  static String get _host => Platform.environment['DB_HOST'] ?? '127.0.0.1';
  static int get _port => int.parse(Platform.environment['DB_PORT'] ?? '5432');
  static String get _user => Platform.environment['DB_USER']!;
  static String get _password => Platform.environment['DB_PASS'] ?? '';
  static String get psqlBin => Platform.environment['MANALOOM_PSQL_BIN'] ?? 'psql';

  static LoteDatabase open() {
    if (!const {'127.0.0.1', 'localhost', '::1'}.contains(_host)) {
      throw StateError('$flag só roda em banco loopback: $_host');
    }
    return LoteDatabase._(Platform.environment['DB_NAME']!);
  }

  static Future<Connection> _connect(String database) => Connection.open(
    Endpoint(
      host: _host,
      port: _port,
      database: database,
      username: _user,
      password: _password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  /// Uma cópia nova do banco migrado.
  Future<LoteCopy> copy(String label) async {
    _sequence++;
    final name = 'lote_${label}_${pid}_$_sequence';
    final admin = await _connect('postgres');
    try {
      await admin.execute('DROP DATABASE IF EXISTS "$name"');
      await admin.execute('CREATE DATABASE "$name" TEMPLATE "$_template"');
    } finally {
      await admin.close();
    }
    return LoteCopy._(name, await _connect(name));
  }
}

class LoteCopy {
  LoteCopy._(this.name, this.connection);

  final String name;
  final Connection connection;
  Pool? _pool;

  /// Um `Pool` da cópia, para chamar uma rota de verdade.
  Pool pool() => _pool ??= Pool.withEndpoints(
    [
      Endpoint(
        host: LoteDatabase._host,
        port: LoteDatabase._port,
        database: name,
        username: LoteDatabase._user,
        password: LoteDatabase._password,
      ),
    ],
    settings: const PoolSettings(
      sslMode: SslMode.disable,
      maxConnectionCount: 1,
    ),
  );

  /// Roda um arquivo de `server/sql/lote/` como no lote: `psql -X`,
  /// `ON_ERROR_STOP`, saída sem alinhamento e separada por TAB. Sem a variável
  /// `aplicar`, é a prévia.
  Future<PsqlRun> runScript(
    String fileName, {
    Map<String, String> variables = const {},
    bool tabular = true,
  }) async {
    final result = await Process.run(
      LoteDatabase.psqlBin,
      [
        '-X',
        '-v',
        'ON_ERROR_STOP=1',
        for (final entry in variables.entries) ...[
          '-v',
          '${entry.key}=${entry.value}',
        ],
        if (tabular) ...['-At', '-F', '\t'],
        '-f',
        'sql/lote/$fileName',
      ],
      environment: {
        'PGHOST': LoteDatabase._host,
        'PGPORT': '${LoteDatabase._port}',
        'PGUSER': LoteDatabase._user,
        'PGPASSWORD': LoteDatabase._password,
        'PGDATABASE': name,
        'PGAPPNAME': 'manaloom-lote-test',
      },
      stdoutEncoding: null,
      stderrEncoding: utf8,
    );
    return PsqlRun(
      result.exitCode,
      result.stdout as List<int>,
      result.stderr as String,
    );
  }

  /// A gravação de um script do lote, como depois da prévia: `-v aplicar=1` e,
  /// para cada objeto da ação, `-v esperado_<objeto>=<n>`.
  Future<PsqlRun> applyScript(
    String fileName, {
    required Map<String, String> expected,
    Map<String, String> variables = const {},
  }) => runScript(
    fileName,
    variables: {
      ...variables,
      'aplicar': '1',
      for (final entry in expected.entries)
        'esperado_${entry.key}': entry.value,
    },
  );

  /// Impressão digital do schema `public`: relações, restrições (com a
  /// definição e se está validada), tipos e as linhas de cada tabela. Igual
  /// antes e depois quer dizer que nada foi gravado.
  Future<String> fingerprint() async {
    final result = await sql(r"""
      SELECT md5(COALESCE(string_agg(item, E'\n' ORDER BY item), ''))
      FROM (
        SELECT 'rel:' || c.relname::text || ':' || c.relkind::text AS item
        FROM pg_class c
        WHERE c.relnamespace = 'public'::regnamespace
        UNION ALL
        SELECT 'con:' || r.conrelid::regclass::text || ':' || r.conname::text || ':'
               || r.convalidated::text || ':' || pg_get_constraintdef(r.oid)
        FROM pg_constraint r
        WHERE r.connamespace = 'public'::regnamespace
        UNION ALL
        SELECT 'type:' || t.typname::text
        FROM pg_type t
        WHERE t.typnamespace = 'public'::regnamespace
        UNION ALL
        SELECT 'rows:' || c.relname::text || ':' || (
                 xpath(
                   '/row/h/text()',
                   query_to_xml(
                     format(
                       'SELECT md5(COALESCE(string_agg(t::text, E''\n'' '
                       'ORDER BY t::text), '''')) AS h FROM %I.%I t',
                       'public', c.relname
                     ),
                     false, true, ''
                   )
                 )
               )[1]::text
        FROM pg_class c
        WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('r', 'p')
      ) items
    """);
    return result.single[0] as String;
  }

  Future<Result> sql(String statement, [Map<String, Object?>? parameters]) =>
      connection.execute(
        parameters == null ? statement : Sql.named(statement),
        parameters: parameters,
      );

  Future<int> count(String statement, [Map<String, Object?>? parameters]) async =>
      ((await sql(statement, parameters)).single[0] as num).toInt();

  Future<void> drop() async {
    await _pool?.close();
    await connection.close();
    final admin = await LoteDatabase._connect('postgres');
    try {
      await admin.execute('DROP DATABASE IF EXISTS "$name"');
    } finally {
      await admin.close();
    }
  }
}

class PsqlRun {
  PsqlRun(this.exitCode, this.stdoutBytes, this.stderr);

  final int exitCode;
  final List<int> stdoutBytes;
  final String stderr;

  String get stdout => utf8.decode(stdoutBytes);

  /// As linhas `fase<TAB>objeto<TAB>quantidade` da saída.
  List<(String, String, String)> get rows => [
    for (final line in const LineSplitter().convert(stdout))
      if (line.split('\t') case [final fase, final objeto, final quantidade])
        (fase, objeto, quantidade),
  ];

  /// A quantidade de [objeto] na [fase]; falha se não houver exatamente uma.
  String value(String fase, String objeto) =>
      rows
          .where((row) => row.$1 == fase && row.$2 == objeto)
          .single
          .$3;

  /// As quantidades da fase `acao`, como o operador as lê na prévia para
  /// passar `-v esperado_<objeto>=<n>` na gravação.
  Map<String, String> get actionCounts => {
    for (final row in rows)
      if (row.$1 == 'acao') row.$2: row.$3,
  };

  /// A prévia rodou inteira e foi desfeita.
  bool get previewRolledBack =>
      value('modo', 'escrita') == 'previa' &&
      value('modo', 'desfecho') == 'rollback';

  /// A gravação rodou inteira e foi confirmada.
  bool get appliedCommitted =>
      value('modo', 'escrita') == 'aplicar' &&
      value('modo', 'desfecho') == 'commit';

  @override
  String toString() => 'exit=$exitCode\nstdout:\n$stdout\nstderr:\n$stderr';
}

/// Usuário ativo mínimo para as tabelas que apontam para `users`.
Future<String> insertLoteUser(LoteCopy copy, String handle) async {
  final result = await copy.sql(
    '''
    INSERT INTO users (username, email, password_hash)
    VALUES (@username, @email, 'x')
    RETURNING id::text
    ''',
    {'username': handle, 'email': '$handle@example.test'},
  );
  return result.single[0] as String;
}

/// A gravação recusa, sem gravar nada, quando falta a contagem esperada de algum
/// objeto da ação, quando uma delas não bate (uma a mais em cada objeto, uma de
/// cada vez) e quando `-v aplicar` não é `1`. [expected] são as contagens certas;
/// [refusal] é o prefixo da mensagem (`d85_1 recusado`).
Future<void> expectApplyRefusals(
  LoteCopy copy,
  String fileName, {
  required Map<String, String> expected,
  required String refusal,
  Map<String, String> variables = const {},
}) async {
  final before = await copy.fingerprint();

  final missing = await copy.runScript(
    fileName,
    variables: {...variables, 'aplicar': '1'},
  );
  expect(missing.exitCode, isNot(0), reason: '$missing');
  expect(missing.stderr, contains(refusal));
  expect(missing.stderr, contains('informe -v esperado_'));

  for (final key in expected.keys) {
    final wrong = {
      for (final entry in expected.entries)
        entry.key: entry.key == key
            ? '${int.parse(entry.value) + 1}'
            : entry.value,
    };
    final mismatch = await copy.applyScript(
      fileName,
      expected: wrong,
      variables: variables,
    );
    expect(mismatch.exitCode, isNot(0), reason: '$key: $mismatch');
    expect(mismatch.stderr, contains(refusal), reason: key);
    expect(mismatch.stderr, contains('o esperado'), reason: key);
  }

  final invalid = await copy.runScript(
    fileName,
    variables: {...variables, 'aplicar': 'sim'},
  );
  expect(invalid.exitCode, isNot(0), reason: '$invalid');
  expect(invalid.stderr, contains('-v aplicar aceita só 1'));

  expect(await copy.fingerprint(), before, reason: 'a recusa gravou algo');
}
