import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/card_identity_support.dart';
import '../lib/mtg_data_integrity_support.dart';
import '../lib/runtime_environment.dart';
import '../lib/sync_cards_utils.dart';

/// Sincroniza cartas e legalidades do MTGJSON para o Postgres.
///
/// Uso:
/// - `dart run bin/sync_cards.dart`                 -> incremental (sets novos)
/// - `dart run bin/sync_cards.dart --full`          -> full sync (AtomicCards.json)
/// - `dart run bin/sync_cards.dart --full --force`  -> força re-download
/// - `dart run bin/sync_cards.dart --since-days=60` -> fallback de janela
///
/// Otimizações vs versão anterior:
/// - SetList.json baixado 1x e reutilizado (antes: 2x)
/// - Legalities com prepared statement seguro (antes: string interpolation)
/// - Incremental: carrega APENAS card IDs do set (antes: todos 33k+)
/// - Progresso com timing detalhado
const _metaUrl = 'https://mtgjson.com/api/v5/Meta.json';
const _setListUrl = 'https://mtgjson.com/api/v5/SetList.json';
const _atomicCardsUrl = 'https://mtgjson.com/api/v5/AtomicCards.json';
const _atomicCardsFileName = 'AtomicCards.json';

/// Tamanho do batch incremental.
/// 500 = bom equilíbrio para sets pequenos sem estourar a query Dart.
const _batchSize = 500;

/// Tamanho do batch do full sync executado pelo helper Python.
/// O full sync processa ~300k legalities; batch maior reduz centenas de
/// round-trips e commits sem prender tudo em uma única transação gigante.
const _fullBatchSize = 10000;

/// Timeout e tentativas para downloads HTTP externos.
const _httpTimeout = Duration(minutes: 3);
const _httpMaxRetries = 3;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
sync_cards.dart - Sincroniza cartas e legalidades (MTGJSON) para o Postgres

Uso:
  dart run bin/sync_cards.dart                Sync incremental (sets novos desde ultimo sync)
  dart run bin/sync_cards.dart --full         Full sync via AtomicCards.json
  dart run bin/sync_cards.dart --full --force Forca download e reprocessa tudo

Opcoes:
  --full           Executa sincronizacao completa (AtomicCards.json)
  --force          Forca re-download do AtomicCards.json
  --since-days=<N> Janela (dias) para fallback quando nao existe checkpoint (default: 45)
  --help           Mostra esta ajuda
