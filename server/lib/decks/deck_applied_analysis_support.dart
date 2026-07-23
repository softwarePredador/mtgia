import 'package:postgres/postgres.dart';

import '../ai/optimize_state_support.dart';

const appliedDeckPostAnalysisVersion =
    'applied_deck_post_analysis_v1_2026-07-22';

Map<String, dynamic> buildAppliedDeckPostAnalysis({
  required Iterable<Map<String, dynamic>> persistedCards,
  required Iterable<Map<String, dynamic>> catalogCards,
}) {
  final catalogById = <String, Map<String, dynamic>>{};
  for (final card in catalogCards) {
    final id = card['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) catalogById[id] = card;
  }

  final analysisCards = <Map<String, dynamic>>[];
  final deckColors = <String>{};
  final unresolvedIds = <String>[];
  for (final persisted in persistedCards) {
    final cardId = persisted['card_id']?.toString().trim() ?? '';
    final quantity = (persisted['quantity'] as num?)?.toInt() ?? 0;
    if (cardId.isEmpty || quantity <= 0) continue;
    final catalog = catalogById[cardId];
    if (catalog == null) {
      unresolvedIds.add(cardId);
      continue;
    }
    final colors =
        (catalog['colors'] as List?)
            ?.map((value) => value.toString())
            .toList(growable: false) ??
        const <String>[];
    final colorIdentity =
        (catalog['color_identity'] as List?)
            ?.map((value) => value.toString())
            .toList(growable: false) ??
        const <String>[];
    deckColors.addAll(colorIdentity.isNotEmpty ? colorIdentity : colors);
    analysisCards.add({
      'id': cardId,
      'name': catalog['name']?.toString() ?? '',
      'type_line': catalog['type_line']?.toString() ?? '',
      'oracle_text': catalog['oracle_text']?.toString() ?? '',
      'mana_cost': catalog['mana_cost']?.toString() ?? '',
      'cmc': _readDouble(catalog['cmc']),
      'colors': colors,
      'color_identity': colorIdentity,
      'quantity': quantity,
      'is_commander': persisted['is_commander'] == true,
    });
  }

  if (unresolvedIds.isNotEmpty) {
    throw StateError(
      'Applied deck analysis could not resolve ${unresolvedIds.length} card rows.',
    );
  }

  final analysis =
      DeckArchetypeAnalyzerCore(
        analysisCards,
        deckColors.toList()..sort(),
      ).generateAnalysis();
  return {
    'schema_version': appliedDeckPostAnalysisVersion,
    'source': 'postgres_persisted_card_catalog',
    'analysis_scope': 'accepted_changes_only',
    'server_recomputed': true,
    'resolved_unique_cards': analysisCards.length,
    ...analysis,
  };
}

double _readDouble(Object? value) => switch (value) {
  num() => value.toDouble(),
  String() => double.tryParse(value.trim()) ?? 0.0,
  _ => 0.0,
};

Future<Map<String, dynamic>> loadAppliedDeckPostAnalysis({
  required Session session,
  required Iterable<Map<String, dynamic>> persistedCards,
}) async {
  final cards = persistedCards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: false);
  final ids = cards
      .map((card) => card['card_id']?.toString().trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (ids.isEmpty) {
    return buildAppliedDeckPostAnalysis(
      persistedCards: cards,
      catalogCards: const <Map<String, dynamic>>[],
    );
  }

  final result = await session.execute(
    Sql.named('''
      SELECT id::text, name, type_line, oracle_text, mana_cost, cmc,
             colors, color_identity
      FROM cards
      WHERE id = ANY(@ids)
    '''),
    parameters: {'ids': ids},
  );
  final catalogCards = <Map<String, dynamic>>[
    for (final row in result)
      {
        'id': row[0]?.toString() ?? '',
        'name': row[1]?.toString() ?? '',
        'type_line': row[2]?.toString() ?? '',
        'oracle_text': row[3]?.toString() ?? '',
        'mana_cost': row[4]?.toString() ?? '',
        'cmc': row[5],
        'colors': row[6],
        'color_identity': row[7],
      },
  ];
  return buildAppliedDeckPostAnalysis(
    persistedCards: cards,
    catalogCards: catalogCards,
  );
}
