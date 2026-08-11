import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_reference_readiness_cli_support.dart';
import 'package:server/ai/commander_reference_readiness_support.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    '/tmp/manaloom_commander_reference_readiness_scorecard';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final selection = parseCommanderReferenceReadinessSelection(args);

  final artifactDir = Directory(
    resolveCommanderReferenceReadinessArtifactDir(args),
  );
  await artifactDir.create(recursive: true);
  final runtimeSummaryPath = _readArg(args, '--runtime-summary=');
  final runtimeProof =
      runtimeSummaryPath == null
          ? null
          : parseCommanderReferenceReadinessRuntimeProof(
            _readJsonObject(runtimeSummaryPath),
          );

  final database = Database();
  await database.connect();
  final startedAt = DateTime.now().toUtc();

  try {
    final commanders =
        selection.allActiveProfiles
            ? await discoverActiveUsableCommanderReferenceProfiles(
              query: (sql) async {
                final rows = await database.connection.execute(sql);
                return <Object?>[for (final row in rows) row[0]];
              },
            )
            : selection.commanders;
    if (commanders.isEmpty) {
      throw StateError(
        'Nenhum commander com profile persistido e confidence >= medium.',
      );
    }

    final scorecards = <Map<String, dynamic>>[];
    for (final commander in commanders) {
      final scorecard = await buildCommanderReferenceReadinessScorecard(
        pool: database.connection,
        commanderName: commander,
        runtimeProof: runtimeProof,
      );
      scorecards.add(scorecard.toJson());
    }

    final summary = {
      'status':
          scorecards.every((card) => card['expansion_ready'] == true)
              ? 'PASS'
              : 'PASS_WITH_RISKS',
      'version': commanderReferenceReadinessVersion,
      'mode': 'read_only_scorecard',
      'db_mutations': false,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'artifact_dir': artifactDir.path,
      'commander_count': scorecards.length,
      'ready_count':
          scorecards.where((card) => card['expansion_ready'] == true).length,
      'scorecards': scorecards,
      'safety': {
        'no_runtime_code_changes': true,
        'no_decklists_recorded': true,
        'no_secrets_recorded': true,
        'scanner_camera_ocr_mlkit_out_of_scope': true,
      },
    };

    final outputPath = '${artifactDir.path}/readiness_scorecard_summary.json';
    await _writeJson(outputPath, summary);
    print(
      jsonEncode({
        'status': summary['status'],
        'commander_count': summary['commander_count'],
        'ready_count': summary['ready_count'],
        'artifact': outputPath,
        'scorecards': [
          for (final card in scorecards)
            {
              'commander_name': card['commander_name'],
              'score': card['score'],
              'status': card['status'],
              'expansion_ready': card['expansion_ready'],
              'blockers': card['blockers'],
              'warnings': card['warnings'],
            },
        ],
      }),
    );
  } finally {
    await database.close();
  }
}

Map<String, dynamic> _readJsonObject(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError('Arquivo nao encontrado: $path');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return decoded.cast<String, dynamic>();
  throw ArgumentError('JSON precisa ser objeto: $path');
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

String resolveCommanderReferenceReadinessArtifactDir(List<String> args) {
  return _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir;
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
Usage:
  dart run bin/commander_reference_readiness_scorecard.dart --commander="Lorehold, the Historian"
  dart run bin/commander_reference_readiness_scorecard.dart --commanders="Lorehold, the Historian;Dina, Soul Steeper"
  dart run bin/commander_reference_readiness_scorecard.dart --all-active-profiles
  dart run bin/commander_reference_readiness_scorecard.dart --commander="Lorehold, the Historian" --runtime-summary=test/artifacts/.../summary.json
  dart run bin/commander_reference_readiness_scorecard.dart --commander="Lorehold, the Historian" --artifact-dir=/path/to/output

Read-only scorecard. No database mutations.
Selection modes are mutually exclusive. --all-active-profiles selects persisted profiles with confidence >= medium.
Default output: $_defaultArtifactDir
''');
}
