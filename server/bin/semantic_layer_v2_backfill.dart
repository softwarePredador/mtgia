#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    'test/artifacts/semantic_layer_v2_backfill_2026-05-18';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  final limit = int.tryParse(_readArg(args, '--limit=') ?? '') ?? 0;
  final chunkSize = int.tryParse(_readArg(args, '--chunk-size=') ?? '') ?? 2500;
  if (chunkSize <= 0 || chunkSize > 10000) {
    throw ArgumentError('--chunk-size deve ficar entre 1 e 10000.');
  }

  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now().toUtc();
  final audit = _SemanticLayerV2Audit();

  var upsertedSemanticRows = 0;
  var upsertedFunctionRows = 0;

  try {
    if (apply) {
      await _ensureSchema(pool);
    }

    var offset = 0;
    var processed = 0;
    while (true) {
      final batchLimit = limit > 0
          ? (limit - processed).clamp(0, chunkSize).toInt()
          : chunkSize;
      if (batchLimit <= 0) break;
      final rows = await _loadCardRows(pool, limit: batchLimit, offset: offset);
      if (rows.isEmpty) break;
      final semanticRows = <Map<String, dynamic>>[];
      final functionRows = <Map<String, dynamic>>[];

      for (final row in rows) {
        final card = _BackfillCard.fromRow(row);
        final semantic = inferSemanticCardAnalysisV2(
          name: card.name,
          typeLine: card.typeLine,
          oracleText: card.oracleText,
          manaCost: card.manaCost,
          cmc: card.cmc,
        );
        audit.add(card, semantic);
        if (semantic.tags.isEmpty) continue;

        semanticRows.add({
          'card_id': card.id,
          'card_name': card.name,
          ...semantic.toJson(),
        });
        for (final tag in semantic.tags) {
          functionRows.add({
            'card_id': card.id,
            'card_name': card.name,
            'tag': tag.tag,
            'confidence': tag.confidence,
            'source': semanticLayerV2Source,
            'evidence': tag.evidence,
          });
        }
      }

      if (apply) {
        upsertedSemanticRows += await _upsertSemanticRows(pool, semanticRows);
        upsertedFunctionRows += await _upsertFunctionRows(pool, functionRows);
      }

      offset += rows.length;
      processed += rows.length;
      print('Processed $processed semantic v2 card rows');
      if (limit > 0 && processed >= limit) break;
    }

    final completedAt = DateTime.now().toUtc();
    final summary = {
      'schema_version': semanticLayerV2SchemaVersion,
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': completedAt.toIso8601String(),
      'duration_ms': completedAt.difference(startedAt).inMilliseconds,
      'artifact_safety': {
        'raw_rules_text_saved': false,
        'card_ids_saved': false,
        'full_deck_lists_saved': false,
        'secrets_saved': false,
        'free_text_evidence_saved': false,
      },
      ...audit.toJson(),
      'upserted_semantic_rows': upsertedSemanticRows,
      'upserted_function_tag_rows': upsertedFunctionRows,
    };
    _assertSanitized(summary);
    await _writeJson(
        '${artifactDir.path}/summary_${summary['mode']}.json', summary);
    await _writeMarkdownReport(
      '${artifactDir.path}/summary_${summary['mode']}.md',
      summary,
    );
    print('[OK] Semantic Layer v2 ${summary['mode']} concluido.');
    print('  - Artefatos: ${artifactDir.path}');
    print('  - Cobertura: ${summary['coverage']['coverage_pct']}%');
  } finally {
    await database.close();
  }
}

class _SemanticLayerV2Audit {
  final roleCounts = <String, int>{};
  final speedCounts = <String, int>{};
  final manaEfficiencyCounts = <String, int>{};
  final cardAdvantageCounts = <String, int>{};
  final interactionCounts = <String, int>{};
  final falsePositiveCandidates = <String, int>{};
  final regressions = <String, int>{};
  var rows = 0;
  var taggedRows = 0;
  var unknownRows = 0;
  var ambiguousRows = 0;

