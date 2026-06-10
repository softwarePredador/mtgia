// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/ai/commander_spellbook_service.dart';
import '../lib/database.dart';

const _comboFunctionTagSource = 'commander_spellbook_combo_v1';

/// Sincroniza a base de combos do Commander Spellbook.
///
/// Baixa o bulk `variants.json` (~500MB) para um arquivo temporário (streaming,
/// para não duplicar em memória), faz o parse e popula as tabelas `card_combos`
/// e `combo_cards`. Combos cujo `oracleId` não esteja presente em nenhuma carta
/// são mantidos mesmo assim — o match em runtime é por oracle_id.
///
/// Uso: dart run bin/sync_combos.dart [--force] [--keep-file]
///
/// Opções:
///   --force      Re-baixa o bulk mesmo se o cache local for recente (<24h).
///   --keep-file  Não apaga o arquivo temporário ao final.
Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final keepFile = args.contains('--keep-file');

  print('🔄 Sync de combos (Commander Spellbook)');

  final tmpDir = Directory.systemTemp;
  final cacheFile = File('${tmpDir.path}/csb_variants.json');

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    print('❌ Sem conexão com o banco. Abortando.');
    exit(1);
  }
  final pool = db.connection;

  try {
    await _ensureCombosTables(pool);

    final needsDownload = force ||
        !cacheFile.existsSync() ||
        DateTime.now()
                .difference(cacheFile.lastModifiedSync())
                .inHours >=
            24;

    if (needsDownload) {
      await _downloadBulk(cacheFile);
    } else {
      final sizeMb =
          (cacheFile.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
      print('📦 Reutilizando cache local (${sizeMb}MB, <24h).');
    }

    print('📖 Lendo e decodificando bulk...');
    final raw = await cacheFile.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final version = (decoded['version'] ?? '?').toString();
    final variants = (decoded['variants'] as List?) ?? const [];
    print('   version=$version, variants=${variants.length}');

    final combos = <_ParsedCombo>[];
    var skipped = 0;
    for (final v in variants) {
      final parsed = _parseVariant(v as Map<String, dynamic>);
      if (parsed == null) {
        skipped++;
        continue;
      }
      combos.add(parsed);
    }
    print('   válidos=${combos.length}, ignorados=$skipped');

    await _upsertCombos(pool, combos);
    await _syncComboFunctionTags(pool);

    final total = await _count(pool, 'card_combos');
    print('✅ Sync concluído. card_combos=$total');
  } catch (e, st) {
    print('❌ Erro no sync de combos: $e');
    print(st);
    exitCode = 1;
  } finally {
    if (!keepFile && cacheFile.existsSync()) {
      try {
        cacheFile.deleteSync();
      } catch (_) {}
    }
    await db.close();
  }
}

/// Baixa o bulk via streaming para [target], evitando carregar tudo em memória
/// duas vezes (download + arquivo).
Future<void> _downloadBulk(File target) async {
  print('⬇️  Baixando ${CommanderSpellbookService.bulkUrl} ...');
  final client = http.Client();
  try {
    final req = http.Request(
      'GET',
      Uri.parse(CommanderSpellbookService.bulkUrl),
    );
    req.headers['User-Agent'] = 'ManaLoom/1.0 (combo-sync)';
    req.headers['Accept'] = 'application/json';

    final resp = await client.send(req).timeout(const Duration(minutes: 5));
    if (resp.statusCode != 200) {
      throw Exception('Download falhou: status=${resp.statusCode}');
    }

    final sink = target.openWrite();
    var bytes = 0;
    var lastLog = 0;
    try {
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        bytes += chunk.length;
        final mb = bytes ~/ (1024 * 1024);
        if (mb >= lastLog + 50) {
          lastLog = mb;
          print('   ...${mb}MB');
        }
      }
    } finally {
      await sink.close();
    }
    final sizeMb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    print('   download concluído (${sizeMb}MB).');
  } finally {
    client.close();
  }
}

