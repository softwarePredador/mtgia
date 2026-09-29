import 'dart:io';

import 'package:test/test.dart';

/// D-83 (item 4 do `BT-AI-029`): o job de sync de combos está pausado.
///
/// `card_combos` e `combo_cards` ficaram sem consumidor quando
/// `POST /ai/weakness-analysis` saiu na D-31. Nenhum agendador do código chama
/// `bin/cron_sync_combos.sh`, e o próprio script só roda com
/// `MANALOOM_COMBO_SYNC_AUTHORIZED=1`: um agendamento de fora do código vira
/// um recibo de pausa, sem baixar o bulk e sem tocar o banco.
void main() {
  late Directory fakeBin;
  late File calls;

  setUp(() {
    // Um `dart` falso no PATH registra se o script tentou rodar o sync.
    fakeBin = Directory.systemTemp.createTempSync('combo_sync_pause_');
    calls = File('${fakeBin.path}/dart_chamado');
    final fakeDart = File('${fakeBin.path}/dart')
      ..writeAsStringSync(
        '#!/bin/sh\nprintf "%s\\n" "\$*" >> "${calls.path}"\n',
      );
    Process.runSync('chmod', ['+x', fakeDart.path]);
  });

  tearDown(() => fakeBin.deleteSync(recursive: true));

  Future<ProcessResult> run([Map<String, String> extra = const {}]) =>
      Process.run(
        'bash',
        ['bin/cron_sync_combos.sh'],
        environment: {'PATH': '${fakeBin.path}:/usr/bin:/bin', ...extra},
        includeParentEnvironment: false,
      );

  test('sem a autorização, recibo de pausa e nenhum sync', () async {
    final result = await run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final receipt = (result.stdout as String).trim();
    expect(receipt, contains('"job":"cron_sync_combos"'));
    expect(receipt, contains('"status":"paused"'));
    expect(receipt, contains('"decision":"D-83"'));
    expect(calls.existsSync(), isFalse, reason: 'o sync não pode rodar');
  });

  test('a autorização precisa ser exatamente 1', () async {
    for (final value in const ['', '0', 'true', 'yes', ' 1', '11']) {
      final result = await run({'MANALOOM_COMBO_SYNC_AUTHORIZED': value});
      expect(result.exitCode, 0, reason: value);
      expect(result.stdout, contains('"status":"paused"'), reason: value);
      expect(calls.existsSync(), isFalse, reason: value);
    }
  });

  test('com a autorização explícita, o job roda o sync de sempre', () async {
    final result = await run({'MANALOOM_COMBO_SYNC_AUTHORIZED': '1'});
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, isNot(contains('"status":"paused"')));
    expect(calls.readAsStringSync().trim(), 'run bin/sync_combos.dart');
  });

  test('nenhum agendador do código chama o job', () {
    // O daemon de ops escreve o manifesto de jobs a partir de JOBS; o
    // bootstrap do Hermes gerencia os jobs do laboratório; a imagem de ops e
    // o entrypoint da API não agendam nada além deles.
    for (final path in const [
      'bin/manaloom_ops_daemon.py',
      'bin/hermes_lab_cron_bootstrap.py',
      'bin/manaloom_ops_entrypoint.sh',
      'bin/api_with_battle_worker.sh',
      'Dockerfile.manaloom-ops',
      'Dockerfile',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('cron_sync_combos')), reason: path);
      expect(source, isNot(contains('sync_combos.dart')), reason: path);
    }
  });
}
