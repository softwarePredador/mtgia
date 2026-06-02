// ignore_for_file: avoid_print

import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/ai/edhrec_service.dart';
import '../lib/ai/edhrec_trend_service.dart';
import '../lib/database.dart';

/// Captura um snapshot diário de inclusão/sinergia das cartas (EDHREC) para
/// cada commander presente nos decks do app, populando `edhrec_card_snapshots`.
///
/// Roda de forma incremental: se já existe snapshot de hoje para um commander,
/// pula (a menos que `--force`). Idempotente via ON CONFLICT no service.
///
/// Uso: dart run bin/snapshot_edhrec.dart [--force] [--limit=N] [--delay-ms=N]
Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final limit = _intArg(args, '--limit=');
  final delayMs = _intArg(args, '--delay-ms=') ?? 350;

  print('🔄 Snapshot EDHREC de cartas por commander');

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    print('❌ Sem conexão com o banco. Abortando.');
    exit(1);
  }
  final pool = db.connection;

  try {
    await _ensureTable(pool);

    final commanders = await _distinctCommanders(pool, limit: limit);
    print('🧭 Commanders distintos nos decks: ${commanders.length}');
    if (commanders.isEmpty) {
      print('⚠️  Nenhum commander encontrado. Nada a fazer.');
      return;
    }

    final today = _todayUtc();
    final trend = EdhrecTrendService(pool);
    final edhrec = EdhrecService();

    var processed = 0;
    var skipped = 0;
    var failed = 0;
    var cardsTotal = 0;

    for (final name in commanders) {
      final slug = EdhrecService.slugFor(name);
      if (!force && await _hasSnapshot(pool, slug, today)) {
        skipped++;
        continue;
      }

      try {
        final data = await edhrec.fetchCommanderData(name);
        if (data == null || data.topCards.isEmpty) {
          failed++;
          print('   ⚠️  sem dados EDHREC: "$name"');
          continue;
        }
        final n = await trend.persistSnapshot(data);
        cardsTotal += n;
        processed++;
        if (processed % 25 == 0) {
          print('   progresso: $processed processados, $cardsTotal cartas');
        }
      } catch (e) {
        failed++;
        print('   ⚠️  erro em "$name": $e');
      }

      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    final total = await _count(pool, 'edhrec_card_snapshots');
    print('✅ Snapshot concluído.');
    print('   processados=$processed, pulados=$skipped, falhas=$failed');
    print('   cartas neste run=$cardsTotal, total tabela=$total');
  } catch (e, st) {
    print('❌ Erro no snapshot EDHREC: $e');
    print(st);
    exitCode = 1;
  } finally {
    await db.close();
  }
}

Future<List<String>> _distinctCommanders(Pool pool, {int? limit}) async {
  final res = await pool.execute(
    Sql.named('''
      SELECT DISTINCT c.name
      FROM deck_cards dc
      JOIN cards c ON c.id = dc.card_id
      WHERE dc.is_commander = true
        AND c.name IS NOT NULL
        AND c.name <> ''
      ORDER BY c.name
      ${limit != null ? 'LIMIT $limit' : ''}
    '''),
  );
  return res.map((r) => r.toColumnMap()['name'] as String).toList();
}

Future<bool> _hasSnapshot(Pool pool, String slug, String date) async {
  final res = await pool.execute(
    Sql.named('''
      SELECT 1 FROM edhrec_card_snapshots
      WHERE commander_slug = @slug AND snapshot_date = @d::date
      LIMIT 1
    '''),
    parameters: {'slug': slug, 'd': date},
  );
  return res.isNotEmpty;
}

Future<void> _ensureTable(Pool pool) async {
  final res = await pool.execute(
    Sql.named(
      "SELECT to_regclass('public.edhrec_card_snapshots') IS NOT NULL AS ok",
    ),
  );
  if (res.first.toColumnMap()['ok'] != true) {
    throw Exception(
      'Tabela edhrec_card_snapshots ausente. Rode `dart run bin/migrate.dart`.',
    );
  }
}

Future<int> _count(Pool pool, String table) async {
  final res = await pool.execute(Sql.named('SELECT count(*)::int FROM $table'));
  return (res.first[0] as int?) ?? 0;
}

String _todayUtc() {
  final d = DateTime.now().toUtc();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

int? _intArg(List<String> args, String prefix) {
  final raw = args
      .firstWhere((a) => a.startsWith(prefix), orElse: () => '')
      .replaceFirst(prefix, '');
  return raw.isEmpty ? null : int.tryParse(raw);
}
