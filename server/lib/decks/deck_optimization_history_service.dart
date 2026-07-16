import 'dart:convert';

import 'package:postgres/postgres.dart';

class DeckOptimizationHistoryService {
  DeckOptimizationHistoryService(this.pool);

  final Pool pool;

  Future<Map<String, dynamic>?> recordAppliedOptimization({
    required String userId,
    required String deckId,
    required Map<String, dynamic> context,
    List<Map<String, dynamic>> afterCardsPayload =
        const <Map<String, dynamic>>[],
  }) async {
    final normalized = normalizeMutationContext(
      context,
      afterCardsPayload: afterCardsPayload,
    );
    if (normalized.isEmpty) return null;

    final result = await pool.execute(
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
      '''),
      parameters: {
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
        'recommendationContext': jsonEncode(
          normalized['recommendation_context'],
        ),
        'validationStatus': normalized['validation_status'],
        'battleStatus': normalized['battle_status'],
        'battleMessage': normalized['battle_message'],
        'reportPayload': jsonEncode(normalized['report_payload']),
      },
    );

    return result.isEmpty ? null : _rowToJson(result.first);
  }

  static Map<String, dynamic> normalizeMutationContext(
    Map<String, dynamic> context, {
    List<Map<String, dynamic>> afterCardsPayload =
        const <Map<String, dynamic>>[],
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
    final afterSnapshot = _map(context['after_snapshot']);
    final computedAfter = _snapshotFromCards(afterCardsPayload);
    final mergedAfterSnapshot = {...computedAfter, ...afterSnapshot};
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
      'before_snapshot': _map(context['before_snapshot']),
      'after_snapshot': mergedAfterSnapshot,
      'recommendation_context': {
        'schema_version': _cleanString(context['schema_version']),
        'mode': _cleanString(context['mode']),
        'intensity': _cleanString(context['intensity']),
        'selection': selection,
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

  static Map<String, dynamic> _snapshotFromCards(
    List<Map<String, dynamic>> cards,
  ) {
    if (cards.isEmpty) return const <String, dynamic>{};
    var totalCards = 0;
    for (final card in cards) {
      totalCards += _int(card['quantity']) ?? 1;
    }
    return {'total_cards': totalCards, 'unique_cards': cards.length};
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
