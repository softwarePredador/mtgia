#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import '../lib/database.dart';

const _defaultCorpusPath = 'test/fixtures/optimization_resolution_corpus.json';
const _generatedDeckNameFilters = '''
        AND d.name NOT LIKE 'Optimization Validation - %'
        AND d.name NOT LIKE 'Resolution Validation - %'
        AND d.name NOT LIKE 'Rebuild Draft - %'
        AND d.name NOT LIKE 'Rebuild Preview - %'
''';

class EligibleDeckRow {
  EligibleDeckRow({
    required this.deckId,
    required this.deckName,
    required this.commanderName,
    required this.totalCards,
    required this.shellHash,
  });

  final String deckId;
  final String deckName;
  final String commanderName;
  final int totalCards;
  final String shellHash;
}

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final corpusPath =
      (env['VALIDATION_CORPUS_PATH'] ?? '').trim().isNotEmpty
          ? env['VALIDATION_CORPUS_PATH']!.trim()
          : _defaultCorpusPath;

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    stderr.writeln('Falha ao conectar ao banco.');
    exitCode = 1;
    return;
  }

  try {
    final eligibleDecks = await _loadEligibleDecks(db.connection);
    final corpusDeckIds = _loadCorpusDeckIds(corpusPath);

    final uniqueCommanders = eligibleDecks
        .map((deck) => deck.commanderName.toLowerCase())
        .toSet()
        .length;
    final shellGroups = <String, List<EligibleDeckRow>>{};
    for (final deck in eligibleDecks) {
      shellGroups.putIfAbsent(deck.shellHash, () => <EligibleDeckRow>[]).add(deck);
    }
    final duplicatedShells = shellGroups.values
        .where((group) => group.length > 1)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final missingFromDb = corpusDeckIds
        .where((deckId) => eligibleDecks.every((deck) => deck.deckId != deckId))
        .toList();

    print('=== AUDITORIA DO CORPUS DE RESOLUCAO ===');
    print('Corpus: $corpusPath');
    print('Decks elegiveis: ${eligibleDecks.length}');
    print('Comandantes unicos: $uniqueCommanders');
    print('Entradas no corpus: ${corpusDeckIds.length}');
    print('Decks do corpus ausentes na base: ${missingFromDb.length}');

    if (missingFromDb.isNotEmpty) {
      print('');
      print('Corpus com decks ausentes na base atual:');
      for (final deckId in missingFromDb) {
        print('- $deckId');
      }
    }

    if (duplicatedShells.isNotEmpty) {
      print('');
      print('Shells duplicadas detectadas:');
      for (final group in duplicatedShells.take(10)) {
        final sample = group.first;
        print(
          '- ${sample.commanderName}: ${group.length} decks com a mesma shell (${sample.shellHash.substring(0, 8)})',
        );
        for (final deck in group.take(5)) {
          print('  ${deck.deckId} | ${deck.deckName}');
        }
      }
    }

    if (eligibleDecks.isNotEmpty) {
      print('');
      print('Decks elegiveis mais recentes:');
      for (final deck in eligibleDecks.take(10)) {
        final inCorpus = corpusDeckIds.contains(deck.deckId) ? ' [corpus]' : '';
        print(
          '- ${deck.commanderName} | ${deck.deckId} | ${deck.deckName}$inCorpus',
        );
      }
    }
  } finally {
    await db.close();
  }
}

List<String> _loadCorpusDeckIds(String path) {
  final file = File(path);
  if (!file.existsSync()) return const <String>[];
  final decoded = jsonDecode(file.readAsStringSync());
  final rawEntries = switch (decoded) {
    {'decks': final List decks} => decks,
    final List decks => decks,
    _ => const <dynamic>[],
  };

  return rawEntries
      .whereType<Map>()
      .map((entry) => entry['deck_id']?.toString().trim() ?? '')
      .where((deckId) => deckId.isNotEmpty)
      .toList();
}

Future<List<EligibleDeckRow>> _loadEligibleDecks(Pool pool) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        d.id::text AS deck_id,
        d.name AS deck_name,
        c.name AS commander_name,
        stats.total_cards,
        md5(
          COALESCE(
            (
              SELECT string_agg(
                dc2.card_id::text || ':' || dc2.quantity::text || ':' || COALESCE(dc2.is_commander, FALSE)::text,
                ',' ORDER BY dc2.card_id
              )
              FROM deck_cards dc2
              WHERE dc2.deck_id = d.id
            ),
            ''
          )
        ) AS shell_hash
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
      WHERE d.deleted_at IS NULL
        AND LOWER(d.format) = 'commander'
        AND stats.total_cards = 100
$_generatedDeckNameFilters
      ORDER BY d.created_at DESC NULLS LAST
      LIMIT 500
    '''),
  );

  return result
      .map(
        (row) => EligibleDeckRow(
          deckId: row[0] as String,
          deckName: row[1] as String? ?? 'Commander Deck',
          commanderName: row[2] as String? ?? 'Unknown Commander',
          totalCards: row[3] as int? ?? 0,
          shellHash: row[4] as String? ?? '',
        ),
      )
      .toList();
}
