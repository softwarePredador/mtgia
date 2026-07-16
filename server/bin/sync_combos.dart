// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/ai/commander_spellbook_service.dart';
import '../lib/database.dart';

const _comboFunctionTagSource = 'commander_spellbook_combo_v1';
const comboSyncWriteApprovalEnvironment = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const comboSyncWriteApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const minimumExpectedCommanderSpellbookCombos = 50000;

bool hasComboSyncWriteApproval(Map<String, String> environment) =>
    environment[comboSyncWriteApprovalEnvironment] ==
    comboSyncWriteApprovalPhrase;

/// Sincroniza a base de combos do Commander Spellbook.
///
/// Baixa o bulk `variants.json` (~500MB) para um arquivo temporário (streaming,
/// para não duplicar em memória), faz o parse e popula as tabelas `card_combos`
/// e `combo_cards`. Combos cujo `oracleId` não esteja presente em nenhuma carta
/// são mantidos mesmo assim — o match em runtime é por oracle_id.
///
/// Uso: dart run bin/sync_combos.dart [--dry-run] [--force] [--keep-file]
///
/// Opções:
///   --dry-run    Baixa, parseia e valida sem conectar ao PostgreSQL.
///   --force      Re-baixa o bulk mesmo se o cache local for recente (<24h).
///   --keep-file  Não apaga o arquivo temporário ao final.
Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final keepFile = args.contains('--keep-file');

  if (!dryRun && !hasComboSyncWriteApproval(Platform.environment)) {
    stderr.writeln(
      'BLOCKED: sincronizar Commander Spellbook altera PostgreSQL. Defina '
      '$comboSyncWriteApprovalEnvironment=$comboSyncWriteApprovalPhrase '
      'somente apos aprovacao explicita para esta execucao.',
    );
    exitCode = 2;
    return;
  }

  print('🔄 Sync de combos (Commander Spellbook)${dryRun ? ' [DRY-RUN]' : ''}');

  final tmpDir = Directory.systemTemp;
  final cacheFile = File('${tmpDir.path}/csb_variants.json');

  Database? db;

  try {
    final needsDownload =
        force ||
        !cacheFile.existsSync() ||
        DateTime.now().difference(cacheFile.lastModifiedSync()).inHours >= 24;

    if (needsDownload) {
      await _downloadBulk(cacheFile);
    } else {
      final sizeMb = (cacheFile.lengthSync() / (1024 * 1024)).toStringAsFixed(
        1,
      );
      print('📦 Reutilizando cache local (${sizeMb}MB, <24h).');
    }

    print('📖 Parse incremental do bulk...');
    final snapshot = await parseCommanderSpellbookBulk(cacheFile);
    final version = snapshot.version;
    final sourceUpdatedAt =
        snapshot.sourceUpdatedAt ?? cacheFile.lastModifiedSync().toUtc();
    final combos = snapshot.combos;
    final skipped = snapshot.skippedVariantCount;
    print('   version=$version, variants=${snapshot.rawVariantCount}');
    validateCommanderSpellbookSnapshot(combos);
    print('   válidos=${combos.length}, ignorados=$skipped');
    final compositionVerifiable =
        combos
            .where(
              (combo) =>
                  combo.prerequisites ==
                  commanderSpellbookVerifiedNoPrerequisitesMarker,
            )
            .length;
    final commanderConstrained =
        combos
            .where((combo) => combo.commanderFlags.any((required) => required))
            .length;
    print(
      '   composition_verifiable=$compositionVerifiable, '
      'requirements_fail_closed=${combos.length - compositionVerifiable}, '
      'must_be_commander=$commanderConstrained',
    );

    final contentHash =
        (await sha256.bind(cacheFile.openRead()).first).toString();
    print('   sha256=$contentHash');
    if (dryRun) {
      print('✅ DRY-RUN concluído: nenhuma conexão ou escrita PostgreSQL.');
      return;
    }

    db = Database();
    await db.connect();
    if (!db.isConnected) {
      throw StateError('Sem conexão com PostgreSQL.');
    }
    final pool = db.connection;
    await _ensureCombosTables(pool);
    await _reconcileCombos(
      pool,
      combos,
      metadata: ComboSnapshotMetadata(
        version: version,
        sourceUpdatedAt: sourceUpdatedAt,
        contentSha256: contentHash,
        rawVariantCount: snapshot.rawVariantCount,
        skippedVariantCount: skipped,
      ),
    );

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
    await db?.close();
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

/// Parses the large Commander Spellbook bulk one variant at a time.
///
/// The previous implementation materialized both the ~579MB JSON string and
/// its full decoded object graph. This scanner only retains the metadata
/// prefix, one variant object, and the compact parsed combo rows.
Future<ParsedCommanderSpellbookSnapshot> parseCommanderSpellbookBulk(
  File file,
) async {
  if (!file.existsSync()) {
    throw ArgumentError('Bulk Commander Spellbook inexistente: ${file.path}');
  }

  var prefix = '';
  var variantsStarted = false;
  var variantsFinished = false;
  String? version;
  DateTime? sourceUpdatedAt;
  StringBuffer? objectBuffer;
  var objectDepth = 0;
  var inString = false;
  var escaped = false;
  var rawVariantCount = 0;
  var skippedVariantCount = 0;
  final combos = <ParsedCommanderSpellbookCombo>[];

  void processVariantArrayText(String text) {
    for (final rune in text.runes) {
      if (variantsFinished) continue;
      final character = String.fromCharCode(rune);
      final buffer = objectBuffer;
      if (buffer == null) {
        if (character.trim().isEmpty || character == ',') continue;
        if (character == ']') {
          variantsFinished = true;
          continue;
        }
        if (character != '{') {
          throw FormatException(
            'Token inesperado no array variants: $character',
          );
        }
        objectBuffer = StringBuffer()..write(character);
        objectDepth = 1;
        inString = false;
        escaped = false;
        continue;
      }

      buffer.write(character);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character == '\\') {
          escaped = true;
        } else if (character == '"') {
          inString = false;
        }
        continue;
      }
      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        objectDepth++;
      } else if (character == '}') {
        objectDepth--;
        if (objectDepth == 0) {
          final decoded = jsonDecode(buffer.toString());
          if (decoded is! Map) {
            throw const FormatException('Variant deve ser um objeto JSON.');
          }
          rawVariantCount++;
          final parsed = parseCommanderSpellbookVariant(
            Map<String, dynamic>.from(decoded),
          );
          if (parsed == null) {
            skippedVariantCount++;
          } else {
            combos.add(parsed);
          }
          objectBuffer = null;
        }
      }
    }
  }

  await for (final chunk in file.openRead().transform(utf8.decoder)) {
    if (variantsStarted) {
      processVariantArrayText(chunk);
      continue;
    }

    prefix += chunk;
    if (prefix.length > 5 * 1024 * 1024) {
      throw const FormatException(
        'Chave variants ausente nos primeiros 5MB do bulk.',
      );
    }
    final keyIndex = prefix.indexOf('"variants"');
    if (keyIndex < 0) continue;
    final arrayIndex = prefix.indexOf('[', keyIndex + '"variants"'.length);
    if (arrayIndex < 0) continue;

    version = _extractJsonStringField(
      prefix.substring(0, arrayIndex),
      'version',
    );
    final timestamp = _extractJsonStringField(
      prefix.substring(0, arrayIndex),
      'timestamp',
    );
    sourceUpdatedAt = DateTime.tryParse(timestamp ?? '')?.toUtc();
    variantsStarted = true;
    final remainder = prefix.substring(arrayIndex + 1);
    prefix = '';
    processVariantArrayText(remainder);
  }

  if (!variantsStarted || !variantsFinished || objectBuffer != null) {
    throw const FormatException('Bulk Commander Spellbook truncado.');
  }
  if (version == null || version.trim().isEmpty) {
    throw const FormatException('Bulk Commander Spellbook sem version.');
  }

  return ParsedCommanderSpellbookSnapshot(
    version: version,
    sourceUpdatedAt: sourceUpdatedAt,
    rawVariantCount: rawVariantCount,
    skippedVariantCount: skippedVariantCount,
    combos: combos,
  );
}

