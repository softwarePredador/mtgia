// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import '../lib/ai/candidate_quality_data_support.dart';
import '../lib/import_card_lookup_service.dart';

final _tableDdlPattern = RegExp(
  r'CREATE\s+(?:TEMP(?:ORARY)?\s+|UNLOGGED\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z_][A-Za-z0-9_]*)',
  caseSensitive: false,
);
final _viewDdlPattern = RegExp(
  r'CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+([A-Za-z_][A-Za-z0-9_]*)',
  caseSensitive: false,
);

const _criticalViews = <String>[
  'card_identity_bridge',
  'card_intelligence_snapshot',
  'optimize_candidate_quality_summary',
];

const _criticalTables = <String>[
  'users',
  'cards',
  'sets',
  'card_legalities',
  'card_localized_names',
  'card_function_tags',
  'card_role_scores',
  'card_semantic_tags_v2',
  'card_battle_rules',
  'decks',
  'deck_cards',
  'deck_matchups',
  'battle_simulations',
  'deck_weakness_reports',
  'commander_learned_decks',
  'deck_learning_events',
  'commander_card_usage',
  'commander_card_synergy',
  'commander_reference_profiles',
  'commander_reference_card_stats',
  'commander_reference_decks',
  'commander_reference_deck_cards',
  'commander_reference_deck_analysis',
  'meta_decks',
  'external_commander_meta_candidates',
  'format_staples',
  'ai_optimize_cache',
  'ai_optimize_jobs',
  'ai_generate_jobs',
  'ml_prompt_feedback',
  'ai_logs',
];

const _externalSourceFindings = <Map<String, String>>[
  {
    'source': 'Scryfall Card API',
    'url': 'https://scryfall.com/docs/api/cards',
    'relevance':
        'Canonical card object fields for oracle_id, legalities, prices, images, all_parts, keywords, produced_mana, rulings_uri, and prints_search_uri.',
    'gap':
        'ManaLoom has core card identity and prices, but should keep all_parts/keywords/produced_mana/rulings_uri available for battle and decision trace enrichment.',
  },
  {
    'source': 'MTGJSON Card Atomic/Deck/Leadership Skills',
    'url': 'https://mtgjson.com/data-models/card/card-atomic/',
    'relevance':
        'Atomic cards separate oracle-like data from printing data; leadershipSkills marks formats where a card can be commander.',
    'gap':
        'Commander/Brawl eligibility should prefer explicit leadershipSkills/official rule gates over text-only inference when available.',
  },
  {
    'source': 'Wizards Commander Format',
    'url': 'https://magic.wizards.com/en/formats/commander',
    'relevance':
        'Official commander color identity, 100-card deck shape, command zone, commander tax, and commander damage framing.',
    'gap':
        'Keep strict color identity and commander tax/damage as backend-owned validation; do not outsource this to Hermes SQLite.',
  },
  {
    'source': 'Edge of Eternities Mechanics',
    'url':
        'https://magic.wizards.com/en/news/feature/edge-of-eternities-mechanics',
    'relevance':
        'Legendary Vehicles and Spacecraft with printed power/toughness can be commanders; Spacecraft/Station/Warp must be modeled deliberately.',
    'gap':
        'Battle/Commander legality should retain backlog coverage for Vehicle/Spacecraft commander, Station, Warp, Void, and Lander signals.',
  },
  {
    'source': '17Lands Metrics',
    'url': 'https://www.17lands.com/metrics_definitions',
    'relevance':
        'Metrics like OH WR, GIH WR, GP WR, IWD, ALSA, and ATA show how to avoid overtrusting raw win rate.',
    'gap':
        'Use methodology for Hermes scorecards only; do not import 17Lands card performance into Commander recommendations.',
  },
];

