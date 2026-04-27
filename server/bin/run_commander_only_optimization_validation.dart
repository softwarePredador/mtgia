#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';

const _defaultApiBaseUrl = 'http://127.0.0.1:8080';
const _defaultCorpusPath = 'test/fixtures/optimization_resolution_corpus.json';
const _defaultArtifactDir =
    'test/artifacts/commander_only_optimization_validation';
const _defaultSummaryJsonPath =
    'test/artifacts/commander_only_optimization_validation/latest_summary.json';
const _defaultDryRunSummaryJsonPath =
    'test/artifacts/commander_only_optimization_validation/latest_dry_run_summary.json';
const _defaultSummaryMdPath =
    'doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md';
const _defaultDryRunSummaryMdPath =
    'doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_DRY_RUN_2026-04-27.md';

class RuntimeValidationConfig {
  RuntimeValidationConfig({
    required this.apply,
    this.skipHealthCheck = false,
    this.proveCacheHit = false,
  });

  final bool apply;
  final bool skipHealthCheck;
  final bool proveCacheHit;

  bool get dryRun => !apply;

  factory RuntimeValidationConfig.parse(List<String> args) {
    var apply = false;
    var explicitDryRun = false;
    var skipHealthCheck = false;
    var proveCacheHit = false;

    for (final arg in args) {
      if (arg == '--apply') {
        apply = true;
        continue;
      }
      if (arg == '--dry-run') {
        explicitDryRun = true;
        continue;
      }
      if (arg == '--skip-health-check') {
        skipHealthCheck = true;
        continue;
      }
      if (arg == '--prove-cache-hit') {
        proveCacheHit = true;
        continue;
      }
      if (arg == '--help' || arg == '-h') {
        _printUsage();
        exit(0);
      }
    }

    if (apply && explicitDryRun) {
      throw ArgumentError('Use apenas um modo: --apply ou --dry-run.');
    }
    if (apply && skipHealthCheck) {
      throw ArgumentError('--skip-health-check so pode ser usado com dry-run.');
    }
    if (!apply && proveCacheHit) {
      throw ArgumentError('--prove-cache-hit exige --apply.');
    }

    return RuntimeValidationConfig(
      apply: apply,
      skipHealthCheck: skipHealthCheck,
      proveCacheHit: proveCacheHit,
    );
  }
}

class ValidationCorpusEntry {
  ValidationCorpusEntry({
    required this.deckId,
    this.label,
    this.note,
  });

  final String deckId;
  final String? label;
  final String? note;
}

class SourceDeckCandidate {
  SourceDeckCandidate({
    required this.deckId,
    required this.deckName,
    required this.cards,
    required this.commanderNames,
    required this.commanderColors,
    required this.archetype,
    required this.bracket,
    this.label,
    this.note,
  });

  final String deckId;
  final String deckName;
  final List<Map<String, dynamic>> cards;
  final List<String> commanderNames;
  final Set<String> commanderColors;
  final String archetype;
  final int bracket;
  final String? label;
  final String? note;

  String get commanderLabel => commanderNames.join(' + ');

  int get commanderCount => commanderNames.length;

  List<Map<String, dynamic>> get commanderOnlyCards => cards
      .where((card) => card['is_commander'] == true)
      .map((card) => {
            'card_id': card['card_id'],
            'quantity': card['quantity'],
            'is_commander': true,
          })
      .toList();
}

class CommanderOnlyRunResult {
  CommanderOnlyRunResult({
    required this.commanderLabel,
    required this.sourceDeckId,
    required this.sourceDeckName,
    required this.seedDeckId,
    required this.archetype,
    required this.bracket,
    required this.resultKind,
    required this.optimizeStatus,
    required this.timings,
    required this.savedArtifactPath,
    required this.expectedChecks,
    required this.failedChecks,
    required this.warnings,
    required this.summary,
  });

  final String commanderLabel;
  final String sourceDeckId;
  final String sourceDeckName;
  final String seedDeckId;
  final String archetype;
  final int bracket;
  final String resultKind;
  final int optimizeStatus;
  final Map<String, dynamic> timings;
  final String savedArtifactPath;
  final List<String> expectedChecks;
  final List<String> failedChecks;
  final List<String> warnings;
  final Map<String, dynamic> summary;

  bool get passed => failedChecks.isEmpty;

  Map<String, dynamic> toJson() => {
        'commander_label': commanderLabel,
        'source_deck_id': sourceDeckId,
        'source_deck_name': sourceDeckName,
        'seed_deck_id': seedDeckId,
        'archetype': archetype,
        'bracket': bracket,
        'result_kind': resultKind,
        'optimize_status': optimizeStatus,
        'timings': timings,
        'saved_artifact_path': savedArtifactPath,
        'expected_checks': expectedChecks,
        'failed_checks': failedChecks,
        'warnings': warnings,
        'summary': summary,
        'passed': passed,
      };
}

