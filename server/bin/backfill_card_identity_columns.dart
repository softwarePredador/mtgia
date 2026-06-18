import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/card_identity_backfill_support.dart';
import '../lib/card_identity_support.dart';
import '../lib/database.dart';

const _collectionUrl = 'https://api.scryfall.com/cards/collection';
const _defaultDelayMs = 100;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
backfill_card_identity_columns.dart - Preenche cards.oracle_id/layout/card_faces_json via Scryfall Collection API.

Uso:
  dart run bin/backfill_card_identity_columns.dart
  dart run bin/backfill_card_identity_columns.dart --limit=150
  dart run bin/backfill_card_identity_columns.dart --apply --limit=150
  dart run bin/backfill_card_identity_columns.dart --apply

Opcoes:
  --apply              Persiste updates. Sem esta flag, roda dry-run.
  --limit=<N>          Limita candidatos para validacao controlada.
  --batch-size=<N>     Tamanho do batch Scryfall, max 75. Default 75.
  --delay-ms=<N>       Pausa entre batches. Default 100ms.
  --include-filled     Reprocessa cartas ja preenchidas. Default: apenas missing.

Nota:
  Antes da Scryfall API, o script reconhece linhas legadas de AtomicCards
  cujo image_url usa /cards/named e trata cards.scryfall_id como oracle_id.