Future<void> main(List<String> args) async {
  final options = _AuditOptions.fromArgs(args);
  final repoRoot = _findRepoRoot(Directory.current);
  final serverRoot = Directory('${repoRoot.path}/server');

  final staticAudit = _runStaticAudit(repoRoot);
  final dbAudit = options.skipDb
      ? <String, dynamic>{'skipped': true, 'reason': '--skip-db'}
      : await _runDatabaseAudit(serverRoot, options.requireDb);

  final report = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'repo_root': repoRoot.path,
    'git': await _gitSummary(repoRoot),
    'static': staticAudit,
    'database': dbAudit,
    'external_sources': _externalSourceFindings,
    'recommendations': _recommendations(staticAudit, dbAudit),
  };

  final jsonText = const JsonEncoder.withIndent('  ').convert(report);
  if (options.jsonOutput != null) {
    await _writeFile(repoRoot, options.jsonOutput!, jsonText);
  }
  if (options.markdownOutput != null) {
    await _writeFile(repoRoot, options.markdownOutput!, _toMarkdown(report));
  }

  print(jsonText);
}

Map<String, dynamic> _runStaticAudit(Directory repoRoot) {
  final files = _scanFiles(repoRoot);
  final tableSources = <String, Set<String>>{};
  final viewSources = <String, Set<String>>{};

  for (final file in files) {
    final rel = _relative(repoRoot, file);
    final text = file.readAsStringSync();
    for (final match in _tableDdlPattern.allMatches(text)) {
      tableSources.putIfAbsent(match.group(1)!, () => {}).add(rel);
    }
    for (final match in _viewDdlPattern.allMatches(text)) {
      viewSources.putIfAbsent(match.group(1)!, () => {}).add(rel);
    }
  }

  final tableRefs = <String, Map<String, dynamic>>{};
  for (final table in tableSources.keys) {
    final readFiles = <String>{};
    final writeFiles = <String>{};
    final allFiles = <String>{};
    for (final file in files) {
      final rel = _relative(repoRoot, file);
      final text = file.readAsStringSync();
      if (RegExp(r'\b' + RegExp.escape(table) + r'\b').hasMatch(text)) {
        allFiles.add(rel);
      }
      if (RegExp(
        r'\b(FROM|JOIN)\s+' + RegExp.escape(table) + r'\b',
        caseSensitive: false,
      ).hasMatch(text)) {
        readFiles.add(rel);
      }
      if (RegExp(
        r'\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+' +
            RegExp.escape(table) +
            r'\b',
        caseSensitive: false,
      ).hasMatch(text)) {
        writeFiles.add(rel);
      }
    }
    tableRefs[table] = {
      'sources': tableSources[table]!.toList()..sort(),
      'classification': _classifyTable(table, tableSources[table]!),
      'read_files': readFiles.toList()..sort(),
      'write_files': writeFiles.toList()..sort(),
      'all_reference_count': allFiles.length,
      'has_runtime_read': readFiles.any((f) => _isRuntimeProductPath(f)),
      'has_runtime_write': writeFiles.any((f) => _isRuntimeProductPath(f)),
      'hermes_files':
          allFiles.where((f) => f.contains('hermes-analysis')).toList()..sort(),
    };
  }

  final appEndpoints = _scanAppEndpoints(repoRoot);
  final staleDocs = _scanStaleDocs(repoRoot);
  final syncScripts = _scanSyncScripts(repoRoot);

  return {
    'table_count': tableSources.length,
    'view_count': viewSources.length,
    'tables': Map.fromEntries(
      tableRefs.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    'views': Map.fromEntries(
      viewSources.entries
          .map((e) => MapEntry(e.key, e.value.toList()..sort()))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    ),
    'app_endpoints': appEndpoints,
    'sync_scripts': syncScripts,
    'stale_docs': staleDocs,
  };
}

Future<Map<String, dynamic>> _runDatabaseAudit(
  Directory serverRoot,
  bool requireDb,
) async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)
    ..load(['${serverRoot.path}/.env']);

  final host = env['DB_HOST'];
  final port = int.tryParse(env['DB_PORT'] ?? '');
  final database = env['DB_NAME'];
  final username = env['DB_USER'];
  final password = env['DB_PASS'];
  if (host == null ||
      port == null ||
      database == null ||
      username == null ||
      password == null) {
    if (requireDb) {
      throw StateError(
          'DB env vars missing: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS');
    }
    return {'skipped': true, 'reason': 'missing DB env vars'};
  }

  final connection = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    final relationRows = await connection.execute(
      Sql.named('''
        SELECT table_name, table_type
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name
      '''),
    );
    final relations = <String, String>{
      for (final row in relationRows)
        row.toColumnMap()['table_name'].toString():
            row.toColumnMap()['table_type'].toString(),
    };

    final rowCounts = <String, int?>{};
    for (final table in _criticalTables) {
      if (!relations.containsKey(table) ||
          relations[table] == 'VIEW' ||
          relations[table] == 'LOCAL TEMPORARY') {
        rowCounts[table] = null;
        continue;
      }
      rowCounts[table] = await _countRelation(connection, table);
    }

    final viewPresence = {
      for (final view in _criticalViews)
        view: relations[view] == 'VIEW' || relations[view] == 'BASE TABLE',
    };

    final rollbackValidation = await _validateViewsInRollback(connection);
    final fanout = await _fanoutChecks(connection, relations);

    return {
      'skipped': false,
      'connection': {
        'host': _redactHost(host),
        'port': port,
        'database': database,
        'username_present': username.isNotEmpty,
      },
      'relation_count': relations.length,
      'relations': relations,
      'critical_row_counts': rowCounts,
      'critical_view_presence': viewPresence,
      'rollback_view_validation': rollbackValidation,
      'fanout_checks': fanout,
    };
  } finally {
    await connection.close();
  }
}