Future<void> main(List<String> args) async {
  final config = RuntimeValidationConfig.parse(args);
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final apiBaseUrl = env['TEST_API_BASE_URL'] ?? _defaultApiBaseUrl;
  final artifactDirPath = env['VALIDATION_ARTIFACT_DIR'] ?? _defaultArtifactDir;
  final summaryJsonPath = env['VALIDATION_SUMMARY_JSON_PATH'] ??
      (config.dryRun ? _defaultDryRunSummaryJsonPath : _defaultSummaryJsonPath);
  final summaryMdPath = env['VALIDATION_SUMMARY_MD_PATH'] ??
      (config.dryRun ? _defaultDryRunSummaryMdPath : _defaultSummaryMdPath);
  final corpusPath = env['VALIDATION_CORPUS_PATH'] ?? _defaultCorpusPath;
  final validationLimit = int.tryParse(env['VALIDATION_LIMIT'] ?? '') ?? 19;
  final maxAllowedTotalMs =
      int.tryParse(env['COMMANDER_ONLY_MAX_TOTAL_MS'] ?? '') ?? 90000;

  final artifactsDir = Directory(artifactDirPath);
  if (!artifactsDir.existsSync()) {
    artifactsDir.createSync(recursive: true);
  }

  if (!config.skipHealthCheck) {
    final apiReadinessError = await _validateApiBaseUrl(apiBaseUrl);
    if (apiReadinessError != null) {
      stderr.writeln(apiReadinessError);
      exitCode = 1;
      return;
    }
  }

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    stderr.writeln('Falha ao conectar ao banco.');
    exitCode = 1;
    return;
  }

  final pool = db.connection;

  try {
    final corpusEntries = _loadCorpusEntries(corpusPath);
    final candidates = await _loadCandidatesFromCorpus(
      pool: pool,
      corpusEntries: corpusEntries,
      limit: validationLimit,
    );

    if (candidates.isEmpty) {
      stderr.writeln('Nenhum candidato valido encontrado no corpus.');
      exitCode = 1;
      return;
    }

    final runStartedAt = DateTime.now().toIso8601String();
    if (config.dryRun) {
      final summary = _buildDryRunSummary(
        apiBaseUrl: apiBaseUrl,
        artifactDirPath: artifactDirPath,
        corpusPath: corpusPath,
        validationLimit: validationLimit,
        maxAllowedTotalMs: maxAllowedTotalMs,
        runStartedAt: runStartedAt,
        apiHealthCheckSkipped: config.skipHealthCheck,
        candidates: candidates,
      );
      await _writeSummaryFiles(
        summary: summary,
        summaryJsonPath: summaryJsonPath,
        summaryMdPath: summaryMdPath,
      );
      print(
        'Dry-run finalizado: ${candidates.length} candidato(s) seriam validados. '
        'Nenhuma autenticacao, deck, optimize, bulk save ou validate foi executado.',
      );
      print('Resumo salvo em $summaryJsonPath');
      print('Relatorio salvo em $summaryMdPath');
      return;
    }

    final token = await _getOrCreateAuthToken(apiBaseUrl);
    final results = <CommanderOnlyRunResult>[];

    for (final candidate in candidates) {
      print('');
      print('=== ${candidate.commanderLabel} | ${candidate.archetype} ===');
      final result = await _runCommanderOnlyValidation(
        apiBaseUrl: apiBaseUrl,
        token: token,
        pool: pool,
        candidate: candidate,
        artifactDirPath: artifactDirPath,
        maxAllowedTotalMs: maxAllowedTotalMs,
        proveCacheHit: config.proveCacheHit,
      );
      results.add(result);
      print(
        '${result.passed ? 'PASSOU' : 'FALHOU'} | '
        '${result.resultKind} | '
        'tempo=${result.timings['total_ms'] ?? 'n/a'}ms',
      );
    }

    final summary = {
      'generated_at': DateTime.now().toIso8601String(),
      'run_started_at': runStartedAt,
      'mode': 'apply',
      'api_base_url': apiBaseUrl,
      'artifact_dir': artifactDirPath,
      'corpus_path': corpusPath,
      'validation_limit': validationLimit,
      'max_allowed_total_ms': maxAllowedTotalMs,
      'total': results.length,
      'passed': results.where((r) => r.passed).length,
      'failed': results.where((r) => !r.passed).length,
      'completed': results.where((r) => r.resultKind == 'completed').length,
      'protected_rejections':
          results.where((r) => r.resultKind == 'protected_rejection').length,
      'cache_hit_probe_enabled': config.proveCacheHit,
      'results': results.map((r) => r.toJson()).toList(),
    };

    await _writeSummaryFiles(
      summary: summary,
      summaryJsonPath: summaryJsonPath,
      summaryMdPath: summaryMdPath,
    );

    print('');
    print('Resumo salvo em $summaryJsonPath');
    print('Relatorio salvo em $summaryMdPath');

    if (results.any((r) => !r.passed)) {
      exitCode = 1;
    }
  } finally {
    await db.close();
  }
}

