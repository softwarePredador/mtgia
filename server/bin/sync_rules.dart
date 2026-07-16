import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';
import '../lib/runtime_environment.dart';

/// Sincroniza as Comprehensive Rules (Wizards) para a tabela `rules`.
///
/// Fonte: https://magic.wizards.com/en/rules (links para MagicCompRules *.txt)
///
/// Uso:
///   dart run bin/sync_rules.dart --check
///   dart run bin/sync_rules.dart
///   dart run bin/sync_rules.dart --force
///   dart run bin/sync_rules.dart --from-file=magicrules.txt
///
/// O script:
/// - `--check` compara fonte, cache e PostgreSQL sem gravar em nenhum deles;
/// - qualquer modo mutavel exige aprovacao textual explicita;
/// - substitui `rules` e seus metadados `sync_state` na mesma transacao;
/// - atualiza `server/magicrules.txt` somente depois do commit PostgreSQL.
const _rulesPageUrl = 'https://magic.wizards.com/en/rules';
final _rulesTxtUrlRegex = RegExp(
  r'https://media\.wizards\.com/\d{4}/downloads/MagicCompRules \d{8}\.txt',
);

const rulesWriteApprovalEnvironment = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const rulesWriteApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const rulesFailureInjectionEnvironment =
    'MANALOOM_ENABLE_RULES_FAILURE_INJECTION';
const rulesFailureInjectionPhrase = 'I_UNDERSTAND_THIS_MUST_ROLL_BACK';
const _minimumComprehensiveRuleRows = 2500;
const _rulesCachePath = 'magicrules.txt';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
sync_rules.dart - Sincroniza as Comprehensive Rules para o Postgres

Uso:
  dart run bin/sync_rules.dart --check
  dart run bin/sync_rules.dart --check --from-file=magicrules.txt
  dart run bin/sync_rules.dart
  dart run bin/sync_rules.dart --force
  dart run bin/sync_rules.dart --from-file=magicrules.txt

Opções:
  --check               Compara fonte/cache/PostgreSQL sem qualquer escrita
  --force               Força re-download mesmo se a versão não mudou
  --from-file=<path>    Importa de um arquivo local (sem baixar)
  --source-url=<url>    Lineage oficial para uso junto de --from-file
  --help                Mostra esta ajuda
