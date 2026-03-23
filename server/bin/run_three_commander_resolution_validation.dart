#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/ai/deck_state_analysis.dart';
import '../lib/database.dart';

const _defaultApiBaseUrl = 'http://127.0.0.1:8080';
late final String _artifactDirPath;
late final String _summaryJsonPath;
late final String _summaryMdPath;
late final int _validationLimit;
late final String _selectionMode;
late final String? _corpusPath;
const _generatedDeckNameFilters = '''
        AND d.name NOT LIKE 'Optimization Validation - %'
        AND d.name NOT LIKE 'Resolution Validation - %'
        AND d.name NOT LIKE 'Rebuild Draft - %'
        AND d.name NOT LIKE 'Rebuild Preview - %'
''';

class SourceDeckCandidate {
  SourceDeckCandidate({
    required this.deckId,
    required this.deckName,
    required this.commanderName,
    required this.commanderCardId,
    required this.commanderColors,
    required this.sourceArchetype,
    required this.bracket,
    required this.cards,
    required this.sourceDeckStateStatus,
    required this.sourceSeverityScore,
    this.expectedFlowPaths = const [],
    this.corpusLabel,
    this.corpusNote,
  });

  final String deckId;
  final String deckName;
  final String commanderName;
  final String commanderCardId;
  final List<String> commanderColors;
  final String? sourceArchetype;
  final int? bracket;
  final List<Map<String, dynamic>> cards;
  final String sourceDeckStateStatus;
  final int sourceSeverityScore;
  final List<String> expectedFlowPaths;
  final String? corpusLabel;
  final String? corpusNote;

  SourceDeckCandidate withCorpusEntry(ValidationCorpusEntry entry) {
    return SourceDeckCandidate(
      deckId: deckId,
      deckName: deckName,
      commanderName: commanderName,
      commanderCardId: commanderCardId,
      commanderColors: commanderColors,
      sourceArchetype: sourceArchetype,
      bracket: bracket,
      cards: cards,
      sourceDeckStateStatus: sourceDeckStateStatus,
      sourceSeverityScore: sourceSeverityScore,
      expectedFlowPaths: entry.expectedFlowPaths,
      corpusLabel: entry.label,
      corpusNote: entry.note,
    );
  }

  String get resolvedArchetype {
    final detected = _normalizeArchetype(sourceArchetype);
    if (detected != null) return detected;
    final analysis =
        DeckArchetypeAnalyzer(cards, commanderColors).generateAnalysis();
    final byAnalysis =
        _normalizeArchetype(analysis['detected_archetype']?.toString());
    return byAnalysis ?? 'midrange';
  }
}

class ValidationCorpusEntry {
  ValidationCorpusEntry({
    required this.deckId,
    this.label,
    this.expectedFlowPaths = const [],
    this.note,
  });

  final String deckId;
  final String? label;
  final List<String> expectedFlowPaths;
  final String? note;
}

class ResolutionRunResult {
  ResolutionRunResult({
    required this.commanderName,
    required this.sourceDeckId,
    required this.sourceDeckName,
    required this.cloneDeckId,
    required this.finalDeckId,
    required this.archetype,
    required this.bracket,
    required this.flowPath,
    required this.optimizeStatus,
    required this.rebuildStatus,
    required this.finalDeckValid,
    required this.finalDeckState,
    required this.finalAverageCmc,
    required this.finalLandCount,
    required this.finalInteraction,
    required this.savedArtifactPath,
    required this.expectedChecks,
    required this.failedChecks,
    required this.warnings,
  });

  final String commanderName;
  final String sourceDeckId;
  final String sourceDeckName;
  final String cloneDeckId;
  final String finalDeckId;
  final String archetype;
  final int bracket;
  final String flowPath;
  final int optimizeStatus;
  final int? rebuildStatus;
  final bool finalDeckValid;
  final String finalDeckState;
  final double finalAverageCmc;
  final int finalLandCount;
  final int finalInteraction;
  final String savedArtifactPath;
  final List<String> expectedChecks;
  final List<String> failedChecks;
  final List<String> warnings;

  bool get passed => failedChecks.isEmpty;

