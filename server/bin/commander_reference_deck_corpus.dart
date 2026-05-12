import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    'test/artifacts/commander_reference_deck_corpus_2026-05-12';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final corpusPath = _readArg(args, '--corpus-json=');
  if (corpusPath == null || corpusPath.trim().isEmpty) {
    throw ArgumentError('Informe --corpus-json=<arquivo>.');
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }

  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final payload = _readJsonObject(corpusPath);
  final decks = parseCommanderReferenceDeckCorpus(payload);
  if (decks.isEmpty) throw ArgumentError('Nenhum deck no corpus.');

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final analyses = await analyzeCommanderReferenceDecks(
      pool: pool,
      decks: decks,
    );
    if (apply) {
      final rejected =
          analyses.where((analysis) => !analysis.accepted).toList();
      if (rejected.isNotEmpty) {
        throw StateError(
          'Corpus contem decks rejeitados; corrija antes do --apply: '
          '${rejected.map((a) => '${a.deck.sourceDeckKey}:${a.rejectionReasons.join('|')}').join(', ')}',
        );
      }
      await ensureCommanderReferenceDeckCorpusTables(pool);
      await upsertCommanderReferenceDeckCorpus(pool, analyses);
    }

    final summariesByCommander = <String, CommanderReferenceCorpusSummary>{};
    for (final commander in analyses.map((a) => a.deck.commanderName).toSet()) {
      final commanderAnalyses = analyses
          .where((analysis) => analysis.deck.commanderName == commander)
          .toList(growable: false);
      summariesByCommander[commander] =
          summarizeCommanderReferenceDeckCorpus(commanderAnalyses);
    }

    final safeName = _safeFileName(decks.first.commanderName);
    final outputPath =
        '${artifactDir.path}/${safeName}_${dryRun ? 'dry_run' : 'apply'}_summary.json';
    final summary = {
      'status': analyses.every((analysis) => analysis.accepted)
          ? 'PASS'
          : 'PASS_WITH_RISKS',
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'artifact_dir': artifactDir.path,
      'deck_count': analyses.length,
      'accepted_deck_count':
          analyses.where((analysis) => analysis.accepted).length,
      'rejected_deck_count':
          analyses.where((analysis) => !analysis.accepted).length,
      'analyses': analyses.map((analysis) => analysis.toJson()).toList(),
      'aggregate': summariesByCommander.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'safety': {
        'no_scraping': true,
        'no_copied_decklist_runtime_generation': true,
        'apply_requires_all_decks_accepted': true,
        'scanner_camera_ocr_mlkit_out_of_scope': true,
      },
    };
    await _writeJson(outputPath, summary);
    print(jsonEncode({
      'status': summary['status'],
      'mode': summary['mode'],
      'db_mutations': apply,
      'deck_count': summary['deck_count'],
      'accepted_deck_count': summary['accepted_deck_count'],
      'rejected_deck_count': summary['rejected_deck_count'],
      'artifact': outputPath,
    }));
  } finally {
    await database.close();
  }
}

Map<String, dynamic> _readJsonObject(String path) {
  final file = File(path);
  if (!file.existsSync()) throw ArgumentError('Arquivo nao encontrado: $path');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return decoded.cast<String, dynamic>();
  throw ArgumentError('corpus-json precisa ser objeto JSON.');
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

String _safeFileName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
Usage:
  dart run bin/commander_reference_deck_corpus.dart --corpus-json=<path> --dry-run
  dart run bin/commander_reference_deck_corpus.dart --corpus-json=<path> --apply

Formato minimo:
{
  "commander": "Lorehold, the Historian",
  "decks": [
    {
      "source": "manual_reference_deck_v1",
      "source_url": "https://example.test/deck/1",
      "power_lane": "casual_high_power",
      "theme": "topdeck_big_spells",
      "cards": [
        {"name": "Lorehold, the Historian", "quantity": 1, "board": "commander"},
        {"name": "Plains", "quantity": 20, "board": "main"}
      ]
    }
  ]
}

O --apply exige todos os decks aceitos: comandante resolvido, commander=1,
main=99, unresolved=0, off_color=0 e sem violacao singleton fora de terrenos
basicos.
''');
}
