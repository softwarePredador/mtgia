import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/meta/mtgtop8_meta_support.dart';

Future<void> main(List<String> args) async {
  final config = _RepairConfig.parse(args);

  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    final brokenRows = await conn.execute(
      Sql.named('''
        SELECT source_url, format, archetype, placement
        FROM meta_decks
        WHERE source_url ILIKE 'https://www.mtgtop8.com/%'
          AND (@allFormats = TRUE OR format = ANY(@formats))
          AND (
            COALESCE(TRIM(archetype), '') = ''
            OR COALESCE(TRIM(placement), '') = ''
            OR placement = '?'
          )
        ORDER BY created_at ASC
      '''),
      parameters: {
        'allFormats': config.formats.isEmpty,
        'formats': config.formats,
      },
    );

    final brokenByEvent = <String, List<Map<String, dynamic>>>{};
    for (final row in brokenRows) {
      final map = row.toColumnMap();
      final sourceUrl = map['source_url']?.toString() ?? '';
      final eventId = extractMtgTop8EventIdFromSourceUrl(sourceUrl);
      if (eventId == null) continue;
      brokenByEvent
          .putIfAbsent(eventId, () => <Map<String, dynamic>>[])
          .add(map);
    }

    final selectedEventIds =
        brokenByEvent.keys.take(config.limitEvents).toList();
    stdout.writeln(
      'Broken rows detectados: ${brokenRows.length} | eventos selecionados: ${selectedEventIds.length}',
    );
    if (config.dryRun) {
      stdout
          .writeln('Modo dry-run ativo: nenhuma escrita em banco sera feita.');
    }

    var repaired = 0;
    var missingMatches = 0;

    for (final eventId in selectedEventIds) {
      final eventUrl = '$mtgTop8BaseUrl/event?e=$eventId';
      stdout.writeln('-> Event $eventId');

      final response = await http.get(Uri.parse(eventUrl));
      if (response.statusCode != 200) {
        stdout.writeln('   [ERR] Event fetch falhou: ${response.statusCode}');
        continue;
      }

      final document = html_parser.parse(response.body);
      final parsedRows = extractMtgTop8EventDeckRowsByUrl(document);
      final eventBrokenRows = brokenByEvent[eventId]!;

      for (final broken in eventBrokenRows.take(config.limitRowsPerEvent)) {
        final sourceUrl = broken['source_url']?.toString() ?? '';
        final parsed = parsedRows[sourceUrl];
        if (parsed == null) {
          missingMatches++;
          stdout.writeln('   [MISS] $sourceUrl');
          continue;
        }

        if (config.dryRun) {
          stdout.writeln(
            '   [DRY] ${parsed.archetype} (${parsed.placement}) <- $sourceUrl',
          );
        } else {
          await conn.execute(
            Sql.named('''
              UPDATE meta_decks
              SET
                archetype = @archetype,
                placement = @placement
              WHERE source_url = @url
            '''),
            parameters: {
              'archetype': parsed.archetype,
              'placement': parsed.placement,
              'url': sourceUrl,
            },
          );
          repaired++;
          stdout.writeln(
            '   [FIX] ${parsed.archetype} (${parsed.placement}) <- $sourceUrl',
          );
        }
      }
    }

    stdout.writeln(
      'Repair concluido: repaired=$repaired missing_matches=$missingMatches',
    );
  } finally {
    await db.close();
  }
}

class _RepairConfig {
  _RepairConfig({
    required this.dryRun,
    required this.formats,
    required this.limitEvents,
    required this.limitRowsPerEvent,
  });

  final bool dryRun;
  final List<String> formats;
  final int limitEvents;
  final int limitRowsPerEvent;

  factory _RepairConfig.parse(List<String> args) {
    var dryRun = true;
    final formats = <String>[];
    var limitEvents = 20;
    var limitRowsPerEvent = 50;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--apply') {
        dryRun = false;
        continue;
      }
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg == '--format' && i + 1 < args.length) {
        formats.add(args[++i].trim());
        continue;
      }
      if (arg == '--formats' && i + 1 < args.length) {
        formats.addAll(
          args[++i]
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );
        continue;
      }
      if (arg == '--limit-events' && i + 1 < args.length) {
        limitEvents = int.tryParse(args[++i]) ?? limitEvents;
        continue;
      }
      if (arg == '--limit-rows-per-event' && i + 1 < args.length) {
        limitRowsPerEvent = int.tryParse(args[++i]) ?? limitRowsPerEvent;
      }
    }

    return _RepairConfig(
      dryRun: dryRun,
      formats: formats,
      limitEvents: limitEvents,
      limitRowsPerEvent: limitRowsPerEvent,
    );
  }
}