  void add(_BackfillCard card, SemanticCardAnalysisV2 semantic) {
    rows++;
    if (semantic.tags.isEmpty) {
      unknownRows++;
    } else {
      taggedRows++;
    }
    if (semantic.tags.length >= 4 ||
        (semantic.tags.isNotEmpty && semantic.roleConfidence < 0.65)) {
      ambiguousRows++;
    }
    _inc(speedCounts, semantic.speed);
    _inc(manaEfficiencyCounts, semantic.manaEfficiency);
    _inc(cardAdvantageCounts, semantic.cardAdvantageType);
    _inc(interactionCounts, semantic.interactionScope);
    for (final tag in semantic.tags) {
      _inc(roleCounts, tag.tag);
    }
    _flagFalsePositiveCandidates(card, semantic);
  }

  Map<String, dynamic> toJson() => {
        'coverage': {
          'card_rows': rows,
          'tagged_rows': taggedRows,
          'unknown_rows': unknownRows,
          'ambiguous_rows': ambiguousRows,
          'coverage_pct': rows == 0
              ? 0
              : double.parse(((taggedRows / rows) * 100).toStringAsFixed(3)),
        },
        'role_counts': _sorted(roleCounts),
        'speed_counts': _sorted(speedCounts),
        'mana_efficiency_counts': _sorted(manaEfficiencyCounts),
        'card_advantage_type_counts': _sorted(cardAdvantageCounts),
        'interaction_scope_counts': _sorted(interactionCounts),
        'false_positive_candidates': _sorted(falsePositiveCandidates),
        'regressions': _sorted(regressions),
      };

  void _flagFalsePositiveCandidates(
    _BackfillCard card,
    SemanticCardAnalysisV2 semantic,
  ) {
    final tags = semantic.tags.map((tag) => tag.tag).toSet();
    final oracle = card.oracleText.toLowerCase();
    if (tags.contains('tutor') && looksLikeOptimizationLandSearchText(oracle)) {
      _inc(regressions, 'land_search_counted_as_tutor');
    }
    if (tags.contains('lifegain') &&
        (oracle.contains("can't gain life") ||
            oracle.contains('cannot gain life'))) {
      _inc(regressions, 'lifegain_hate_counted_as_lifegain');
    }
    if (tags.contains('removal') &&
        oracle.contains('exile target') &&
        oracle.contains('return') &&
        oracle.contains('battlefield')) {
      _inc(falsePositiveCandidates, 'blink_like_removal');
    }
    if (tags.contains('ramp') &&
        semantic.manaEfficiency == 'expensive' &&
        semantic.cardAdvantageType == 'none') {
      _inc(falsePositiveCandidates, 'expensive_ramp_review');
    }
  }
}

class _BackfillCard {
  const _BackfillCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.cmc,
  });

  final String id;
  final String name;
  final String typeLine;
  final String oracleText;
  final String? manaCost;
  final Object? cmc;

  factory _BackfillCard.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return _BackfillCard(
      id: map['id'].toString(),
      name: (map['name'] as String?)?.trim() ?? '',
      typeLine: (map['type_line'] as String?)?.trim() ?? '',
      oracleText: (map['oracle_text'] as String?) ?? '',
      manaCost: (map['mana_cost'] as String?)?.trim(),
      cmc: map['cmc'],
    );
  }
}

Future<void> _ensureSchema(Pool pool) async {
  for (final statement in candidateQualitySchemaStatements) {
    await pool.execute(statement);
  }
  for (final statement in candidateQualityIndexStatements) {
    await pool.execute(statement);
  }
  await pool.execute(optimizeCandidateQualitySummaryViewStatement);
}

Future<List<ResultRow>> _loadCardRows(
  Pool pool, {
  required int limit,
  required int offset,
}) {
  return pool.execute(
    Sql.named('''
      SELECT id, name, type_line, oracle_text, mana_cost, cmc
      FROM cards
      WHERE COALESCE(type_line, '') <> ''
        AND COALESCE(oracle_text, '') <> ''
      ORDER BY name ASC, id ASC
      LIMIT @limit OFFSET @offset
    '''),
    parameters: {'limit': limit, 'offset': offset},
  );
}

Future<int> _upsertSemanticRows(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 750)) {
    await pool.execute(
      Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    card_name text,
    schema_version text,
    speed text,
    mana_efficiency text,
    card_advantage_type text,
    interaction_scope text,
    combo_piece boolean,
    wincon boolean,
    engine boolean,
    payoff boolean,
    enabler boolean,
    protection_type text,
    recursion_type text,
    role_confidence numeric,
    explanation_reason text,
    tags jsonb,
    source text
  )
)
INSERT INTO card_semantic_tags_v2 (
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine, payoff,
  enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
)
SELECT
  card_id::uuid, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine, payoff,
  enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, CURRENT_TIMESTAMP