Future<int> _countRelation(Connection connection, String relation) async {
  final result = await connection
      .execute('SELECT COUNT(*)::int AS c FROM ${_q(relation)}');
  return _toInt(result.first.toColumnMap()['c']);
}

Future<Map<String, dynamic>> _validateViewsInRollback(
    Connection connection) async {
  final result = <String, dynamic>{};
  await connection.execute('BEGIN');
  try {
    await connection.execute(Sql.named(createCardLocalizedNamesTableSql));
    for (final sql in createCardLocalizedNamesIndexesSql) {
      await connection.execute(Sql.named(sql));
    }
    for (final sql in candidateQualitySchemaStatements) {
      await connection.execute(Sql.named(sql));
    }
    for (final sql in candidateQualityIndexStatements) {
      await connection.execute(Sql.named(sql));
    }
    await connection
        .execute(Sql.named(optimizeCandidateQualitySummaryViewStatement));
    await connection.execute(Sql.named(cardIntelligenceSnapshotViewStatement));
    await connection.execute(Sql.named(createCardIdentityBridgeViewSql));

    for (final view in _criticalViews) {
      result[view] = {
        'compiled_in_rollback': true,
        'row_count_in_rollback': await _countRelation(connection, view),
      };
    }
  } catch (e) {
    result['error'] = e.toString();
  } finally {
    await connection.execute('ROLLBACK');
  }
  return result;
}

Future<Map<String, dynamic>> _fanoutChecks(
  Connection connection,
  Map<String, String> relations,
) async {
  final checks = <String, dynamic>{};

  if (relations.containsKey('deck_cards') &&
      relations.containsKey('card_intelligence_snapshot')) {
    checks['deck_cards_to_card_intelligence_snapshot'] = await _rowCompare(
      connection,
      '''
        SELECT
          COUNT(*)::int AS rows,
          COUNT(DISTINCT dc.id)::int AS distinct_deck_card_rows
        FROM deck_cards dc
        JOIN card_intelligence_snapshot cis ON cis.id = dc.card_id
      ''',
    );
  }

  if (relations.containsKey('deck_cards') &&
      relations.containsKey('card_battle_rules')) {
    checks['direct_deck_cards_to_card_battle_rules_fanout_potential'] =
        await _rowCompare(
      connection,
      '''
        SELECT
          COUNT(*)::int AS rows,
          COUNT(DISTINCT dc.id)::int AS distinct_deck_card_rows
        FROM deck_cards dc
        JOIN card_battle_rules cbr ON cbr.card_id = dc.card_id
      ''',
    );
  }

  if (relations.containsKey('cards') &&
      relations.containsKey('card_battle_rules')) {
    final result = await connection.execute('''
      SELECT COUNT(*)::int AS c
      FROM (
        SELECT card_id
        FROM card_battle_rules
        GROUP BY card_id
        HAVING COUNT(*) > 1
      ) x
    ''');
    checks['cards_with_multiple_battle_rules'] =
        _toInt(result.first.toColumnMap()['c']);
  }

  if (relations.containsKey('cards') &&
      relations.containsKey('card_function_tags')) {
    final result = await connection.execute('''
      SELECT COUNT(*)::int AS c
      FROM (
        SELECT card_id
        FROM card_function_tags
        GROUP BY card_id
        HAVING COUNT(*) > 1
      ) x
    ''');
    checks['cards_with_multiple_function_tags'] =
        _toInt(result.first.toColumnMap()['c']);
  }

  return checks;
}

