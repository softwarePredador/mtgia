import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/import_card_lookup_service.dart';

const _defaultLanguages = {
  'pt',
  'es',
  'fr',
  'de',
  'it',
  'ja',
  'ko',
  'ru',
  'zhs',
  'zht',
};

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
sync_localized_card_names.dart - Popula aliases localizados de cartas via Scryfall.

Uso:
  dart run bin/sync_localized_card_names.dart --dry-run
  dart run bin/sync_localized_card_names.dart --apply
  dart run bin/sync_localized_card_names.dart --apply --langs=pt,es,fr
  dart run bin/sync_localized_card_names.dart --dry-run --source-file=/tmp/localized-cards.json

Notas:
  - Usa busca paginada da Scryfall por idioma (`lang:<idioma>`).
  - Nao chama API por carta durante import.
  - Por padrao sincroniza pt, es, fr, de, it, ja, ko, ru, zhs, zht.
''');
    return;
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  final sourceFile = _argValue(args, '--source-file');
  final langs = (_argValue(args, '--langs')?.split(',') ?? _defaultLanguages)
      .map((lang) => lang.trim().toLowerCase())
      .where((lang) => lang.isNotEmpty)
      .toSet();
  final limit = int.tryParse(_argValue(args, '--limit') ?? '');

  stdout.writeln(
    '🌐 Sync localized names mode=${dryRun ? 'dry-run' : 'apply'} '
    'langs=${langs.join(',')}',
  );

  final cards = sourceFile == null
      ? await _downloadLocalizedCards(langs, limit: limit)
      : jsonDecode(await File(sourceFile).readAsString()) as List<dynamic>;

  final rows = buildLocalizedNameRows(cards, langs: langs, limit: limit);
  stdout.writeln('🧾 Localized aliases candidatos: ${rows.length}');

  final byLang = <String, int>{};
  for (final row in rows) {
    byLang.update(row.lang, (value) => value + 1, ifAbsent: () => 1);
  }
  stdout.writeln('📊 Por idioma: ${jsonEncode(byLang)}');

  if (dryRun) {
    stdout.writeln('✅ Dry-run concluido sem mutacoes.');
    return;
  }

  final db = Database();
  await db.connect();
  final pool = db.connection;

  try {
    await pool.runTx((session) async {
      await ensureCardLocalizedNamesTable(session);
      await _upsertRows(session, rows);
    });
    stdout.writeln('✅ Apply concluido: ${rows.length} aliases sincronizados.');
  } finally {
    await db.close();
  }
}

String? _argValue(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

Map<String, String> get _scryfallHeaders => {
      'User-Agent': 'ManaLoom localized import sync',
      'Accept': 'application/json',
    };

Future<List<dynamic>> _downloadLocalizedCards(
  Set<String> langs, {
  int? limit,
}) async {
  final client = http.Client();
  try {
    final allCards = <dynamic>[];
    for (final lang in langs) {
      Uri? uri = Uri.https('api.scryfall.com', '/cards/search', {
        'q': 'lang:$lang',
        'unique': 'prints',
        'order': 'name',
      });
      var page = 0;
      while (uri != null) {
        page += 1;
        final response = await _getScryfallPage(client, uri);
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? const <dynamic>[];
        allCards.addAll(data);
        if (limit != null && allCards.length >= limit) {
          return allCards.take(limit).toList();
        }
        final nextPage = body['next_page']?.toString();
        uri = nextPage == null || nextPage.isEmpty ? null : Uri.parse(nextPage);
        stdout.write(
          '\r  baixando lang=$lang page=$page total=${allCards.length}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      stdout.writeln();
    }
    return allCards;
  } finally {
    client.close();
  }
}

Future<http.Response> _getScryfallPage(http.Client client, Uri uri) async {
  for (var attempt = 1; attempt <= 4; attempt += 1) {
    final response = await client
        .get(uri, headers: _scryfallHeaders)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode == 200) return response;

    if (response.statusCode == 429 && attempt < 4) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      final wait = Duration(
          seconds: (retryAfter == null || retryAfter < 1) ? 60 : retryAfter);
      stdout.writeln('\n⏳ Scryfall 429; aguardando ${wait.inSeconds}s...');
      await Future<void>.delayed(wait);
      continue;
    }

    throw StateError(
      'Scryfall search HTTP ${response.statusCode}: ${response.body}',
    );
  }
  throw StateError('Scryfall search failed unexpectedly.');
}

List<LocalizedNameRow> buildLocalizedNameRows(
  List<dynamic> cards, {
  required Set<String> langs,
  int? limit,
}) {
  final rows = <LocalizedNameRow>[];
  final seen = <String>{};

  for (final raw in cards) {
    if (raw is! Map<String, dynamic>) continue;
    final lang = raw['lang']?.toString().trim().toLowerCase();
    final printedName = raw['printed_name']?.toString().trim();
    final scryfallId = raw['id']?.toString().trim();
    final name = raw['name']?.toString().trim();

    if (lang == null ||
        printedName == null ||
        scryfallId == null ||
        name == null ||
        lang.isEmpty ||
        printedName.isEmpty ||
        scryfallId.isEmpty ||
        name.isEmpty ||
        !langs.contains(lang)) {
      continue;
    }

    final normalized = normalizeLocalizedImportName(printedName);
    if (normalized.isEmpty) continue;

    final row = LocalizedNameRow(
      scryfallId: scryfallId,
      oracleId: raw['oracle_id']?.toString(),
      lang: lang,
      printedName: printedName,
      normalizedPrintedName: normalized,
      canonicalName: name,
      setCode: raw['set']?.toString(),
      collectorNumber: raw['collector_number']?.toString(),
    );

    final key = '${row.scryfallId}|${row.lang}|${row.normalizedPrintedName}';
    if (!seen.add(key)) continue;
    rows.add(row);
    if (limit != null && rows.length >= limit) break;
  }

  return rows;
}

Future<void> _upsertRows(Session session, List<LocalizedNameRow> rows) async {
  if (rows.isEmpty) return;

  const batchSize = 500;
  for (var i = 0; i < rows.length; i += batchSize) {
    final batch = rows.sublist(
      i,
      (i + batchSize).clamp(0, rows.length),
    );
    final values = <String>[];
    final params = <String, dynamic>{};

    for (var j = 0; j < batch.length; j++) {
      final row = batch[j];
      values.add('''
        (@sid$j::uuid, @oid$j::uuid, @lang$j, @printed$j, @normalized$j,
         @canonical$j, @set$j, @collector$j)
      ''');
      params['sid$j'] = row.scryfallId;
      params['oid$j'] = row.oracleId;
      params['lang$j'] = row.lang;
      params['printed$j'] = row.printedName;
      params['normalized$j'] = row.normalizedPrintedName;
      params['canonical$j'] = row.canonicalName;
      params['set$j'] = row.setCode;
      params['collector$j'] = row.collectorNumber;
    }

    await session.execute(
      Sql.named('''
        INSERT INTO card_localized_names (
          scryfall_id, oracle_id, lang, printed_name, normalized_printed_name,
          canonical_name, set_code, collector_number
        )
        VALUES ${values.join(',')}
        ON CONFLICT (scryfall_id, lang, normalized_printed_name) DO UPDATE SET
          oracle_id = EXCLUDED.oracle_id,
          printed_name = EXCLUDED.printed_name,
          canonical_name = EXCLUDED.canonical_name,
          set_code = EXCLUDED.set_code,
          collector_number = EXCLUDED.collector_number,
          updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: params,
    );

    await session.execute(Sql.named('''
      UPDATE card_localized_names l
      SET card_id = c.id
      FROM cards c
      WHERE l.card_id IS NULL
        AND (
          c.scryfall_id = l.scryfall_id
          OR c.scryfall_id = l.oracle_id
          OR lower(c.name) = lower(l.canonical_name)
        )
    '''));

    stdout.write('\r  ... ${i + batch.length} / ${rows.length}');
  }
  stdout.writeln();
}

class LocalizedNameRow {
  const LocalizedNameRow({
    required this.scryfallId,
    required this.oracleId,
    required this.lang,
    required this.printedName,
    required this.normalizedPrintedName,
    required this.canonicalName,
    required this.setCode,
    required this.collectorNumber,
  });

  final String scryfallId;
  final String? oracleId;
  final String lang;
  final String printedName;
  final String normalizedPrintedName;
  final String canonicalName;
  final String? setCode;
  final String? collectorNumber;
}
