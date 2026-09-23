// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../lib/database.dart';
import '../lib/privacy/account_deletion_outbox.dart';

/// D-68 (BT-PRIV-002): consome o outbox da exclusão de conta uma vez.
///
/// Roda na imagem de ops, agendado pelo `manaloom_ops_daemon.py` como
/// `manaloom_account_deletion_outbox`, sem capability. Toda execução deixa um
/// recibo sem identificador: a linha `MANALOOM_ACCOUNT_DELETION_OUTBOX {json}`
/// no stdout e o mesmo JSON em `--output-dir`
/// (`MANALOOM_ACCOUNT_DELETION_OUTBOX_OUTPUT_DIR`), quando definido.
///
/// Saída 0: execução concluída. Saída 2: a tabela não existe (a migration 060
/// não foi aplicada). Saída 1: erro.
Future<void> main(List<String> args) async {
  final outputDir =
      _option(args, '--output-dir') ??
      Platform.environment['MANALOOM_ACCOUNT_DELETION_OUTBOX_OUTPUT_DIR'];
  final runId = _runId();
  final database = Database();
  Map<String, dynamic> receipt;
  try {
    await database.connect();
    receipt = await AccountDeletionOutboxWorker(
      database.connection,
    ).runOnce(runId: runId);
  } on AccountDeletionOutboxMissing catch (error) {
    stderr.writeln(error);
    receipt = _stopped(runId, 'outbox_missing');
    exitCode = 2;
  } catch (error) {
    stderr.writeln('account_deletion_outbox: ${error.runtimeType}');
    receipt = _stopped(runId, 'error');
    exitCode = 1;
  } finally {
    if (database.isConnected) await database.close();
  }
  print(accountDeletionOutboxReceiptLine(receipt));
  if (outputDir != null && outputDir.isNotEmpty) {
    final directory = Directory(outputDir)..createSync(recursive: true);
    File(
      '${directory.path}/account_deletion_outbox_$runId.json',
    ).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    );
  }
}

Map<String, dynamic> _stopped(String runId, String status) => {
  'schema': accountDeletionOutboxReceiptSchema,
  'contract': accountDeletionOutboxContract,
  'run_id': runId,
  'finished_at': DateTime.now().toUtc().toIso8601String(),
  'status': status,
};

String? _option(List<String> args, String name) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == name && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

String _runId() {
  final random = Random.secure();
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[^0-9]'),
    '',
  );
  final suffix =
      List.generate(
        6,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  return '${stamp.substring(0, 14)}_$suffix';
}