void _printUsage() {
  print('''
Uso: dart run bin/run_commander_only_optimization_validation.dart [--dry-run|--apply]

Modo padrao:
  --dry-run   Planeja o runtime E2E sem autenticar, criar deck ou chamar optimize.
  --skip-health-check
              No dry-run, pula GET /health e POST /auth/login vazio. Use para
              planejamento estrutural/offline quando a API local nao esta viva.

Escrita real:
  --apply     Executa o runtime antigo completo: login/register, cria deck seed,
              chama /ai/optimize, aplica bulk cards e valida o deck.
  --prove-cache-hit
              Com --apply, repete o mesmo /ai/optimize antes do apply para
              provar cache.hit=true no runtime vivo.

Variaveis de ambiente mantidas:
  TEST_API_BASE_URL
  VALIDATION_ARTIFACT_DIR
  VALIDATION_SUMMARY_JSON_PATH
  VALIDATION_SUMMARY_MD_PATH
  VALIDATION_CORPUS_PATH
  VALIDATION_LIMIT
  COMMANDER_ONLY_MAX_TOTAL_MS
''');
}

Future<CommanderOnlyRunResult> _runCommanderOnlyValidation({
  required String apiBaseUrl,
  required String token,
  required Pool pool,
  required SourceDeckCandidate candidate,
  required String artifactDirPath,
  required int maxAllowedTotalMs,
  required bool proveCacheHit,
}) async {
  final seedDeckId = await _createCommanderOnlySeedDeck(
    apiBaseUrl: apiBaseUrl,
    token: token,
    candidate: candidate,
  );

  final optimizePayload = {
    'deck_id': seedDeckId,
    'archetype': candidate.archetype,
    'bracket': candidate.bracket,
    'keep_theme': true,
  };

  final optimizeResponse = await _optimizeWithPolling(
    apiBaseUrl: apiBaseUrl,
    token: token,
    payload: optimizePayload,
  );
  final optimizeBody = _decodeJson(optimizeResponse);

  final qualityError = optimizeBody['quality_error'] as Map<String, dynamic>?;
  final qualityCode = qualityError?['code']?.toString() ?? '';

  if (optimizeResponse.statusCode != 200) {
    final protectedRejection = optimizeResponse.statusCode == 422 &&
        {
          'OPTIMIZE_NEEDS_REPAIR',
          'OPTIMIZE_NO_SAFE_SWAPS',
          'OPTIMIZE_QUALITY_REJECTED',
          'OPTIMIZE_NO_ACTIONABLE_SWAPS',
        }.contains(qualityCode);

    final artifactPath = await _writeArtifact(
      artifactDirPath: artifactDirPath,
      commanderLabel: candidate.commanderLabel,
      payload: {
        'source_deck_id': candidate.deckId,
        'source_deck_name': candidate.deckName,
        'seed_deck_id': seedDeckId,
        'optimize_request': optimizePayload,
        'optimize_status': optimizeResponse.statusCode,
        'optimize_response': optimizeBody,
      },
    );

    return CommanderOnlyRunResult(
      commanderLabel: candidate.commanderLabel,
      sourceDeckId: candidate.deckId,
      sourceDeckName: candidate.deckName,
      seedDeckId: seedDeckId,
      archetype: candidate.archetype,
      bracket: candidate.bracket,
      resultKind: protectedRejection ? 'protected_rejection' : 'failure',
      optimizeStatus: optimizeResponse.statusCode,
      timings: _extractTimingSummary(optimizeBody),
      savedArtifactPath: artifactPath,
      expectedChecks: protectedRejection
          ? const [
              'o backend recusou o commander-only inseguro em vez de retornar um deck ruim',
            ]
          : const [],
      failedChecks: protectedRejection
          ? const []
          : ['POST /ai/optimize retornou ${optimizeResponse.statusCode}'],
      warnings: [
        if (protectedRejection)
          'Rejeicao protegida: ${qualityError?['message'] ?? qualityCode}',
        ...((qualityError?['reasons'] as List?)?.map((e) => '$e') ??
            const Iterable<String>.empty()),
        _extractMessage(optimizeBody),
      ],
      summary: {
        'mode': optimizeBody['mode'],
        'quality_error_code': qualityCode,
      },
    );
  }

  final mode = optimizeBody['mode']?.toString() ?? '';
  http.Response? cacheProbeResponse;
  Map<String, dynamic>? cacheProbeBody;
  if (proveCacheHit) {
    cacheProbeResponse = await _optimizeWithPolling(
      apiBaseUrl: apiBaseUrl,
      token: token,
      payload: optimizePayload,
    );
    cacheProbeBody = _decodeJson(cacheProbeResponse);
  }

  final additionsDetailed = (optimizeBody['additions_detailed'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((item) => item['card_id'] is String)
          .toList() ??
      <Map<String, dynamic>>[];

  final bulkResponse = await http.post(
    Uri.parse('$apiBaseUrl/decks/$seedDeckId/cards/bulk'),
    headers: _jsonHeaders(token),
    body: jsonEncode({
      'cards': additionsDetailed
          .map((item) => {
                'card_id': item['card_id'] as String,
                'quantity': (item['quantity'] as int?) ?? 1,
              })
          .toList(),
    }),
  );

  final validateResponse = await http.post(
    Uri.parse('$apiBaseUrl/decks/$seedDeckId/validate'),
    headers: _authHeaders(token),
  );

  final savedCards = await _loadDeckCards(pool, seedDeckId);
  final finalCardCount = savedCards.fold<int>(
    0,
    (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
  );
  final finalCommanderCount = savedCards
      .where((card) => card['is_commander'] == true)
      .fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));
  final landCount = savedCards.fold<int>(0, (sum, card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    if (!typeLine.contains('land')) return sum;
    return sum + ((card['quantity'] as int?) ?? 0);
  });
  final basicCount = savedCards.fold<int>(0, (sum, card) {
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    final isBasic = typeLine.contains('basic land');
    if (!isBasic) return sum;
    return sum + ((card['quantity'] as int?) ?? 0);
  });

  final postAnalysis =
      (optimizeBody['post_analysis'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final consistencySlo =
      (optimizeBody['consistency_slo'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final timingSummary = _extractTimingSummary(optimizeBody);
  final totalMs = (timingSummary['total_ms'] as int?) ?? 0;
  final cacheProbeHit =
      ((cacheProbeBody?['cache'] as Map?)?['hit'] as bool?) == true;

  final expectedChecks = <String>[];
  final failedChecks = <String>[];

  void expectCheck(String description, bool passed) {
    expectedChecks.add(description);
    if (!passed) failedChecks.add(description);
  }

  final manaAssessment = postAnalysis['mana_base_assessment']?.toString() ?? '';

  expectCheck('optimize retornou mode=complete', mode == 'complete');
  expectCheck('complete retornou additions_detailed utilizavel',
      additionsDetailed.isNotEmpty);
  expectCheck('POST /decks/:id/cards/bulk retornou sucesso',
      bulkResponse.statusCode == 200);
  expectCheck('POST /decks/:id/validate aprovou o deck final',
      validateResponse.statusCode == 200);
  expectCheck('deck final mantem 100 cartas', finalCardCount == 100);
  expectCheck('deck final preserva a quantidade correta de comandantes',
      finalCommanderCount == candidate.commanderCount);
  expectCheck('land count final ficou em faixa segura',
      landCount >= 28 && landCount <= 42);
  expectCheck('basic lands nao inflaram acima do toleravel', basicCount <= 40);
  expectCheck('pipeline terminou abaixo do budget de tempo',
      totalMs > 0 && totalMs <= maxAllowedTotalMs);
  expectCheck(
    'mana base final nao ficou com alerta forte',
    !manaAssessment.toLowerCase().contains('poucos terrenos') &&
        !manaAssessment.toLowerCase().contains('falta mana'),
  );
  expectCheck(
    'guaranteed basics stage nao precisou fechar o deck',
    consistencySlo['guaranteed_basics_stage_used'] != true,
  );
  if (proveCacheHit) {
    expectCheck(
      'segunda chamada de optimize confirmou cache.hit=true',
      cacheProbeResponse?.statusCode == 200 && cacheProbeHit,
    );
  }

  final artifactPath = await _writeArtifact(
    artifactDirPath: artifactDirPath,
    commanderLabel: candidate.commanderLabel,
    payload: {
      'source_deck_id': candidate.deckId,
      'source_deck_name': candidate.deckName,
      'seed_deck_id': seedDeckId,
      'optimize_request': optimizePayload,
      'optimize_response': optimizeBody,
      'bulk_status': bulkResponse.statusCode,
      'validate_status': validateResponse.statusCode,
      if (proveCacheHit) 'cache_probe_status': cacheProbeResponse?.statusCode,
      if (proveCacheHit) 'cache_probe_response': cacheProbeBody,
      'saved_cards': savedCards,
    },
  );

  return CommanderOnlyRunResult(
    commanderLabel: candidate.commanderLabel,
    sourceDeckId: candidate.deckId,
    sourceDeckName: candidate.deckName,
    seedDeckId: seedDeckId,
    archetype: candidate.archetype,
    bracket: candidate.bracket,
    resultKind: 'completed',
    optimizeStatus: optimizeResponse.statusCode,
    timings: timingSummary,
    savedArtifactPath: artifactPath,
    expectedChecks: expectedChecks,
    failedChecks: failedChecks,
    warnings: [
      if (basicCount > 36) 'basic lands altos: $basicCount',
      ...((optimizeBody['validation_warnings'] as List?)?.map((e) => '$e') ??
          const Iterable<String>.empty()),
      if (bulkResponse.statusCode != 200)
        'bulk save falhou: ${bulkResponse.body}',
      if (validateResponse.statusCode != 200)
        'validate falhou: ${validateResponse.body}',
      if (proveCacheHit && !cacheProbeHit)
        'cache hit nao confirmado na segunda chamada de optimize',
    ],
    summary: {
      'mode': mode,
      'final_card_count': finalCardCount,
      'final_commander_count': finalCommanderCount,
      'land_count': landCount,
      'basic_count': basicCount,
      'mana_base_assessment': manaAssessment,
      'average_cmc': postAnalysis['average_cmc'],
      'consistency_slo': consistencySlo,
      if (proveCacheHit)
        'cache_probe': {
          'status': cacheProbeResponse?.statusCode,
          'hit': cacheProbeHit,
          'cache_key': (cacheProbeBody?['cache'] as Map?)?['cache_key'],
        },
    },
  );
}

Map<String, dynamic> _buildDryRunSummary({
  required String apiBaseUrl,
  required String artifactDirPath,
  required String corpusPath,
  required int validationLimit,
  required int maxAllowedTotalMs,
  required String runStartedAt,
  required bool apiHealthCheckSkipped,
  required List<SourceDeckCandidate> candidates,
}) {
  return {
    'generated_at': DateTime.now().toIso8601String(),
    'run_started_at': runStartedAt,
    'mode': 'dry_run',
    'api_base_url': apiBaseUrl,
    'artifact_dir': artifactDirPath,
    'corpus_path': corpusPath,
    'validation_limit': validationLimit,
    'max_allowed_total_ms': maxAllowedTotalMs,
    'total': candidates.length,
    'passed': 0,
    'failed': 0,
    'completed': 0,
    'protected_rejections': 0,
    'api_health_check_skipped': apiHealthCheckSkipped,
    'writes_blocked_by_default': true,
    'requires_apply_for_writes': true,
    'blocked_operations': const [
      'auth login/register',
      'POST /decks',
      'POST /ai/optimize',
      'POST /decks/:id/cards/bulk',
      'POST /decks/:id/validate',
    ],
    'results': candidates
        .map(
          (candidate) => {
            'commander_label': candidate.commanderLabel,
            'source_deck_id': candidate.deckId,
            'source_deck_name': candidate.deckName,
            'seed_deck_id': null,
            'archetype': candidate.archetype,
            'bracket': candidate.bracket,
            'result_kind': 'dry_run_planned',
            'optimize_status': null,
            'timings': const <String, dynamic>{},
            'saved_artifact_path': null,
            'expected_checks': const [
              'runtime E2E planejado sem escrita real',
              'usar --apply para autenticar, criar deck seed, otimizar e validar',
            ],
            'failed_checks': const <String>[],
            'warnings': const [
              'dry-run nao prova optimize/apply runtime; apenas prova candidatos e guardrail de escrita',
            ],
            'summary': {
              'mode': 'dry_run',
              'would_create_seed_deck': true,
              'would_optimize': true,
              'would_bulk_apply': true,
              'would_validate_deck': true,
              'commander_count': candidate.commanderCount,
              'commander_colors': candidate.commanderColors.toList()..sort(),
              'source_card_count': candidate.cards.fold<int>(
                0,
                (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
              ),
            },
            'passed': true,
          },
        )
        .toList(),
  };
}

Future<List<SourceDeckCandidate>> _loadCandidatesFromCorpus({
  required Pool pool,
  required List<ValidationCorpusEntry> corpusEntries,
  required int limit,
}) async {
  final candidates = <SourceDeckCandidate>[];

  for (final entry in corpusEntries.take(limit)) {
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT d.id::text, d.name, NULLIF(TRIM(d.archetype), '') AS archetype, d.bracket::int
        FROM decks d
        WHERE d.id = @deckId
          AND d.deleted_at IS NULL
          AND LOWER(d.format) = 'commander'
      '''),
      parameters: {'deckId': entry.deckId},
    );

    if (deckResult.isEmpty) continue;
    final row = deckResult.first;
    final cards = await _loadDeckCards(pool, entry.deckId);
    final total = cards.fold<int>(
      0,
      (sum, card) => sum + ((card['quantity'] as int?) ?? 0),
    );
    final commanderCards =
        cards.where((card) => card['is_commander'] == true).toList();
    if (total != 100 || commanderCards.isEmpty) continue;

    final commanderNames = commanderCards
        .map((card) => card['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final commanderColors = <String>{};
    for (final card in commanderCards) {
      final colors =
          (card['colors'] as List?)?.cast<String>() ?? const <String>[];
      commanderColors.addAll(colors.map((color) => color.toUpperCase()));
    }

    candidates.add(
      SourceDeckCandidate(
        deckId: row[0] as String,
        deckName: row[1] as String? ?? 'Commander Deck',
        cards: cards,
        commanderNames: commanderNames,
        commanderColors: commanderColors,
        archetype: _normalizeArchetype(row[2]?.toString()) ?? 'midrange',
        bracket: row[3] as int? ?? 2,
        label: entry.label,
        note: entry.note,
      ),
    );
  }

  return candidates;
}

Future<List<Map<String, dynamic>>> _loadDeckCards(
    Pool pool, String deckId) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        dc.card_id::text,
        dc.quantity::int,
        dc.is_commander,
        c.name,
        c.type_line,
        COALESCE(c.mana_cost, '') AS mana_cost,
        COALESCE(c.colors, ARRAY[]::text[]) AS colors,
        COALESCE(
          (
            SELECT SUM(
              CASE
                WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                WHEN m[1] = 'X' THEN 0
                ELSE 1
              END
            )
            FROM regexp_matches(COALESCE(c.mana_cost, ''), '\\{([^}]+)\\}', 'g') AS m(m)
          ),
          0
        )::double precision AS cmc,
        COALESCE(c.oracle_text, '') AS oracle_text
      FROM deck_cards dc
      JOIN cards c ON c.id = dc.card_id
      WHERE dc.deck_id = @deckId
      ORDER BY dc.is_commander DESC, c.name ASC
    '''),
    parameters: {'deckId': deckId},
  );

  return result
      .map(
        (row) => <String, dynamic>{
          'card_id': row[0] as String,
          'quantity': row[1] as int,
          'is_commander': row[2] as bool? ?? false,
          'name': row[3] as String? ?? '',
          'type_line': row[4] as String? ?? '',
          'mana_cost': row[5] as String? ?? '',
          'colors': (row[6] as List?)?.cast<String>() ?? const <String>[],
          'cmc': (row[7] as num?)?.toDouble() ?? 0.0,
          'oracle_text': row[8] as String? ?? '',
        },
      )
      .toList();
}

Future<String> _createCommanderOnlySeedDeck({
  required String apiBaseUrl,
  required String token,
  required SourceDeckCandidate candidate,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/decks'),
    headers: _jsonHeaders(token),
    body: jsonEncode({
      'name':
          'Commander Only Validation - ${candidate.commanderLabel} - ${DateTime.now().millisecondsSinceEpoch}',
      'format': 'commander',
      'description':
          'Seed minima com apenas comandante(s) para validacao commander-only',
      'is_public': false,
      'cards': candidate.commanderOnlyCards,
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(
        'Falha ao criar deck seed commander-only: ${response.body}');
  }

  final body = _decodeJson(response);
  final deckId =
      body['id']?.toString() ?? (body['deck']?['id']?.toString() ?? '');
  if (deckId.isEmpty) {
    throw Exception('Resposta sem id do deck seed: ${response.body}');
  }
  return deckId;
}

Future<http.Response> _optimizeWithPolling({
  required String apiBaseUrl,
  required String token,
  required Map<String, dynamic> payload,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/ai/optimize'),
    headers: _jsonHeaders(token),
    body: jsonEncode(payload),
  );

  if (response.statusCode != 202) {
    return response;
  }

  final body = _decodeJson(response);
  final jobId = body['job_id']?.toString();
  if (jobId == null || jobId.isEmpty) {
    throw Exception('Resposta 202 sem job_id: ${response.body}');
  }

  for (var poll = 0; poll < 150; poll++) {
    await Future<void>.delayed(const Duration(seconds: 2));
    final pollResponse = await http.get(
      Uri.parse('$apiBaseUrl/ai/optimize/jobs/$jobId'),
      headers: _authHeaders(token),
    );
    final pollBody = _decodeJson(pollResponse);
    final status = pollBody['status']?.toString();

    if (status == 'completed') {
      return http.Response(
        jsonEncode(pollBody['result'] ?? <String, dynamic>{}),
        200,
      );
    }
    if (status == 'failed') {
      return http.Response(jsonEncode(pollBody), 422);
    }
  }

  return http.Response(
    jsonEncode({'error': 'Polling timeout para optimize job'}),
    500,
  );
}

List<ValidationCorpusEntry> _loadCorpusEntries(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Corpus de validacao nao encontrado em $path');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final rawEntries = switch (decoded) {
    {'decks': final List decks} => decks,
    final List decks => decks,
    _ => throw StateError(
        'Corpus invalido em $path: esperado lista ou objeto com "decks".'),
  };

  return rawEntries
      .whereType<Map>()
      .map((raw) => raw.cast<dynamic, dynamic>())
      .map(
        (entry) => ValidationCorpusEntry(
          deckId: entry['deck_id']?.toString().trim() ?? '',
          label: entry['label']?.toString(),
          note: entry['note']?.toString(),
        ),
      )
      .where((entry) => entry.deckId.isNotEmpty)
      .toList();
}

Future<String?> _validateApiBaseUrl(String apiBaseUrl) async {
  try {
    final healthResponse = await http
        .get(Uri.parse('$apiBaseUrl/health'))
        .timeout(const Duration(seconds: 5));
    if (healthResponse.statusCode != 200) {
      return 'API invalida em $apiBaseUrl: GET /health retornou '
          '${_httpFailureSummary(healthResponse)}.';
    }

    final healthBody = _tryDecodeJsonObject(healthResponse.body);
    if (healthBody?['service'] != 'mtgia-server') {
      return 'API invalida em $apiBaseUrl: GET /health nao retornou '
          'service=mtgia-server. Resposta: ${_bodyPreview(healthResponse.body)}. '
          'Suba o backend com `cd server && PORT=8081 dart run .dart_frog/server.dart` '
          'e rode com `TEST_API_BASE_URL=http://127.0.0.1:8081`.';
    }

    final authProbe = await http
        .post(
          Uri.parse('$apiBaseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 5));
    final authBody = _tryDecodeJsonObject(authProbe.body);
    final authLooksValid = authProbe.statusCode == 400 &&
        (authBody?['message']?.toString().trim().isNotEmpty ?? false);
    if (!authLooksValid) {
      return 'API invalida em $apiBaseUrl: POST /auth/login nao respondeu '
          'como a API ManaLoom. Resposta: ${_httpFailureSummary(authProbe)}. '
          'Verifique se a porta nao esta ocupada por servidor estatico.';
    }

    return null;
  } catch (error) {
    return 'Servidor inacessivel em $apiBaseUrl: $error. '
        'Suba o backend e/ou defina TEST_API_BASE_URL para a porta correta.';
  }
}

Future<String> _getOrCreateAuthToken(String apiBaseUrl) async {
  const email = 'optimization.validation.bot@example.com';
  const password = 'OptimizationPass123!';
  const username = 'optimization_validation_bot';

  Future<http.Response> login() {
    return http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  var response = await login();
  if (response.statusCode != 200) {
    final register = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    if (register.statusCode != 201 && register.statusCode != 400) {
      throw Exception(
        'Falha ao registrar usuario de teste: ${_httpFailureSummary(register)}',
      );
    }

    response = await login();
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao autenticar usuario de teste: ${_httpFailureSummary(response)}',
    );
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final token = decoded['token']?.toString();
  if (token == null || token.isEmpty) {
    throw Exception('Token ausente na autenticacao.');
  }
  return token;
}

Map<String, dynamic> _decodeJson(http.Response response) {
  final body = response.body.trim();
  if (body.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  return {'value': decoded};
}

Map<String, dynamic>? _tryDecodeJsonObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    return null;
  }
  return null;
}

String _httpFailureSummary(http.Response response) {
  return 'status=${response.statusCode}, body=${_bodyPreview(response.body)}';
}

String _bodyPreview(String raw) {
  final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 220) return normalized;
  return '${normalized.substring(0, 220)}...';
}

Map<String, dynamic> _extractTimingSummary(Map<String, dynamic> body) {
  final timings = (body['timings'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  return {
    'total_ms': (timings['total_ms'] as num?)?.toInt() ?? 0,
    'stages_ms': (timings['stages_ms'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
  };
}

Map<String, String> _authHeaders(String token) => {
      'Authorization': 'Bearer $token',
    };

Map<String, String> _jsonHeaders(String token) => {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

String _extractMessage(Map<String, dynamic> body) {
  return body['message']?.toString() ??
      body['error']?.toString() ??
      body['reason']?.toString() ??
      '';
}

String? _normalizeArchetype(String? raw) {
  final value = raw?.trim().toLowerCase() ?? '';
  if (value.isEmpty) return null;
  if (value.contains('control')) return 'control';
  if (value.contains('aggro')) return 'aggro';
  if (value.contains('combo')) return 'combo';
  if (value.contains('stax')) return 'stax';
  if (value.contains('tribal')) return 'tribal';
  if (value.contains('midrange')) return 'midrange';
  return value;
}

Future<String> _writeArtifact({
  required String artifactDirPath,
  required String commanderLabel,
  required Map<String, dynamic> payload,
}) async {
  final safeName = commanderLabel
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final file = File('$artifactDirPath/$safeName.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
  return file.path;
}

Future<void> _writeSummaryFiles({
  required Map<String, dynamic> summary,
  required String summaryJsonPath,
  required String summaryMdPath,
}) async {
  await File(summaryJsonPath).parent.create(recursive: true);
  await File(summaryJsonPath).writeAsString(
    const JsonEncoder.withIndent('  ').convert(summary),
  );
  await File(summaryMdPath).parent.create(recursive: true);
  await File(summaryMdPath).writeAsString(_buildMarkdownReport(summary));
}

String _buildMarkdownReport(Map<String, dynamic> summary) {
  final isDryRun = summary['mode'] == 'dry_run';
  final isCacheHitProbe = summary['cache_hit_probe_enabled'] == true;
  final title = isDryRun
      ? '# Dry-run Commander-Only Optimization - 2026-04-27'
      : isCacheHitProbe
          ? '# Commander-Only Cache Hit Probe - 2026-04-27'
          : '# Validacao Commander-Only - 2026-04-21';
  final buffer = StringBuffer()
    ..writeln(title)
    ..writeln()
    ..writeln('- Mode: `${summary['mode'] ?? 'apply'}`')
    ..writeln('- API base: `${summary['api_base_url']}`')
    ..writeln('- Corpus: `${summary['corpus_path']}`')
    ..writeln('- Total: `${summary['total']}`')
    ..writeln('- Passed: `${summary['passed']}`')
    ..writeln('- Failed: `${summary['failed']}`')
    ..writeln('- Completed: `${summary['completed']}`')
    ..writeln('- Protected rejections: `${summary['protected_rejections']}`')
    ..writeln();

  if (isDryRun) {
    buffer
      ..writeln(
          '> Dry-run: nenhuma autenticacao, criacao de deck, optimize, bulk save ou validate foi executado.')
      ..writeln('> Use `--apply` para executar o runtime E2E com escrita real.')
      ..writeln(
          '> Health check pulado: `${summary['api_health_check_skipped'] == true}`.')
      ..writeln();
  }

  final results =
      (summary['results'] as List?)?.whereType<Map>().toList() ?? const [];
  for (final raw in results) {
    final result = raw.cast<dynamic, dynamic>();
    buffer
      ..writeln('## ${result['commander_label']}')
      ..writeln()
      ..writeln('- Result kind: `${result['result_kind']}`')
      ..writeln('- Passed: `${result['passed']}`')
      ..writeln('- Source deck: `${result['source_deck_id']}`')
      ..writeln('- Seed deck: `${result['seed_deck_id']}`')
      ..writeln('- Archetype: `${result['archetype']}`')
      ..writeln('- Timings: `${jsonEncode(result['timings'])}`');

    final resultSummary = result['summary'] is Map
        ? (result['summary'] as Map).cast<dynamic, dynamic>()
        : const <dynamic, dynamic>{};
    final cacheProbe = resultSummary['cache_probe'] is Map
        ? (resultSummary['cache_probe'] as Map).cast<dynamic, dynamic>()
        : null;
    if (cacheProbe != null) {
      buffer
        ..writeln(
            '- Cache probe: `status=${cacheProbe['status']}, hit=${cacheProbe['hit']}, cache_key=${cacheProbe['cache_key']}`');
    }

    final failedChecks =
        (result['failed_checks'] as List?)?.map((e) => '- $e').join('\n') ?? '';
    if (failedChecks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Failed checks:')
        ..writeln(failedChecks);
    }

    final warnings =
        (result['warnings'] as List?)?.map((e) => '- $e').join('\n') ?? '';
    if (warnings.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Warnings:')
        ..writeln(warnings);
    }

    buffer.writeln();
  }

  return buffer.toString();
}