Future<Map<String, int>> _rowCompare(Connection connection, String sql) async {
  final result = await connection.execute(sql);
  final row = result.first.toColumnMap();
  return {
    'rows': _toInt(row['rows']),
    'distinct_deck_card_rows': _toInt(row['distinct_deck_card_rows']),
    'extra_rows': _toInt(row['rows']) - _toInt(row['distinct_deck_card_rows']),
  };
}

List<File> _scanFiles(Directory repoRoot) {
  final roots = <Directory>[
    Directory('${repoRoot.path}/server'),
    Directory(
        '${repoRoot.path}/docs/hermes-analysis/manaloom-knowledge/scripts'),
  ].where((d) => d.existsSync()).toList();
  final allowed = {'.dart', '.sql', '.py', '.sh'};
  final files = <File>[];
  for (final root in roots) {
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (allowed.any((ext) => entity.path.endsWith(ext))) {
        files.add(entity);
      }
    }
  }
  return files;
}

Map<String, dynamic> _scanAppEndpoints(Directory repoRoot) {
  final appRoot = Directory('${repoRoot.path}/app/lib');
  if (!appRoot.existsSync()) return {'skipped': true};

  final endpoints = <String, Set<String>>{};
  final endpointPattern = RegExp(
    r'''(?:apiClient|_apiClient|api|_api)\.(?:get|post|put|delete)\(\s*['"]([^'"]+)['"]''',
  );
  for (final entity in appRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final rel = _relative(repoRoot, entity);
    final text = entity.readAsStringSync();
    for (final match in endpointPattern.allMatches(text)) {
      endpoints.putIfAbsent(match.group(1)!, () => {}).add(rel);
    }
  }
  return {
    'endpoint_count': endpoints.length,
    'endpoints': Map.fromEntries(
      endpoints.entries
          .map((e) => MapEntry(e.key, e.value.toList()..sort()))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    ),
  };
}

List<Map<String, String>> _scanStaleDocs(Directory repoRoot) {
  final docsRoot = Directory('${repoRoot.path}/docs/hermes-analysis');
  if (!docsRoot.existsSync()) return const [];
  final stalePatterns = <RegExp>[
    RegExp(r'deck_matchups.*write-only', caseSensitive: false),
    RegExp(r'deck_weakness_reports.*write-only', caseSensitive: false),
    RegExp(r'deck_matchups.*nunca', caseSensitive: false),
    RegExp(r'deck_weakness_reports.*nunca', caseSensitive: false),
  ];
  final findings = <Map<String, String>>[];
  for (final entity in docsRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.md')) continue;
    final rel = _relative(repoRoot, entity);
    if (rel ==
        'docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md') {
      continue;
    }
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('rejeitad')) {
        continue;
      }
      if (stalePatterns.any((p) => p.hasMatch(line))) {
        findings.add({'file': rel, 'line': '${i + 1}', 'text': line.trim()});
      }
    }
  }
  return findings;
}