''');
    return;
  }

  final force = args.contains('--force') || args.contains('-f');
  final full = args.contains('--full');
  final sinceDays = parseSinceDays(args) ?? 45;

  final env = loadRuntimeEnvironment();
  final environment = (env['ENVIRONMENT'] ?? 'development').toLowerCase();
  print(
    '🔄 Sync de cartas (ENVIRONMENT=$environment)${full ? ' [FULL]' : ' [INCREMENTAL]'}${force ? ' [FORÇADO]' : ''}',
  );

  final db = Database();
  await db.connect();
  final pool = db.connection;

  final startedAt = DateTime.now();
  try {
    await _ensureSyncStateTable(pool);
    await _ensureCardsColorIdentity(pool);
    await _ensureCardsCombatMetadata(pool);
    await _ensureSetsTable(pool);

    // Baixa SetList.json UMA VEZ e reutiliza
    final setListData = await _fetchSetListData();
    await _syncSetsFromData(pool, setListData);

    final meta = await _fetchMtgJsonMeta();
    final remoteVersion = (meta['version'] ?? '').toString().trim();
    final remoteDate = (meta['date'] ?? '').toString().trim();

    final lastVersion = await _getSyncState(pool, 'mtgjson_meta_version');
    final lastSyncAtStr = await _getSyncState(pool, 'cards_last_sync_at');
    final lastSyncAt =
        lastSyncAtStr != null ? DateTime.tryParse(lastSyncAtStr) : null;

    if (!force && lastVersion != null && lastVersion == remoteVersion) {
      print(
        '✅ MTGJSON ja esta atualizado (version=$remoteVersion). Nada a fazer.',
      );
      return;
    }

    print(
      '📦 MTGJSON remoto: version=$remoteVersion, date=$remoteDate (local=$lastVersion)',
    );

    final beforeCards = await _count(pool, 'cards');
    final beforeLegalities = await _count(pool, 'card_legalities');

    int processedCards;
    int processedLegalities;

    final hasExistingBase = beforeCards > 0;
    final effectiveLastSyncAt =
        lastSyncAt ??
        (hasExistingBase && !full
            ? DateTime.now().subtract(Duration(days: sinceDays))
            : null);

    if (full || effectiveLastSyncAt == null) {
      // FULL SYNC
      final atomicFile = await _downloadAtomicCards(force: force);
      final sw = Stopwatch()..start();

      final fullResult = await _syncFullAtomicFast(atomicFile);
      processedCards = fullResult.processedCards;
      processedLegalities = fullResult.processedLegalities;
      print('🃏 Cards + legalities concluido em ${sw.elapsedMilliseconds}ms');
    } else {
      // INCREMENTAL SYNC
      final setCodes = getNewSetCodesSinceFromData(
        setListData,
        effectiveLastSyncAt,
      );
      if (setCodes.isEmpty) {
        print(
          '✅ Nenhum set novo desde ${effectiveLastSyncAt.toIso8601String()}.',
        );
        processedCards = 0;
        processedLegalities = 0;
      } else {
        print('🆕 Sets novos (${setCodes.length}): ${setCodes.join(', ')}');
        processedCards = 0;
        processedLegalities = 0;

        for (final code in setCodes) {
          final setData = await _fetchSetJson(code);
          final cards =
              (setData['cards'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
          if (cards.isEmpty) continue;

          processedCards += await _upsertCardsFromSet(pool, cards, code);
          processedLegalities += await _upsertLegalitiesFromSet(pool, cards);
        }
      }
    }

    final afterCards = await _count(pool, 'cards');
    final afterLegalities = await _count(pool, 'card_legalities');

    await _setSyncState(pool, 'mtgjson_meta_version', remoteVersion);
    await _setSyncState(pool, 'mtgjson_meta_date', remoteDate);
    await _setSyncState(
      pool,
      'cards_last_sync_at',
      DateTime.now().toIso8601String(),
    );

    await _logSync(
      pool,
      syncType: 'cards',
      status: 'success',
      recordsInserted: (afterCards - beforeCards).clamp(0, 1 << 31),
      recordsUpdated: (processedCards - (afterCards - beforeCards)).clamp(
        0,
        1 << 31,
      ),
      recordsDeleted: 0,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
    await _logSync(
      pool,
      syncType: 'card_legalities',
      status: 'success',
      recordsInserted: (afterLegalities - beforeLegalities).clamp(0, 1 << 31),
      recordsUpdated: (processedLegalities -
              (afterLegalities - beforeLegalities))
          .clamp(0, 1 << 31),
      recordsDeleted: 0,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );

    final elapsed = DateTime.now().difference(startedAt);
    print('✅ Sync concluido em ${elapsed.inSeconds}s.');
    print('  - Cards: $processedCards processadas (total $afterCards)');
    print(
      '  - Legalities: $processedLegalities processadas (total $afterLegalities)',
    );
  } catch (e) {
    await _logSync(
      pool,
      syncType: 'cards',
      status: 'failed',
      recordsInserted: 0,
      recordsUpdated: 0,
      recordsDeleted: 0,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      errorMessage: e.toString(),
    );
    rethrow;
  } finally {
    await db.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INFRAESTRUTURA
// ═══════════════════════════════════════════════════════════════════════

Future<void> _ensureSyncStateTable(Pool pool) async {
  await pool.execute(
    Sql.named('''
    CREATE TABLE IF NOT EXISTS sync_state (
      key TEXT PRIMARY KEY,
      value TEXT,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  '''),
  );
}

Future<void> _ensureCardsColorIdentity(Pool pool) async {
  await pool.execute(
    Sql.named(
      'ALTER TABLE cards ADD COLUMN IF NOT EXISTS color_identity TEXT[]',
    ),
  );
  await pool.execute(
    Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_cards_color_identity ON cards USING GIN (color_identity)',
    ),
  );
}

Future<void> _ensureCardsCombatMetadata(Pool pool) async {
  await pool.execute(
    Sql.named('ALTER TABLE cards ADD COLUMN IF NOT EXISTS power TEXT'),
  );
  await pool.execute(
    Sql.named('ALTER TABLE cards ADD COLUMN IF NOT EXISTS toughness TEXT'),
  );
  await pool.execute(
    Sql.named('ALTER TABLE cards ADD COLUMN IF NOT EXISTS keywords TEXT[]'),
  );
  await pool.execute(
    Sql.named('ALTER TABLE cards ADD COLUMN IF NOT EXISTS is_reserved BOOLEAN'),
  );
  await pool.execute(
    Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_cards_keywords ON cards USING GIN (keywords)',
    ),
  );
}

Future<void> _ensureSetsTable(Pool pool) async {
  await pool.execute(
    Sql.named('''
    CREATE TABLE IF NOT EXISTS sets (
      code TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      release_date DATE,
      type TEXT,
      block TEXT,
      is_online_only BOOLEAN,
      is_foreign_only BOOLEAN,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  '''),
  );
}

Future<String?> _getSyncState(Pool pool, String key) async {
  final result = await pool.execute(
    Sql.named('SELECT value FROM sync_state WHERE key = @key'),
    parameters: {'key': key},
  );
  if (result.isEmpty) return null;
  return result.first[0] as String?;
}

Future<void> _setSyncState(Pool pool, String key, String value) async {
  await pool.execute(
    Sql.named('''
    INSERT INTO sync_state (key, value) VALUES (@key, @value)
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = CURRENT_TIMESTAMP
  '''),
    parameters: {'key': key, 'value': value},
  );
}

Future<int> _count(Pool pool, String table) async {
  final res = await pool.execute(Sql.named('SELECT count(*)::int FROM $table'));
  return (res.first[0] as int?) ?? 0;
}

Future<http.Response> _httpGetWithRetry(
  Uri uri, {
  required String label,
}) async {
  Object? lastError;

  for (var attempt = 1; attempt <= _httpMaxRetries; attempt++) {
    try {
      final response = await http.get(uri).timeout(_httpTimeout);
      if (response.statusCode == 200) {
        return response;
      }

      final retryable =
          response.statusCode == 429 || response.statusCode >= 500;
      final message =
          'Falha ao baixar $label: status=${response.statusCode} (tentativa $attempt/$_httpMaxRetries)';

      if (!retryable || attempt == _httpMaxRetries) {
        throw Exception(message);
      }

      print('⚠️  $message; tentando novamente...');
      await Future.delayed(Duration(seconds: attempt * 2));
    } on TimeoutException catch (e) {
      lastError = e;
      if (attempt == _httpMaxRetries) break;
      print(
        '⚠️  Timeout em $label (tentativa $attempt/$_httpMaxRetries); tentando novamente...',
      );
      await Future.delayed(Duration(seconds: attempt * 2));
    } on SocketException catch (e) {
      lastError = e;
      if (attempt == _httpMaxRetries) break;
      print(
        '⚠️  Erro de rede em $label (tentativa $attempt/$_httpMaxRetries); tentando novamente...',
      );
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }

  throw Exception(
    'Falha ao baixar $label apos $_httpMaxRetries tentativas: $lastError',
  );
}

Future<void> _logSync(
  Pool pool, {
  required String syncType,
  required String status,
  required int recordsInserted,
  required int recordsUpdated,
  required int recordsDeleted,
  required DateTime startedAt,
  required DateTime finishedAt,
  String? errorMessage,
}) async {
  try {
    await pool.execute(
      Sql.named('''
      INSERT INTO sync_log (
        sync_type, format, records_updated, records_inserted, records_deleted,
        status, error_message, started_at, finished_at
      ) VALUES (
        @syncType, NULL, @updated, @inserted, @deleted,
        @status, @error, @startedAt, @finishedAt
      )
    '''),
      parameters: {
        'syncType': syncType,
        'updated': recordsUpdated,
        'inserted': recordsInserted,
        'deleted': recordsDeleted,
        'status': status,
        'error': errorMessage,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
      },
    );
  } catch (_) {}
}

// ═══════════════════════════════════════════════════════════════════════
// DOWNLOAD / FETCH
// ═══════════════════════════════════════════════════════════════════════

Future<Map<String, dynamic>> _fetchMtgJsonMeta() async {
  final res = await _httpGetWithRetry(Uri.parse(_metaUrl), label: 'Meta.json');
  final decoded =
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  return decoded['data'] as Map<String, dynamic>;
}

/// Baixa SetList.json UMA VEZ e retorna a lista.
Future<List<dynamic>> _fetchSetListData() async {
  print('⬇️  Baixando SetList.json...');
  final res = await _httpGetWithRetry(
    Uri.parse(_setListUrl),
    label: 'SetList.json',
  );
  final decoded =
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  return decoded['data'] as List<dynamic>;
}

Future<Map<String, dynamic>> _fetchSetJson(String setCode) async {
  print('⬇️  Baixando set $setCode...');
  final res = await _httpGetWithRetry(
    Uri.parse('https://mtgjson.com/api/v5/$setCode.json'),
    label: '$setCode.json',
  );
  final decoded =
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  return decoded['data'] as Map<String, dynamic>;
}

Future<File> _downloadAtomicCards({required bool force}) async {
  final file = File(_atomicCardsFileName);
  if (!force && await file.exists()) {
    final size = await file.length();
    print(
      '📁 Usando cache local: $_atomicCardsFileName (${(size / 1024 / 1024).toStringAsFixed(1)}MB)',
    );
    return file;
  }
  print('⬇️  Baixando $_atomicCardsUrl (pode demorar ~1min)...');
  final res = await _httpGetWithRetry(
    Uri.parse(_atomicCardsUrl),
    label: 'AtomicCards.json',
  );
  await file.writeAsBytes(res.bodyBytes);
  print(
    '✅ Download concluido (${(res.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)}MB)',
  );
  return file;
}

Future<_FullAtomicSyncResult> _syncFullAtomicFast(File atomicFile) async {
  print('🚀 Full sync rapido via psycopg2/execute_values...');
  final pythonExecutable = Platform.isWindows ? 'python' : 'python3';
  final result = await Process.run(
    pythonExecutable,
    [
      'bin/sync_cards_full_fast.py',
      '--atomic-cards',
      atomicFile.path,
      '--batch-size',
      _fullBatchSize.toString(),
    ],
    workingDirectory: Directory.current.path,
    runInShell: Platform.isWindows,
  );

  final stderrText = result.stderr?.toString().trim() ?? '';
  if (stderrText.isNotEmpty) {
    for (final line in stderrText.split(RegExp(r'\r?\n'))) {
      if (line.trim().isNotEmpty) print('  $line');
    }
  }

  if (result.exitCode != 0) {
    final stdoutText = result.stdout?.toString().trim() ?? '';
    throw Exception(
      'sync_cards_full_fast.py falhou com exit=${result.exitCode}: '
      '${stderrText.isNotEmpty ? stderrText : stdoutText}',
    );
  }

  final stdoutText = result.stdout?.toString().trim() ?? '';
  if (stdoutText.isEmpty) {
    throw Exception('sync_cards_full_fast.py nao retornou JSON.');
  }
  final lastLine = stdoutText.split(RegExp(r'\r?\n')).last.trim();
  final decoded = jsonDecode(lastLine) as Map<String, dynamic>;
  return _FullAtomicSyncResult(
    processedCards: (decoded['processed_cards'] as num?)?.toInt() ?? 0,
    processedLegalities:
        (decoded['processed_legalities'] as num?)?.toInt() ?? 0,
  );
}

class _FullAtomicSyncResult {
  const _FullAtomicSyncResult({
    required this.processedCards,
    required this.processedLegalities,
  });

  final int processedCards;
  final int processedLegalities;
}

// ═══════════════════════════════════════════════════════════════════════
// SYNC DE SETS
// ═══════════════════════════════════════════════════════════════════════

Future<void> _syncSetsFromData(Pool pool, List<dynamic> setListData) async {
  print('📋 Sincronizando ${setListData.length} sets...');

  final rows = <List<Object?>>[];
  for (final item in setListData) {
    if (item is! Map) continue;
    final code = normalizeMtgSetCode(item['code']?.toString());
    final name = item['name']?.toString().trim();
    if (code == null || code.isEmpty || name == null || name.isEmpty) continue;

    final releaseDateStr = item['releaseDate']?.toString();
    final releaseDate =
        releaseDateStr != null ? DateTime.tryParse(releaseDateStr) : null;

    rows.add([
      code,
      name,
      releaseDate?.toIso8601String().split('T').first,
      item['type']?.toString(),
      item['block']?.toString(),
      item['isOnlineOnly'] as bool?,
      item['isForeignOnly'] as bool?,
    ]);
  }

  final dedupedRows = _dedupeRowsByKey(rows, (row) => row[0]?.toString() ?? '');
  for (var i = 0; i < dedupedRows.length; i += _batchSize) {
    final end = (i + _batchSize).clamp(0, dedupedRows.length);
    await _upsertSetRowsBatch(pool, dedupedRows.sublist(i, end));
  }
}

Future<void> _upsertSetRowsBatch(Pool pool, List<List<Object?>> rows) async {
  if (rows.isEmpty) return;

  const columns = [
    'code',
    'name',
    'release_date',
    'type',
    'block',
    'is_online_only',
    'is_foreign_only',
  ];
  final parameters = <String, Object?>{};
  final valuesSql = <String>[];

  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final placeholders = <String>[];
    final row = rows[rowIndex];
    for (var colIndex = 0; colIndex < columns.length; colIndex++) {
      final key = 'r${rowIndex}c$colIndex';
      parameters[key] = row[colIndex];
      placeholders.add('@$key');
    }
    valuesSql.add('(${placeholders.join(', ')}, CURRENT_TIMESTAMP)');
  }

  await pool.execute(
    Sql.named('''
    INSERT INTO sets (${columns.join(', ')}, updated_at)
    VALUES ${valuesSql.join(', ')}
    ON CONFLICT (code) DO UPDATE SET
      name = EXCLUDED.name,
      release_date = EXCLUDED.release_date,
      type = EXCLUDED.type,
      block = EXCLUDED.block,
      is_online_only = EXCLUDED.is_online_only,
      is_foreign_only = EXCLUDED.is_foreign_only,
      updated_at = CURRENT_TIMESTAMP
  '''),
    parameters: parameters,
  );
}

// ═══════════════════════════════════════════════════════════════════════
// UPSERT DE CARDS
// ═══════════════════════════════════════════════════════════════════════

/// Incremental: processa cartas de um set em batch.
Future<int> _upsertCardsFromSet(
  Pool pool,
  List<Map<String, dynamic>> cards,
  String setCode,
) async {
  final canonicalSetCode = normalizeMtgSetCode(setCode) ?? setCode.trim();
  print('🃏 Upsert de ${cards.length} cards (set=$canonicalSetCode)...');

  final includeIdentityColumns = await hasCardIdentityColumns(pool);
  var processed = 0;
  final rows = <List<Object?>>[];
  for (final card in cards) {
    final row = extractSetCardSyncRow(card, canonicalSetCode);
    if (row != null) rows.add(row);
  }
  final dedupedRows = _dedupeRowsByKey(rows, (row) => row[0]?.toString() ?? '');

  for (var i = 0; i < dedupedRows.length; i += _batchSize) {
    final end = (i + _batchSize).clamp(0, dedupedRows.length);
    final batch = dedupedRows.sublist(i, end);
    await _upsertCardRowsBatch(
      pool,
      batch,
      includeCollectorFoil: true,
      includeIdentityColumns: includeIdentityColumns,
    );
    processed += batch.length;
  }
  return processed;
}

Future<void> _upsertCardRowsBatch(
  Pool pool,
  List<List<Object?>> rows, {
  required bool includeCollectorFoil,
  required bool includeIdentityColumns,
}) async {
  if (rows.isEmpty) return;

  final columns = [
    'scryfall_id',
    if (includeIdentityColumns) 'oracle_id',
    'name',
    'mana_cost',
    'type_line',
    'oracle_text',
    'colors',
    'color_identity',
    'power',
    'toughness',
    'keywords',
    'image_url',
    'set_code',
    'rarity',
    'is_reserved',
    if (includeCollectorFoil) 'collector_number',
    if (includeCollectorFoil) 'foil',
    if (includeIdentityColumns) 'layout',
    if (includeIdentityColumns) 'card_faces_json',
  ];
  final params = <String, Object?>{};
  final values = <String>[];

  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final rowValues = [
      row[0],
      if (includeIdentityColumns) row[1],
      row[2],
      row[3],
      row[4],
      row[5],
      row[6],
      row[7],
      row[8],
      row[9],
      row[10],
      row[11],
      row[12],
      row[13],
      row[14],
      if (includeCollectorFoil) row[15],
      if (includeCollectorFoil) row[16],
      if (includeIdentityColumns) row[17],
      if (includeIdentityColumns) row[18],
    ];
    final placeholders = <String>[];
    for (var columnIndex = 0; columnIndex < rowValues.length; columnIndex++) {
      final key = 'v_${rowIndex}_$columnIndex';
      params[key] = rowValues[columnIndex];
      placeholders.add('@$key');
    }
    values.add('(${placeholders.join(', ')})');
  }

  final collectorUpdates =
      includeCollectorFoil
          ? '''
      collector_number = COALESCE(EXCLUDED.collector_number, cards.collector_number),
      foil = COALESCE(EXCLUDED.foil, cards.foil),
'''
          : '';
  final identityUpdates =
      includeIdentityColumns
          ? '''
      oracle_id = COALESCE(EXCLUDED.oracle_id, cards.oracle_id),
      layout = COALESCE(EXCLUDED.layout, cards.layout),
      card_faces_json = COALESCE(EXCLUDED.card_faces_json, cards.card_faces_json),
'''
          : '';

  final sql = '''
    INSERT INTO cards (${columns.join(', ')})
    VALUES ${values.join(',\n')}
    ON CONFLICT (scryfall_id) DO UPDATE SET
      name = EXCLUDED.name,
      mana_cost = EXCLUDED.mana_cost,
      type_line = EXCLUDED.type_line,
      oracle_text = EXCLUDED.oracle_text,
      colors = EXCLUDED.colors,
      color_identity = EXCLUDED.color_identity,
      power = EXCLUDED.power,
      toughness = EXCLUDED.toughness,
      keywords = EXCLUDED.keywords,
      image_url = CASE
        WHEN EXCLUDED.image_url LIKE 'https://cards.scryfall.io/%'
          THEN EXCLUDED.image_url
        WHEN cards.image_url LIKE 'https://cards.scryfall.io/%'
          THEN cards.image_url
        ELSE EXCLUDED.image_url
      END,
      set_code = EXCLUDED.set_code,
      rarity = EXCLUDED.rarity,
      is_reserved = COALESCE(EXCLUDED.is_reserved, cards.is_reserved),
      $identityUpdates
      $collectorUpdates
      created_at = cards.created_at
  ''';

  await pool.runTx((session) async {
    await session.execute(Sql.named(sql), parameters: params);
  });
}

List<List<Object?>> _dedupeRowsByKey(
  List<List<Object?>> rows,
  String Function(List<Object?> row) keyOf,
) {
  final byKey = <String, List<Object?>>{};
  for (final row in rows) {
    final key = keyOf(row);
    if (key.isEmpty) continue;
    byKey[key] = row;
  }
  return byKey.values.toList(growable: false);
}

// ═══════════════════════════════════════════════════════════════════════
// UPSERT DE LEGALITIES
// ═══════════════════════════════════════════════════════════════════════

/// Incremental: legalidades de um set em batch.
/// Carrega APENAS os card IDs relevantes (nao todos 33k+).
Future<int> _upsertLegalitiesFromSet(
  Pool pool,
  List<Map<String, dynamic>> cards,
) async {
  // Coleta oracle IDs deste set
  final oracleIds = <String>{};
  for (final card in cards) {
    final ids = card['identifiers'] as Map<String, dynamic>?;
    final oid = ids?['scryfallOracleId']?.toString();
    if (oid != null && oid.isNotEmpty) oracleIds.add(oid);
  }
  if (oracleIds.isEmpty) return 0;

  // Carrega APENAS os IDs internos necessarios
  final cardIdMap = await _loadCardIdMapForOracleIds(pool, oracleIds);

  var processed = 0;
  final rows = <List<Object?>>[];
  for (final card in cards) {
    final ids = card['identifiers'] as Map<String, dynamic>?;
    final oracleId = ids?['scryfallOracleId']?.toString();
    if (oracleId == null) continue;
    final internalId = cardIdMap[oracleId];
    if (internalId == null) continue;

    final legalities = card['legalities'] as Map<String, dynamic>?;
    if (legalities == null) continue;

    for (final entry in legalities.entries) {
      rows.add([internalId, entry.key, entry.value.toString().toLowerCase()]);
    }
  }
  final dedupedRows = _dedupeRowsByKey(rows, (row) => '${row[0]}|${row[1]}');

  for (var i = 0; i < dedupedRows.length; i += _batchSize) {
    final end = (i + _batchSize).clamp(0, dedupedRows.length);
    final batch = dedupedRows.sublist(i, end);
    await _upsertLegalityRowsBatch(pool, batch);
    processed += batch.length;
  }
  return processed;
}

/// Carrega APENAS os oracle_id -> internal_id de um conjunto especifico.
Future<Map<String, String>> _loadCardIdMapForOracleIds(
  Pool pool,
  Set<String> oracleIds,
) async {
  if (oracleIds.isEmpty) return {};
  final hasIdentityColumns = await hasCardIdentityColumns(pool);
  final sql =
      hasIdentityColumns
          ? '''
      SELECT COALESCE(oracle_id, scryfall_id)::text AS oracle_lookup_id,
             id::text
      FROM cards
      WHERE oracle_id = ANY(@ids)
         OR scryfall_id = ANY(@ids)
    '''
          : '''
      SELECT scryfall_id::text AS oracle_lookup_id,
             id::text
      FROM cards
      WHERE scryfall_id = ANY(@ids)
    ''';
  final result = await pool.execute(
    Sql.named(sql),
    parameters: {'ids': oracleIds.toList()},
  );
  final map = <String, String>{};
  for (final row in result) {
    map[row[0] as String] = row[1] as String;
  }
  return map;
}

Future<void> _upsertLegalityRowsBatch(
  Pool pool,
  List<List<Object?>> rows,
) async {
  if (rows.isEmpty) return;

  final params = <String, Object?>{};
  final values = <String>[];
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final placeholders = <String>[];
    for (var columnIndex = 0; columnIndex < 3; columnIndex++) {
      final key = 'l_${rowIndex}_$columnIndex';
      params[key] = row[columnIndex];
      placeholders.add('@$key');
    }
    values.add('(${placeholders.join(', ')})');
  }

  final sql = '''
    INSERT INTO card_legalities (card_id, format, status)
    VALUES ${values.join(',\n')}
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status
  ''';

  await pool.runTx((session) async {
    await session.execute(Sql.named(sql), parameters: params);
  });
}
