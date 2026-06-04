import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'commander_reference_profile_support.dart';

Future<void> ensureDeckLearningEventsTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS deck_learning_events (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      deck_id UUID NOT NULL,
      commander_name TEXT,
      format TEXT NOT NULL,
      card_count INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'user_created',
      event_data JSONB DEFAULT '{}'::jsonb,
      synced_to_hermes BOOLEAN NOT NULL DEFAULT FALSE,
      synced_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_deck_learning_events_synced
    ON deck_learning_events (synced_to_hermes, created_at)
  ''');
}

Future<void> ensureCommanderCardUsageTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_card_usage (
      commander_name_normalized TEXT NOT NULL,
      card_name_normalized TEXT NOT NULL,
      usage_count INTEGER NOT NULL DEFAULT 1,
      last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (commander_name_normalized, card_name_normalized)
    )
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_card_usage_commander
    ON commander_card_usage (commander_name_normalized, usage_count DESC)
  ''');
}

Future<void> upsertCommanderCardUsage({
  required Pool pool,
  required String commanderName,
  required List<Map<String, dynamic>> cards,
}) async {
  final normalizedCommander = normalizeCommanderReferenceName(commanderName);
  for (final card in cards) {
    final cardName = card['name']?.toString().trim() ?? '';
    if (cardName.isEmpty) continue;
    try {
      await pool.execute(
        Sql.named('''
          INSERT INTO commander_card_usage (
            commander_name_normalized, card_name_normalized, usage_count
          ) VALUES (
            @commander, @card, 1
          )
          ON CONFLICT (commander_name_normalized, card_name_normalized)
          DO UPDATE SET
            usage_count = commander_card_usage.usage_count + 1,
            last_used_at = NOW()
        '''),
        parameters: {
          'commander': normalizedCommander,
          'card': normalizeCommanderReferenceName(cardName),
        },
      );
    } catch (_) {}
  }
}

Future<List<Map<String, dynamic>>> loadUsageHotCards({
  required Pool pool,
  required String commanderName,
  int limit = 30,
}) async {
  final normalized = normalizeCommanderReferenceName(commanderName);
  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT ccu.card_name_normalized, c.name AS canonical_name,
               ccu.usage_count, ccu.last_used_at
        FROM commander_card_usage ccu
        LEFT JOIN cards c ON LOWER(SPLIT_PART(c.name, ' // ', 1)) = ccu.card_name_normalized
        WHERE ccu.commander_name_normalized = @commander
        ORDER BY ccu.usage_count DESC
        LIMIT @limit
      '''),
      parameters: {
        'commander': normalized,
        'limit': limit,
      },
    );
    return result
        .map((row) => {
              'card_name_normalized': row[0]?.toString(),
              'canonical_name': row[1]?.toString(),
              'usage_count': int.tryParse(row[2]?.toString() ?? '') ?? 0,
              'last_used_at': row[3]?.toString(),
            })
        .where((card) => (card['usage_count'] as int) > 0)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String buildUsageHotCardsPrompt(List<Map<String, dynamic>> hotCards) {
  if (hotCards.isEmpty) return '';
  final top = hotCards.take(12).toList();
  final lines = <String>[
    'Real-player usage data for this commander:',
    for (final card in top)
      '- ${card["canonical_name"] ?? card["card_name_normalized"]} (saved ${card["usage_count"]}x by users)',
    'Prefer these cards when building the deck - they have been validated by real players.',
  ];
  return lines.join('\n');
}

Future<void> logDeckLearningEvent({
  required Pool pool,
  required String deckId,
  String? commanderName,
  required String format,
  required int cardCount,
  String source = 'user_created',
  Map<String, dynamic> eventData = const {},
}) async {
  try {
    await pool.execute(
      Sql.named('''
        INSERT INTO deck_learning_events (
          deck_id, commander_name, format, card_count, source, event_data
        ) VALUES (
          @deckId::uuid, @commanderName, @format, @cardCount, @source, @eventData::jsonb
        )
      '''),
      parameters: {
        'deckId': deckId,
        'commanderName': commanderName,
        'format': format,
        'cardCount': cardCount,
        'source': source,
        'eventData': jsonEncode(eventData),
      },
    );
  } catch (_) {
    // Non-blocking: falha no log não quebra criação do deck
  }
}