''');
    return;
  }

  final apply = args.contains('--apply');
  final includeFilled = args.contains('--include-filled');
  final limit = _parseIntArg(args, '--limit=');
  final batchSize = normalizeScryfallCollectionBatchSize(
    _parseIntArg(args, '--batch-size=') ?? scryfallCollectionMaxBatchSize,
  );
  final delayMs =
      (_parseIntArg(args, '--delay-ms=') ?? _defaultDelayMs).clamp(0, 60000);

  final db = Database();
  await db.connect();

  try {
    final pool = db.connection;
    if (!await hasCardIdentityColumns(pool)) {
      throw StateError(
        'cards.oracle_id/layout/card_faces_json ausentes. Rode bin/migrate.dart antes.',
      );
    }

    final trustedLegacyOracle = await _backfillTrustedLegacyOracleIds(
      pool,
      apply: apply,
    );

    final candidates = await _loadCandidates(
      pool,
      limit: limit,
      includeFilled: includeFilled,
    );
    final candidateIds = candidates
        .map((candidate) => candidate.scryfallId)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    var requested = 0;
    var found = 0;
    var updated = 0;
    var failedBatches = 0;
    final notFound = <String>[];

    final client = http.Client();
    try {
      final chunks = chunkForScryfallCollection(
        candidateIds,
        batchSize: batchSize,
      );
      for (var index = 0; index < chunks.length; index++) {
        final chunk = chunks[index];
        requested += chunk.length;
        final identities = await _fetchCollectionIdentities(client, chunk);
        if (identities == null) {
          failedBatches++;
        } else {
          found += identities.length;
          notFound.addAll(chunk.where((id) => !identities.containsKey(id)));
          if (apply && identities.isNotEmpty) {
            updated += await _updateIdentities(pool, identities.values);
          }
        }

        stderr.writeln(
          'card_identity_backfill batch ${index + 1}/${chunks.length} '
          'requested=$requested found=$found updated=$updated apply=$apply',
        );

        if (index < chunks.length - 1 && delayMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
      }
    } finally {
      client.close();
    }

    final summary = {
      'apply': apply,
      'include_filled': includeFilled,
      'limit': limit,
      'batch_size': batchSize,
      'delay_ms': delayMs,
      'trusted_legacy_oracle_candidates': trustedLegacyOracle.candidates,
      'trusted_legacy_oracle_updated': trustedLegacyOracle.updated,
      'candidates': candidates.length,
      'requested': requested,
      'found': found,
      'updated': updated,
      'not_found': notFound.length,
      'failed_batches': failedBatches,
    };
    stdout.writeln('CARD_IDENTITY_BACKFILL ${jsonEncode(summary)}');

    if (failedBatches > 0) exitCode = 1;
  } finally {
    await db.close();
  }
}

int? _parseIntArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    final value = int.tryParse(arg.substring(prefix.length).trim());
    if (value != null) return value;
  }
  return null;
}

Future<List<_Candidate>> _loadCandidates(
  Pool pool, {
  required int? limit,
  required bool includeFilled,
}) async {
  final where = includeFilled
      ? 'scryfall_id IS NOT NULL'
      : '''
        scryfall_id IS NOT NULL
        AND oracle_id IS NULL
      ''';
  final sql = '''
    SELECT id::text, scryfall_id::text, name
    FROM cards
    WHERE $where
    ORDER BY name, id
    ${limit == null ? '' : 'LIMIT @limit'}
  ''';
  final result = await pool.execute(
    Sql.named(sql),
    parameters: {
      if (limit != null) 'limit': limit,
    },
  );
  return [
    for (final row in result)
      _Candidate(
        id: row[0] as String,
        scryfallId: row[1] as String,
        name: row[2]?.toString() ?? '',
      ),
  ];
}

Future<_TrustedLegacyOracleResult> _backfillTrustedLegacyOracleIds(
  Pool pool, {
  required bool apply,
}) async {
  final countResult = await pool.execute('''
    SELECT COUNT(*)
    FROM cards
    WHERE oracle_id IS NULL
      AND scryfall_id IS NOT NULL
      AND image_url LIKE 'https://api.scryfall.com/cards/named%'
  ''');
  final candidates = (countResult.single[0] as num).toInt();
  if (!apply || candidates == 0) {
    return _TrustedLegacyOracleResult(candidates: candidates, updated: 0);
  }

  final result = await pool.execute('''
    UPDATE cards
    SET oracle_id = scryfall_id
    WHERE oracle_id IS NULL
      AND scryfall_id IS NOT NULL
      AND image_url LIKE 'https://api.scryfall.com/cards/named%'
  ''');
  return _TrustedLegacyOracleResult(
    candidates: candidates,
    updated: result.affectedRows,
  );
}

Future<Map<String, CardIdentityBackfillPayload>?> _fetchCollectionIdentities(
  http.Client client,
  List<String> scryfallIds,
) async {
  final byPrintingId = await _fetchCollectionIdentitiesByKey(
    client,
    buildScryfallCollectionRequestBody(scryfallIds),
    parseScryfallCollectionIdentities,
  );
  if (byPrintingId == null) return null;

  final unresolved = scryfallIds
      .where((id) => !byPrintingId.containsKey(id))
      .toList(growable: false);
  if (unresolved.isEmpty) return byPrintingId;

  final byOracleId = await _fetchCollectionIdentitiesByKey(
    client,
    buildScryfallCollectionOracleRequestBody(unresolved),
    parseScryfallCollectionIdentitiesByOracleId,
  );
  if (byOracleId == null) return byPrintingId;

  final resolved = Map<String, CardIdentityBackfillPayload>.of(byPrintingId);
  for (final legacyOracleId in unresolved) {
    final payload = byOracleId[legacyOracleId];
    if (payload == null) continue;
    resolved[legacyOracleId] = CardIdentityBackfillPayload(
      scryfallId: legacyOracleId,
      oracleId: payload.oracleId,
      layout: payload.layout,
      cardFacesJson: payload.cardFacesJson,
    );
  }
  return resolved;
}

Future<Map<String, CardIdentityBackfillPayload>?>
    _fetchCollectionIdentitiesByKey(
  http.Client client,
  String body,
  Map<String, CardIdentityBackfillPayload> Function(Map<String, dynamic>)
      parser,
) async {
  for (var attempt = 1; attempt <= 3; attempt++) {
    final response = await client
        .post(
          Uri.parse(_collectionUrl),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': 'ManaLoomCardIdentityBackfill/1.0',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return parser(decoded);
      }
      return const {};
    }

    if (response.statusCode == 429 || response.statusCode >= 500) {
      await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      continue;
    }

    stderr.writeln(
      'Scryfall collection request failed status=${response.statusCode}',
    );
    return null;
  }
  stderr.writeln('Scryfall collection request exhausted retries.');
  return null;
}

Future<int> _updateIdentities(
  Pool pool,
  Iterable<CardIdentityBackfillPayload> identities,
) async {
  var updated = 0;
  await pool.runTx((session) async {
    for (final identity in identities) {
      final result = await session.execute(
        Sql.named('''
          UPDATE cards
          SET oracle_id = @oracle_id::uuid,
              layout = COALESCE(@layout, layout),
              card_faces_json = COALESCE(CAST(@card_faces_json AS jsonb), card_faces_json)
          WHERE scryfall_id = @scryfall_id::uuid
        '''),
        parameters: {
          'scryfall_id': identity.scryfallId,
          'oracle_id': identity.oracleId,
          'layout': identity.layout,
          'card_faces_json': identity.cardFacesJson,
        },
      );
      updated += result.affectedRows;
    }
  });
  return updated;
}

class _Candidate {
  final String id;
  final String scryfallId;
  final String name;

  const _Candidate({
    required this.id,
    required this.scryfallId,
    required this.name,
  });
}

class _TrustedLegacyOracleResult {
  final int candidates;
  final int updated;

  const _TrustedLegacyOracleResult({
    required this.candidates,
    required this.updated,
  });
}
