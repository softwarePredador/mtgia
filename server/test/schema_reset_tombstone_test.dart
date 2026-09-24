import 'dart:io';

import 'package:test/test.dart';

/// BT-DB-004 (D-48): os resets destrutivos de schema falham fechado quando
/// executados, e o `--full` do extrator de insights exige aprovação antes de
/// abrir a conexão.
///
/// Os binários rodam de verdade. O banco apontado é uma porta local fechada:
/// um entrypoint que tentasse conectar sairia com outro código e outra
/// mensagem.
void main() {
  const closedDatabase = {
    'DB_HOST': '127.0.0.1',
    'DB_PORT': '1',
    'DB_NAME': 'banco_que_nao_existe',
    'DB_USER': 'ninguem',
    'DB_PASS': 'nada',
    'DB_CONNECT_TIMEOUT_SECONDS': '2',
    'ENVIRONMENT': 'development',
  };

  Future<ProcessResult> run(
    String script, [
    List<String> args = const [],
    Map<String, String> environment = const {},
  ]) => Process.run(
    Platform.resolvedExecutable,
    ['bin/$script', ...args],
    environment: {...closedDatabase, ...environment},
  ).timeout(const Duration(minutes: 2));

  for (final script in const ['update_schema.dart', 'setup_database.dart']) {
    test('$script é tombstone: sai com 2, sem conectar', () async {
      final result = await run(script);
      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect('${result.stderr}', contains('BLOCKED:'));
      expect('${result.stderr}', contains('bin/migrate.dart'));
      expect('${result.stdout}', isEmpty);

      final source = File('bin/$script').readAsStringSync();
      expect(source, isNot(contains('lib/database.dart')));
      expect(source, isNot(contains('database_setup.sql\')')));
      expect(source, isNot(contains('execute(')));
      expect(source, isNot(contains('Database(')));
    });
  }

  test(
    'extract_meta_insights --full sem aprovação para antes de conectar',
    () async {
      final result = await run('extract_meta_insights.dart', ['--full']);
      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect('${result.stderr}', contains('BLOCKED: --full apaga'));
      expect('${result.stderr}', contains('Nenhuma conexão foi aberta.'));
      expect('${result.stdout}', isNot(contains('Carregando meta decks')));
    },
  );

  test('extract_meta_insights --full com outra frase também para', () async {
    final result = await run(
      'extract_meta_insights.dart',
      ['--full'],
      {'MANALOOM_CONFIRM_POSTGRES_WRITES': 'sim'},
    );
    expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
    expect('${result.stderr}', contains('BLOCKED: --full apaga'));
  });

  test('o TRUNCATE do --full só existe depois do bloqueio de aprovação', () {
    final source = File('bin/extract_meta_insights.dart').readAsStringSync();
    final gate = source.indexOf('BLOCKED: --full apaga');
    final connect = source.indexOf('await db.connect()');
    final truncate = source.indexOf('TRUNCATE card_meta_insights');
    expect(gate, greaterThan(0));
    expect(connect, greaterThan(gate));
    expect(truncate, greaterThan(connect));
  });
}
