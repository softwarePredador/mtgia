import 'dart:convert';

import 'package:postgres/postgres.dart';

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
