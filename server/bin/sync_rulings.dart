// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';

/// Sincroniza as rulings oficiais de cartas (Gatherer/Scryfall) a partir do
/// bulk MTGJSON `AtomicCards.json` para a tabela `card_rulings`.
///
/// Cada ruling é `{date, text}` e está associada ao `oracleId`
/// (= `cards.scryfall_id` no nosso schema). Idempotente via
/// `ON CONFLICT (oracle_id, comment_hash)`.
///
/// Uso: dart run bin/sync_rulings.dart [--force] [--file=AtomicCards.json]
const _atomicCardsUrl = 'https://mtgjson.com/api/v5/AtomicCards.json';
const _defaultFile = 'AtomicCards.json';

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final fileArg = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');
  final filePath = fileArg.isNotEmpty ? fileArg : _defaultFile;

  print('🔄 Sync de rulings de cartas (MTGJSON AtomicCards)');

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    print('❌ Sem conexão com o banco. Abortando.');
    exit(1);
  }
  final pool = db.connection;

  try {
    await _ensureTable(pool);

    final file = File(filePath);
    if (force || !file.existsSync()) {
      await _download(file);
    } else {
      final sizeMb = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
      print('📁 Usando cache local: $filePath (${sizeMb}MB)');
    }

    print('📖 Decodificando AtomicCards...');
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final data = (decoded['data'] as Map<String, dynamic>?) ?? const {};
    print('   cartas=${data.length}');

    final rulings = <_Ruling>[];
    final seen = <String>{};
    var cardsWithRulings = 0;
    for (final entry in data.entries) {
      final faces = entry.value;
      if (faces is! List || faces.isEmpty) continue;
      final first = faces.first;
      if (first is! Map) continue;
      final oracleId =
          (first['identifiers']?['scryfallOracleId'])?.toString();
      if (oracleId == null || oracleId.isEmpty) continue;
      final list = first['rulings'];
      if (list is! List || list.isEmpty) continue;
      cardsWithRulings++;
      for (final r in list) {
        if (r is! Map) continue;
        final text = r['text']?.toString();
        if (text == null || text.trim().isEmpty) continue;
        final date = r['date']?.toString();
        final hash =
            md5.convert(utf8.encode('${date ?? ''}|$text')).toString();
        // Dedupe global por (oracle_id, hash): cartas que compartilham oracleId
        // (DFCs/reprints listadas separadamente) repetem as mesmas rulings.
        if (!seen.add('$oracleId|$hash')) continue;
        rulings.add(_Ruling(
          oracleId: oracleId,
          publishedAt: date,
          comment: text,
          hash: hash,
        ));
      }
    }
    print('   cartas com rulings=$cardsWithRulings, rulings totais=${rulings.length}');

    await _upsert(pool, rulings);

    final total = await _count(pool, 'card_rulings');
    print('✅ Sync concluído. card_rulings=$total');
  } catch (e, st) {
    print('❌ Erro no sync de rulings: $e');
    print(st);
    exitCode = 1;
  } finally {
    await db.close();
  }
}

Future<void> _download(File target) async {
  print('⬇️  Baixando $_atomicCardsUrl ...');
  final client = http.Client();
  try {
    final req = http.Request('GET', Uri.parse(_atomicCardsUrl));
    req.headers['User-Agent'] = 'ManaLoom/1.0 (rulings-sync)';
    final resp = await client.send(req).timeout(const Duration(minutes: 5));
    if (resp.statusCode != 200) {
      throw Exception('Download falhou: status=${resp.statusCode}');
    }
    final sink = target.openWrite();
    try {
      await resp.stream.pipe(sink);
    } finally {
      await sink.close();
    }
    print('   download concluído.');
  } finally {
    client.close();
  }
}

Future<void> _upsert(Pool pool, List<_Ruling> rulings) async {
  if (rulings.isEmpty) {
    print('⚠️  Nenhuma ruling para inserir.');
    return;
  }

  const batchSize = 500;
  var done = 0;
  for (var start = 0; start < rulings.length; start += batchSize) {
    final end = (start + batchSize).clamp(0, rulings.length);
    final batch = rulings.sublist(start, end);

    final rows = <String>[];
    final params = <String, dynamic>{};
    for (var i = 0; i < batch.length; i++) {
      final r = batch[i];
      rows.add(
        '(@o$i, \'mtgjson\', @d$i::date, @c$i, @h$i, CURRENT_TIMESTAMP)',
      );
      params['o$i'] = r.oracleId;
      params['d$i'] = r.publishedAt;
      params['c$i'] = r.comment;
      params['h$i'] = r.hash;
    }

    await pool.execute(
      Sql.named('''
        INSERT INTO card_rulings (
          oracle_id, source, published_at, comment, comment_hash, created_at
        ) VALUES ${rows.join(', ')}
        ON CONFLICT (oracle_id, comment_hash) DO UPDATE SET
          published_at = EXCLUDED.published_at,
          comment = EXCLUDED.comment
      '''),
      parameters: params,
    );

    done += batch.length;
    if (done % 5000 == 0 || done == rulings.length) {
      print('   upsert $done/${rulings.length}');
    }
  }
}

Future<void> _ensureTable(Pool pool) async {
  final res = await pool.execute(
    Sql.named("SELECT to_regclass('public.card_rulings') IS NOT NULL AS ok"),
  );
  if (res.first.toColumnMap()['ok'] != true) {
    throw Exception(
      'Tabela card_rulings ausente. Rode `dart run bin/migrate.dart` antes.',
    );
  }
}

Future<int> _count(Pool pool, String table) async {
  final res = await pool.execute(Sql.named('SELECT count(*)::int FROM $table'));
  return (res.first[0] as int?) ?? 0;
}

class _Ruling {
  final String oracleId;
  final String? publishedAt;
  final String comment;
  final String hash;

  _Ruling({
    required this.oracleId,
    required this.publishedAt,
    required this.comment,
    required this.hash,
  });
}
