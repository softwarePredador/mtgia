import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

/// Banco descartável para os scripts do lote de deploy (`server/sql/lote/`).
///
/// Os testes de banco recebem em `DB_*` um PostgreSQL descartável em loopback,
/// migrado do zero (`database_setup.sql` e `bin/migrate.dart`). Cada cenário roda
/// numa cópia dele (`CREATE DATABASE ... TEMPLATE`), apagada no fim, porque os
/// scripts do lote fazem `COMMIT` de verdade. O script roda pelo `psql`, com os
/// mesmos argumentos do lote, e nunca por uma reescrita em Dart.
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
  /// `ON_ERROR_STOP`, saída sem alinhamento e separada por TAB.
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
