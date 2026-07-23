import 'dart:convert';

import 'package:postgres/postgres.dart';

class DeckOptimizationHistoryService {
  DeckOptimizationHistoryService(this.pool);

  final Pool pool;

  Future<Map<String, dynamic>?> recordAppliedOptimization({
    required String userId,
    required String deckId,
    required Map<String, dynamic> context,
    Session? session,
    List<Map<String, dynamic>> beforeCardsPayload =
        const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> afterCardsPayload =
        const <Map<String, dynamic>>[],
    Map<String, dynamic> beforeValidation = const <String, dynamic>{},
    Map<String, dynamic> afterValidation = const <String, dynamic>{},
    Map<String, dynamic> beforeDeckMetadata = const <String, dynamic>{},
    Map<String, dynamic> afterDeckMetadata = const <String, dynamic>{},
    required Map<String, dynamic> authoritativeAfterAnalysis,
  }) async {
    if (authoritativeAfterAnalysis.isEmpty) {
      throw ArgumentError.value(
        authoritativeAfterAnalysis,
        'authoritativeAfterAnalysis',
        'Applied optimization history requires server-recomputed analysis.',
      );
    }
    final normalized = normalizeMutationContext(
      context,
      beforeCardsPayload: beforeCardsPayload,
      afterCardsPayload: afterCardsPayload,
      beforeValidation: beforeValidation,
      afterValidation: afterValidation,
      beforeDeckMetadata: beforeDeckMetadata,
      afterDeckMetadata: afterDeckMetadata,
      authoritativeAfterAnalysis: authoritativeAfterAnalysis,
    );
    if (normalized.isEmpty) return null;

    final query = Sql.named('''
      INSERT INTO deck_optimization_events (
        user_id,
        deck_id,
        event_type,
        mode,
        intensity,
        archetype,
        bracket,
        selected_change_count,
        removals,
        additions,
        before_snapshot,
        after_snapshot,
        recommendation_context,
        validation_status,
        battle_status,
        battle_message,
        report_payload
      )
      VALUES (
        CAST(@userId AS uuid),
        CAST(@deckId AS uuid),
        @eventType,
        @mode,
        @intensity,
        @archetype,
        CAST(NULLIF(@bracket, '') AS int),
        @selectedChangeCount,
        @removals::jsonb,
        @additions::jsonb,
        @beforeSnapshot::jsonb,
        @afterSnapshot::jsonb,
        @recommendationContext::jsonb,
        @validationStatus,
        @battleStatus,
        @battleMessage,
        @reportPayload::jsonb
      )
      RETURNING id, deck_id, event_type, mode, intensity, archetype, bracket,
                selected_change_count, validation_status, battle_status,
                battle_message, created_at
    ''');
    final parameters = {
      'userId': userId,
      'deckId': deckId,
      'eventType': normalized['event_type'],
      'mode': normalized['mode'],
      'intensity': normalized['intensity'],
      'archetype': normalized['archetype'],
      'bracket': normalized['bracket']?.toString() ?? '',
      'selectedChangeCount': normalized['selected_change_count'],
      'removals': jsonEncode(normalized['removals']),
      'additions': jsonEncode(normalized['additions']),
      'beforeSnapshot': jsonEncode(normalized['before_snapshot']),
      'afterSnapshot': jsonEncode(normalized['after_snapshot']),
      'recommendationContext': jsonEncode(normalized['recommendation_context']),
      'validationStatus': normalized['validation_status'],
      'battleStatus': normalized['battle_status'],
      'battleMessage': normalized['battle_message'],
      'reportPayload': jsonEncode(normalized['report_payload']),
    };
    final result =
        session == null
            ? await pool.execute(query, parameters: parameters)
            : await session.execute(query, parameters: parameters);

    return result.isEmpty ? null : _rowToJson(result.first);
  }

