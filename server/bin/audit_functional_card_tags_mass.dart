#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';

const _defaultArtifactDir =
    'test/artifacts/functional_card_tags_mass_audit_2026-05-18';
const _defaultChunkSize = 2500;
const _exampleLimit = 30;
const _sourceDescription =
    'cards where type_line and oracle_text are non-empty';

const _allowedEvidence = <String>{
  'type_line_land',
  'mana_or_land_ramp_text',
  'temporary_mana_burst_text',
  'card_draw_text',
  'draw_discard_selection_text',
  'non_land_library_search',
  'targeted_interaction_text',
  'counterspell_is_interaction',
  'counterspell_can_protect_plan',
  'mass_removal_text',
  'protection_keyword_or_effect',
  'graveyard_return_text',
  'graveyard_payoff_or_setup_text',
  'token_creation_text',
  'repeatable_sacrifice_outlet_text',
  'death_trigger_payoff_text',
  'life_gain_text',
  'life_loss_payoff_text',
  'instant_sorcery_cast_payoff_text',
  'artifact_payoff_text',
  'enchantment_payoff_text',
  'enters_the_battlefield_text',
  'exile_then_return_text',
  'blink_can_protect_permanent',
  'high_mana_value_or_big_turn_text',
  'exile_play_or_cast_value_text',
};

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir,
  );
  final chunkSize =
      int.tryParse(_readArg(args, '--chunk-size=') ?? '') ?? _defaultChunkSize;
  if (chunkSize <= 0 || chunkSize > 10000) {
    throw ArgumentError('--chunk-size deve ficar entre 1 e 10000.');
  }

  await artifactDir.create(recursive: true);

  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final pool = await _connectQuietly(env);
  final startedAt = DateTime.now().toUtc();
  final audit = _FunctionalCardTagsMassAudit();

  try {
    final totalRows = await _loadTotalRows(pool);
    var offset = 0;
    while (offset < totalRows) {
      final rows = await _loadCardRows(pool, limit: chunkSize, offset: offset);
      if (rows.isEmpty) break;
      for (final row in rows) {
        audit.add(_AuditCard.fromRow(row));
      }
      offset += rows.length;
      print('Processed $offset/$totalRows card rows');
    }

    final completedAt = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'metadata': {
        'generated_at': completedAt.toIso8601String(),
        'started_at': startedAt.toIso8601String(),
        'duration_ms': completedAt.difference(startedAt).inMilliseconds,
        'schema_version': functionalCardTagsSchemaVersion,
        'source': _sourceDescription,
        'card_rows_expected': totalRows,
        'card_rows_processed': audit.totalRows,
        'artifact_safety': {
          'oracle_text_saved': false,
          'card_ids_saved': false,
          'db_connection_details_saved': false,
          'decklists_saved': false,
          'example_limit_per_bucket': _exampleLimit,
        },
        'provenance': {
          'git_commit': await _gitCommit(),
          'functional_card_tags_sha256':
              await _sha256Path('lib/ai/functional_card_tags.dart'),
          'optimization_functional_roles_sha256':
              await _sha256Path('lib/ai/optimization_functional_roles.dart'),
        },
      },
      ...audit.toJson(),
    };

    final outputPath = '${artifactDir.path}/summary.json';
    await _writeJson(outputPath, payload);
    print('Artifact written: $outputPath');
    print('Coverage: ${audit.coveragePercent.toStringAsFixed(2)}%');
    print('Cards processed: ${audit.totalRows}');
  } finally {
    await pool.close();
  }
}

class _FunctionalCardTagsMassAudit {
  final _tagStats = <String, _TagStats>{
    for (final tag in functionalCardTagsV1) tag: _TagStats(tag),
  };
  final _untaggedByType = <String, int>{};
  final _possibleFalsePositives = <String, _ReasonBucket>{};
  final _possibleFalseNegatives = <String, _ReasonBucket>{};
  final _evidenceCounts = <String, int>{};
  final _unexpectedEvidence = <String, int>{};
  final _multiTagDistribution = <String, int>{};

  var totalRows = 0;
  var taggedRows = 0;
  var untaggedRows = 0;
  var distinctNames = <String>{};
  var taggedDistinctNames = <String>{};
  var doubleFacedRows = 0;

  double get coveragePercent =>
      totalRows == 0 ? 0 : (taggedRows / totalRows) * 100;