String? _extractJsonStringField(String prefix, String field) {
  final match = RegExp(
    '"${RegExp.escape(field)}"\\s*:\\s*("(?:\\\\.|[^"\\\\])*")',
  ).firstMatch(prefix);
  final encoded = match?.group(1);
  if (encoded == null) return null;
  final decoded = jsonDecode(encoded);
  return decoded is String ? decoded : null;
}

/// Extrai um combo de uma variant do bulk. Retorna null se inválido.
ParsedCommanderSpellbookCombo? parseCommanderSpellbookVariant(
  Map<String, dynamic> v,
) {
  final id = v['id']?.toString();
  if (id == null || id.isEmpty) return null;

  final status = (v['status'] ?? 'OK').toString();
  // Apenas combos OK (exclui rascunhos / removidos).
  if (status != 'OK') return null;
  final legalities = v['legalities'];
  if (legalities is! Map || legalities['commander'] != true) return null;

  final uses = (v['uses'] as List?) ?? const [];
  final oracleIds = <String>[];
  final names = <String>[];
  final commanderFlags = <bool>[];
  final oracleIndex = <String, int>{};
  var hasUnverifiedCardMultiplicity = false;
  var hasUnverifiedUseState = false;
  for (final u in uses) {
    if (u is! Map) continue;
    final card = u['card'];
    if (card is! Map) continue;
    final oracleId = card['oracleId']?.toString();
    final name = card['name']?.toString();
    if (oracleId == null || oracleId.isEmpty || name == null) continue;
    final mustBeCommander = u['mustBeCommander'] == true;
    final quantity = int.tryParse((u['quantity'] ?? '').toString());
    if (quantity != 1) hasUnverifiedCardMultiplicity = true;
    final zones = ((u['zoneLocations'] as List?) ?? const [])
        .map((zone) => zone.toString())
        .toList(growable: false);
    if (zones.length != 1 || zones.single != 'B') {
      hasUnverifiedUseState = true;
    }
    for (final stateKey in const [
      'exileCardState',
      'libraryCardState',
      'graveyardCardState',
      'battlefieldCardState',
    ]) {
      if ((u[stateKey] ?? '').toString().trim().isNotEmpty) {
        hasUnverifiedUseState = true;
      }
    }
    // Dedupe por oracle_id (uma carta listada 2x por quantidade não duplica
    // PK), preservando a restrição mais forte se qualquer ocorrência exigir
    // que a carta seja o comandante.
    final existingIndex = oracleIndex[oracleId];
    if (existingIndex != null) {
      hasUnverifiedCardMultiplicity = true;
      commanderFlags[existingIndex] =
          commanderFlags[existingIndex] || mustBeCommander;
      continue;
    }
    oracleIndex[oracleId] = oracleIds.length;
    oracleIds.add(oracleId);
    names.add(name);
    commanderFlags.add(mustBeCommander);
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
  final templateRequirements = (v['requires'] as List?) ?? const [];
  final unverifiedTemplateRequirement =
      templateRequirements.isEmpty
          ? ''
          : '[unverified_template_requirements:${templateRequirements.length}]';
  final unverifiedMultiplicity =
      hasUnverifiedCardMultiplicity ? '[unverified_card_multiplicity]' : '';
  final unverifiedUseState =
      hasUnverifiedUseState ? '[unverified_use_state_requirements]' : '';
  final unverifiedPrerequisites =
      [
        easy,
        notable,
        unverifiedTemplateRequirement,
        unverifiedMultiplicity,
        unverifiedUseState,
      ].where((e) => e.isNotEmpty).join('\n').trim();
  final prerequisites =
      unverifiedPrerequisites.isEmpty
          ? commanderSpellbookVerifiedNoPrerequisitesMarker
          : unverifiedPrerequisites;

  return ParsedCommanderSpellbookCombo(
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

void validateCommanderSpellbookSnapshot(
  List<ParsedCommanderSpellbookCombo> combos, {
  int minimumCombos = minimumExpectedCommanderSpellbookCombos,
}) {
  if (combos.length < minimumCombos) {
    throw StateError(
      'Snapshot Commander Spellbook incompleto: ${combos.length} combos; '
      'minimo=$minimumCombos.',
    );
  }
  final distinctIds = combos.map((combo) => combo.id).toSet();
  if (distinctIds.length != combos.length) {
    throw StateError(
      'Snapshot Commander Spellbook contem IDs duplicados: '
      'rows=${combos.length}, distinct=${distinctIds.length}.',
    );
  }
}

Future<void> _reconcileCombos(
  Pool pool,
  List<ParsedCommanderSpellbookCombo> combos, {
  required ComboSnapshotMetadata metadata,
}) async {
  if (combos.isEmpty) {
    print('⚠️  Nenhum combo para inserir.');
    return;
  }

  // Lotes grandes com INSERT multi-linha para minimizar round-trips ao DB
  // (crítico quando o banco é remoto).
  // Cada statement permanece bem abaixo do limite de 65.535 parâmetros do
  // PostgreSQL, enquanto 1.000 reduz em 5x os round-trips pelo túnel remoto.
  const batchSize = 1000;
  var done = 0;

  await pool.runTx((tx) async {
    await tx.execute('''
      CREATE TEMP TABLE incoming_commander_spellbook_combo_ids (
        id TEXT PRIMARY KEY
      ) ON COMMIT DROP
    ''');

    for (var start = 0; start < combos.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, combos.length);
      final batch = combos.sublist(start, end);
      await _upsertComboBatch(tx, batch);
      done += batch.length;
      print('   staging/upsert $done/${combos.length}');
    }

    final staged = await tx.execute(
      'SELECT count(*)::int FROM incoming_commander_spellbook_combo_ids',
    );
    final stagedCount = staged.first[0] as int? ?? 0;
    if (stagedCount != combos.length) {
      throw StateError(
        'Staging Spellbook divergente: esperado=${combos.length}, '
        'obtido=$stagedCount.',
      );
    }

    // Snapshot-replace: variantes removidas ou que deixaram de ser OK saem
    // somente depois do staging integral, dentro da mesma transacao.
    await tx.execute('''
      DELETE FROM card_combos c
      WHERE c.source = 'commander_spellbook'
        AND NOT EXISTS (
          SELECT 1
          FROM incoming_commander_spellbook_combo_ids incoming
          WHERE incoming.id = c.id
        )
    ''');

    await _syncComboFunctionTags(tx);
    await tx.execute(
      Sql.named('''
        INSERT INTO data_source_snapshots (
          dataset, provider, source_uri, source_version, source_updated_at,
          source_etag, content_sha256, row_count, distinct_identity_count,
          status, metadata, completed_at
        ) VALUES (
          'commander_spellbook_combos', 'commander_spellbook', @uri, @version,
          @updated, '', @hash, @rows, @rows, 'succeeded', @metadata::jsonb,
          NOW()
        )
        ON CONFLICT (dataset, provider, content_sha256) DO UPDATE SET
          source_version = EXCLUDED.source_version,
          source_updated_at = EXCLUDED.source_updated_at,
          row_count = EXCLUDED.row_count,
          distinct_identity_count = EXCLUDED.distinct_identity_count,
          status = EXCLUDED.status,
          metadata = EXCLUDED.metadata,
          completed_at = EXCLUDED.completed_at
      '''),
      parameters: {
        'uri': CommanderSpellbookService.bulkUrl,
        'version': metadata.version,
        'updated': metadata.sourceUpdatedAt,
        'hash': metadata.contentSha256,
        'rows': combos.length,
        'metadata': jsonEncode({
          'raw_variant_count': metadata.rawVariantCount,
          'skipped_variant_count': metadata.skippedVariantCount,
          'composition_verifiable_count':
              combos
                  .where(
                    (combo) =>
                        combo.prerequisites ==
                        commanderSpellbookVerifiedNoPrerequisitesMarker,
                  )
                  .length,
          'requirements_fail_closed_count':
              combos
                  .where(
                    (combo) =>
                        combo.prerequisites !=
                        commanderSpellbookVerifiedNoPrerequisitesMarker,
                  )
                  .length,
          'must_be_commander_combo_count':
              combos
                  .where(
                    (combo) => combo.commanderFlags.any((required) => required),
                  )
                  .length,
          'requirements_contract': 'manaloom_requirements_v1_fail_closed',
        }),
      },
    );
  });
}

Future<void> _upsertComboBatch(
  Session tx,
  List<ParsedCommanderSpellbookCombo> batch,
) async {
  final comboRows = <String>[];
  final comboParams = <String, dynamic>{};
  final incomingRows = <String>[];
  final incomingParams = <String, dynamic>{};
  for (var i = 0; i < batch.length; i++) {
    final c = batch[i];
    comboRows.add(
      '(@id$i, \'commander_spellbook\', @st$i, @ci$i, @mn$i, @pr$i, '
      '@de$i, @po$i, @oi$i, @nm$i, @cc$i, CURRENT_TIMESTAMP)',
    );
    incomingRows.add('(@id$i)');
    incomingParams['id$i'] = c.id;
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
  await tx.execute(
    Sql.named('''
      INSERT INTO incoming_commander_spellbook_combo_ids (id)
      VALUES ${incomingRows.join(', ')}
      ON CONFLICT (id) DO NOTHING
    '''),
    parameters: incomingParams,
  );

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
}

Future<void> _ensureCombosTables(Pool pool) async {
  // As tabelas são criadas por bin/migrate.dart (migration 015). Aqui só
  // validamos a presença para falhar cedo com mensagem clara.
  final res = await pool.execute(
    Sql.named('''
      SELECT to_regclass('public.card_combos') IS NOT NULL AS has_combos,
             to_regclass('public.combo_cards') IS NOT NULL AS has_cards,
             to_regclass('public.data_source_snapshots') IS NOT NULL
               AS has_snapshots
    '''),
  );
  final row = res.first.toColumnMap();
  if (row['has_combos'] != true ||
      row['has_cards'] != true ||
      row['has_snapshots'] != true) {
    throw Exception(
      'Schema Spellbook incompleto (card_combos/combo_cards/'
      'data_source_snapshots). '
      'Rode `dart run bin/migrate.dart` antes do sync.',
    );
  }
}

Future<void> _syncComboFunctionTags(Session tx) async {
  final hasTags = await _hasTable(tx, 'card_function_tags');
  if (!hasTags) {
    print(
      '⚠️  card_function_tags ausente; combo_piece persistido não atualizado.',
    );
    return;
  }

  print('🏷️  Reconciliando combo_piece com combo_cards...');
  await tx.execute(
    Sql.named('''
        DELETE FROM card_function_tags cft
        WHERE cft.source = @source
          AND NOT EXISTS (
            SELECT 1
            FROM cards c
            JOIN combo_cards cc ON cc.oracle_id = c.oracle_id::text
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
        JOIN combo_cards cc ON cc.oracle_id = c.oracle_id::text
        GROUP BY c.id, c.name
        ON CONFLICT (card_id, tag, source) DO UPDATE SET
          card_name = EXCLUDED.card_name,
          confidence = EXCLUDED.confidence,
          evidence = EXCLUDED.evidence,
          updated_at = CURRENT_TIMESTAMP
      '''),
    parameters: {'source': _comboFunctionTagSource},
  );

  final tagged = await tx.execute(
    Sql.named('''
      SELECT COUNT(*)::int
      FROM card_function_tags
      WHERE source = @source AND tag = 'combo_piece'
    '''),
    parameters: {'source': _comboFunctionTagSource},
  );
  print('   combo_piece persistido: ${tagged.first[0]} cartas');
}

Future<bool> _hasTable(Session session, String tableName) async {
  try {
    final result = await session.execute(
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

class ParsedCommanderSpellbookCombo {
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

  ParsedCommanderSpellbookCombo({
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

class ParsedCommanderSpellbookSnapshot {
  final String version;
  final DateTime? sourceUpdatedAt;
  final int rawVariantCount;
  final int skippedVariantCount;
  final List<ParsedCommanderSpellbookCombo> combos;

  const ParsedCommanderSpellbookSnapshot({
    required this.version,
    required this.sourceUpdatedAt,
    required this.rawVariantCount,
    required this.skippedVariantCount,
    required this.combos,
  });
}

class ComboSnapshotMetadata {
  final String version;
  final DateTime sourceUpdatedAt;
  final String contentSha256;
  final int rawVariantCount;
  final int skippedVariantCount;

  const ComboSnapshotMetadata({
    required this.version,
    required this.sourceUpdatedAt,
    required this.contentSha256,
    required this.rawVariantCount,
    required this.skippedVariantCount,
  });
}
