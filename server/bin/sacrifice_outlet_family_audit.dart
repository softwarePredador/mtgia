#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/database.dart';

const _heuristicSource = 'deterministic_heuristic_v1';
const _semanticSource = 'deterministic_semantic_v2';
const _outletTag = 'sacrifice_outlet';
const _outletEvidence = 'external_activated_sacrifice_outlet_cost';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('''
Read-only sacrifice outlet family audit.

Usage:
  dart run bin/sacrifice_outlet_family_audit.dart \
    --artifact-dir=/tmp/manaloom_sacrifice_outlet_family_audit \
    [--sample-limit=20]
''');
    return;
  }

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ??
        '/tmp/manaloom_sacrifice_outlet_family_audit',
  );
  final sampleLimit = _readIntArg(args, '--sample-limit=', fallback: 20);
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  try {
    final pool = database.connection;
    final heuristicCards = await _loadHeuristicOwnerCards(pool);
    final semanticCards = await _loadSemanticOwnerCards(pool);
    final expectedHeuristic = _expectedOutletIds(heuristicCards);
    final globalExpectedSemantic = _expectedOutletIds(semanticCards);
    final functionRows = await _loadFunctionRows(pool);
    final semanticRows = await _loadSemanticRows(pool);

    final currentHeuristic =
        functionRows
            .where((row) => row.source == _heuristicSource)
            .map((row) => row.cardId)
            .toSet();
    final currentSemanticFunction =
        functionRows
            .where((row) => row.source == _semanticSource)
            .map((row) => row.cardId)
            .toSet();
    final currentSemanticTags =
        semanticRows
            .where((row) => row.hasOutlet)
            .map((row) => row.cardId)
            .toSet();
    final existingSemanticIds = semanticRows.map((row) => row.cardId).toSet();
    final expectedSemantic = globalExpectedSemantic.intersection(
      existingSemanticIds,
    );
    final deferredMissingSemanticIds = globalExpectedSemantic.difference(
      existingSemanticIds,
    );
    final deferredMissingSemanticCards = <Map<String, dynamic>>[
      for (final card in semanticCards)
        if (deferredMissingSemanticIds.contains(card.id))
          {'card_id': card.id, 'card_name': card.name},
    ]..sort(
      (a, b) => (a['card_name'] as String).compareTo(b['card_name'] as String),
    );
    final nameById = <String, String>{
      for (final card in [...heuristicCards, ...semanticCards])
        card.id: card.name,
    };

    final summary = <String, dynamic>{
      'schema_version': 'pg873_sacrifice_outlet_family_audit_v2',
      'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'db_mutations': false,
      'classifier': {
        'tag': _outletTag,
        'confidence': 0.8,
        'evidence': _outletEvidence,
        'contract':
            'external activated sacrifice cost; self, named-self, trigger, additional-cost and parenthetical reminder text excluded',
      },
      'deferred_missing_semantic_snapshots': {
        'count': deferredMissingSemanticCards.length,
        'card_id_sha256': _digest(deferredMissingSemanticIds),
        'artifact': 'deferred_missing_semantic_cards.json',
        'contains_raw_oracle_text': false,
        'scope': 'full_semantic_backfill_required',
        'reason':
            'PG873 never creates partial card_semantic_tags_v2 snapshots; these cards require the complete deterministic semantic backfill contract.',
      },
      'owner_scopes': {
        _heuristicSource: {
          'cards_scanned': heuristicCards.length,
          ..._laneSummary(
            expected: expectedHeuristic,
            current: currentHeuristic,
            names: nameById,
            sampleLimit: sampleLimit,
          ),
          'current_wrong_evidence':
              functionRows
                  .where(
                    (row) =>
                        row.source == _heuristicSource &&
                        expectedHeuristic.contains(row.cardId) &&
                        row.evidence != _outletEvidence,
                  )
                  .length,
        },
        '${_semanticSource}_function': {
          'cards_scanned': semanticCards.length,
          'existing_semantic_snapshot_cards': existingSemanticIds.length,
          'global_expected_count': globalExpectedSemantic.length,
          'global_expected_card_id_sha256': _digest(globalExpectedSemantic),
          ..._laneSummary(
            expected: expectedSemantic,
            current: currentSemanticFunction,
            names: nameById,
            sampleLimit: sampleLimit,
          ),
          'current_wrong_evidence':
              functionRows
                  .where(
                    (row) =>
                        row.source == _semanticSource &&
                        expectedSemantic.contains(row.cardId) &&
                        row.evidence != _outletEvidence,
                  )
                  .length,
        },
        '${_semanticSource}_json': {
          'cards_scanned': semanticCards.length,
          'existing_semantic_snapshot_cards': existingSemanticIds.length,
          'global_expected_count': globalExpectedSemantic.length,
          'global_expected_card_id_sha256': _digest(globalExpectedSemantic),
          ..._laneSummary(
            expected: expectedSemantic,
            current: currentSemanticTags,
            names: nameById,
            sampleLimit: sampleLimit,
          ),
          'current_wrong_evidence':
              semanticRows
                  .where(
                    (row) =>
                        row.hasOutlet &&
                        expectedSemantic.contains(row.cardId) &&
                        row.outletEvidence != _outletEvidence,
                  )
                  .length,
        },
      },
    };

    final output = const JsonEncoder.withIndent('  ').convert(summary);
    await File('${artifactDir.path}/summary.json').writeAsString('$output\n');
    await File(
      '${artifactDir.path}/deferred_missing_semantic_cards.json',
    ).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(deferredMissingSemanticCards)}\n',
    );
    print(output);
  } finally {
    await database.close();
  }
}