  Map<String, dynamic> toJson() => {
        'commander_name': commanderName,
        'source_deck_id': sourceDeckId,
        'source_deck_name': sourceDeckName,
        'clone_deck_id': cloneDeckId,
        'final_deck_id': finalDeckId,
        'archetype': archetype,
        'bracket': bracket,
        'flow_path': flowPath,
        'optimize_status': optimizeStatus,
        'rebuild_status': rebuildStatus,
        'final_deck_valid': finalDeckValid,
        'final_deck_state': finalDeckState,
        'final_average_cmc': finalAverageCmc,
        'final_land_count': finalLandCount,
        'final_interaction': finalInteraction,
        'saved_artifact_path': savedArtifactPath,
        'expected_checks': expectedChecks,
        'failed_checks': failedChecks,
        'warnings': warnings,
        'passed': passed,
      };
}

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final apiBaseUrl = env['TEST_API_BASE_URL'] ?? _defaultApiBaseUrl;
  _artifactDirPath = env['VALIDATION_ARTIFACT_DIR'] ??
      'test/artifacts/optimization_resolution_three_decks';
  _summaryJsonPath = env['VALIDATION_SUMMARY_JSON_PATH'] ??
      'test/artifacts/optimization_resolution_three_decks/latest_summary.json';
  _summaryMdPath = env['VALIDATION_SUMMARY_MD_PATH'] ??
      '../RELATORIO_RESOLUCAO_3_DECKS_2026-03-17.md';
  _validationLimit = int.tryParse(env['VALIDATION_LIMIT'] ?? '') ?? 3;
  _selectionMode = (env['VALIDATION_SELECTION_MODE'] ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('-', '_');
  _corpusPath = _resolveCorpusPath(env['VALIDATION_CORPUS_PATH']);

  final artifactsDir = Directory(_artifactDirPath);
  if (!artifactsDir.existsSync()) {
    artifactsDir.createSync(recursive: true);
  }

  final serverOk = await _ensureServerIsReachable(apiBaseUrl);
  if (!serverOk) {
    stderr.writeln('Servidor inacessivel em $apiBaseUrl.');
    exitCode = 1;
    return;
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
    final token = await _getOrCreateAuthToken(apiBaseUrl);
    final candidates = await _loadSourceCandidates(pool);
    final corpusEntries =
        _corpusPath != null ? _loadCorpusEntries(_corpusPath!) : const <ValidationCorpusEntry>[];
    final usingCorpus = corpusEntries.isNotEmpty;
    final selected = usingCorpus
        ? _selectCandidatesFromCorpus(
            candidates,
            corpusEntries: corpusEntries,
            limit: _validationLimit,
          )
        : _selectCandidates(
            candidates,
            limit: _validationLimit,
            selectionMode: _selectionMode,
          );

    if (selected.length < _validationLimit) {
      stderr.writeln(
        'Nao foi possivel selecionar ${_validationLimit} decks Commander validos e distintos. Encontrados: ${selected.length}',
      );
      exitCode = 1;
      return;
    }

    final results = <ResolutionRunResult>[];
    final runStartedAt = DateTime.now().toIso8601String();

    for (final candidate in selected) {
      print('');
      print(
        '=== ${candidate.commanderName} | ${candidate.resolvedArchetype} ===',
      );
      final result = await _runResolutionForDeck(
        apiBaseUrl: apiBaseUrl,
        token: token,
        pool: pool,
        candidate: candidate,
      );
      results.add(result);
      print(
        '${result.passed ? 'PASSOU' : 'FALHOU'} | '
        '${result.flowPath} | '
        'deck final ${result.finalDeckState} | '
        'lands=${result.finalLandCount} | '
        'interaction=${result.finalInteraction}',
      );
    }

    final summary = {
      'generated_at': DateTime.now().toIso8601String(),
      'run_started_at': runStartedAt,
      'api_base_url': apiBaseUrl,
      'artifact_dir': _artifactDirPath,
      'selection_mode': usingCorpus ? 'corpus' : _selectionMode,
      if (_corpusPath != null) 'corpus_path': _corpusPath,
      'total': results.length,
      'direct_optimizations':
          results.where((r) => r.flowPath == 'optimized_directly').length,
      'rebuild_resolutions':
          results.where((r) => r.flowPath == 'rebuild_guided').length,
      'safe_no_change':
          results.where((r) => r.flowPath == 'safe_no_change').length,
      'unresolved': results
          .where((r) => r.flowPath == 'unresolved_rejection')
          .length,
      'passed': results.where((r) => r.passed).length,
      'failed': results.where((r) => !r.passed).length,
      'results': results.map((r) => r.toJson()).toList(),
    };

    await File(_summaryJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
    );
    await File(_summaryMdPath).writeAsString(_buildMarkdownReport(summary));

    print('');
    print('Resumo salvo em $_summaryJsonPath');
    print('Relatorio salvo em $_summaryMdPath');

    if (results.any((r) => !r.passed) ||
        results.any((r) => r.flowPath == 'unresolved_rejection')) {
      exitCode = 1;
    }
  } finally {
    await db.close();
  }
}