''');
    return;
  }

  validateRulesSyncArguments(args);
  final checkOnly = args.contains('--check');
  final env = loadRuntimeEnvironment();
  final environment = (env['ENVIRONMENT'] ?? 'development').toLowerCase();
  final force = args.contains('--force') || args.contains('-f');
  final fromFile = _parseFromFile(args);
  final sourceUrlOverride = _readArg(args, '--source-url=');
  final injectFailureAfterRules = args.contains('--test-fail-after-rules');

  if (checkOnly && force) {
    throw ArgumentError('--check e --force nao podem ser combinados.');
  }
  if (sourceUrlOverride != null && fromFile == null) {
    throw ArgumentError('--source-url exige --from-file.');
  }
  if (!checkOnly && fromFile != null && sourceUrlOverride == null) {
    throw ArgumentError(
      'Importacao mutavel por arquivo exige --source-url oficial para lineage.',
    );
  }
  if (checkOnly && injectFailureAfterRules) {
    throw ArgumentError(
      '--test-fail-after-rules existe apenas para validar rollback mutavel.',
    );
  }
  if (!checkOnly && !hasRulesWriteApproval(Platform.environment)) {
    throw StateError(
      'PostgreSQL write refused: export '
      '$rulesWriteApprovalEnvironment=$rulesWriteApprovalPhrase.',
    );
  }
  if (injectFailureAfterRules &&
      !hasRulesFailureInjectionApproval(Platform.environment)) {
    throw StateError(
      'Rules failure injection refused: export '
      '$rulesFailureInjectionEnvironment=$rulesFailureInjectionPhrase.',
    );
  }

  stdout.writeln(
    '📚 Regras (ENVIRONMENT=$environment)'
    '${checkOnly ? ' [CHECK READ-ONLY]' : ''}'
    '${force ? ' [FORÇADO]' : ''}',
  );

  final snapshot = await _loadRulesSnapshot(
    fromFile: fromFile,
    sourceUrlOverride: sourceUrlOverride,
  );
  final parsed = parseComprehensiveRules(snapshot.rulesText);
  final parsedRowsSha256 = comprehensiveRulesRowsSha256(parsed);
  validateComprehensiveRulesSnapshot(snapshot, parsedRuleCount: parsed.length);
  stdout.writeln('🔎 Regras parseadas: ${parsed.length}');

  final db = Database();
  await db.connect();
  final pool = db.connection;

  try {
    if (checkOnly) {
      final databaseState = await loadRulesDatabaseState(pool);
      final cacheState = await loadRulesCacheState(File(_rulesCachePath));
      final report = evaluateRulesFreshness(
        snapshot: snapshot,
        parsedRuleCount: parsed.length,
        parsedRowsSha256: parsedRowsSha256,
        databaseState: databaseState,
        cacheState: cacheState,
      );
      stdout.writeln(jsonEncode(report.toJson()));
      if (!report.isFresh) {
        throw StateError(
          'Rules freshness check failed: ${report.failureReasons.join(', ')}',
        );
      }
      stdout.writeln('✅ Fonte, cache e PostgreSQL de regras estao alinhados.');
      return;
    }

    final applied = await pool.runTx<bool>((session) async {
      await session.execute(
        "SELECT pg_advisory_xact_lock(hashtext('manaloom_sync_rules'))",
      );
      await _ensureSyncStateTable(session);
      await _ensureRulesIndexes(session);
      await session.execute('LOCK TABLE rules IN SHARE ROW EXCLUSIVE MODE');
      await session.execute(
        'LOCK TABLE sync_state IN SHARE ROW EXCLUSIVE MODE',
      );

      final current = await loadRulesDatabaseState(session);
      if (!force &&
          current.versionDate == snapshot.versionDate &&
          current.contentSha256 == snapshot.contentSha256 &&
          current.rowsSha256 == parsedRowsSha256 &&
          current.ruleCount == parsed.length) {
        return false;
      }

      await executeRulesSnapshotMutation(
        replaceRules: () => _replaceRules(session, parsed),
        writeMetadata: () async {
          await _setSyncState(
            session,
            'rules_source_url',
            snapshot.sourceReference,
          );
          await _setSyncState(
            session,
            'rules_version_date',
            snapshot.versionDate,
          );
          await _setSyncState(
            session,
            'rules_content_sha256',
            snapshot.contentSha256,
          );
          await _setSyncState(session, 'rules_rows_sha256', parsedRowsSha256);
          await _setSyncState(
            session,
            'rules_last_sync_at',
            DateTime.now().toUtc().toIso8601String(),
          );
        },
        injectFailureAfterRules: injectFailureAfterRules,
      );
      return true;
    });

    await _writeRulesCacheAtomically(snapshot.rulesText);
    if (!applied) {
      stdout.writeln(
        '✅ PostgreSQL ja estava alinhado; cache local reconciliado.',
      );
      return;
    }

    stdout.writeln('\n✅ Regras e metadados importados em uma transacao.');
  } finally {
    await db.close();
  }
}

String? _parseFromFile(List<String> args) {
  return _readArg(args, '--from-file=');
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    final value = arg.substring(prefix.length).trim();
    return value.isEmpty ? null : value;
  }
  return null;
}

void validateRulesSyncArguments(List<String> args) {
  const exact = <String>{'--check', '--force', '-f', '--test-fail-after-rules'};
  for (final arg in args) {
    if (exact.contains(arg)) continue;
    if (arg.startsWith('--from-file=') || arg.startsWith('--source-url=')) {
      final value = arg.substring(arg.indexOf('=') + 1).trim();
      if (value.isNotEmpty) continue;
    }
    throw ArgumentError('Opcao desconhecida ou vazia: $arg');
  }
}

bool isOfficialRulesSourceUrl(String value) {
  final normalized = value.replaceAll('%20', ' ');
  final match = _rulesTxtUrlRegex.firstMatch(normalized);
  return match != null && match.group(0) == normalized;
}

bool hasRulesWriteApproval(Map<String, String> environment) {
  return environment[rulesWriteApprovalEnvironment] == rulesWriteApprovalPhrase;
}

bool hasRulesFailureInjectionApproval(Map<String, String> environment) {
  return environment[rulesFailureInjectionEnvironment] ==
      rulesFailureInjectionPhrase;
}

Future<RulesSnapshot> _loadRulesSnapshot({
  String? fromFile,
  String? sourceUrlOverride,
}) async {
  if (fromFile != null) {
    final file = File(fromFile);
    if (!await file.exists()) {
      throw Exception('Arquivo não encontrado: $fromFile');
    }
    final text = await file.readAsString();
    final versionDate = extractRulesVersionDateFromText(text);
    if (versionDate == null) {
      throw StateError(
        'Nao foi possivel provar a data efetiva no arquivo $fromFile.',
      );
    }
    if (sourceUrlOverride != null) {
      if (!isOfficialRulesSourceUrl(sourceUrlOverride)) {
        throw StateError('A lineage informada nao e uma fonte oficial valida.');
      }
      final sourceDate = _extractRulesDate(sourceUrlOverride);
      if (sourceDate != null && sourceDate != versionDate) {
        throw StateError(
          'A data da fonte ($sourceDate) diverge do arquivo ($versionDate).',
        );
      }
    }
    return RulesSnapshot(
      rulesText: text,
      sourceReference:
          sourceUrlOverride ?? 'local-file:${file.uri.pathSegments.last}',
      versionDate: versionDate,
    );
  }

  final (latestUrl, versionDate) = await _discoverLatestRulesTxtUrl();
  final encodedUrl = latestUrl.replaceAll(' ', '%20');
  stdout.writeln('⬇️  Baixando rules: $latestUrl');

  final res = await http.get(Uri.parse(encodedUrl));
  if (res.statusCode != 200) {
    throw Exception('Falha ao baixar rules txt: ${res.statusCode}');
  }

  final text = utf8.decode(res.bodyBytes);
  final effectiveDate = extractRulesVersionDateFromText(text);
  if (effectiveDate == null) {
    throw StateError('A fonte oficial nao contem data efetiva reconhecivel.');
  }
  if (versionDate != null && versionDate != effectiveDate) {
    throw StateError(
      'A data da URL oficial ($versionDate) diverge do conteudo '
      '($effectiveDate).',
    );
  }
  return RulesSnapshot(
    rulesText: text,
    sourceReference: latestUrl,
    versionDate: effectiveDate,
  );
}

Future<(String url, String? versionDate)> _discoverLatestRulesTxtUrl() async {
  final res = await http.get(Uri.parse(_rulesPageUrl));
  if (res.statusCode != 200) {
    throw Exception('Falha ao carregar página de rules: ${res.statusCode}');
  }
  final html = utf8.decode(res.bodyBytes);

  final matches =
      _rulesTxtUrlRegex
          .allMatches(html)
          .map((m) => m.group(0)!)
          .toSet()
          .toList();
  if (matches.isEmpty) {
    throw Exception(
      'Não encontrei link .txt de regras na página $_rulesPageUrl',
    );
  }

  String best = matches.first;
  String? bestDate = _extractRulesDate(best);

  for (final url in matches.skip(1)) {
    final date = _extractRulesDate(url);
    if (bestDate == null) {
      best = url;
      bestDate = date;
      continue;
    }
    if (date != null && date.compareTo(bestDate) > 0) {
      best = url;
      bestDate = date;
    }
  }

  return (best, bestDate);
}

String? _extractRulesDate(String url) {
  final match = RegExp(r'(\d{8})\.txt$').firstMatch(url);
  return match?.group(1);
}

List<ComprehensiveRuleRow> parseComprehensiveRules(String text) {
  final lines = const LineSplitter().convert(text);

  var currentCategory = 'General';
  String? currentRuleNumber;
  final currentRuleText = StringBuffer();

  final majorSectionRegex = RegExp(r'^(\d)\.\s+(.*)'); // "1. Game Concepts"
  final subSectionRegex = RegExp(r'^(\d{3})\.\s+(.*)'); // "100. General"
  final ruleRegex = RegExp(
    r'^(\d{3}\.\d+[a-z]?)\.?\s+(.*)',
  ); // "100.1" or "100.1a"

  final out = <ComprehensiveRuleRow>[];

  void flush() {
    final title = currentRuleNumber;
    if (title == null) return;
    final desc = currentRuleText.toString().trim();
    if (desc.isEmpty) return;
    out.add(
      ComprehensiveRuleRow(
        title: title,
        description: desc,
        category: currentCategory,
      ),
    );
  }

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final majorMatch = majorSectionRegex.firstMatch(line);
    if (majorMatch != null) {
      flush();
      currentRuleNumber = null;
      currentRuleText.clear();
      currentCategory = majorMatch.group(2) ?? 'General';
      continue;
    }

    final subMatch = subSectionRegex.firstMatch(line);
    if (subMatch != null) {
      flush();
      currentRuleNumber = null;
      currentRuleText.clear();
      currentCategory = subMatch.group(2) ?? currentCategory;
      continue;
    }

    final ruleMatch = ruleRegex.firstMatch(line);
    if (ruleMatch != null) {
      flush();
      currentRuleNumber = ruleMatch.group(1);
      currentRuleText.clear();
      currentRuleText.write(ruleMatch.group(2));
      continue;
    }

    if (currentRuleNumber != null) {
      currentRuleText.write('\n$line');
    }
  }

  flush();
  return out;
}

String comprehensiveRulesRowsSha256(Iterable<ComprehensiveRuleRow> rows) {
  final canonical =
      rows
          .map((row) => jsonEncode([row.title, row.description, row.category]))
          .toList()
        ..sort();
  return sha256.convert(utf8.encode(canonical.join('\n'))).toString();
}

String? extractRulesVersionDateFromText(String text) {
  final match = RegExp(
    r'These rules are effective as of ([A-Z][a-z]+) (\d{1,2}), (\d{4})\.',
  ).firstMatch(text);
  if (match == null) return null;
  const months = <String, int>{
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };
  final month = months[match.group(1)];
  final day = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (month == null || day == null || year == null) return null;
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return '${year.toString().padLeft(4, '0')}'
      '${month.toString().padLeft(2, '0')}'
      '${day.toString().padLeft(2, '0')}';
}

void validateComprehensiveRulesSnapshot(
  RulesSnapshot snapshot, {
  required int parsedRuleCount,
  int minimumRuleRows = _minimumComprehensiveRuleRows,
}) {
  if (!RegExp(r'^\d{8}$').hasMatch(snapshot.versionDate)) {
    throw StateError('Rules snapshot sem versionDate YYYYMMDD valida.');
  }
  if (parsedRuleCount < minimumRuleRows) {
    throw StateError(
      'Rules snapshot incompleto: $parsedRuleCount regras; '
      'minimo=$minimumRuleRows.',
    );
  }
  if (snapshot.contentSha256.length != 64) {
    throw StateError('Rules snapshot sem SHA-256 valido.');
  }
}

Future<void> executeRulesSnapshotMutation({
  required Future<void> Function() replaceRules,
  required Future<void> Function() writeMetadata,
  bool injectFailureAfterRules = false,
}) async {
  await replaceRules();
  if (injectFailureAfterRules) {
    throw StateError(
      'Injected rules sync failure after rules replacement; '
      'the PostgreSQL transaction must roll back.',
    );
  }
  await writeMetadata();
}

Future<void> _replaceRules(
  Session session,
  List<ComprehensiveRuleRow> parsed,
) async {
  await session.execute(Sql.named('TRUNCATE TABLE rules'));

  const batchSize = 500;
  for (var i = 0; i < parsed.length; i += batchSize) {
    final batch = parsed.sublist(i, (i + batchSize).clamp(0, parsed.length));

    final values = <String>[];
    final params = <String, dynamic>{};
    for (var j = 0; j < batch.length; j++) {
      values.add('(@t$j, @d$j, @c$j)');
      params['t$j'] = batch[j].title;
      params['d$j'] = batch[j].description;
      params['c$j'] = batch[j].category;
    }

    await session.execute(
      Sql.named(
        'INSERT INTO rules (title, description, category) '
        'VALUES ${values.join(', ')}',
      ),
      parameters: params,
    );
    stdout.write('\r⬆️  Importando... ${(i + batch.length)}/${parsed.length}');
  }
}

Future<void> _writeRulesCacheAtomically(String rulesText) async {
  final target = File(_rulesCachePath);
  final temporary = File(
    '${target.path}.tmp.${pid}.${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await temporary.writeAsString(
      normalizeComprehensiveRulesText(rulesText),
      flush: true,
    );
    await temporary.rename(target.path);
  } finally {
    if (await temporary.exists()) {
      await temporary.delete();
    }
  }
}

Future<RulesCacheState> loadRulesCacheState(File cacheFile) async {
  if (!await cacheFile.exists()) return const RulesCacheState.missing();
  final text = await cacheFile.readAsString();
  return RulesCacheState(
    exists: true,
    versionDate: extractRulesVersionDateFromText(text),
    contentSha256: comprehensiveRulesContentSha256(text),
  );
}

Future<RulesDatabaseState> loadRulesDatabaseState(Session session) async {
  final tableState = await session.execute(
    Sql.named('''
