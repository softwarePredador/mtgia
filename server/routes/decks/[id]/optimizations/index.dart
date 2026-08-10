import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/decks/deck_optimization_history_service.dart';
import '../../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  try {
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT id
        FROM decks
        WHERE id = @deckId AND user_id = @userId
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    if (deckResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: const {'error': 'Deck not found or permission denied.'},
      );
    }

    final currentCardsResult = await pool.execute(
      Sql.named('''
        SELECT card_id::text, quantity::int, is_commander, condition
        FROM deck_cards
        WHERE deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );
    final currentSignature = DeckOptimizationHistoryService.buildDeckSignature([
      for (final row in currentCardsResult)
        {
          'card_id': row[0]?.toString() ?? '',
          'quantity': row[1] as int? ?? 0,
          'is_commander': row[2] as bool? ?? false,
          'condition': row[3]?.toString() ?? 'NM',
        },
    ]);

    final rollbackResult = await pool.execute(
      Sql.named('''
        SELECT report_payload ->> 'rollback_of_event_id'
        FROM deck_optimization_events
        WHERE deck_id = @deckId
          AND user_id = @userId
          AND event_type = 'optimize_rollback'
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    final rolledBackEventIds =
        rollbackResult
            .map((row) => row[0]?.toString().trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    final historyResult = await pool.execute(
      Sql.named('''
        SELECT id, deck_id, event_type, mode, intensity, archetype, bracket,
               selected_change_count, removals, additions, before_snapshot,
               after_snapshot, recommendation_context, validation_status,
               battle_status, battle_message, report_payload, created_at
        FROM deck_optimization_events
        WHERE deck_id = @deckId AND user_id = @userId
        ORDER BY created_at DESC, id DESC
        LIMIT 20
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );

    final events = <Map<String, dynamic>>[];
    for (final row in historyResult) {
      final eventId = row[0]?.toString() ?? '';
      final eventType = row[2]?.toString() ?? '';
      final beforeSnapshot = _asMap(row[10]);
      final afterSnapshot = _asMap(row[11]);
      final recommendationContext = _asMap(row[12]);
      final reportPayload = _asMap(row[16]);
      final afterCards = DeckOptimizationHistoryService.cardsFromSnapshot(
        afterSnapshot,
      );
      final hasSnapshots =
          beforeSnapshot['cards'] is List &&
          afterSnapshot['cards'] is List &&
          afterCards.isNotEmpty;
      final expectedSignature =
          DeckOptimizationHistoryService.buildDeckSignature(afterCards);
      final alreadyRolledBack = rolledBackEventIds.contains(eventId);
      final canRollback =
          eventType == 'optimize_apply' &&
          hasSnapshots &&
          !alreadyRolledBack &&
          currentSignature == expectedSignature;

      events.add({
        'id': eventId,
        'deck_id': row[1]?.toString() ?? '',
        'event_type': eventType,
        'mode': row[3]?.toString() ?? '',
        'intensity': row[4]?.toString() ?? '',
        'archetype': row[5]?.toString() ?? '',
        'bracket': row[6],
        'selected_change_count': row[7] as int? ?? 0,
        'removals': _publicChanges(row[8]),
        'additions': _publicChanges(row[9]),
        'source_summary': _sourceSummary(recommendationContext),
        'validation_status': row[13]?.toString() ?? '',
        'battle_status': row[14]?.toString() ?? '',
        'battle_message': row[15]?.toString() ?? '',
        'created_at': _dateString(row[17]),
        'can_rollback': canRollback,
        'rollback_reason':
            canRollback
                ? ''
                : _rollbackReason(
                  eventType: eventType,
                  hasSnapshots: hasSnapshots,
                  alreadyRolledBack: alreadyRolledBack,
                  signatureMatches: currentSignature == expectedSignature,
                ),
        'rollback_of_event_id':
            reportPayload['rollback_of_event_id']?.toString() ?? '',
      });
    }

    return Response.json(body: {'events': events, 'total': events.length});
  } catch (error) {
    print('[ERROR] optimization history failed: $error');
    return internalServerError('Failed to load optimization history');
  }
}

List<Map<String, dynamic>> _publicChanges(Object? raw) {
  final list = _asList(raw);
  return list
      .take(20)
      .map((entry) {
        final item = _asMap(entry);
        final playerFacing = _asMap(item['player_facing']);
        final confidence = _asMap(item['confidence']);
        return <String, dynamic>{
          'card_id': item['card_id']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'quantity': _positiveInt(item['quantity']),
          'reason':
              playerFacing['summary']?.toString() ??
              item['reason']?.toString() ??
              '',
          'role':
              playerFacing['primary_role_label']?.toString() ??
              item['role']?.toString() ??
              item['function']?.toString() ??
              '',
          'source_label':
              playerFacing['source_label']?.toString() ??
              item['source_label']?.toString() ??
              item['source']?.toString() ??
              '',
          'image_url': item['image_url']?.toString() ?? '',
          'set_code': item['set_code']?.toString() ?? '',
          'collector_number': item['collector_number']?.toString() ?? '',
          if (confidence.isNotEmpty)
            'confidence': {
              'level': confidence['level']?.toString() ?? '',
              'score': confidence['score'],
            },
        };
      })
      .toList(growable: false);
}

Map<String, dynamic> _sourceSummary(Map<String, dynamic> recommendation) {
  final meta = _asMap(recommendation['meta_reference_context']);
  final references = _asList(meta['references']);
  final warnings = _asMap(recommendation['warnings']);
  return {
    'post_analysis_source':
        recommendation['post_analysis_source']?.toString() ?? '',
    'priority_source': meta['priority_source']?.toString() ?? '',
    'selection_reason': meta['selection_reason']?.toString() ?? '',
    'reference_count': references.length,
    'has_meta_reference': meta.isNotEmpty,
    'has_warnings': warnings.isNotEmpty,
  };
}

String _rollbackReason({
  required String eventType,
  required bool hasSnapshots,
  required bool alreadyRolledBack,
  required bool signatureMatches,
}) {
  if (eventType != 'optimize_apply') return 'not_apply_event';
  if (alreadyRolledBack) return 'already_rolled_back';
  if (!hasSnapshots) return 'snapshot_unavailable';
  if (!signatureMatches) return 'deck_changed_after_apply';
  return 'unavailable';
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return value is List ? value : const <dynamic>[];
}

int _positiveInt(Object? value) {
  final parsed =
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : 1;
}

String? _dateString(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
