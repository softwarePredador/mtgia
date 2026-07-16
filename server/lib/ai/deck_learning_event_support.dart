import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'commander_reference_profile_support.dart';

const loadUsageHotCardsSql = '''
  SELECT
    ccu.card_name_normalized,
    COALESCE(card_lookup.canonical_name, ccu.card_name_normalized)
      AS canonical_name,
    ccu.usage_count,
    ccu.last_used_at
  FROM commander_card_usage ccu
  LEFT JOIN LATERAL (
    SELECT c.name AS canonical_name
    FROM cards c
    WHERE LOWER(SPLIT_PART(c.name, ' // ', 1)) = ccu.card_name_normalized
    ORDER BY c.name ASC
    LIMIT 1
  ) card_lookup ON TRUE
  WHERE ccu.commander_name_normalized = @commander
    AND ccu.card_name_normalized <> @commander
  ORDER BY ccu.usage_count DESC, ccu.last_used_at DESC, ccu.card_name_normalized
  LIMIT @limit
''';

const usageHotCardsGenerationCandidateLimit = 50;

Future<void> upsertCommanderCardUsage({
  required Pool pool,
  required String commanderName,
  required List<Map<String, dynamic>> cards,
}) async {
  final normalizedCommander = normalizeCommanderReferenceName(commanderName);
  for (final card in learningUsageCardsForCommander(
    commanderName: commanderName,
    cards: cards,
  )) {
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

List<Map<String, dynamic>> learningUsageCardsForCommander({
  required String commanderName,
  required Iterable<Map<String, dynamic>> cards,
}) {
  final normalizedCommander = normalizeCommanderReferenceName(commanderName);
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final card in cards) {
    if (card['is_commander'] == true) continue;
    final cardName = card['name']?.toString().trim() ?? '';
    if (cardName.isEmpty) continue;
    final normalizedCard = normalizeCommanderReferenceName(cardName);
    if (normalizedCard.isEmpty || normalizedCard == normalizedCommander) {
      continue;
    }
    if (!seen.add(normalizedCard)) continue;
    result.add(card);
  }
  return result;
}

int learningCardQuantityTotal(Iterable<Object?> cards) {
  var total = 0;
  for (final card in cards) {
    if (card is! Map) continue;
    total += _quantityValue(card['quantity']);
  }
  return total;
}

Future<List<Map<String, dynamic>>> loadUsageHotCards({
  required Pool pool,
  required String commanderName,
  int limit = 30,
}) async {
  final normalized = normalizeCommanderReferenceName(commanderName);
  try {
    final result = await pool.execute(
      Sql.named(loadUsageHotCardsSql),
      parameters: {'commander': normalized, 'limit': limit},
    );
    return result
        .map(
          (row) => {
            'card_name_normalized': row[0]?.toString(),
            'canonical_name': row[1]?.toString(),
            'usage_count': int.tryParse(row[2]?.toString() ?? '') ?? 0,
            'last_used_at': row[3]?.toString(),
          },
        )
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
    'Prefer these cards only when legal, on-color, and structurally appropriate for the deck.',
  ];
  return lines.join('\n');
}

List<String> usageHotCardCanonicalNames(
  List<Map<String, dynamic>> hotCards, {
  int limit = usageHotCardsGenerationCandidateLimit,
}) {
  return hotCards
      .take(limit)
      .map(
        (card) =>
            card['canonical_name']?.toString().trim().isNotEmpty == true
                ? card['canonical_name']!.toString().trim()
                : (card['card_name_normalized']?.toString().trim() ?? ''),
      )
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

Future<void> logGeneratedDeckForLearning({
  required Pool pool,
  required Map<String, dynamic> responseBody,
  String source = 'ai_generated',
}) async {
  try {
    final generatedDeck = responseBody['generated_deck'];
    if (generatedDeck is! Map) return;

    final commander = generatedDeck['commander'];
    final commanderName =
        commander is Map
            ? commander['name']?.toString()
            : commander?.toString();
    final cards =
        (generatedDeck['cards'] as List?)
            ?.whereType<Map>()
            .map((c) => c.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    if (commanderName == null || commanderName.isEmpty) return;
    if (cards.isEmpty) return;

    final cardCount =
        cards.fold<int>(0, (sum, c) {
          return sum + _quantityValue(c['quantity']);
        }) +
        (commanderName.isNotEmpty ? 1 : 0);

    final eventData = <String, dynamic>{
      'generation_mode': source,
      'cards':
          cards
              .map(
                (c) => {
                  'name': c['name']?.toString() ?? '',
                  'quantity': c['quantity'],
                },
              )
              .take(200)
              .toList(),
    };

    await pool.execute(
      Sql.named('''
        INSERT INTO deck_learning_events (
          deck_id, commander_name, format, card_count, source, event_data
        ) VALUES (
          gen_random_uuid(), @commanderName, 'commander', @cardCount, @source, @eventData::jsonb
        )
      '''),
      parameters: {
        'commanderName': commanderName,
        'cardCount': cardCount,
        'source': source,
        'eventData': jsonEncode(eventData),
      },
    );
  } catch (_) {}
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

int _quantityValue(Object? value) {
  if (value is int) return value > 0 ? value : 1;
  if (value is num) {
    final rounded = value.round();
    return rounded > 0 ? rounded : 1;
  }
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : 1;
}