  void add(_AuditCard card) {
    totalRows++;
    distinctNames.add(card.normalizedName);
    if (card.isDoubleFacedLike) doubleFacedRows++;

    final inferredTags = inferFunctionalCardTags(
      name: card.name,
      typeLine: card.typeLine,
      oracleText: card.oracleText,
      manaCost: card.manaCost,
      cmc: card.cmc,
    );
    final tagNames = inferredTags.map((tag) => tag.tag).toSet();
    _multiTagDistribution.update(
      tagNames.length.toString(),
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    if (tagNames.isEmpty) {
      untaggedRows++;
      _untaggedByType.update(
        card.coarseType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    } else {
      taggedRows++;
      taggedDistinctNames.add(card.normalizedName);
    }

    for (final tag in inferredTags) {
      final safeEvidence = _safeEvidence(tag.evidence);
      _evidenceCounts.update(safeEvidence, (value) => value + 1,
          ifAbsent: () => 1);
      _tagStats[tag.tag]?.add(card, tag, safeEvidence);

      final falsePositiveReason = _possibleFalsePositiveReason(
        tag: tag.tag,
        evidence: tag.evidence,
        card: card,
      );
      if (falsePositiveReason != null) {
        _possibleFalsePositives
            .putIfAbsent(
              '${tag.tag}:$falsePositiveReason',
              () => _ReasonBucket(
                tag: tag.tag,
                reason: falsePositiveReason,
              ),
            )
            .add(card, tag.confidence, safeEvidence);
      }
    }

    for (final entry in _possibleFalseNegativeReasons(card, tagNames).entries) {
      _possibleFalseNegatives
          .putIfAbsent(
            '${entry.key}:${entry.value}',
            () => _ReasonBucket(
              tag: entry.key,
              reason: entry.value,
            ),
          )
          .add(card, null, null);
    }
  }

  Map<String, dynamic> toJson() => {
        'coverage': {
          'card_rows': totalRows,
          'distinct_card_names': distinctNames.length,
          'tagged_rows': taggedRows,
          'tagged_distinct_card_names': taggedDistinctNames.length,
          'untagged_rows': untaggedRows,
          'coverage_pct': double.parse(coveragePercent.toStringAsFixed(3)),
          'double_faced_like_rows': doubleFacedRows,
          'multi_tag_distribution': _sortedMap(_multiTagDistribution),
        },
        'tag_counts': {
          for (final entry in _tagStats.entries)
            entry.key: entry.value.countsJson(),
        },
        'untagged_cards_by_type': _sortedMap(_untaggedByType),
        'top_30_examples_by_tag': {
          for (final entry in _tagStats.entries)
            entry.key: entry.value.examplesJson(),
        },
        'possible_false_positives_by_heuristic':
            _reasonBucketsJson(_possibleFalsePositives),
        'possible_false_negatives': _reasonBucketsJson(
          _possibleFalseNegatives,
        ),
        'evidence_counts': _sortedMap(_evidenceCounts),
        'unexpected_evidence_counts': _sortedMap(_unexpectedEvidence),
        'limitations': [
          'Examples are card names and coarse metadata only; oracle_text is never persisted.',
          'False-positive and false-negative sections are heuristic suspects, not final adjudications.',
          'Double-faced, split, adventure, and modal cards may combine faces in a single oracle_text row.',
        ],
      };

  String _safeEvidence(String evidence) {
    if (_allowedEvidence.contains(evidence)) return evidence;
    _unexpectedEvidence.update(evidence, (value) => value + 1,
        ifAbsent: () => 1);
    return 'unexpected_evidence_redacted';
  }
}

class _TagStats {
  _TagStats(this.tag);

  final String tag;
  final examples = <_Example>[];
  final _exampleNames = <String>{};
  final _distinctNames = <String>{};
  var rowCount = 0;
  var confidenceTotal = 0.0;

  void add(_AuditCard card, FunctionalCardTag functionalTag, String evidence) {
    rowCount++;
    confidenceTotal += functionalTag.confidence;
    _distinctNames.add(card.normalizedName);
    if (_exampleNames.add(card.normalizedName)) {
      examples.add(
        _Example(
          name: card.name,
          typeLine: card.typeLine,
          manaCost: card.manaCost,
          cmc: card.cmcString,
          confidence: functionalTag.confidence,
          evidence: evidence,
        ),
      );
    }
  }

  Map<String, dynamic> countsJson() => {
        'card_rows': rowCount,
        'distinct_card_names': _distinctNames.length,
        'avg_confidence': rowCount == 0
            ? 0
            : double.parse((confidenceTotal / rowCount).toStringAsFixed(3)),
      };

  List<Map<String, dynamic>> examplesJson() {
    final sorted = [...examples]..sort((a, b) {
        final byConfidence = b.confidence!.compareTo(a.confidence!);
        if (byConfidence != 0) return byConfidence;
        return a.name.compareTo(b.name);
      });
    return sorted
        .take(_exampleLimit)
        .map((example) => example.toJson())
        .toList();
  }
}

class _ReasonBucket {
  _ReasonBucket({required this.tag, required this.reason});

  final String tag;
  final String reason;
  final examples = <_Example>[];
  final _exampleNames = <String>{};
  var count = 0;

  void add(_AuditCard card, double? confidence, String? evidence) {
    count++;
    if (_exampleNames.add(card.normalizedName)) {
      examples.add(
        _Example(
          name: card.name,
          typeLine: card.typeLine,
          manaCost: card.manaCost,
          cmc: card.cmcString,
          confidence: confidence,
          evidence: evidence,
        ),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final sorted = [...examples]..sort((a, b) => a.name.compareTo(b.name));
    return {
      'tag': tag,
      'reason': reason,
      'card_rows': count,
      'examples': sorted
          .take(_exampleLimit)
          .map((example) => example.toJson(includeNulls: false))
          .toList(),
    };
  }
}

class _Example {
  const _Example({
    required this.name,
    required this.typeLine,
    required this.manaCost,
    required this.cmc,
    this.confidence,
    this.evidence,
  });

  final String name;
  final String typeLine;
  final String? manaCost;
  final String? cmc;
  final double? confidence;
  final String? evidence;

  Map<String, dynamic> toJson({bool includeNulls = true}) {
    final json = <String, dynamic>{
      'name': name,
      'type_line': typeLine,
      'mana_cost': manaCost,
      'cmc': cmc,
      'confidence': confidence == null
          ? null
          : double.parse(confidence!.toStringAsFixed(3)),
      'evidence': evidence,
    };
    if (includeNulls) return json;
    json.removeWhere((_, value) => value == null || value == '');
    return json;
  }
}

class _AuditCard {
  _AuditCard({
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.cmc,
  });

  final String name;
  final String typeLine;
  final String oracleText;
  final String? manaCost;
  final Object? cmc;

  String get normalizedName => normalizeFunctionalCardName(name);
  String get oracle => oracleText.toLowerCase();
  String get type => typeLine.toLowerCase();
  String? get cmcString => cmc?.toString();
  bool get isInstantOrSorcery =>
      type.contains('instant') || type.contains('sorcery');
  bool get isDoubleFacedLike =>
      typeLine.contains('//') || oracleText.contains('\n//\n');

  String get coarseType {
    if (type.contains('creature')) return 'creature';
    if (type.contains('instant')) return 'instant';
    if (type.contains('sorcery')) return 'sorcery';
    if (type.contains('artifact')) return 'artifact';
    if (type.contains('enchantment')) return 'enchantment';
    if (type.contains('planeswalker')) return 'planeswalker';
    if (type.contains('battle')) return 'battle';
    if (type.contains('land')) return 'land';
    return 'other';
  }

  factory _AuditCard.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return _AuditCard(
      name: (map['name'] as String?)?.trim() ?? '',
      typeLine: (map['type_line'] as String?)?.trim() ?? '',
      oracleText: (map['oracle_text'] as String?) ?? '',
      manaCost: (map['mana_cost'] as String?)?.trim(),
      cmc: map['cmc'],
    );
  }
}

String? _possibleFalsePositiveReason({
  required String tag,
  required String evidence,
  required _AuditCard card,
}) {
  final oracle = card.oracle;

  if (tag == 'ramp' &&
      evidence == 'mana_or_land_ramp_text' &&
      card.isInstantOrSorcery &&
      _looksLikeTemporaryMana(oracle, card.normalizedName)) {
    return 'temporary_mana_or_ritual_counted_as_ramp';
  }

  if (tag == 'tutor' &&
      oracle.contains('search your library') &&
      _containsBasicLandTypeSearch(oracle)) {
    return 'land_ramp_search_counted_as_tutor';
  }

  if (tag == 'lifegain' &&
      (oracle.contains("can't gain life") ||
          oracle.contains('cannot gain life') ||
          oracle.contains('players can\'t gain life'))) {
    return 'lifegain_hate_text_counted_as_lifegain';
  }

  if (tag == 'draw' &&
      (oracle.contains('each player draws') ||
          oracle.contains('target player draws') ||
          oracle.contains('each player may draw'))) {
    return 'symmetric_or_target_player_draw_counted_as_draw';
  }

  if (tag == 'removal' &&
      oracle.contains('target') &&
      oracle.contains('card') &&
      oracle.contains('graveyard') &&
      oracle.contains('owner')) {
    return 'graveyard_card_return_counted_as_removal';
  }

  if (tag == 'removal' &&
      oracle.contains('exile target') &&
      oracle.contains('return') &&
      oracle.contains('battlefield')) {
    return 'blink_like_exile_return_counted_as_removal';
  }

  if (tag == 'board_wipe' &&
      (oracle.contains('all creatures you control') ||
          oracle.contains('each creature you control'))) {
    return 'own_board_only_effect_counted_as_wipe';
  }

  if (tag == 'protection' && evidence == 'counterspell_can_protect_plan') {
    return 'counterspell_low_confidence_protection_signal';
  }

  if (tag == 'etb' && oracle.contains('as long as')) {
    return 'as_long_as_text_may_trigger_etb_by_broad_as_match';
  }

  return null;
}

Map<String, String> _possibleFalseNegativeReasons(
  _AuditCard card,
  Set<String> tags,
) {
  final oracle = card.oracle;
  final reasons = <String, String>{};

  if (!tags.contains('draw') && !tags.contains('loot')) {
    if ((oracle.contains('draw') &&
            (oracle.contains('card') || oracle.contains('cards'))) ||
        oracle.contains('investigate') ||
        oracle.contains('connive')) {
      reasons['draw'] =
          oracle.contains('investigate') || oracle.contains('connive')
              ? 'investigate_or_connive_selection_not_tagged_draw'
              : 'draw_text_not_tagged_draw';
    }
  }

  if (!tags.contains('ramp')) {
    if (_looksLikeBroadRamp(oracle)) {
      reasons['ramp'] = 'broad_mana_or_land_acceleration_not_tagged_ramp';
    }
  }

  if (!tags.contains('removal') && !tags.contains('board_wipe')) {
    if (oracle.contains('fight') ||
        oracle.contains('target player sacrifices') ||
        oracle.contains('target opponent sacrifices') ||
        oracle.contains('each opponent sacrifices a creature') ||
        oracle.contains('deals damage equal') && oracle.contains('target')) {
      reasons['removal'] = 'fight_edict_or_damage_interaction_not_tagged';
    }
  }

  if (!tags.contains('board_wipe')) {
    if (!_looksLikeOwnBoardOrCombatDamageAssignment(oracle) &&
        (oracle.contains('each creature') ||
            oracle.contains('all creatures')) &&
        (oracle.contains('gets -') ||
            oracle.contains('damage') ||
            oracle.contains('destroy') ||
            oracle.contains('exile') ||
            oracle.contains('sacrifice'))) {
      reasons['board_wipe'] = 'broad_each_or_all_creature_sweeper_not_tagged';
    }
  }

  if (!tags.contains('protection')) {
    if (oracle.contains('ward') ||
        oracle.contains('prevent all damage') ||
        oracle.contains("can't be the target") ||
        oracle.contains('cannot be the target') ||
        oracle.contains('regenerate target') ||
        oracle.contains('gains hexproof') ||
        oracle.contains('gains indestructible')) {
      reasons['protection'] =
          'ward_prevent_regenerate_or_targeting_protection_not_tagged';
    }
  }

  return reasons;
}

bool _looksLikeTemporaryMana(String oracle, String normalizedName) {
  return normalizedName == 'jeska\'s will' ||
      oracle.contains('until end of turn') ||
      oracle.contains('until your next turn') ||
      oracle.contains('this turn') && oracle.contains('add {');
}

bool _looksLikeOwnBoardOrCombatDamageAssignment(String oracle) {
  return oracle.contains('all creatures you control') ||
      oracle.contains('each creature you control') ||
      oracle.contains('assigns combat damage');
}

bool _containsBasicLandTypeSearch(String oracle) {
  return oracle.contains('forest card') ||
      oracle.contains('plains card') ||
      oracle.contains('island card') ||
      oracle.contains('swamp card') ||
      oracle.contains('mountain card') ||
      oracle.contains('basic land') ||
      oracle.contains('land card');
}

bool _looksLikeBroadRamp(String oracle) {
  return looksLikeOptimizationRampText(oracle) ||
      oracle.contains('create') && oracle.contains('treasure') ||
      oracle.contains('add one mana') ||
      oracle.contains('add two mana') ||
      oracle.contains('add three mana') ||
      oracle.contains('add mana') ||
      oracle.contains('play an additional land') ||
      oracle.contains('put') &&
          oracle.contains('land') &&
          oracle.contains('onto the battlefield') ||
      oracle.contains('search your library') &&
          _containsBasicLandTypeSearch(oracle);
}

Future<int> _loadTotalRows(Pool pool) async {
  final result = await pool.execute(Sql('''
    SELECT COUNT(*) AS total
    FROM cards
    WHERE COALESCE(type_line, '') <> ''
      AND COALESCE(oracle_text, '') <> ''
  '''));
  return (result.first.toColumnMap()['total'] as int?) ?? 0;
}

Future<List<ResultRow>> _loadCardRows(
  Pool pool, {
  required int limit,
  required int offset,
}) async {
  return pool.execute(
    Sql.named('''
      SELECT name, type_line, oracle_text, mana_cost, cmc
      FROM cards
      WHERE COALESCE(type_line, '') <> ''
        AND COALESCE(oracle_text, '') <> ''
      ORDER BY name ASC, id ASC
      LIMIT @limit OFFSET @offset
    '''),
    parameters: {'limit': limit, 'offset': offset},
  );
}

Future<Pool> _connectQuietly(DotEnv env) async {
  final endpoint = _endpointFromEnvironment(env);
  final explicitSsl = _parseSslMode(env['DB_SSL_MODE']);
  final modes = explicitSsl == null
      ? const [SslMode.disable, SslMode.require]
      : [explicitSsl];

  for (final mode in modes) {
    Pool? pool;
    try {
      pool = Pool.withEndpoints(
        [endpoint],
        settings: PoolSettings(maxConnectionCount: 2, sslMode: mode),
      );
      await pool.execute(Sql('SELECT 1'));
      return pool;
    } catch (_) {
      await pool?.close();
    }
  }

  throw StateError(
    'Database connection failed. Check DB_* or DATABASE_URL locally.',
  );
}

Endpoint _endpointFromEnvironment(DotEnv env) {
  final databaseUrl = (env['DATABASE_URL'] ?? '').trim();
  if (databaseUrl.isNotEmpty) {
    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');
    return Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database:
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
      username: userInfo.isNotEmpty && userInfo.first.isNotEmpty
          ? Uri.decodeComponent(userInfo.first)
          : null,
      password: userInfo.length > 1 ? Uri.decodeComponent(userInfo[1]) : null,
    );
  }

  final host = env['DB_HOST'];
  final port = int.tryParse(env['DB_PORT'] ?? '') ?? 5432;
  final database = env['DB_NAME'];
  final username = env['DB_USER'];
  final password = env['DB_PASS'];

  if (host == null ||
      host.trim().isEmpty ||
      database == null ||
      database.trim().isEmpty ||
      username == null ||
      username.trim().isEmpty) {
    throw StateError(
      'Database environment is incomplete. Configure DB_* or DATABASE_URL locally.',
    );
  }

  return Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );
}

SslMode? _parseSslMode(String? raw) {
  if (raw == null) return null;
  return switch (raw.trim().toLowerCase()) {
    'disable' || 'off' || 'false' || '0' => SslMode.disable,
    'require' || 'on' || 'true' || '1' => SslMode.require,
    'verifyfull' || 'verify_full' || 'verify-full' => SslMode.verifyFull,
    _ => null,
  };
}

Future<String> _gitCommit() async {
  final result = await Process.run('git', ['rev-parse', 'HEAD']);
  if (result.exitCode != 0) return 'unknown';
  return (result.stdout as String).trim();
}

Future<String> _sha256Path(String path) async {
  final file = File(path);
  if (!await file.exists()) return 'missing';
  return sha256.convert(await file.readAsBytes()).toString();
}

Future<void> _writeJson(String path, Object? payload) async {
  final encoder = const JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

Map<String, int> _sortedMap(Map<String, int> input) {
  final entries = input.entries.toList()
    ..sort((a, b) {
      final byValue = b.value.compareTo(a.value);
      if (byValue != 0) return byValue;
      return a.key.compareTo(b.key);
    });
  return {for (final entry in entries) entry.key: entry.value};
}

List<Map<String, dynamic>> _reasonBucketsJson(
    Map<String, _ReasonBucket> buckets) {
  final sorted = buckets.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byTag = a.tag.compareTo(b.tag);
      if (byTag != 0) return byTag;
      return a.reason.compareTo(b.reason);
    });
  return sorted.map((bucket) => bucket.toJson()).toList();
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
Audit Functional Card Tags v1 against local ManaLoom cards.

Usage:
  dart run bin/audit_functional_card_tags_mass.dart [options]

Options:
  --artifact-dir=<path>  Output directory for sanitized summary.json.
  --chunk-size=<n>       DB read chunk size, default $_defaultChunkSize.

Safety:
  The runner writes no oracle_text, card ids, DB connection details, secrets, or decklists.
''');
}