  Future<Map<String, dynamic>> recordRollback({
    required Session session,
    required String userId,
    required String deckId,
    required String appliedEventId,
    required Map<String, dynamic> appliedEvent,
    required List<Map<String, dynamic>> beforeCardsPayload,
    required List<Map<String, dynamic>> afterCardsPayload,
    required Map<String, dynamic> afterValidation,
    Map<String, dynamic> beforeDeckMetadata = const <String, dynamic>{},
    Map<String, dynamic> afterDeckMetadata = const <String, dynamic>{},
  }) async {
    final result = await session.execute(
      Sql.named('''
        INSERT INTO deck_optimization_events (
          user_id,
          deck_id,
          event_type,
          mode,
          intensity,
          archetype,
          bracket,
          selected_change_count,
          removals,
          additions,
          before_snapshot,
          after_snapshot,
          recommendation_context,
          validation_status,
          battle_status,
          battle_message,
          report_payload
        )
        VALUES (
          CAST(@userId AS uuid),
          CAST(@deckId AS uuid),
          'optimize_rollback',
          @mode,
          @intensity,
          @archetype,
          CAST(NULLIF(@bracket, '') AS int),
          @selectedChangeCount,
          @removals::jsonb,
          @additions::jsonb,
          @beforeSnapshot::jsonb,
          @afterSnapshot::jsonb,
          @recommendationContext::jsonb,
          @validationStatus,
          @battleStatus,
          @battleMessage,
          @reportPayload::jsonb
        )
        RETURNING id, deck_id, event_type, mode, intensity, archetype, bracket,
                  selected_change_count, validation_status, battle_status,
                  battle_message, created_at
      '''),
      parameters: {
        'userId': userId,
        'deckId': deckId,
        'mode': _cleanString(appliedEvent['mode']),
        'intensity': _cleanString(appliedEvent['intensity']),
        'archetype': _cleanString(appliedEvent['archetype']),
        'bracket': appliedEvent['bracket']?.toString() ?? '',
        'selectedChangeCount': appliedEvent['selected_change_count'] ?? 0,
        'removals': jsonEncode(_limitedList(appliedEvent['additions'])),
        'additions': jsonEncode(_limitedList(appliedEvent['removals'])),
        'beforeSnapshot': jsonEncode(
          buildCardsSnapshot(beforeCardsPayload, metadata: beforeDeckMetadata),
        ),
        'afterSnapshot': jsonEncode(
          buildCardsSnapshot(
            afterCardsPayload,
            validation: afterValidation,
            metadata: afterDeckMetadata,
          ),
        ),
        'recommendationContext': jsonEncode({
          'schema_version': 'optimize_rollback_v1_2026-07-22',
          'rollback_of_event_id': appliedEventId,
        }),
        'validationStatus': _cleanString(afterValidation['validation_state']),
        'battleStatus': 'invalidated_by_rollback',
        'battleMessage':
            'O deck voltou ao snapshot anterior; rode battle ou replay novamente.',
        'reportPayload': jsonEncode({
          'rollback_of_event_id': appliedEventId,
          'rollback_guard': 'exact_after_snapshot_signature',
        }),
      },
    );

    return _rowToJson(result.first);
  }

  static Map<String, dynamic> normalizeMutationContext(
    Map<String, dynamic> context, {
    List<Map<String, dynamic>> beforeCardsPayload =
        const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> afterCardsPayload =
        const <Map<String, dynamic>>[],
    Map<String, dynamic> beforeValidation = const <String, dynamic>{},
    Map<String, dynamic> afterValidation = const <String, dynamic>{},
    Map<String, dynamic> beforeDeckMetadata = const <String, dynamic>{},
    Map<String, dynamic> afterDeckMetadata = const <String, dynamic>{},
    Map<String, dynamic> authoritativeAfterAnalysis = const <String, dynamic>{},
  }) {
    final source = _cleanString(context['source']);
    final type = _cleanString(context['type']);
    if (source != 'optimize_preview' && type != 'optimization_apply') {
      return const <String, dynamic>{};
    }

    final validation = _map(context['optimization_contract']);
    final deckbuilderValidation = _map(validation['deckbuilder_validation']);
    final battleValidation =
        _map(context['battle_validation']).isNotEmpty
            ? _map(context['battle_validation'])
            : _map(validation['battle_validation']);
    final beforeAnalysis = _map(context['before_snapshot']);
    final afterAnalysis =
        authoritativeAfterAnalysis.isNotEmpty
            ? authoritativeAfterAnalysis
            : _map(context['after_snapshot']);
    final beforeSnapshot = buildCardsSnapshot(
      beforeCardsPayload,
      validation: beforeValidation,
      analysis: beforeAnalysis,
      metadata: beforeDeckMetadata,
    );
    final afterSnapshot = buildCardsSnapshot(
      afterCardsPayload,
      validation: afterValidation,
      analysis: afterAnalysis,
      metadata: afterDeckMetadata,
    );
    final selection = _map(context['selection']);
    final selectedChangeCount =
        _int(context['selected_change_count']) ??
        _int(selection['selected_change_count']) ??
        (_list(context['removals']).length +
            _list(context['additions']).length);

    return {
      'event_type': 'optimize_apply',
      'mode': _cleanString(context['mode']),
      'intensity': _cleanString(context['intensity']),
      'archetype': _cleanString(context['archetype']),
      'bracket': _int(context['bracket']),
      'selected_change_count': selectedChangeCount,
      'removals': _limitedList(context['removals']),
      'additions': _limitedList(context['additions']),
      'before_snapshot': beforeSnapshot,
      'after_snapshot': afterSnapshot,
      'recommendation_context': {
        'schema_version': _cleanString(context['schema_version']),
        'mode': _cleanString(context['mode']),
        'intensity': _cleanString(context['intensity']),
        'selection': selection,
        'selection_scope': _cleanString(context['selection_scope']),
        'preview_change_count': _int(context['preview_change_count']),
        'post_analysis_source':
            authoritativeAfterAnalysis.isNotEmpty
                ? 'server_recomputed_from_persisted_selection'
                : 'legacy_client_preview',
        'warnings': _map(context['warnings']),
        'meta_reference_context': _map(context['meta_reference_context']),
      },
      'validation_status':
          _cleanString(deckbuilderValidation['status']).isEmpty
              ? 'preview_applied'
              : _cleanString(deckbuilderValidation['status']),
      'battle_status':
          _cleanString(battleValidation['status']).isEmpty
              ? 'pending_after_apply'
              : _cleanString(battleValidation['status']),
      'battle_message':
          _cleanString(battleValidation['message']).isEmpty
              ? 'Rode playtest, battle ou replay para validar desempenho real.'
              : _cleanString(battleValidation['message']),
      'report_payload': {
        'optimization_contract': validation,
        'battle_validation': battleValidation,
      },
    };
  }