Future<ResolutionRunResult> _runResolutionForDeck({
  required String apiBaseUrl,
  required String token,
  required Pool pool,
  required SourceDeckCandidate candidate,
}) async {
  final cloneDeckId = await _createDeckClone(
    apiBaseUrl: apiBaseUrl,
    token: token,
    candidate: candidate,
  );

  final optimizePayload = {
    'deck_id': cloneDeckId,
    'archetype': candidate.resolvedArchetype,
    'bracket': candidate.bracket ?? 2,
    'keep_theme': true,
  };

  final optimizeResponse = await _optimizeWithPolling(
    apiBaseUrl: apiBaseUrl,
    token: token,
    payload: optimizePayload,
  );
  final optimizeBody = _decodeJson(optimizeResponse);

  String flowPath = 'optimized_directly';
  int? rebuildStatus;
  String finalDeckId = cloneDeckId;
  Map<String, dynamic>? rebuildBody;
  final warnings = <String>[];

  if (optimizeResponse.statusCode == 200) {
    final optimizedCards = await _applyRecommendations(
      pool: pool,
      originalCards: candidate.cards,
      responseBody: optimizeBody,
    );

    final putResponse = await http.put(
      Uri.parse('$apiBaseUrl/decks/$cloneDeckId'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'cards': optimizedCards
            .map(
              (card) => {
                'card_id': card['card_id'],
                'quantity': card['quantity'],
                if (card['is_commander'] == true) 'is_commander': true,
              },
            )
            .toList(),
      }),
    );
    if (putResponse.statusCode != 200) {
      warnings.add('Falha ao salvar optimize direto: ${putResponse.body}');
    }
  } else {
    flowPath = 'unresolved_rejection';
    final qualityError = optimizeBody['quality_error'] is Map
        ? (optimizeBody['quality_error'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final qualityCode = qualityError['code']?.toString() ?? '';
    final outcomeCode = optimizeBody['outcome_code']?.toString() ?? '';
    final deckState = optimizeBody['deck_state'] is Map
        ? (optimizeBody['deck_state'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final nextAction = optimizeBody['next_action'] is Map
        ? (optimizeBody['next_action'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final nextPayload = nextAction['payload'] is Map
        ? (nextAction['payload'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    if (optimizeResponse.statusCode == 422 &&
        const {'near_peak', 'no_safe_upgrade_found'}.contains(outcomeCode) &&
        deckState['status']?.toString() == 'healthy') {
      flowPath = 'safe_no_change';
      warnings.add(
        'Nenhuma troca segura encontrada; deck original preservado em estado saudável.',
      );
    } else if (optimizeResponse.statusCode == 422 &&
        qualityCode == 'OPTIMIZE_NEEDS_REPAIR' &&
        nextAction['type']?.toString() == 'rebuild_guided') {
      final rebuildPayload = {
        'deck_id': nextPayload['deck_id']?.toString() ?? cloneDeckId,
        'archetype':
            nextPayload['archetype']?.toString() ?? candidate.resolvedArchetype,
        'bracket': nextPayload['bracket'] ?? candidate.bracket ?? 2,
        'theme': nextPayload['theme']?.toString(),
        'rebuild_scope': nextPayload['rebuild_scope']?.toString() ?? 'auto',
        'save_mode': nextPayload['save_mode']?.toString() ?? 'draft_clone',
      };

      final rebuildResponse = await http.post(
        Uri.parse('$apiBaseUrl/ai/rebuild'),
        headers: _jsonHeaders(token),
        body: jsonEncode(rebuildPayload),
      );
      rebuildStatus = rebuildResponse.statusCode;
      rebuildBody = _decodeJson(rebuildResponse);

      if (rebuildResponse.statusCode == 200) {
        flowPath = 'rebuild_guided';
        finalDeckId = rebuildBody['draft_deck_id']?.toString() ?? '';
        if (finalDeckId.isEmpty) {
          warnings.add('Rebuild retornou 200 sem draft_deck_id.');
          flowPath = 'unresolved_rejection';
          finalDeckId = cloneDeckId;
        }
      } else {
        warnings.add(
          'Falha ao executar rebuild_guided: ${_extractMessage(rebuildBody)}',
        );
      }
    } else {
      warnings.add(
        'Rejeicao nao resolvida automaticamente: ${_extractMessage(optimizeBody)}',
      );
    }
  }

  final finalCards = await _loadDeckCards(pool, finalDeckId);
  final finalValidate = finalDeckId.isNotEmpty
      ? await http.post(
          Uri.parse('$apiBaseUrl/decks/$finalDeckId/validate'),
          headers: _authHeaders(token),
        )
      : http.Response('{"error":"final deck ausente"}', 500);

  final finalAnalysis = DeckArchetypeAnalyzer(
    finalCards,
    candidate.commanderColors,
  ).generateAnalysis();
  final finalState = assessDeckOptimizationState(
    cards: finalCards,
    deckAnalysis: finalAnalysis,
    deckFormat: 'commander',
    currentTotalCards: _totalCards(finalCards),
    commanderColorIdentity: candidate.commanderColors.toSet(),
  );

  final artifactPath = await _writeDeckArtifact(
    commanderName: candidate.commanderName,
    payload: {
      'source_deck_id': candidate.deckId,
      'source_deck_name': candidate.deckName,
      'clone_deck_id': cloneDeckId,
      'final_deck_id': finalDeckId,
      'optimize_request': optimizePayload,
      'optimize_status': optimizeResponse.statusCode,
      'optimize_response': optimizeBody,
      if (rebuildBody != null) 'rebuild_status': rebuildStatus,
      if (rebuildBody != null) 'rebuild_response': rebuildBody,
      'final_validate_status': finalValidate.statusCode,
      'final_validate_response': _decodeJson(finalValidate),
      'final_analysis': finalAnalysis,
      'final_state': finalState.toJson(),
    },
  );

  final expectedChecks = <String>[];
  final failedChecks = <String>[];

  void expectCheck(String description, bool passed) {
    expectedChecks.add(description);
    if (!passed) failedChecks.add(description);
  }

  final finalCardCount = _totalCards(finalCards);
  final commanderCount = finalCards
      .where((card) => card['is_commander'] == true)
      .fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));
  final finalLandCount = _landCount(finalAnalysis);
  final finalInteraction = _countInteraction(finalAnalysis);

  expectCheck('deck final existe', finalDeckId.isNotEmpty);
  expectCheck('deck final mantem 100 cartas', finalCardCount == 100);
  expectCheck('deck final mantem exatamente 1 comandante', commanderCount == 1);
  expectCheck(
    'POST /decks/:id/validate aprovou o deck final',
    finalValidate.statusCode == 200,
  );
  expectCheck(
    'deck final terminou em estado healthy',
    finalState.status == 'healthy',
  );
  expectCheck(
    'deck final manteve land count saudável',
    finalLandCount >= 34 && finalLandCount <= 40,
  );

  if (flowPath == 'rebuild_guided') {
    final rebuildValidation = rebuildBody?['validation'] is Map
        ? (rebuildBody!['validation'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final deckStateAfter = rebuildValidation['deck_state_after'] is Map
        ? (rebuildValidation['deck_state_after'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    expectCheck('rebuild_guided retornou 200', rebuildStatus == 200);
    expectCheck(
      'rebuild_guided marcou strict_rules_valid',
      rebuildValidation['strict_rules_valid'] == true,
    );
    expectCheck(
      'rebuild_guided retornou deck_state_after healthy',
      deckStateAfter['status']?.toString() == 'healthy',
    );
  }

  if (candidate.expectedFlowPaths.isNotEmpty) {
    expectCheck(
      'flow_path segue expectativa do corpus (${candidate.expectedFlowPaths.join(' / ')})',
      candidate.expectedFlowPaths.contains(flowPath),
    );
  }

  return ResolutionRunResult(
    commanderName: candidate.commanderName,
    sourceDeckId: candidate.deckId,
    sourceDeckName: candidate.deckName,
    cloneDeckId: cloneDeckId,
    finalDeckId: finalDeckId,
    archetype: candidate.resolvedArchetype,
    bracket: candidate.bracket ?? 2,
    flowPath: flowPath,
    optimizeStatus: optimizeResponse.statusCode,
    rebuildStatus: rebuildStatus,
    finalDeckValid: finalValidate.statusCode == 200,
    finalDeckState: finalState.status,
    finalAverageCmc: _parseDouble(finalAnalysis['average_cmc']),
    finalLandCount: finalLandCount,
    finalInteraction: finalInteraction,
    savedArtifactPath: artifactPath,
    expectedChecks: expectedChecks,
    failedChecks: failedChecks,
    warnings: warnings,
  );
}

Future<bool> _ensureServerIsReachable(String apiBaseUrl) async {
  try {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/health'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode < 500;
  } catch (_) {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(const {'email': 'healthcheck@example.com'}),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 400 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
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
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
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
      throw Exception('Falha ao registrar usuario de teste: ${register.body}');
    }

    response = await login();
  }

  if (response.statusCode != 200) {
    throw Exception('Falha ao autenticar usuario de teste: ${response.body}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final token = decoded['token']?.toString();
  if (token == null || token.isEmpty) {
    throw Exception('Token ausente na autenticacao.');
  }
  return token;
}

Future<List<SourceDeckCandidate>> _loadSourceCandidates(Pool pool) async {
  final decksResult = await pool.execute(
    Sql.named('''
      SELECT
        d.id::text,
        d.name,
        NULLIF(TRIM(d.archetype), '') AS archetype,
        d.bracket::int,
        c.id::text AS commander_card_id,
        c.name AS commander_name,
        COALESCE(c.colors, ARRAY[]::text[]) AS commander_colors
      FROM decks d
      JOIN (
        SELECT deck_id, SUM(quantity)::int AS total_cards
        FROM deck_cards
        GROUP BY deck_id
      ) stats ON stats.deck_id = d.id
      JOIN LATERAL (
        SELECT dc.card_id
        FROM deck_cards dc
        WHERE dc.deck_id = d.id AND dc.is_commander = TRUE
        ORDER BY dc.card_id
        LIMIT 1
      ) cmd ON TRUE
      JOIN cards c ON c.id = cmd.card_id
      WHERE d.deleted_at IS NULL
        AND LOWER(d.format) = 'commander'
        AND stats.total_cards = 100
$_generatedDeckNameFilters
      ORDER BY d.created_at DESC NULLS LAST
      LIMIT 120
    '''),
  );

  final candidates = <SourceDeckCandidate>[];

  for (final row in decksResult) {
    final deckId = row[0] as String;
    final deckName = row[1] as String? ?? 'Commander Deck';
    final archetype = row[2] as String?;
    final bracket = row[3] as int?;
    final commanderCardId = row[4] as String;
    final commanderName = row[5] as String;
    final commanderColors =
        (row[6] as List?)?.cast<String>() ?? const <String>[];

    final cards = await _loadDeckCards(pool, deckId);
    if (cards.isEmpty) continue;

    final total = _totalCards(cards);
    final hasCommander = cards.any((card) => card['is_commander'] == true);
    if (total != 100 || !hasCommander) continue;
    final deckAnalysis =
        DeckArchetypeAnalyzer(cards, commanderColors).generateAnalysis();
    final deckState = assessDeckOptimizationState(
      cards: cards,
      deckAnalysis: deckAnalysis,
      deckFormat: 'commander',
      currentTotalCards: total,
      commanderColorIdentity: commanderColors.toSet(),
    );

    candidates.add(
      SourceDeckCandidate(
        deckId: deckId,
        deckName: deckName,
        commanderName: commanderName,
        commanderCardId: commanderCardId,
        commanderColors: commanderColors,
        sourceArchetype: archetype,
        bracket: bracket,
        cards: cards,
        sourceDeckStateStatus: deckState.status,
        sourceSeverityScore: deckState.severityScore,
      ),
    );
  }

  return candidates;
}

Future<List<Map<String, dynamic>>> _loadDeckCards(
  Pool pool,
  String deckId,
) async {
  if (deckId.isEmpty) return const <Map<String, dynamic>>[];
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

String? _resolveCorpusPath(String? raw) {
  final normalized = raw?.trim() ?? '';
  if (normalized.isEmpty) return null;
  return normalized;
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
    _ => throw StateError('Corpus invalido em $path: esperado lista ou objeto com "decks".'),
  };

  final entries = <ValidationCorpusEntry>[];
  for (final rawEntry in rawEntries) {
    if (rawEntry is! Map) continue;
    final entry = rawEntry.cast<dynamic, dynamic>();
    final deckId = entry['deck_id']?.toString().trim() ?? '';
    if (deckId.isEmpty) continue;
    entries.add(
      ValidationCorpusEntry(
        deckId: deckId,
        label: entry['label']?.toString(),
        expectedFlowPaths: _parseExpectedFlowPaths(entry),
        note: entry['note']?.toString(),
      ),
    );
  }

  return entries;
}

List<SourceDeckCandidate> _selectCandidatesFromCorpus(
  List<SourceDeckCandidate> candidates, {
  required List<ValidationCorpusEntry> corpusEntries,
  required int limit,
}) {
  if (limit > corpusEntries.length) {
    throw StateError(
      'VALIDATION_LIMIT=$limit excede o corpus configurado (${corpusEntries.length} entradas).',
    );
  }

  final byId = <String, SourceDeckCandidate>{
    for (final candidate in candidates) candidate.deckId: candidate,
  };
  final selected = <SourceDeckCandidate>[];
  final missing = <String>[];

  for (final entry in corpusEntries.take(limit)) {
    final candidate = byId[entry.deckId];
    if (candidate == null) {
      missing.add(entry.deckId);
      continue;
    }
    selected.add(candidate.withCorpusEntry(entry));
  }

  if (missing.isNotEmpty) {
    throw StateError(
      'Corpus referencia decks inexistentes ou invalidos: ${missing.join(', ')}',
    );
  }

  return selected;
}

List<String> _parseExpectedFlowPaths(Map<dynamic, dynamic> entry) {
  final multi = entry['expected_flow_paths'];
  if (multi is List) {
    return multi
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  final single = entry['expected_flow_path']?.toString().trim() ?? '';
  if (single.isEmpty) return const [];
  return [single];
}

List<SourceDeckCandidate> _selectCandidates(
  List<SourceDeckCandidate> candidates, {
  required int limit,
  required String selectionMode,
}) {
  if (limit <= 3 && selectionMode != 'balanced') {
    return _selectThreeCandidates(candidates).take(limit).toList();
  }
  return _selectBalancedCandidates(candidates, limit: limit);
}

List<SourceDeckCandidate> _selectThreeCandidates(List<SourceDeckCandidate> candidates) {
  final selected = <SourceDeckCandidate>[];
  final usedCommanders = <String>{};

  void tryPickByArchetype(String archetype) {
    for (final candidate in candidates) {
      final commanderKey = candidate.commanderName.toLowerCase();
      if (usedCommanders.contains(commanderKey)) continue;
      if (candidate.resolvedArchetype != archetype) continue;
      selected.add(candidate);
      usedCommanders.add(commanderKey);
      return;
    }
  }

  for (final archetype in const ['aggro', 'control', 'midrange']) {
    tryPickByArchetype(archetype);
  }

  for (final candidate in candidates) {
    if (selected.length >= 3) break;
    final commanderKey = candidate.commanderName.toLowerCase();
    if (usedCommanders.contains(commanderKey)) continue;
    selected.add(candidate);
    usedCommanders.add(commanderKey);
  }

  return selected.take(3).toList();
}

List<SourceDeckCandidate> _selectBalancedCandidates(
  List<SourceDeckCandidate> candidates, {
  required int limit,
}) {
  final ordered = [...candidates]
    ..sort((a, b) {
      final statusOrder = _statusPriority(a.sourceDeckStateStatus)
          .compareTo(_statusPriority(b.sourceDeckStateStatus));
      if (statusOrder != 0) return statusOrder;
      final severityOrder = b.sourceSeverityScore.compareTo(a.sourceSeverityScore);
      if (severityOrder != 0) return severityOrder;
      return a.commanderName.toLowerCase().compareTo(b.commanderName.toLowerCase());
    });

  final selected = <SourceDeckCandidate>[];
  final usedCommanders = <String>{};
  final preferredStatuses = const ['needs_repair', 'healthy'];
  final preferredArchetypes = const ['aggro', 'control', 'midrange'];

  void tryPick(String status, String archetype) {
    if (selected.length >= limit) return;
    for (final candidate in ordered) {
      final commanderKey = candidate.commanderName.toLowerCase();
      if (usedCommanders.contains(commanderKey)) continue;
      if (candidate.sourceDeckStateStatus != status) continue;
      if (candidate.resolvedArchetype != archetype) continue;
      selected.add(candidate);
      usedCommanders.add(commanderKey);
      return;
    }
  }

  while (selected.length < limit) {
    final before = selected.length;
    for (final status in preferredStatuses) {
      for (final archetype in preferredArchetypes) {
        tryPick(status, archetype);
      }
    }
    if (selected.length == before) break;
  }

  for (final candidate in ordered) {
    if (selected.length >= limit) break;
    final commanderKey = candidate.commanderName.toLowerCase();
    if (usedCommanders.contains(commanderKey)) continue;
    selected.add(candidate);
    usedCommanders.add(commanderKey);
  }

  return selected.take(limit).toList();
}

int _statusPriority(String status) {
  return switch (status) {
    'needs_repair' => 0,
    'incomplete' => 1,
    'healthy' => 2,
    _ => 3,
  };
}

Future<String> _createDeckClone({
  required String apiBaseUrl,
  required String token,
  required SourceDeckCandidate candidate,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/decks'),
    headers: _jsonHeaders(token),
    body: jsonEncode({
      'name':
          'Resolution Validation - ${candidate.commanderName} - ${DateTime.now().millisecondsSinceEpoch}',
      'format': 'commander',
      'description': 'Deck clone para validacao do fluxo completo de optimize/rebuild',
      'is_public': false,
      'cards': candidate.cards
          .map(
            (card) => {
              'card_id': card['card_id'],
              'quantity': card['quantity'],
              if (card['is_commander'] == true) 'is_commander': true,
            },
          )
          .toList(),
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Falha ao criar clone do deck: ${response.body}');
  }

  final body = _decodeJson(response);
  final deckId =
      body['id']?.toString() ?? (body['deck']?['id']?.toString() ?? '');
  if (deckId.isEmpty) {
    throw Exception('Resposta sem id do deck clonado: ${response.body}');
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

  for (var poll = 0; poll < 180; poll++) {
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

Future<List<Map<String, dynamic>>> _applyRecommendations({
  required Pool pool,
  required List<Map<String, dynamic>> originalCards,
  required Map<String, dynamic> responseBody,
}) async {
  final next =
      originalCards.map((card) => Map<String, dynamic>.from(card)).toList();

  final removalsDetailed =
      (responseBody['removals_detailed'] as List?)?.whereType<Map>().toList() ??
          const <Map>[];

  final additionsDetailed = (responseBody['additions_detailed'] as List?)
          ?.whereType<Map>()
          .toList() ??
      const <Map>[];

  final removalCounts = <String, int>{};
  for (final raw in removalsDetailed) {
    final card = raw.cast<String, dynamic>();
    final name = card['name']?.toString().trim().toLowerCase();
    if (name == null || name.isEmpty) continue;
    final qty = (card['quantity'] as int?) ?? 1;
    removalCounts[name] = (removalCounts[name] ?? 0) + qty;
  }

  for (final entry in removalCounts.entries) {
    var remaining = entry.value;
    for (var i = next.length - 1; i >= 0 && remaining > 0; i--) {
      final cardName = (next[i]['name']?.toString().trim().toLowerCase() ?? '');
      if (cardName != entry.key) continue;
      if (next[i]['is_commander'] == true) continue;

      final qty = (next[i]['quantity'] as int?) ?? 0;
      if (qty <= remaining) {
        next.removeAt(i);
        remaining -= qty;
      } else {
        next[i]['quantity'] = qty - remaining;
        remaining = 0;
      }
    }
  }

  for (final raw in additionsDetailed) {
    final addition = raw.cast<String, dynamic>();
    final cardId = addition['card_id']?.toString();
    if (cardId == null || cardId.isEmpty) continue;

    final qty = (addition['quantity'] as int?) ?? 1;
    final existingIndex = next.indexWhere((card) => card['card_id'] == cardId);

    if (existingIndex >= 0) {
      next[existingIndex]['quantity'] =
          ((next[existingIndex]['quantity'] as int?) ?? 0) + qty;
      continue;
    }

    next.add({
      'card_id': cardId,
      'quantity': qty,
      'is_commander': false,
      'name': addition['name']?.toString() ?? '',
    });
  }

  final missingCardIds = next
      .where((card) =>
          (card['card_id']?.toString().isNotEmpty ?? false) &&
          (((card['type_line'] as String?) ?? '').isEmpty ||
              ((card['oracle_text'] as String?) ?? '').isEmpty))
      .map((card) => card['card_id'].toString())
      .toSet()
      .toList();

  if (missingCardIds.isNotEmpty) {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id::text,
          name,
          type_line,
          mana_cost,
          colors,
          COALESCE(
            (SELECT SUM(
              CASE
                WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                WHEN m[1] = 'X' THEN 0
                ELSE 1
              END
            ) FROM regexp_matches(cards.mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
            0
          ) as cmc,
          oracle_text
        FROM cards
        WHERE id::text = ANY(@ids)
      '''),
      parameters: {'ids': missingCardIds},
    );

    final byId = <String, Map<String, dynamic>>{};
    for (final row in result) {
      byId[row[0] as String] = {
        'name': row[1] as String? ?? '',
        'type_line': row[2] as String? ?? '',
        'mana_cost': row[3] as String? ?? '',
        'colors': (row[4] as List?)?.cast<String>() ?? const <String>[],
        'cmc': (row[5] as num?)?.toDouble() ?? 0.0,
        'oracle_text': row[6] as String? ?? '',
      };
    }

    for (final card in next) {
      final cardId = card['card_id']?.toString();
      if (cardId == null || cardId.isEmpty) continue;
      final details = byId[cardId];
      if (details == null) continue;
      card['name'] = details['name'];
      card['type_line'] = details['type_line'];
      card['mana_cost'] = details['mana_cost'];
      card['colors'] = details['colors'];
      card['cmc'] = details['cmc'];
      card['oracle_text'] = details['oracle_text'];
    }
  }

  return next;
}

Map<String, dynamic> _decodeJson(http.Response response) {
  final body = response.body.trim();
  if (body.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  return {'value': decoded};
}

Future<String> _writeDeckArtifact({
  required String commanderName,
  required Map<String, dynamic> payload,
}) async {
  final slug = _slugify(commanderName);
  final path = '$_artifactDirPath/$slug.json';
  await File(path).writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
  return path;
}

int _totalCards(List<Map<String, dynamic>> cards) {
  return cards.fold<int>(0, (sum, card) => sum + ((card['quantity'] as int?) ?? 0));
}

int _landCount(Map<String, dynamic> analysis) {
  final types = (analysis['type_distribution'] as Map<String, dynamic>?) ?? {};
  return (types['lands'] as int?) ?? 0;
}

int _countInteraction(Map<String, dynamic> analysis) {
  final types = (analysis['type_distribution'] as Map<String, dynamic>?) ?? {};
  return ((types['instants'] as int?) ?? 0) +
      ((types['sorceries'] as int?) ?? 0);
}

double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0.0;
}

String? _normalizeArchetype(String? archetype) {
  final value = archetype?.trim().toLowerCase();
  if (value == null || value.isEmpty) return null;
  if (const {'aggro', 'control', 'midrange'}.contains(value)) return value;
  return switch (value) {
    'tempo' || 'spellslinger' => 'control',
    'stax' || 'combo' || 'aristocrats' || 'tribal' || 'voltron' => 'midrange',
    _ => null,
  };
}

String _slugify(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'deck' : normalized;
}

Map<String, String> _authHeaders(String token) => {
      'Authorization': 'Bearer $token',
    };

Map<String, String> _jsonHeaders(String token) => {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

String _extractMessage(Map<String, dynamic> body) {
  return body['error']?.toString() ??
      body['message']?.toString() ??
      body.toString();
}

String _buildMarkdownReport(Map<String, dynamic> summary) {
  final results =
      (summary['results'] as List).whereType<Map<String, dynamic>>().toList();

  final buffer = StringBuffer()
    ..writeln(
      '# Relatorio de Resolucao Real - ${summary['total']} Decks Commander',
    )
    ..writeln()
    ..writeln('- Gerado em: `${summary['generated_at']}`')
    ..writeln('- API: `${summary['api_base_url']}`')
    ..writeln('- Artefatos: `${summary['artifact_dir']}`')
    ..writeln('- Seleção: `${summary['selection_mode']}`')
    ..writeln('- Total: `${summary['total']}`')
    ..writeln('- Otimizacoes diretas: `${summary['direct_optimizations']}`')
    ..writeln('- Resolvidos via rebuild: `${summary['rebuild_resolutions']}`')
    ..writeln('- Sem troca segura: `${summary['safe_no_change']}`')
    ..writeln('- Nao resolvidos: `${summary['unresolved']}`')
    ..writeln('- Passaram: `${summary['passed']}`')
    ..writeln('- Falharam: `${summary['failed']}`')
    ..writeln()
    ..writeln('## Resultado por deck')
    ..writeln();

  for (final result in results) {
    buffer
      ..writeln('### ${result['commander_name']}')
      ..writeln()
      ..writeln('- Source deck: `${result['source_deck_id']}`')
      ..writeln('- Clone deck: `${result['clone_deck_id']}`')
      ..writeln('- Deck final: `${result['final_deck_id']}`')
      ..writeln('- Caminho: `${result['flow_path']}`')
      ..writeln('- Archetype usado: `${result['archetype']}`')
      ..writeln('- Optimize status: `${result['optimize_status']}`')
      ..writeln('- Rebuild status: `${result['rebuild_status'] ?? 'n/d'}`')
      ..writeln('- Deck final valido: `${result['final_deck_valid']}`')
      ..writeln('- Deck final healthy: `${result['final_deck_state']}`')
      ..writeln('- CMC medio final: `${result['final_average_cmc']}`')
      ..writeln('- Terrenos finais: `${result['final_land_count']}`')
      ..writeln('- Interacao final: `${result['final_interaction']}`')
      ..writeln('- Artifact: `${result['saved_artifact_path']}`')
      ..writeln(
        '- Status final: `${result['passed'] == true ? 'PASSOU' : 'FALHOU'}`',
      )
      ..writeln();

    final failedChecks =
        (result['failed_checks'] as List?)?.map((item) => '$item').toList() ??
            const <String>[];
    if (failedChecks.isNotEmpty) {
      buffer.writeln('Falhas:');
      for (final item in failedChecks) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    final warnings =
        (result['warnings'] as List?)?.map((item) => '$item').toList() ??
            const <String>[];
    if (warnings.isNotEmpty) {
      buffer.writeln('Avisos:');
      for (final item in warnings.take(12)) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }
  }

  return buffer.toString();
}
