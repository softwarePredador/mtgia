import 'package:postgres/postgres.dart';

import '../e2e_validation_policy.dart';

// Bump whenever the player-facing optimize response contract changes. Cached
// payloads are returned as-is, so reusing an older schema can omit safety fields
// such as optimization_contract and battle_validation for up to six hours.
const optimizeCacheContractVersion = 'v9';

String buildOptimizeDeckSignature(List<ResultRow> cardsResult) {
  final entries = <String>[];
  for (final row in cardsResult) {
    final cardId = row[9].toString();
    final quantity = (row[2] as int?) ?? 1;
    final condition = row.length > 12 ? row[12]?.toString() : null;
    final normalizedCondition =
        (condition == null || condition.trim().isEmpty)
            ? 'NM'
            : condition.trim().toUpperCase();
    entries.add('$cardId:$quantity:$normalizedCondition');
  }
  entries.sort();
  return entries.join('|');
}

String buildOptimizeCacheKey({
  required String deckId,
  required String archetype,
  required String mode,
  required int? bracket,
  required bool keepTheme,
  required String deckSignature,
  String intensity = 'focused',
  String recommendationContextSignature = '',
}) {
  final parts = [
    'optimize',
    mode.toLowerCase().trim(),
    intensity.toLowerCase().trim(),
    deckId,
    archetype.toLowerCase().trim(),
    '${bracket ?? 'none'}',
    keepTheme ? 'keep' : 'free',
    deckSignature,
  ];
  final contextSignature = recommendationContextSignature.trim();
  if (contextSignature.isNotEmpty) {
    parts.add('rc:$contextSignature');
  }
  final base = parts.join('::');
  return '$optimizeCacheContractVersion:${stableOptimizeHash(base)}';
}

String stableOptimizeHash(String value) {
  var hash = 2166136261;
  for (final code in value.codeUnits) {
    hash ^= code;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

Future<Map<String, dynamic>?> loadOptimizeCache({
  required Pool pool,
  required String cacheKey,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT payload
      FROM ai_optimize_cache
      WHERE cache_key = @cache_key
        AND expires_at > NOW()
      ORDER BY created_at DESC
      LIMIT 1
    '''),
    parameters: {'cache_key': cacheKey},
  );

  if (result.isEmpty) return null;
  final payload = result.first[0];
  if (payload is Map<String, dynamic>) {
    return Map<String, dynamic>.from(payload);
  }
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

Future<void> saveOptimizeCache({
  required Pool pool,
  required String cacheKey,
  required String? userId,
  required String deckId,
  required String deckSignature,
  required Map<String, dynamic> payload,
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO ai_optimize_cache (
        cache_key,
        user_id,
        deck_id,
        deck_signature,
        payload,
        expires_at
      ) VALUES (
        @cache_key,
        CAST(@user_id AS uuid),
        CAST(@deck_id AS uuid),
        @deck_signature,
        @payload,
        NOW() + INTERVAL '6 hours'
      )
      ON CONFLICT (cache_key)
      DO UPDATE SET
        user_id = EXCLUDED.user_id,
        deck_id = EXCLUDED.deck_id,
        deck_signature = EXCLUDED.deck_signature,
        payload = EXCLUDED.payload,
        expires_at = EXCLUDED.expires_at,
        created_at = NOW()
    '''),
    parameters: {
      'cache_key': cacheKey,
      'user_id': userId,
      'deck_id': deckId,
      'deck_signature': deckSignature,
      'payload': payload,
    },
  );

  if (shouldRunGlobalHousekeeping()) {
    await pool.execute('''
      DELETE FROM ai_optimize_cache
      WHERE expires_at <= NOW()
    ''');
  }
}