Map<String, dynamic> _laneSummary({
  required Set<String> expected,
  required Set<String> current,
  required Map<String, String> names,
  required int sampleLimit,
}) {
  final toAdd = expected.difference(current);
  final toRemove = current.difference(expected);
  final retained = expected.intersection(current);
  return {
    'expected_count': expected.length,
    'expected_card_id_sha256': _digest(expected),
    'current_count': current.length,
    'current_card_id_sha256': _digest(current),
    'retained_count': retained.length,
    'to_add_count': toAdd.length,
    'to_remove_count': toRemove.length,
    'to_add_sample': _sampleNames(toAdd, names, sampleLimit),
    'to_remove_sample': _sampleNames(toRemove, names, sampleLimit),
  };
}

String _digest(Set<String> ids) {
  final sorted = ids.toList()..sort();
  return sha256.convert(utf8.encode(sorted.join('\n'))).toString();
}

List<String> _sampleNames(
  Set<String> ids,
  Map<String, String> names,
  int sampleLimit,
) {
  final values = ids.map((id) => names[id] ?? id).toList()..sort();
  return values.take(sampleLimit).toList(growable: false);
}

Set<String> _expectedOutletIds(List<_AuditCard> cards) {
  return {
    for (final card in cards)
      if (looksLikeExternalSacrificeOutlet(
        name: card.name,
        oracleText: card.oracleText,
      ))
        card.id,
  };
}

Future<List<_AuditCard>> _loadHeuristicOwnerCards(Pool pool) async {
  final rows = await pool.execute('''
SELECT DISTINCT ON (LOWER(c.name))
  c.id::text,
  c.name,
  COALESCE(c.oracle_text, '') AS oracle_text,
  COALESCE(c.type_line, '') AS type_line,
  c.mana_cost,
  c.cmc
FROM cards c
WHERE c.name IS NOT NULL
  AND c.name NOT LIKE 'A-%'
  AND c.name NOT LIKE '\\_%' ESCAPE '\\'
  AND c.name NOT LIKE '%World Champion%'
  AND c.name NOT LIKE '%Heroes of the Realm%'
ORDER BY LOWER(c.name), c.set_code ASC NULLS LAST, c.id ASC
''');
  return rows.map(_AuditCard.fromRow).toList(growable: false);
}

