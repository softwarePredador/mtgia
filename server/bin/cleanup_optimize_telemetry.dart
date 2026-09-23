// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../lib/database.dart';
import '../lib/privacy/retention_cleanup.dart';

/// Limpeza por prazo (D-70), agendada pelo `manaloom_ops_daemon.py` como
/// `manaloom_ai_runtime_cleanup`, sem capability.
///
/// Os prazos vêm do inventário de retenção (`retentionCleanupRules`); não há
/// flag nem variável de ambiente que os encurte.
///
/// Uso:
///   dart run bin/cleanup_optimize_telemetry.dart                 # agendado
///   dart run bin/cleanup_optimize_telemetry.dart --mode dry-run  # só conta
///   MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
///     dart run bin/cleanup_optimize_telemetry.dart --mode activate
///   MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
///     dart run bin/cleanup_optimize_telemetry.dart --mode deactivate
///
/// Toda execução deixa o recibo `MANALOOM_RETENTION_CLEANUP {json}` no
/// stdout e, com `--output-dir` ou `MANALOOM_RETENTION_CLEANUP_OUTPUT_DIR`, o
/// mesmo JSON num arquivo. Saída 0: concluída; 2: argumento inválido; 3: modo
/// supervisionado sem a aprovação; 4: outra execução em andamento; 1: erro.
Future<void> main(List<String> args) async {
  final parsed = parseRetentionCleanupArguments(args);
  if (parsed == null) {
    stderr.writeln(
      'uso: cleanup_optimize_telemetry.dart '
      '[--mode scheduled|activate|deactivate|dry-run] [--output-dir <dir>]. '
      'Os prazos vêm do inventário de retenção (D-70); não há flag de prazo.',
    );
    exitCode = 2;
    return;
  }
  final (mode, outputDirOption) = parsed;
  final outputDir =
      outputDirOption ??
      Platform.environment['MANALOOM_RETENTION_CLEANUP_OUTPUT_DIR'];
  final runId = _runId();
  final database = Database();
  Map<String, dynamic> receipt;
  try {
    if (mode.requiresWriteApproval &&
        Platform.environment[retentionCleanupWriteApprovalEnvironment] !=
            retentionCleanupWriteApprovalValue) {
      throw RetentionCleanupRefused(mode);
    }
    await database.connect();
    receipt = await RetentionCleanupRunner(
      database.connection,
    ).run(mode: mode, runId: runId, environment: Platform.environment);
    if (receipt['status'] == 'busy') exitCode = 4;
  } on RetentionCleanupRefused catch (error) {
    stderr.writeln(error);
    receipt = _stopped(runId, mode, 'refused');
    exitCode = 3;
  } catch (error) {
    stderr.writeln('retention cleanup: ${error.runtimeType}');
    receipt = _stopped(runId, mode, 'error');
    exitCode = 1;
  } finally {
    if (database.isConnected) await database.close();
  }
  print(retentionCleanupReceiptLine(receipt));
  if (outputDir != null && outputDir.isNotEmpty) {
    final directory = Directory(outputDir)..createSync(recursive: true);
    File('${directory.path}/retention_cleanup_$runId.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    );
  }
}

Map<String, dynamic> _stopped(
  String runId,
  RetentionCleanupMode mode,
  String status,
) => {
  'schema': retentionCleanupReceiptSchema,
  'contract': retentionCleanupContract,
  'job': retentionCleanupJobName,
  'run_id': runId,
  'mode': mode.wireName,
  'finished_at': DateTime.now().toUtc().toIso8601String(),
  'status': status,
  'applied': false,
};

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
