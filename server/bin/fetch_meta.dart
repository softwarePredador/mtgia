import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/meta/mtgtop8_meta_support.dart';

// Script para buscar decks do Meta (MTGTop8)
// Uso:
//   dart run bin/fetch_meta.dart [format]
//   dart run bin/fetch_meta.dart EDH --dry-run --limit-events=1 --limit-decks=3
//   dart run bin/fetch_meta.dart EDH --refresh-existing --limit-events=1 --limit-decks=10

Future<void> main(List<String> args) async {
  final config = _FetchMetaConfig.parse(args);
  final formatsToProcess = config.inputFormat == 'ALL'
      ? mtgTop8SupportedFormats.keys.toList()
      : [config.inputFormat];

  Database? db;
  dynamic conn;
  if (!config.dryRun) {
    db = Database();
    await db.connect();
    conn = db.connection;
  }

  try {
    for (final formatCode in formatsToProcess) {
      if (!mtgTop8SupportedFormats.containsKey(formatCode)) {
        print('Formato desconhecido: $formatCode. Pulando...');
        continue;
      }

      print(
        '\n=== Iniciando crawler para ${mtgTop8SupportedFormats[formatCode]} ($formatCode) ===',
      );
      if (config.dryRun) {
        print('Modo dry-run ativo: nenhuma escrita em banco sera feita.');
      }

      final formatUrl = '$mtgTop8BaseUrl/format?f=$formatCode';
      print('Acessando $formatUrl...');

      final response = await http.get(Uri.parse(formatUrl));
      if (response.statusCode != 200) {
        print(
            'Falha ao acessar MTGTop8 para $formatCode: ${response.statusCode}');
        continue;
      }

      final document = parser.parse(response.body);
      final eventLinks = extractRecentMtgTop8EventPaths(
        document,
        limit: config.limitEvents,
      );

      print('Encontrados ${eventLinks.length} eventos recentes.');

      for (final link in eventLinks) {
        final eventUrl = resolveMtgTop8Url(link);
        print('  -> Processando evento: $eventUrl');

        await _processEvent(
          conn,
          eventUrl,
          formatCode: formatCode,
          config: config,
        );

        sleep(Duration(milliseconds: config.delayEventMs));
      }
    }

    print('\nCrawler finalizado com sucesso!');
  } catch (e) {
    print('Erro crítico: $e');
    rethrow;
  } finally {
    await db?.close();
  }
}

Future<void> _processEvent(
  dynamic conn,
  String eventUrl, {
  required String formatCode,
  required _FetchMetaConfig config,
}) async {
  try {
    final response = await http.get(Uri.parse(eventUrl));
    final document = parser.parse(response.body);

    final rows = document.querySelectorAll('div.hover_tr');
    print('     Encontrados ${rows.length} linhas de decks neste evento.');

    for (final row in rows.take(config.limitDecks)) {
      final parsedRow = parseMtgTop8EventDeckRow(
        row,
        defaultFormatCode: formatCode,
      );
      if (parsedRow == null) continue;

      Map<String, dynamic>? existingRow;
      if (!config.dryRun) {
        final exists = await conn.execute(
          Sql.named('''
            SELECT archetype, placement
            FROM meta_decks
            WHERE source_url = @url
            LIMIT 1
          '''),
          parameters: {'url': parsedRow.deckUrl},
        );
        if (exists.isNotEmpty) {
          existingRow = exists.first.toColumnMap();
        }
      }

      if (existingRow != null) {
        if (config.refreshExisting &&
            _shouldRepairExistingMetaDeck(
              archetype: existingRow['archetype']?.toString(),
              placement: existingRow['placement']?.toString(),
              parsedRow: parsedRow,
            )) {
          await conn.execute(
            Sql.named('''
              UPDATE meta_decks
              SET
                archetype = @archetype,
                placement = @placement
              WHERE source_url = @url
            '''),
            parameters: {
              'archetype': parsedRow.archetype,
              'placement': parsedRow.placement,
              'url': parsedRow.deckUrl,
            },
          );
          print(
            '     [FIX] Deck reparado: ${parsedRow.archetype} (${parsedRow.placement})',
          );
        } else {
          print(
            '     [SKIP] Deck já importado: ${parsedRow.archetype} (${parsedRow.placement})',
          );
        }
        continue;
      }

      print(
        '     [NEW] ${config.dryRun ? "Validando" : "Importando"} deck: '
        '${parsedRow.archetype} (${parsedRow.placement})...',
      );

      final exportUrl = '$mtgTop8BaseUrl/mtgo?d=${parsedRow.deckId}';
      final exportResponse = await http.get(Uri.parse(exportUrl));
      if (exportResponse.statusCode != 200) {
        print(
          '     [ERR] Falha no export $exportUrl (${exportResponse.statusCode})',
        );
        continue;
      }

      final cardList = exportResponse.body.trim();
      if (cardList.isEmpty) {
        print('     [ERR] Deck exportado vazio: ${parsedRow.archetype}');
        continue;
      }

      if (config.dryRun) {
        final cardCount =
            cardList.split('\n').where((line) => line.trim().isNotEmpty).length;
        print(
          '     [DRY] OK format=${parsedRow.formatCode} '
          'placement=${parsedRow.placement} cards=$cardCount url=${parsedRow.deckUrl}',
        );
      } else {
        await conn.execute(
          Sql.named('''
            INSERT INTO meta_decks (format, archetype, source_url, card_list, placement)
            VALUES (@format, @archetype, @url, @list, @placement)
          '''),
          parameters: {
            'format': parsedRow.formatCode,
            'archetype': parsedRow.archetype,
            'url': parsedRow.deckUrl,
            'list': cardList,
            'placement': parsedRow.placement,
          },
        );
        print('     [OK] Salvo no banco.');
      }

      sleep(Duration(milliseconds: config.delayDeckMs));
    }
  } catch (e) {
    print('     Erro ao processar evento: $e');
  }
}