  static Map<String, dynamic> _rowToJson(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id']?.toString() ?? '',
      'deck_id': map['deck_id']?.toString() ?? '',
      'event_type': map['event_type']?.toString() ?? '',
      'mode': map['mode']?.toString() ?? '',
      'intensity': map['intensity']?.toString() ?? '',
      'archetype': map['archetype']?.toString() ?? '',
      'bracket': map['bracket'],
      'selected_change_count': map['selected_change_count'] as int? ?? 0,
      'validation_status': map['validation_status']?.toString() ?? '',
      'battle_status': map['battle_status']?.toString() ?? '',
      'battle_message': map['battle_message']?.toString() ?? '',
      'created_at': _dateString(map['created_at']),
    };
  }

  static Map<String, dynamic> buildCardsSnapshot(
    List<Map<String, dynamic>> cards, {
    Map<String, dynamic> validation = const <String, dynamic>{},
    Map<String, dynamic> analysis = const <String, dynamic>{},
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalizedCards = normalizeCards(cards);
    var totalCards = 0;
    for (final card in normalizedCards) {
      totalCards += _int(card['quantity']) ?? 1;
    }
    return {
      'cards': normalizedCards,
      'signature': buildDeckSignature(normalizedCards),
      'total_cards': totalCards,
      'unique_cards': normalizedCards.length,
      if (validation.isNotEmpty) 'validation': validation,
      if (analysis.isNotEmpty) 'analysis': analysis,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  static List<Map<String, dynamic>> normalizeCards(
    Iterable<Map<String, dynamic>> cards,
  ) {
    final normalized = <Map<String, dynamic>>[];
    for (final card in cards) {
      final cardId = _cleanString(card['card_id']);
      final quantity = _int(card['quantity']);
      if (cardId.isEmpty || quantity == null || quantity <= 0) continue;
      final condition = _cleanString(card['condition']).toUpperCase();
      normalized.add({
        'card_id': cardId,
        'quantity': quantity,
        'is_commander': card['is_commander'] == true,
        'condition': condition.isEmpty ? 'NM' : condition,
      });
    }
    normalized.sort((a, b) {
      final idOrder = (a['card_id'] as String).compareTo(
        b['card_id'] as String,
      );
      if (idOrder != 0) return idOrder;
      return (a['is_commander'] == true ? 0 : 1).compareTo(
        b['is_commander'] == true ? 0 : 1,
      );
    });
    return List<Map<String, dynamic>>.unmodifiable(normalized);
  }

  static String buildDeckSignature(Iterable<Map<String, dynamic>> cards) {
    return normalizeCards(cards)
        .map(
          (card) =>
              '${card['card_id']}:${card['quantity']}:${card['condition']}',
        )
        .join('|');
  }

  static List<Map<String, dynamic>> cardsFromSnapshot(Object? value) {
    final cards = _map(value)['cards'];
    if (cards is! List) return const <Map<String, dynamic>>[];
    return normalizeCards(
      cards.whereType<Map>().map((card) => card.cast<String, dynamic>()),
    );
  }

  static Map<String, dynamic> validationFromSnapshot(Object? value) {
    return _map(_map(value)['validation']);
  }

  static Map<String, dynamic> metadataFromSnapshot(Object? value) {
    return _map(_map(value)['metadata']);
  }

  static List<dynamic> _limitedList(Object? value) {
    return _list(value).take(80).toList(growable: false);
  }

  static List<dynamic> _list(Object? value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _cleanString(Object? value) => value?.toString().trim() ?? '';

  static String? _dateString(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    final text = value?.toString();
    return text == null || text.trim().isEmpty ? null : text;
  }
}