Map<String, dynamic> _scanSyncScripts(Directory repoRoot) {
  final scriptsRoot = Directory(
      '${repoRoot.path}/docs/hermes-analysis/manaloom-knowledge/scripts');
  if (!scriptsRoot.existsSync()) return {'skipped': true};
  final rows = <Map<String, dynamic>>[];
  for (final entity
      in scriptsRoot.listSync(recursive: false, followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.py') && !name.endsWith('.sh')) continue;
    if (!name.contains('sync') &&
        !name.contains('export') &&
        !name.contains('import') &&
        !name.contains('materialize')) {
      continue;
    }
    final text = entity.readAsStringSync();
    rows.add({
      'file': _relative(repoRoot, entity),
      'direction': _classifySyncDirection(name, text),
      'mentions_postgres': text.contains('psycopg') ||
          text.contains('DB_HOST') ||
          text.contains('DATABASE_URL'),
      'mentions_sqlite': text.contains('sqlite3') || text.contains('.db'),
      'has_apply_flag': text.contains('--apply') || text.contains('apply='),
    });
  }
  return {'script_count': rows.length, 'scripts': rows};
}

String _classifySyncDirection(String name, String text) {
  if (name.startsWith('sync_pg_') || name.contains('_pg_to_')) {
    return 'postgres_to_hermes_or_local';
  }
  if (name.contains('materialize') || name.contains('export_hermes')) {
    return 'hermes_to_postgres_candidate';
  }
  if (name.contains('import')) return 'external_or_file_to_hermes';
  if (text.contains('DB_HOST') && text.contains('sqlite3')) {
    return 'mixed_postgres_sqlite';
  }
  return 'other_sync';
}

String _classifyTable(String table, Set<String> sources) {
  if (table.startsWith('tmp_')) return 'temporary';
  final hasProduct = sources.any((s) =>
      s == 'server/database_setup.sql' ||
      s == 'server/bin/migrate.dart' ||
      s.startsWith('server/lib/') ||
      s.startsWith('server/routes/'));
  final hasHermes = sources.any((s) => s.contains('docs/hermes-analysis'));
  if (hasProduct && hasHermes) return 'postgres_product_and_hermes_bridge';
  if (hasProduct) return 'postgres_product';
  if (hasHermes) return 'hermes_sqlite_or_lab';
  return 'unknown';
}

bool _isRuntimeProductPath(String path) =>
    path.startsWith('server/lib/') || path.startsWith('server/routes/');

List<Map<String, String>> _recommendations(
  Map<String, dynamic> staticAudit,
  Map<String, dynamic> dbAudit,
) {
  final recs = <Map<String, String>>[];

  final staleDocs = staticAudit['stale_docs'] as List<dynamic>? ?? const [];
  if (staleDocs.isNotEmpty) {
    recs.add({
      'priority': 'P1',
      'title': 'Clean stale Hermes docs about table usage',
      'reason':
          'Historical docs still claim write-only behavior for tables that now have runtime reads.',
      'action':
          'Move stale sections to historical notes or update them with current source evidence.',
    });
  }

  if (dbAudit['skipped'] != true) {
    final viewPresence =
        dbAudit['critical_view_presence'] as Map<String, dynamic>? ?? {};
    final missingViews = _criticalViews
        .where((view) => viewPresence[view] != true)
        .toList(growable: false);
    if (missingViews.isNotEmpty) {
      recs.add({
        'priority': 'P1',
        'title': 'Persist missing internal aggregate views',
        'reason':
            'Rollback compilation passed, but production does not currently expose ${missingViews.join(', ')}.',
        'action':
            'Run the backend-owned foundation/backfill path or migration before relying on those views in production-only diagnostics.',
      });
    }

    final fanout = dbAudit['fanout_checks'] as Map<String, dynamic>? ?? {};
    final direct =
        fanout['direct_deck_cards_to_card_battle_rules_fanout_potential'];
    if (direct is Map && _toInt(direct['extra_rows']) > 0) {
      recs.add({
        'priority': 'P0',
        'title': 'Keep battle-rule joins behind card_intelligence_snapshot',
        'reason':
            'Direct joins from deck_cards to card_battle_rules multiply deck rows.',
        'action':
            'Route deck analysis, optimize context, recommendations, weakness analysis, and Hermes syncs through aggregated snapshots.',
      });
    }
  }

  recs.add({
    'priority': 'P1',
    'title': 'Add commander_learning_snapshot',
    'reason':
        'Learned decks, commander usage, and Hermes evidence still require multiple table-specific reads.',
    'action':
        'Create an internal backend-owned snapshot for commander learning, keeping Hermes metadata hidden from normal app users.',
  });
  recs.add({
    'priority': 'P2',
    'title': 'Add decision-impact metrics inspired by 17Lands methodology',
    'reason':
        'Raw Lorehold WR is not enough to trust deck or battle improvements.',
    'action':
        'Track with/without-seen/cast deltas, sample size, baseline hash, and opponent archetype; do not import 17Lands Commander recommendations.',
  });
  return recs;
}

String _toMarkdown(Map<String, dynamic> report) {
  final staticAudit = report['static'] as Map<String, dynamic>;
  final database = report['database'] as Map<String, dynamic>;
  final recommendations = report['recommendations'] as List<dynamic>;
  final externalSources = report['external_sources'] as List<dynamic>;
  final staleDocs = staticAudit['stale_docs'] as List<dynamic>;
  final app = staticAudit['app_endpoints'] as Map<String, dynamic>;
  final sync = staticAudit['sync_scripts'] as Map<String, dynamic>;

  final b = StringBuffer()
    ..writeln('# Data Model Final Validation — 2026-06-15')
    ..writeln()
    ..writeln('Generated at: `${report['generated_at']}`')
    ..writeln()
    ..writeln('## Executive summary')
    ..writeln()
    ..writeln(
        '- Static inventory found `${staticAudit['table_count']}` tables and `${staticAudit['view_count']}` views across product backend and Hermes scripts.')
    ..writeln(
        '- App scan found `${app['endpoint_count'] ?? 0}` API endpoint string references in Flutter code.')
    ..writeln(
        '- Hermes sync scan found `${sync['script_count'] ?? 0}` sync/import/export/materialize scripts.')
    ..writeln(
        '- PostgreSQL validation was `${database['skipped'] == true ? 'skipped' : 'executed'}`.')
    ..writeln()
    ..writeln('## PostgreSQL runtime validation')
    ..writeln();

  if (database['skipped'] == true) {
    b.writeln('- Skipped: `${database['reason']}`');
  } else {
    b
      ..writeln('- Public relations found: `${database['relation_count']}`.')
      ..writeln(
          '- Critical view presence: `${jsonEncode(database['critical_view_presence'])}`.')
      ..writeln('- Rollback view validation:')
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ')
          .convert(database['rollback_view_validation']))
      ..writeln('```')
      ..writeln('- Fanout checks:')
      ..writeln('```json')
      ..writeln(
          const JsonEncoder.withIndent('  ').convert(database['fanout_checks']))
      ..writeln('```')
      ..writeln('- Critical row counts:')
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ')
          .convert(database['critical_row_counts']))
      ..writeln('```');
  }

  b
    ..writeln()
    ..writeln('## Static linkage validation')
    ..writeln()
    ..writeln(
        '- Table classification distinguishes `postgres_product`, `postgres_product_and_hermes_bridge`, and `hermes_sqlite_or_lab` to avoid false positives.')
    ..writeln(
        '- Low-use tables are not automatically bugs; lineage/cache/lab tables are valid when documented and excluded from app-facing assumptions.')
    ..writeln()
    ..writeln('### Stale documentation candidates')
    ..writeln();

  if (staleDocs.isEmpty) {
    b.writeln('- None found for current stale write-only patterns.');
  } else {
    for (final item in staleDocs.take(30)) {
      final row = item as Map<String, dynamic>;
      b.writeln('- `${row['file']}:${row['line']}` — ${row['text']}');
    }
  }

  b
    ..writeln()
    ..writeln('## Hermes / EasyPanel / SQL coherence')
    ..writeln()
    ..writeln('- PostgreSQL remains the source of truth for product behavior.')
    ..writeln(
        '- Hermes SQLite tables are classified as cache/lab/report-only unless a backend sync explicitly promotes reviewed data.')
    ..writeln(
        '- Scripts with `--apply` or materialization behavior must remain opt-in and reviewed before promotion.')
    ..writeln()
    ..writeln('## External source gap review')
    ..writeln();
  for (final item in externalSources) {
    final row = item as Map<String, dynamic>;
    b
      ..writeln('- [${row['source']}](${row['url']})')
      ..writeln('  - Relevance: ${row['relevance']}')
      ..writeln('  - Gap: ${row['gap']}');
  }

  b
    ..writeln()
    ..writeln('## Prioritized next actions')
    ..writeln();
  for (final item in recommendations) {
    final row = item as Map<String, dynamic>;
    b
      ..writeln('- **${row['priority']} — ${row['title']}**')
      ..writeln('  - Reason: ${row['reason']}')
      ..writeln('  - Action: ${row['action']}');
  }

  return b.toString();
}

