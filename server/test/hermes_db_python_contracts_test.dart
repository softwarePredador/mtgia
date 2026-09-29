import 'dart:io';

import 'package:test/test.dart';

/// BT-AI-030: os testes Python do `db_helper` do Hermes e do sync do
/// deck-alvo rodam com a suíte do servidor, como os contratos Python do
/// expurgo e do alimentador (`hermes_learning_purge_test.dart`). A suíte roda
/// no `full` do gate local (`quality_gate.sh full`, testes do backend) e em
/// todo commit da frente.
///
/// Os dois arquivos contra PostgreSQL pulam sem `RUN_HERMES_*=1` e sem
/// `DATABASE_URL` em loopback; aqui as chaves vão vazias de propósito, para
/// que o teste nunca toque num banco.
void main() {
  const scriptsDir = '../docs/hermes-analysis/manaloom-knowledge/scripts';
  const contracts = [
    'test_db_helper.py',
    'test_db_helper_pg_live.py',
    'test_sync_pg_target_deck_to_hermes.py',
    'test_sync_pg_target_deck_to_hermes_pg_live.py',
  ];

  test('os testes Python do db_helper e do sync do deck-alvo passam', () async {
    for (final contract in contracts) {
      expect(
        File('$scriptsDir/$contract').existsSync(),
        isTrue,
        reason: contract,
      );
    }
    final result = await Process.run(
      'python3',
      ['-m', 'unittest', ...contracts],
      workingDirectory: scriptsDir,
      environment: const {
        'PYTHONDONTWRITEBYTECODE': '1',
        'PYTHONWARNINGS': 'error::ResourceWarning',
        'RUN_HERMES_DB_HELPER_PG_TESTS': '',
        'RUN_HERMES_TARGET_DECK_PG_TESTS': '',
        'DATABASE_URL': '',
        'MANALOOM_POSTGRES_ENV': '',
        'MANALOOM_CONFIRM_POSTGRES_READS': '',
        'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
      },
    );
    final output = '${result.stdout}\n${result.stderr}';
    expect(result.exitCode, 0, reason: output);
    // Os dois arquivos contra PostgreSQL pulam como classe inteira.
    expect(output, contains('OK (skipped=2)'), reason: output);
  });
}
