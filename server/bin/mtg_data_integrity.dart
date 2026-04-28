import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/database.dart';
import 'package:server/mtg_data_integrity_support.dart';

const _defaultArtifactDir = 'test/artifacts/mtg_data_integrity_2026-04-28';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
mtg_data_integrity.dart - Auditoria e saneamento seguro de dados MTG

Uso:
  dart run bin/mtg_data_integrity.dart
  dart run bin/mtg_data_integrity.dart --apply-color-identity
  dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/mtg_data_integrity_2026-04-28

Opcoes:
  --apply-color-identity  Executa backfill idempotente em cards.color_identity IS NULL
  --artifact-dir=<path>   Diretorio dos artefatos (default: $_defaultArtifactDir)
  --help                 Mostra esta ajuda

Sem --apply-color-identity, o comando e dry-run e nao executa UPDATE/DELETE.
''');
    return;
  }

  final applyColorIdentity = args.contains('--apply-color-identity');
  final mode = applyColorIdentity ? 'apply' : 'dry_run';
  final artifactDir = Directory(
    _readArgValue(args, '--artifact-dir=') ?? _defaultArtifactDir,
  );
  await artifactDir.create(recursive: true);

  final startedAt = DateTime.now();
  final database = Database();
  await database.connect();
  final pool = database.connection;

  try {
    final duplicateVariants = await _loadDuplicateSetVariants(pool);
    final duplicateGroupCount =
        duplicateVariants.map((row) => row['lower_code']).toSet().length;
    await _writeJson(
      '${artifactDir.path}/duplicate_set_codes.json',
      duplicateVariants,
    );
    await _writeCsv(
      '${artifactDir.path}/duplicate_set_codes.csv',
      duplicateVariants,
      [
        'lower_code',
        'code',
        'name',
        'release_date',
        'type',
        'cards_exact_reference_count',
      ],
    );

    final cardSetReferences =
        await _loadCardSetReferencesForDuplicateGroups(pool);
    await _writeJson(
      '${artifactDir.path}/duplicate_set_card_references.json',
      cardSetReferences,
    );
    await _writeCsv(
      '${artifactDir.path}/duplicate_set_card_references.csv',
      cardSetReferences,
      ['lower_code', 'cards_set_code', 'card_count'],
    );

    final nullTotal = await _countNullColorIdentity(pool);
    final nullBySet = await _loadNullColorIdentityBySet(pool);
    await _writeJson(
        '${artifactDir.path}/null_color_identity_by_set.json', nullBySet);
    await _writeCsv(
      '${artifactDir.path}/null_color_identity_by_set.csv',
      nullBySet,
      [
        'set_code',
        'set_release_date',
        'null_count',
        'future_null_count',
        'recent_or_future_null_count',
        'colors_known_count',
        'mana_cost_known_count',
        'oracle_text_known_count',
        'type_line_known_count',
      ],
    );

    final nullByType = await _loadNullColorIdentityByType(pool);
    await _writeJson(
        '${artifactDir.path}/null_color_identity_by_type.json', nullByType);
    await _writeCsv(
      '${artifactDir.path}/null_color_identity_by_type.csv',
      nullByType,
      ['type_line', 'null_count', 'recent_or_future_null_count'],
    );

    final nullRows = await _loadNullColorIdentityRows(pool);
    final backfillCandidates = <Map<String, dynamic>>[];
    final unresolvedRows = <Map<String, dynamic>>[];

    for (final row in nullRows) {
      final decision = decideColorIdentityBackfill(
        colorsKnown: row['colors_known'] == true,
        colors: _stringList(row['colors']),
        manaCost: row['mana_cost']?.toString(),
        oracleText: row['oracle_text']?.toString(),
        typeLine: row['type_line']?.toString(),
      );

      final payload = {
        'id': row['id'],
        'name': row['name'],
        'set_code': row['set_code'],
        'set_release_date': _dateString(row['set_release_date']),
        'type_line': row['type_line'],
        'mana_cost': row['mana_cost'],
        'colors_known': row['colors_known'],
        'colors': _stringList(row['colors']).join('|'),
        'resolved_color_identity': decision.identity.join('|'),
        'sources': decision.sources.join('|'),
        'reason': decision.reason,
      };

      if (decision.deterministic) {
        backfillCandidates.add(payload);
      } else {
        unresolvedRows.add(payload);
      }
    }

    final backfillFilePrefix = applyColorIdentity
        ? 'color_identity_backfill_apply_candidates'
        : 'color_identity_backfill_dry_run';
    final unresolvedFilePrefix = applyColorIdentity
        ? 'color_identity_unresolved_apply'
        : 'color_identity_unresolved_dry_run';

    await _writeJson(
      '${artifactDir.path}/$backfillFilePrefix.json',
      backfillCandidates,
    );
    await _writeCsv(
      '${artifactDir.path}/$backfillFilePrefix.csv',
      backfillCandidates,
      [
        'id',
        'name',
        'set_code',
        'set_release_date',
        'type_line',
        'mana_cost',
        'colors_known',
        'colors',
        'resolved_color_identity',
        'sources',
        'reason',
      ],
    );
    await _writeJson(
      '${artifactDir.path}/$unresolvedFilePrefix.json',
      unresolvedRows,
    );
    await _writeCsv(
      '${artifactDir.path}/$unresolvedFilePrefix.csv',
      unresolvedRows,
      [
        'id',
        'name',
        'set_code',
        'set_release_date',
        'type_line',
        'mana_cost',
        'colors_known',
        'colors',
        'resolved_color_identity',
        'sources',
        'reason',
      ],
    );

    var updatedRows = 0;
    var nullAfterApply = nullTotal;
    if (applyColorIdentity) {
      updatedRows = await _applyColorIdentityBackfill(pool, backfillCandidates);
      nullAfterApply = await _countNullColorIdentity(pool);
    }

    final summary = {
      'mode': mode,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toIso8601String(),
      'artifact_dir': artifactDir.path,
      'duplicate_set_code_groups': duplicateGroupCount,
      'duplicate_set_code_variants': duplicateVariants.length,
      'null_color_identity_total': nullTotal,
      'null_color_identity_recent_or_future_total':
          _sumInt(nullBySet, 'recent_or_future_null_count'),
      'null_color_identity_future_total':
          _sumInt(nullBySet, 'future_null_count'),
      'color_identity_deterministic_backfill_candidates':
          backfillCandidates.length,
      'color_identity_unresolved_rows': unresolvedRows.length,
      'color_identity_updated_rows': updatedRows,
      'null_color_identity_after_apply': nullAfterApply,
      'db_mutations': applyColorIdentity,
    };
    await _writeJson('${artifactDir.path}/summary_$mode.json', summary);
    await _writeSummaryMarkdown(
      '${artifactDir.path}/summary_$mode.md',
      summary,
    );

    stdout.writeln(
      applyColorIdentity
          ? '✅ Backfill de color_identity concluido.'
          : '✅ Auditoria dry-run concluida.',
    );
    stdout.writeln('  - Artefatos: ${artifactDir.path}');
    stdout.writeln('  - Duplicidades LOWER(sets.code): $duplicateGroupCount');
    stdout.writeln('  - cards.color_identity IS NULL antes: $nullTotal');
    stdout.writeln(
      '  - Candidatos deterministicos: ${backfillCandidates.length}',
    );
    stdout.writeln('  - Unresolved: ${unresolvedRows.length}');
    if (applyColorIdentity) {
      stdout.writeln('  - Linhas atualizadas: $updatedRows');
      stdout
          .writeln('  - cards.color_identity IS NULL depois: $nullAfterApply');
    }
  } finally {
    await database.close();
  }
}

Future<List<Map<String, dynamic>>> _loadDuplicateSetVariants(Pool pool) async {
  final result = await pool.execute(Sql.named('''
    WITH duplicate_codes AS (
      SELECT LOWER(code) AS lower_code
      FROM sets
      GROUP BY LOWER(code)
      HAVING COUNT(*) > 1
    )
    SELECT
      LOWER(s.code) AS lower_code,
      s.code,
      s.name,
      s.release_date,
      s.type,
      COUNT(c.id)::int AS cards_exact_reference_count
    FROM sets s
    JOIN duplicate_codes d ON d.lower_code = LOWER(s.code)
    LEFT JOIN cards c ON c.set_code = s.code
    GROUP BY LOWER(s.code), s.code, s.name, s.release_date, s.type
    ORDER BY
      LOWER(s.code),
      CASE WHEN s.code = UPPER(s.code) THEN 0 ELSE 1 END,
      s.code
  '''));
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadCardSetReferencesForDuplicateGroups(
    Pool pool) async {
  final result = await pool.execute(Sql.named('''
    WITH duplicate_codes AS (
      SELECT LOWER(code) AS lower_code
      FROM sets
      GROUP BY LOWER(code)
      HAVING COUNT(*) > 1
    )
    SELECT
      LOWER(c.set_code) AS lower_code,
      c.set_code AS cards_set_code,
      COUNT(*)::int AS card_count
    FROM cards c
    JOIN duplicate_codes d ON d.lower_code = LOWER(c.set_code)
    GROUP BY LOWER(c.set_code), c.set_code
    ORDER BY LOWER(c.set_code), c.set_code
  '''));
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<int> _countNullColorIdentity(Pool pool) async {
  final result = await pool.execute(
    Sql.named('SELECT COUNT(*)::int FROM cards WHERE color_identity IS NULL'),
  );
  return (result.first[0] as num).toInt();
}

Future<List<Map<String, dynamic>>> _loadNullColorIdentityBySet(
    Pool pool) async {
  final result = await pool.execute(Sql.named('''
    WITH canonical_sets AS (
      SELECT *
      FROM (
        SELECT
          code,
          release_date,
          ROW_NUMBER() OVER (
            PARTITION BY LOWER(code)
            ORDER BY
              release_date DESC NULLS LAST,
              CASE WHEN code = UPPER(code) THEN 0 ELSE 1 END,
              name ASC
          ) AS rn
        FROM sets
      ) ranked
      WHERE rn = 1
    )
    SELECT
      c.set_code,
      s.release_date AS set_release_date,
      COUNT(*)::int AS null_count,
      COUNT(*) FILTER (
        WHERE s.release_date > CURRENT_DATE
      )::int AS future_null_count,
      COUNT(*) FILTER (
        WHERE s.release_date >= CURRENT_DATE - INTERVAL '180 days'
      )::int AS recent_or_future_null_count,
      COUNT(*) FILTER (WHERE c.colors IS NOT NULL)::int AS colors_known_count,
      COUNT(*) FILTER (
        WHERE c.mana_cost IS NOT NULL AND c.mana_cost <> ''
      )::int AS mana_cost_known_count,
      COUNT(*) FILTER (
        WHERE c.oracle_text IS NOT NULL AND c.oracle_text <> ''
      )::int AS oracle_text_known_count,
      COUNT(*) FILTER (
        WHERE c.type_line IS NOT NULL AND c.type_line <> ''
      )::int AS type_line_known_count
    FROM cards c
    LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
    WHERE c.color_identity IS NULL
    GROUP BY c.set_code, s.release_date
    ORDER BY null_count DESC, c.set_code
  '''));
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadNullColorIdentityByType(
    Pool pool) async {
  final result = await pool.execute(Sql.named('''
    WITH canonical_sets AS (
      SELECT *
      FROM (
        SELECT
          code,
          release_date,
          ROW_NUMBER() OVER (
            PARTITION BY LOWER(code)
            ORDER BY
              release_date DESC NULLS LAST,
              CASE WHEN code = UPPER(code) THEN 0 ELSE 1 END,
              name ASC
          ) AS rn
        FROM sets
      ) ranked
      WHERE rn = 1
    )
    SELECT
      COALESCE(c.type_line, '<NULL>') AS type_line,
      COUNT(*)::int AS null_count,
      COUNT(*) FILTER (
        WHERE s.release_date >= CURRENT_DATE - INTERVAL '180 days'
      )::int AS recent_or_future_null_count
    FROM cards c
    LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
    WHERE c.color_identity IS NULL
    GROUP BY COALESCE(c.type_line, '<NULL>')
    ORDER BY null_count DESC, type_line ASC
  '''));
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadNullColorIdentityRows(Pool pool) async {
  final result = await pool.execute(Sql.named('''
    WITH canonical_sets AS (
      SELECT *
      FROM (
        SELECT
          code,
          release_date,
          ROW_NUMBER() OVER (
            PARTITION BY LOWER(code)
            ORDER BY
              release_date DESC NULLS LAST,
              CASE WHEN code = UPPER(code) THEN 0 ELSE 1 END,
              name ASC
          ) AS rn
        FROM sets
      ) ranked
      WHERE rn = 1
    )
    SELECT
      c.id::text,
      c.name,
      c.set_code,
      s.release_date AS set_release_date,
      c.type_line,
      c.mana_cost,
      c.oracle_text,
      c.colors IS NOT NULL AS colors_known,
      c.colors
    FROM cards c
    LEFT JOIN canonical_sets s ON LOWER(s.code) = LOWER(c.set_code)
    WHERE c.color_identity IS NULL
    ORDER BY s.release_date DESC NULLS LAST, c.set_code, c.name
  '''));
  return result.map((row) => row.toColumnMap()).toList();
}

Future<int> _applyColorIdentityBackfill(
  Pool pool,
  List<Map<String, dynamic>> candidates,
) async {
  var updated = 0;

  final idsByIdentity = <String, List<String>>{};
  for (final candidate in candidates) {
    final id = candidate['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final identityKey = candidate['resolved_color_identity']?.toString() ?? '';
    idsByIdentity.putIfAbsent(identityKey, () => <String>[]).add(id);
  }

  for (final entry in idsByIdentity.entries) {
    final identity = _splitIdentity(entry.key);
    final ids = entry.value;
    for (var i = 0; i < ids.length; i += 500) {
      final batch = ids.sublist(i, (i + 500).clamp(0, ids.length));
      final result = await pool.execute(
        Sql.named('''
          UPDATE cards
          SET color_identity = @identity
          WHERE id::text = ANY(@ids) AND color_identity IS NULL
          RETURNING id
        '''),
        parameters: {
          'ids': batch,
          'identity': identity,
        },
      );
      updated += result.length;
    }
  }

  return updated;
}

List<String> _splitIdentity(Object? value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return const <String>[];
  return text.split('|').where((item) => item.isNotEmpty).toList();
}

String? _readArgValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length).trim();
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const <String>[];
}

int _sumInt(List<Map<String, dynamic>> rows, String key) => rows.fold<int>(
      0,
      (sum, row) => sum + ((row[key] as num?)?.toInt() ?? 0),
    );

Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> row) {
  return row.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
}

Object? _jsonSafeValue(Object? value) {
  if (value is DateTime) return _dateString(value);
  if (value is List) return value.map(_jsonSafeValue).toList();
  return value;
}

String? _dateString(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String().split('T').first;
  return value.toString();
}

Future<void> _writeJson(String path, Object payload) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
}

Future<void> _writeCsv(
  String path,
  List<Map<String, dynamic>> rows,
  List<String> headers,
) async {
  final buffer = StringBuffer()..writeln(headers.map(_csvCell).join(','));
  for (final row in rows) {
    buffer.writeln(headers.map((header) => _csvCell(row[header])).join(','));
  }
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(buffer.toString());
}

String _csvCell(Object? value) {
  final text = value == null ? '' : value.toString();
  return '"${text.replaceAll('"', '""')}"';
}

Future<void> _writeSummaryMarkdown(
  String path,
  Map<String, dynamic> summary,
) async {
  final lines = [
    '# MTG Data Integrity Dry-run Summary',
    '',
    '- Mode: `${summary['mode']}`',
    '- Artifact dir: `${summary['artifact_dir']}`',
    '- Duplicate `LOWER(sets.code)` groups: ${summary['duplicate_set_code_groups']}',
    '- Duplicate set-code variants: ${summary['duplicate_set_code_variants']}',
    '- `cards.color_identity IS NULL`: ${summary['null_color_identity_total']}',
    '- Recent/future null color identities: ${summary['null_color_identity_recent_or_future_total']}',
    '- Future null color identities: ${summary['null_color_identity_future_total']}',
    '- Deterministic backfill candidates: ${summary['color_identity_deterministic_backfill_candidates']}',
    '- Unresolved rows: ${summary['color_identity_unresolved_rows']}',
    '- Updated rows: ${summary['color_identity_updated_rows']}',
    '- Null color identities after apply: ${summary['null_color_identity_after_apply']}',
    '- DB mutations: `${summary['db_mutations']}`',
    '',
  ];
  await File(path).writeAsString(lines.join('\n'));
}