Future<Map<String, dynamic>> _gitSummary(Directory repoRoot) async {
  Future<String> run(List<String> args) async {
    final result =
        await Process.run('git', args, workingDirectory: repoRoot.path);
    return result.stdout.toString().trim();
  }

  return {
    'head': await run(['rev-parse', 'HEAD']),
    'branch': await run(['branch', '--show-current']),
    'status_short': await run(['status', '--short']),
  };
}

Directory _findRepoRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (Directory('${current.path}/.git').existsSync() &&
        Directory('${current.path}/server').existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find repo root from ${start.path}');
    }
    current = parent;
  }
}

Future<void> _writeFile(Directory repoRoot, String path, String content) async {
  final rootPath = repoRoot.absolute.path;
  final file = File(path.startsWith('/') ? path : '$rootPath/$path').absolute;
  if (!file.path.startsWith('$rootPath/')) {
    throw ArgumentError('Output path must stay inside repo: $path');
  }
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

String _relative(Directory root, File file) =>
    file.absolute.path.replaceFirst('${root.absolute.path}/', '');

String _q(String identifier) => '"${identifier.replaceAll('"', '""')}"';

String _redactHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1') return host;
  final parts = host.split('.');
  if (parts.length == 4 && parts.every((p) => int.tryParse(p) != null)) {
    return '${parts.first}.x.x.${parts.last}';
  }
  if (parts.length > 2) return '${parts.first}.….' '${parts.last}';
  return '[redacted-host]';
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class _AuditOptions {
  final String? jsonOutput;
  final String? markdownOutput;
  final bool skipDb;
  final bool requireDb;

  const _AuditOptions({
    required this.jsonOutput,
    required this.markdownOutput,
    required this.skipDb,
    required this.requireDb,
  });

  factory _AuditOptions.fromArgs(List<String> args) {
    String? jsonOutput;
    String? markdownOutput;
    var skipDb = false;
    var requireDb = false;

    for (final arg in args) {
      if (arg.startsWith('--json-output=')) {
        jsonOutput = arg.substring('--json-output='.length);
      } else if (arg.startsWith('--markdown-output=')) {
        markdownOutput = arg.substring('--markdown-output='.length);
      } else if (arg == '--skip-db') {
        skipDb = true;
      } else if (arg == '--require-db') {
        requireDb = true;
      } else if (arg == '--help' || arg == '-h') {
        print('''
Usage: dart run bin/audit_data_model_links.dart [options]

Options:
  --json-output=<path>       Write full machine-readable audit.
  --markdown-output=<path>   Write human-readable report.
  --skip-db                  Skip PostgreSQL validation.
  --require-db               Fail if DB env vars or connection are unavailable.
''');
        exit(0);
      }
    }

    if (skipDb && requireDb) {
      throw ArgumentError('--skip-db and --require-db cannot be combined');
    }

    return _AuditOptions(
      jsonOutput: jsonOutput,
      markdownOutput: markdownOutput,
      skipDb: skipDb,
      requireDb: requireDb,
    );
  }
}