FROM input
ON CONFLICT (card_id, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  schema_version = EXCLUDED.schema_version,
  speed = EXCLUDED.speed,
  mana_efficiency = EXCLUDED.mana_efficiency,
  card_advantage_type = EXCLUDED.card_advantage_type,
  interaction_scope = EXCLUDED.interaction_scope,
  combo_piece = EXCLUDED.combo_piece,
  wincon = EXCLUDED.wincon,
  engine = EXCLUDED.engine,
  payoff = EXCLUDED.payoff,
  enabler = EXCLUDED.enabler,
  protection_type = EXCLUDED.protection_type,
  recursion_type = EXCLUDED.recursion_type,
  role_confidence = EXCLUDED.role_confidence,
  explanation_reason = EXCLUDED.explanation_reason,
  tags = EXCLUDED.tags,
  updated_at = CURRENT_TIMESTAMP
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += batch.length;
  }
  return count;
}

Future<int> _upsertFunctionRows(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 1000)) {
    await pool.execute(
      Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    card_name text,
    tag text,
    confidence numeric,
    source text,
    evidence text
  )
)
INSERT INTO card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id::uuid, card_name, tag, confidence, source, evidence, CURRENT_TIMESTAMP
FROM input
ON CONFLICT (card_id, tag, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += batch.length;
  }
  return count;
}

void _inc(Map<String, int> map, String key) {
  final normalized = key.trim().isEmpty ? 'unknown' : key.trim();
  map[normalized] = (map[normalized] ?? 0) + 1;
}

Map<String, int> _sorted(Map<String, int> map) {
  final entries = map.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });
  return {for (final entry in entries) entry.key: entry.value};
}

Iterable<List<T>> _batches<T>(List<T> values, int size) sync* {
  for (var i = 0; i < values.length; i += size) {
    yield values.sublist(
        i, i + size > values.length ? values.length : i + size);
  }
}

Future<void> _writeJson(String path, Object payload) async {
  final encoder = const JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

Future<void> _writeMarkdownReport(
  String path,
  Map<String, dynamic> summary,
) async {
  final coverage = summary['coverage'] as Map<String, dynamic>;
  await File(path).writeAsString('''
# Semantic Layer v2 Backfill

## Resultado

- `mode`: `${summary['mode']}`
- `db_mutations`: `${summary['db_mutations']}`
- `schema_version`: `${summary['schema_version']}`
- `card_rows`: `${coverage['card_rows']}`
- `tagged_rows`: `${coverage['tagged_rows']}`
- `unknown_rows`: `${coverage['unknown_rows']}`
- `ambiguous_rows`: `${coverage['ambiguous_rows']}`
- `coverage_pct`: `${coverage['coverage_pct']}`

## Sanitizacao

O artefato contem somente agregados. Nao salva texto de regras bruto, card ids,
listas completas, credenciais, tokens, e-mails QA nem texto livre de usuarios.
''');
}

void _assertSanitized(Object payload) {
  final text = jsonEncode(payload);
  final forbiddenPatterns = [
    'OPENAI' '_API' '_KEY',
    'DATABASE' '_URL',
    'JWT',
    r'Bearer\s+',
    r'postgres:\/\/',
    r'@gmail\.com',
    r'@example\.com',
    'oracle' '_text',
    'deck' 'list',
  ];
  if (RegExp('(${forbiddenPatterns.join('|')})', caseSensitive: false)
      .hasMatch(text)) {
    throw StateError('Artifact sanitization failed for Semantic Layer v2.');
  }
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
semantic_layer_v2_backfill.dart - Backfill sanitizado da Semantic Layer v2

Uso:
  dart run bin/semantic_layer_v2_backfill.dart --dry-run
  dart run bin/semantic_layer_v2_backfill.dart --apply
  dart run bin/semantic_layer_v2_backfill.dart --dry-run --limit=500

Opcoes:
  --dry-run               Gera summary agregado sem mutar banco (default)
  --apply                 Cria schema aditivo e faz upsert idempotente
  --limit=<N>             Limita linhas processadas
  --chunk-size=<N>        Tamanho do lote (default: 2500)
  --artifact-dir=<path>   Diretorio dos artefatos
  --help                  Mostra esta ajuda
''');
}
