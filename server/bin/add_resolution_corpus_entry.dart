#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/database.dart';

const _defaultCorpusPath = 'test/fixtures/optimization_resolution_corpus.json';
const _generatedDeckNameFilters = '''
        AND d.name NOT LIKE 'Optimization Validation - %'
        AND d.name NOT LIKE 'Resolution Validation - %'
        AND d.name NOT LIKE 'Rebuild Draft - %'
        AND d.name NOT LIKE 'Rebuild Preview - %'
''';

class EligibleDeckInfo {
  EligibleDeckInfo({
    required this.deckId,
    required this.deckName,
    required this.commanderName,
    required this.totalCards,
  });

  final String deckId;
  final String deckName;
  final String commanderName;
  final int totalCards;
}

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options.showHelp) {
    _printUsage();
    return;
  }

  if (options.deckId.isEmpty) {
    stderr.writeln('Uso invalido: --deck-id é obrigatório.');
    _printUsage();
    exitCode = 64;
    return;
  }

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    stderr.writeln('Falha ao conectar ao banco.');
    exitCode = 1;
    return;
  }

  try {
    final deckInfo = await _loadEligibleDeckInfo(db.connection, options.deckId);
    if (deckInfo == null) {
      stderr.writeln(
        'Deck ${options.deckId} não é elegível para o corpus de resolução '
        '(Commander, 100 cartas, não deletado, não-gerado).',
      );
      exitCode = 2;
      return;
    }

    final file = File(options.corpusPath);
    if (!file.existsSync()) {
      stderr.writeln('Corpus não encontrado em ${options.corpusPath}.');
      exitCode = 2;
      return;
    }

    final root = _loadCorpus(file);
    final decks = (root['decks'] as List).cast<Map<String, dynamic>>();
    final existingIndex =
        decks.indexWhere((entry) => entry['deck_id']?.toString() == options.deckId);

    if (existingIndex != -1 && !options.replaceExisting) {
      stderr.writeln(
        'Deck ${options.deckId} já existe no corpus. Use --replace para atualizar a entrada.',
      );
      exitCode = 3;
      return;
    }

    final payload = <String, dynamic>{
      'deck_id': options.deckId,
      'label': options.label.isNotEmpty ? options.label : deckInfo.commanderName,
      if (options.expectedFlowPaths.length == 1)
        'expected_flow_path': options.expectedFlowPaths.single,
      if (options.expectedFlowPaths.length > 1)
        'expected_flow_paths': options.expectedFlowPaths,
      if (options.note.isNotEmpty) 'note': options.note,
    };

    if (existingIndex == -1) {
      decks.add(payload);
    } else {
      decks[existingIndex] = payload;
    }

    root['decks'] = decks;
    final pretty = const JsonEncoder.withIndent('  ').convert(root);

    print('=== PREVIEW DA ENTRADA ===');
    print(const JsonEncoder.withIndent('  ').convert(payload));
    print('');
    print('Deck validado:');
    print('- commander: ${deckInfo.commanderName}');
    print('- deck_id: ${deckInfo.deckId}');
    print('- deck_name: ${deckInfo.deckName}');
    print('- total_cards: ${deckInfo.totalCards}');
    print('- corpus_path: ${options.corpusPath}');
    print('- replace_existing: ${options.replaceExisting}');

    if (options.dryRun) {
      print('');
      print('Dry-run ativo: nenhuma alteração foi gravada.');
      return;
    }

    file.writeAsStringSync('$pretty\n');
    print('');
    print('Entrada gravada com sucesso em ${options.corpusPath}.');
  } finally {
    await db.close();
  }
}

Map<String, dynamic> _loadCorpus(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, dynamic>) {
    final decks = decoded['decks'];
    if (decks is List) {
      return {
        ...decoded,
        'decks': decks
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList(),
      };
    }
  }
  throw StateError(
    'Corpus inválido em ${file.path}. Esperado objeto com chave "decks".',
  );
}

Future<EligibleDeckInfo?> _loadEligibleDeckInfo(Pool pool, String deckId) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        d.id::text AS deck_id,
        d.name AS deck_name,
        c.name AS commander_name,
        stats.total_cards
      FROM decks d
      JOIN (
        SELECT deck_id, SUM(quantity)::int AS total_cards
        FROM deck_cards
        GROUP BY deck_id
      ) stats ON stats.deck_id = d.id
      JOIN LATERAL (
        SELECT dc.card_id
        FROM deck_cards dc
        WHERE dc.deck_id = d.id AND dc.is_commander = TRUE
        ORDER BY dc.card_id
        LIMIT 1
      ) cmd ON TRUE
      JOIN cards c ON c.id = cmd.card_id
      WHERE d.id = @deckId
        AND d.deleted_at IS NULL
        AND LOWER(d.format) = 'commander'
        AND stats.total_cards = 100