class _FetchMetaConfig {
  _FetchMetaConfig({
    required this.inputFormat,
    required this.dryRun,
    required this.limitEvents,
    required this.limitDecks,
    required this.delayEventMs,
    required this.delayDeckMs,
    required this.refreshExisting,
  });

  final String inputFormat;
  final bool dryRun;
  final int limitEvents;
  final int limitDecks;
  final int delayEventMs;
  final int delayDeckMs;
  final bool refreshExisting;

  factory _FetchMetaConfig.parse(List<String> args) {
    var inputFormat = 'ST';
    var dryRun = false;
    var limitEvents = 6;
    var limitDecks = 8;
    var delayEventMs = 2000;
    var delayDeckMs = 500;
    var refreshExisting = false;

    for (final arg in args) {
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg == '--refresh-existing') {
        refreshExisting = true;
        continue;
      }
      if (arg.startsWith('--limit-events=')) {
        limitEvents = int.tryParse(arg.substring('--limit-events='.length)) ??
            limitEvents;
        continue;
      }
      if (arg.startsWith('--limit-decks=')) {
        limitDecks =
            int.tryParse(arg.substring('--limit-decks='.length)) ?? limitDecks;
        continue;
      }
      if (arg.startsWith('--delay-event-ms=')) {
        delayEventMs =
            int.tryParse(arg.substring('--delay-event-ms='.length)) ??
                delayEventMs;
        continue;
      }
      if (arg.startsWith('--delay-deck-ms=')) {
        delayDeckMs = int.tryParse(arg.substring('--delay-deck-ms='.length)) ??
            delayDeckMs;
        continue;
      }
      if (!arg.startsWith('--')) {
        inputFormat = arg.trim();
      }
    }

    return _FetchMetaConfig(
      inputFormat: inputFormat,
      dryRun: dryRun,
      limitEvents: limitEvents,
      limitDecks: limitDecks,
      delayEventMs: delayEventMs,
      delayDeckMs: delayDeckMs,
      refreshExisting: refreshExisting,
    );
  }
}

bool _shouldRepairExistingMetaDeck({
  required String? archetype,
  required String? placement,
  required MtgTop8EventDeckRow parsedRow,
}) {
  final normalizedArchetype = archetype?.trim() ?? '';
  final normalizedPlacement = placement?.trim() ?? '';

  if (normalizedArchetype.isEmpty) return true;
  if (normalizedPlacement.isEmpty || normalizedPlacement == '?') return true;
  if (normalizedPlacement != parsedRow.placement) return true;
  return false;
}