SELECT
  to_regclass('public.rules') IS NOT NULL AS rules_exists,
  to_regclass('public.sync_state') IS NOT NULL AS sync_state_exists
'''),
  );
  final columns = tableState.first.toColumnMap();
  final rulesExists = columns['rules_exists'] == true;
  final syncStateExists = columns['sync_state_exists'] == true;
  var ruleCount = 0;
  String? rowsSha256;
  if (rulesExists) {
    final rulesResult = await session.execute(
      Sql.named('''
SELECT title, description, category
FROM rules
ORDER BY title, description, category
'''),
    );
    final rows = rulesResult
        .map((row) {
          final value = row.toColumnMap();
          return ComprehensiveRuleRow(
            title: value['title'].toString(),
            description: value['description'].toString(),
            category: value['category'].toString(),
          );
        })
        .toList(growable: false);
    ruleCount = rows.length;
    rowsSha256 = comprehensiveRulesRowsSha256(rows);
  }

  final metadata = <String, String>{};
  if (syncStateExists) {
    final result = await session.execute(
      Sql.named('''
SELECT key, value
FROM sync_state
WHERE key IN (
  'rules_source_url',
  'rules_version_date',
  'rules_content_sha256',
  'rules_rows_sha256',
  'rules_last_sync_at'
)
ORDER BY key
'''),
    );
    for (final row in result) {
      final value = row.toColumnMap();
      metadata[value['key'].toString()] = value['value'].toString();
    }
  }
  return RulesDatabaseState(
    rulesTableExists: rulesExists,
    syncStateTableExists: syncStateExists,
    ruleCount: ruleCount,
    sourceReference: metadata['rules_source_url'],
    versionDate: metadata['rules_version_date'],
    contentSha256: metadata['rules_content_sha256'],
    rowsSha256: rowsSha256,
    persistedRowsSha256: metadata['rules_rows_sha256'],
    lastSyncAt: metadata['rules_last_sync_at'],
  );
}

RulesFreshnessReport evaluateRulesFreshness({
  required RulesSnapshot snapshot,
  required int parsedRuleCount,
  required String parsedRowsSha256,
  required RulesDatabaseState databaseState,
  required RulesCacheState cacheState,
}) {
  final failures = <String>[];
  if (!databaseState.rulesTableExists) {
    failures.add('rules_table_missing');
  }
  if (!databaseState.syncStateTableExists) {
    failures.add('sync_state_table_missing');
  }
  if (databaseState.versionDate != snapshot.versionDate) {
    failures.add('database_version_mismatch');
  }
  if (databaseState.contentSha256 != snapshot.contentSha256) {
    failures.add('database_content_hash_mismatch');
  }
  if (databaseState.rowsSha256 != parsedRowsSha256) {
    failures.add('database_rows_hash_mismatch');
  }
  if (databaseState.persistedRowsSha256 != parsedRowsSha256) {
    failures.add('database_persisted_rows_hash_mismatch');
  }
  if (databaseState.ruleCount != parsedRuleCount) {
    failures.add('database_rule_count_mismatch');
  }
  if (!cacheState.exists) {
    failures.add('local_cache_missing');
  } else {
    if (cacheState.versionDate != snapshot.versionDate) {
      failures.add('local_cache_version_mismatch');
    }
    if (cacheState.contentSha256 != snapshot.contentSha256) {
      failures.add('local_cache_content_hash_mismatch');
    }
  }
  return RulesFreshnessReport(
    snapshot: snapshot,
    parsedRuleCount: parsedRuleCount,
    parsedRowsSha256: parsedRowsSha256,
    databaseState: databaseState,
    cacheState: cacheState,
    failureReasons: failures,
  );
}

Future<void> _ensureRulesIndexes(Session session) async {
  await session.execute(
    Sql.named('CREATE INDEX IF NOT EXISTS idx_rules_title ON rules (title)'),
  );
  await session.execute(
    Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_rules_category ON rules (category)',
    ),
  );
}

Future<void> _ensureSyncStateTable(Session session) async {
  await session.execute(
    Sql.named('''
      CREATE TABLE IF NOT EXISTS sync_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    '''),
  );
}

Future<void> _setSyncState(Session session, String key, String value) async {
  await session.execute(
    Sql.named('''
      INSERT INTO sync_state (key, value, updated_at)
      VALUES (@k, @v, CURRENT_TIMESTAMP)
      ON CONFLICT (key) DO UPDATE
      SET value = EXCLUDED.value,
          updated_at = CURRENT_TIMESTAMP
    '''),
    parameters: {'k': key, 'v': value},
  );
}

String normalizeComprehensiveRulesText(String text) =>
    text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

/// Produces a newline-invariant source digest.
///
/// Wizards publishes this corpus with CRLF. Hashing one canonical CRLF form
/// preserves the existing PostgreSQL lineage digest while allowing the
/// repository cache itself to remain normalized to LF.
String comprehensiveRulesContentSha256(String text) {
  final canonicalLf = normalizeComprehensiveRulesText(text);
  final canonicalSourceText = canonicalLf.replaceAll('\n', '\r\n');
  return sha256.convert(utf8.encode(canonicalSourceText)).toString();
}

class RulesSnapshot {
  RulesSnapshot({
    required String rulesText,
    required this.sourceReference,
    required this.versionDate,
  }) : rulesText = normalizeComprehensiveRulesText(rulesText),
       contentSha256 = comprehensiveRulesContentSha256(rulesText);

  final String rulesText;
  final String sourceReference;
  final String versionDate;
  final String contentSha256;
}

class RulesDatabaseState {
  const RulesDatabaseState({
    required this.rulesTableExists,
    required this.syncStateTableExists,
    required this.ruleCount,
    this.sourceReference,
    this.versionDate,
    this.contentSha256,
    this.rowsSha256,
    this.persistedRowsSha256,
    this.lastSyncAt,
  });

  final bool rulesTableExists;
  final bool syncStateTableExists;
  final int ruleCount;
  final String? sourceReference;
  final String? versionDate;
  final String? contentSha256;
  final String? rowsSha256;
  final String? persistedRowsSha256;
  final String? lastSyncAt;

  Map<String, dynamic> toJson() => {
    'rules_table_exists': rulesTableExists,
    'sync_state_table_exists': syncStateTableExists,
    'rule_count': ruleCount,
    'source_reference': sourceReference,
    'version_date': versionDate,
    'content_sha256': contentSha256,
    'rows_sha256': rowsSha256,
    'persisted_rows_sha256': persistedRowsSha256,
    'last_sync_at': lastSyncAt,
  };
}

class RulesCacheState {
  const RulesCacheState({
    required this.exists,
    this.versionDate,
    this.contentSha256,
  });

  const RulesCacheState.missing()
    : exists = false,
      versionDate = null,
      contentSha256 = null;

  final bool exists;
  final String? versionDate;
  final String? contentSha256;

  Map<String, dynamic> toJson() => {
    'exists': exists,
    'version_date': versionDate,
    'content_sha256': contentSha256,
  };
}

class RulesFreshnessReport {
  const RulesFreshnessReport({
    required this.snapshot,
    required this.parsedRuleCount,
    required this.parsedRowsSha256,
    required this.databaseState,
    required this.cacheState,
    required this.failureReasons,
  });

  final RulesSnapshot snapshot;
  final int parsedRuleCount;
  final String parsedRowsSha256;
  final RulesDatabaseState databaseState;
  final RulesCacheState cacheState;
  final List<String> failureReasons;

  bool get isFresh => failureReasons.isEmpty;

  Map<String, dynamic> toJson() => {
    'status': isFresh ? 'pass' : 'fail',
    'expected': {
      'source_reference': snapshot.sourceReference,
      'version_date': snapshot.versionDate,
      'content_sha256': snapshot.contentSha256,
      'rows_sha256': parsedRowsSha256,
      'rule_count': parsedRuleCount,
    },
    'database': databaseState.toJson(),
    'local_cache': cacheState.toJson(),
    'failure_reasons': failureReasons,
    'mutations_performed': false,
  };
}

class ComprehensiveRuleRow {
  const ComprehensiveRuleRow({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;
}