$_generatedDeckNameFilters
      LIMIT 1
    '''),
    parameters: {'deckId': deckId},
  );

  if (result.isEmpty) return null;
  final row = result.first;
  return EligibleDeckInfo(
    deckId: row[0] as String,
    deckName: row[1] as String? ?? 'Commander Deck',
    commanderName: row[2] as String? ?? 'Unknown Commander',
    totalCards: row[3] as int? ?? 0,
  );
}

_CliOptions _parseArgs(List<String> args) {
  var deckId = '';
  var corpusPath = _defaultCorpusPath;
  var label = '';
  var note = '';
  final expectedFlowPaths = <String>[];
  var dryRun = false;
  var replaceExisting = false;
  var showHelp = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      showHelp = true;
      continue;
    }
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg == '--replace') {
      replaceExisting = true;
      continue;
    }

    String? nextValue() {
      if (i + 1 >= args.length) return null;
      return args[++i];
    }

    if (arg == '--deck-id') {
      deckId = nextValue() ?? '';
      continue;
    }
    if (arg.startsWith('--deck-id=')) {
      deckId = arg.substring('--deck-id='.length);
      continue;
    }
    if (arg == '--corpus-path') {
      corpusPath = nextValue() ?? corpusPath;
      continue;
    }
    if (arg.startsWith('--corpus-path=')) {
      corpusPath = arg.substring('--corpus-path='.length);
      continue;
    }
    if (arg == '--label') {
      label = nextValue() ?? '';
      continue;
    }
    if (arg.startsWith('--label=')) {
      label = arg.substring('--label='.length);
      continue;
    }
    if (arg == '--note') {
      note = nextValue() ?? '';
      continue;
    }
    if (arg.startsWith('--note=')) {
      note = arg.substring('--note='.length);
      continue;
    }
    if (arg == '--expected-flow-path') {
      final value = nextValue() ?? '';
      if (value.isNotEmpty) expectedFlowPaths.add(value);
      continue;
    }
    if (arg.startsWith('--expected-flow-path=')) {
      final value = arg.substring('--expected-flow-path='.length);
      if (value.isNotEmpty) expectedFlowPaths.add(value);
      continue;
    }
    if (arg == '--expected-flow-paths') {
      final value = nextValue() ?? '';
      expectedFlowPaths.addAll(_splitFlowPaths(value));
      continue;
    }
    if (arg.startsWith('--expected-flow-paths=')) {
      expectedFlowPaths.addAll(
        _splitFlowPaths(arg.substring('--expected-flow-paths='.length)),
      );
      continue;
    }
  }

  return _CliOptions(
    deckId: deckId.trim(),
    corpusPath: corpusPath.trim(),
    label: label.trim(),
    note: note.trim(),
    expectedFlowPaths: expectedFlowPaths
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(),
    dryRun: dryRun,
    replaceExisting: replaceExisting,
    showHelp: showHelp,
  );
}

List<String> _splitFlowPaths(String raw) {
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

void _printUsage() {
  print('''
Uso:
  dart run bin/add_resolution_corpus_entry.dart \\
    --deck-id <uuid> \\
    [--label "Commander Name"] \\
    [--expected-flow-path rebuild_guided] \\
    [--expected-flow-path optimized_directly] \\
    [--note "observação"] \\
    [--replace] [--dry-run]

Flags:
  --deck-id                 UUID do deck-fonte a adicionar no corpus.
  --label                   Rótulo amigável salvo no JSON.
  --expected-flow-path      Pode ser repetido.
  --expected-flow-paths     Lista separada por vírgula.
  --note                    Observação curta para o corpus.
  --corpus-path             Caminho alternativo do manifesto.
  --replace                 Atualiza entrada existente do mesmo deck_id.
  --dry-run                 Valida e mostra preview sem gravar.
  --help, -h                Exibe esta ajuda.
''');
}

class _CliOptions {
  _CliOptions({
    required this.deckId,
    required this.corpusPath,
    required this.label,
    required this.note,
    required this.expectedFlowPaths,
    required this.dryRun,
    required this.replaceExisting,
    required this.showHelp,
  });

  final String deckId;
  final String corpusPath;
  final String label;
  final String note;
  final List<String> expectedFlowPaths;
  final bool dryRun;
  final bool replaceExisting;
  final bool showHelp;
}