/// Extrai um combo de uma variant do bulk. Retorna null se inválido.
_ParsedCombo? _parseVariant(Map<String, dynamic> v) {
  final id = v['id']?.toString();
  if (id == null || id.isEmpty) return null;

  final status = (v['status'] ?? 'OK').toString();
  // Apenas combos OK (exclui rascunhos / removidos).
  if (status != 'OK') return null;

  final uses = (v['uses'] as List?) ?? const [];
  final oracleIds = <String>[];
  final names = <String>[];
  final commanderFlags = <bool>[];
  final seenOracle = <String>{};
  for (final u in uses) {
    if (u is! Map) continue;
    final card = u['card'];
    if (card is! Map) continue;
    final oracleId = card['oracleId']?.toString();
    final name = card['name']?.toString();
    if (oracleId == null || oracleId.isEmpty || name == null) continue;
    // Dedupe por oracle_id (uma carta listada 2x por quantidade não duplica PK).
    if (!seenOracle.add(oracleId)) continue;
    oracleIds.add(oracleId);
    names.add(name);
    commanderFlags.add(u['mustBeCommander'] == true);
  }
  if (oracleIds.length < 2) return null;

  final produces = <String>[];
  final producesRaw = (v['produces'] as List?) ?? const [];
  for (final p in producesRaw) {
    if (p is! Map) continue;
    final feature = p['feature'];
    final name = feature is Map ? feature['name']?.toString() : null;
    if (name != null && name.isNotEmpty) produces.add(name);
  }

  final easy = (v['easyPrerequisites'] ?? '').toString().trim();
  final notable = (v['notablePrerequisites'] ?? '').toString().trim();
  final prerequisites =
      [easy, notable].where((e) => e.isNotEmpty).join('\n').trim();

  return _ParsedCombo(
    id: id,
    status: status,
    colorIdentity: (v['identity'] ?? '').toString().toUpperCase(),
    manaNeeded: (v['manaNeeded'] ?? '').toString(),
    prerequisites: prerequisites,
    description: (v['description'] ?? '').toString(),
    produces: produces,
    oracleIds: oracleIds,
    names: names,
    commanderFlags: commanderFlags,
  );
}

Future<void> _upsertCombos(Pool pool, List<_ParsedCombo> combos) async {
  if (combos.isEmpty) {
    print('⚠️  Nenhum combo para inserir.');
    return;
  }

  // Lotes grandes com INSERT multi-linha para minimizar round-trips ao DB
  // (crítico quando o banco é remoto).
  const batchSize = 200;
  var done = 0;

  for (var start = 0; start < combos.length; start += batchSize) {
    final end = (start + batchSize).clamp(0, combos.length);
    final batch = combos.sublist(start, end);

    await pool.runTx((tx) async {
      // 1) Upsert de card_combos em uma única instrução multi-linha.
      final comboRows = <String>[];
      final comboParams = <String, dynamic>{};
      for (var i = 0; i < batch.length; i++) {
        final c = batch[i];
        comboRows.add(
          '(@id$i, \'commander_spellbook\', @st$i, @ci$i, @mn$i, @pr$i, '
          '@de$i, @po$i, @oi$i, @nm$i, @cc$i, CURRENT_TIMESTAMP)',
        );
        comboParams['id$i'] = c.id;
        comboParams['st$i'] = c.status;
        comboParams['ci$i'] = c.colorIdentity;
        comboParams['mn$i'] = c.manaNeeded;
        comboParams['pr$i'] = c.prerequisites;
        comboParams['de$i'] = c.description;
        comboParams['po$i'] = c.produces;
        comboParams['oi$i'] = c.oracleIds;
        comboParams['nm$i'] = c.names;
        comboParams['cc$i'] = c.oracleIds.length;
      }
      await tx.execute(
        Sql.named('''
          INSERT INTO card_combos (
            id, source, status, color_identity, mana_needed, prerequisites,
            description, produces, card_oracle_ids, card_names, card_count,
            updated_at
          ) VALUES ${comboRows.join(', ')}
          ON CONFLICT (id) DO UPDATE SET
            status = EXCLUDED.status,
            color_identity = EXCLUDED.color_identity,
            mana_needed = EXCLUDED.mana_needed,
            prerequisites = EXCLUDED.prerequisites,
            description = EXCLUDED.description,
            produces = EXCLUDED.produces,
            card_oracle_ids = EXCLUDED.card_oracle_ids,
            card_names = EXCLUDED.card_names,
            card_count = EXCLUDED.card_count,
            updated_at = CURRENT_TIMESTAMP
        '''),
        parameters: comboParams,
      );

      // 2) Reescreve combo_cards do lote: um DELETE + um INSERT multi-linha.
      final ids = batch.map((c) => c.id).toList();
      await tx.execute(
        Sql.named('DELETE FROM combo_cards WHERE combo_id = ANY(@ids)'),
        parameters: {'ids': ids},
      );

      final cardRows = <String>[];
      final cardParams = <String, dynamic>{};
      var k = 0;
      for (final c in batch) {
        for (var j = 0; j < c.oracleIds.length; j++) {
          cardRows.add('(@cb$k, @or$k, @cn$k, @cm$k)');
          cardParams['cb$k'] = c.id;
          cardParams['or$k'] = c.oracleIds[j];
          cardParams['cn$k'] = c.names[j];
          cardParams['cm$k'] = c.commanderFlags[j];
          k++;
        }
      }
      if (cardRows.isNotEmpty) {
        await tx.execute(
          Sql.named('''
            INSERT INTO combo_cards (combo_id, oracle_id, card_name, must_be_commander)
            VALUES ${cardRows.join(', ')}
            ON CONFLICT (combo_id, oracle_id) DO NOTHING
          '''),
          parameters: cardParams,
        );
      }
    });

    done += batch.length;
    print('   upsert $done/${combos.length}');
  }
}

