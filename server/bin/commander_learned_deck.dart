import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:server/database.dart';

const _defaultArtifactDir = 'test/artifacts/commander_learned_deck_import';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final inputPath = _readArg(args, '--input-json=');
  if (inputPath == null || inputPath.trim().isEmpty) {
    throw ArgumentError('Informe --input-json=<arquivo>.');
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }
  final deactivateOtherActive = !args.contains('--keep-other-active');

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir,
  );
  await artifactDir.create(recursive: true);

  final payload = _readJsonObject(inputPath);
  final input = parseCommanderLearnedDeckInput(payload);
  final startedAt = DateTime.now().toUtc();

  final database = Database();
  await database.connect();
  final pool = database.connection;

  try {
    if (apply) {
      await ensureCommanderLearnedDecksTable(pool);
      await upsertCommanderLearnedDeck(
        pool,
        input,
        deactivateOtherActive: deactivateOtherActive,
      );
    }

    final summary = {
      'status': 'PASS',
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'commander': input.commanderName,
      'commander_name_normalized': input.commanderNameNormalized,
      'deck_name': input.deckName,
      'source_system': input.sourceSystem,
      'source_ref': input.sourceRef,
      'card_count': input.cardCount,
      'parsed_card_count': input.cards.fold<int>(
        0,
        (sum, card) => sum + card.quantity,
      ),
      'is_active': input.isActive,
      'deactivate_other_active': deactivateOtherActive,
      'metadata': input.metadata,
      'safety': {
        'idempotent_key': 'source_system+source_ref',
        'no_secrets_recorded': true,
        'dry_run_default': true,
      },
    };
    final safeName = input.commanderNameNormalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final outputPath =
        '${artifactDir.path}/${safeName}_${input.sourceRef.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_${dryRun ? 'dry_run' : 'apply'}_summary.json';
    await _writeJson(outputPath, summary);
    print(jsonEncode({
      'status': summary['status'],
      'mode': summary['mode'],
      'db_mutations': summary['db_mutations'],
      'commander': summary['commander'],
      'source_ref': summary['source_ref'],
      'card_count': summary['card_count'],
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
  throw ArgumentError('input-json precisa ser objeto JSON.');
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
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
  dart run bin/commander_learned_deck.dart --input-json=<path> --dry-run
  dart run bin/commander_learned_deck.dart --input-json=<path> --apply

Options:
  --keep-other-active      Nao desativa outros decks ativos do mesmo comandante.
  --artifact-dir=<path>    Diretorio para resumo sanitizado.

Formato minimo:
{
  "source_system": "hermes",
  "source_ref": "learned_deck:82",
  "commander_name": "Lorehold, the Historian",
  "deck_name": "Lorehold Best-of Learned No Premium Mox 2026-06-02",
  "card_list": "1 Lorehold, the Historian\\n1 Sol Ring\\n...",
  "card_count": 100,
  "is_active": true
}

Tambem aceita payload bruto Hermes com campos "id" e "commander".
''');
}