Future<List<_AuditCard>> _loadSemanticOwnerCards(Pool pool) async {
  final rows = await pool.execute('''
SELECT
  id::text,
  name,
  COALESCE(oracle_text, '') AS oracle_text,
  COALESCE(type_line, '') AS type_line,
  mana_cost,
  cmc
FROM cards
WHERE COALESCE(type_line, '') <> ''
  AND COALESCE(oracle_text, '') <> ''
ORDER BY name ASC, id ASC
''');
  return rows.map(_AuditCard.fromRow).toList(growable: false);
}

Future<List<_FunctionRow>> _loadFunctionRows(Pool pool) async {
  final rows = await pool.execute(
    Sql.named('''
SELECT card_id::text, source, COALESCE(evidence, '') AS evidence
FROM card_function_tags
WHERE tag = @tag
  AND source IN (@heuristicSource, @semanticSource)
'''),
    parameters: {
      'tag': _outletTag,
      'heuristicSource': _heuristicSource,
      'semanticSource': _semanticSource,
    },
  );
  return rows.map(_FunctionRow.fromRow).toList(growable: false);
}

Future<List<_SemanticRow>> _loadSemanticRows(Pool pool) async {
  final rows = await pool.execute('''
SELECT
  card_id::text,
  tags @> '[{"tag":"sacrifice_outlet"}]'::jsonb AS has_outlet,
  COALESCE((
    SELECT element->>'evidence'
    FROM jsonb_array_elements(tags) AS element
    WHERE element->>'tag' = 'sacrifice_outlet'
    LIMIT 1
  ), '') AS outlet_evidence
FROM card_semantic_tags_v2
WHERE source = 'deterministic_semantic_v2'
  AND schema_version = 'semantic_layer_v2_2026_05_18'
''');
  return rows.map(_SemanticRow.fromRow).toList(growable: false);
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

int _readIntArg(List<String> args, String prefix, {required int fallback}) {
  final raw = _readArg(args, prefix);
  final parsed = raw == null ? null : int.tryParse(raw);
  if (parsed == null || parsed < 0) return fallback;
  return parsed;
}

class _AuditCard {
  const _AuditCard({
    required this.id,
    required this.name,
    required this.oracleText,
    required this.typeLine,
    required this.manaCost,
    required this.cmc,
  });

  final String id;
  final String name;
  final String oracleText;
  final String typeLine;
  final String? manaCost;
  final Object? cmc;

  factory _AuditCard.fromRow(ResultRow row) => _AuditCard(
    id: row[0].toString(),
    name: (row[1] as String?)?.trim() ?? '',
    oracleText: (row[2] as String?) ?? '',
    typeLine: (row[3] as String?)?.trim() ?? '',
    manaCost: (row[4] as String?)?.trim(),
    cmc: row[5],
  );
}

class _FunctionRow {
  const _FunctionRow({
    required this.cardId,
    required this.source,
    required this.evidence,
  });

  final String cardId;
  final String source;
  final String evidence;

  factory _FunctionRow.fromRow(ResultRow row) => _FunctionRow(
    cardId: row[0].toString(),
    source: (row[1] as String?) ?? '',
    evidence: (row[2] as String?) ?? '',
  );
}

class _SemanticRow {
  const _SemanticRow({
    required this.cardId,
    required this.hasOutlet,
    required this.outletEvidence,
  });

  final String cardId;
  final bool hasOutlet;
  final String outletEvidence;

  factory _SemanticRow.fromRow(ResultRow row) => _SemanticRow(
    cardId: row[0].toString(),
    hasOutlet: (row[1] as bool?) ?? false,
    outletEvidence: (row[2] as String?) ?? '',
  );
}