Future<void> _ensureCombosTables(Pool pool) async {
  // As tabelas são criadas por bin/migrate.dart (migration 015). Aqui só
  // validamos a presença para falhar cedo com mensagem clara.
  final res = await pool.execute(
    Sql.named('''
      SELECT to_regclass('public.card_combos') IS NOT NULL AS has_combos,
             to_regclass('public.combo_cards') IS NOT NULL AS has_cards
    '''),
  );
  final row = res.first.toColumnMap();
  if (row['has_combos'] != true || row['has_cards'] != true) {
    throw Exception(
      'Tabelas card_combos/combo_cards ausentes. '
      'Rode `dart run bin/migrate.dart` antes do sync.',
    );
  }
}

Future<void> _syncComboFunctionTags(Pool pool) async {
  final hasTags = await _hasTable(pool, 'card_function_tags');
  if (!hasTags) {
    print('⚠️  card_function_tags ausente; combo_piece persistido não atualizado.');
    return;
  }

  print('🏷️  Reconciliando combo_piece com combo_cards...');
  await pool.runTx((tx) async {
    await tx.execute(
      Sql.named('''
        DELETE FROM card_function_tags cft
        WHERE cft.source = @source
          AND NOT EXISTS (
            SELECT 1
            FROM cards c
            JOIN combo_cards cc ON cc.oracle_id = c.scryfall_id::text
            WHERE c.id = cft.card_id
          )
      '''),
      parameters: {'source': _comboFunctionTagSource},
    );

    await tx.execute(
      Sql.named('''
        INSERT INTO card_function_tags (
          card_id, card_name, tag, confidence, source, evidence, updated_at
        )
        SELECT
          c.id,
          c.name,
          'combo_piece',
          0.960,
          @source,
          'present_in_commander_spellbook_combos:' || COUNT(DISTINCT cc.combo_id)::text,
          CURRENT_TIMESTAMP
        FROM cards c
        JOIN combo_cards cc ON cc.oracle_id = c.scryfall_id::text
        GROUP BY c.id, c.name
        ON CONFLICT (card_id, tag, source) DO UPDATE SET
          card_name = EXCLUDED.card_name,
          confidence = EXCLUDED.confidence,
          evidence = EXCLUDED.evidence,
          updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: {'source': _comboFunctionTagSource},
    );
  });

  final tagged = await pool.execute(
    Sql.named('''
      SELECT COUNT(*)::int
      FROM card_function_tags
      WHERE source = @source AND tag = 'combo_piece'
    '''),
    parameters: {'source': _comboFunctionTagSource},
  );
  print('   combo_piece persistido: ${tagged.first[0]} cartas');
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  try {
    final result = await pool.execute(
      Sql.named('SELECT to_regclass(@name) IS NOT NULL'),
      parameters: {'name': tableName},
    );
    return result.isNotEmpty && result.first[0] == true;
  } catch (_) {
    return false;
  }
}

Future<int> _count(Pool pool, String table) async {
  final res = await pool.execute(Sql.named('SELECT count(*)::int FROM $table'));
  return (res.first[0] as int?) ?? 0;
}

class _ParsedCombo {
  final String id;
  final String status;
  final String colorIdentity;
  final String manaNeeded;
  final String prerequisites;
  final String description;
  final List<String> produces;
  final List<String> oracleIds;
  final List<String> names;
  final List<bool> commanderFlags;

  _ParsedCombo({
    required this.id,
    required this.status,
    required this.colorIdentity,
    required this.manaNeeded,
    required this.prerequisites,
    required this.description,
    required this.produces,
    required this.oracleIds,
    required this.names,
    required this.commanderFlags,
  });
}
