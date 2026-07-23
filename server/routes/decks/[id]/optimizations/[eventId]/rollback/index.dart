import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/deck_rules_service.dart';
import '../../../../../../lib/deck_validation_state_support.dart';
import '../../../../../../lib/decks/deck_optimization_history_service.dart';
import '../../../../../../lib/http_responses.dart';

Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String eventId,
) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  try {
    final result = await pool.runTx((session) async {
      final deckResult = await session.execute(
        Sql.named('''
          SELECT format
          FROM decks
          WHERE id = @deckId AND user_id = @userId
          FOR UPDATE
        '''),
        parameters: {'deckId': deckId, 'userId': userId},
      );
      if (deckResult.isEmpty) {
        throw const _RollbackRequestException(
          'deck_not_found',
          'Deck not found or permission denied.',
          HttpStatus.notFound,
        );
      }
      final format = deckResult.first[0]?.toString().toLowerCase() ?? '';

      final eventResult = await session.execute(
        Sql.named('''
          SELECT event_type, mode, intensity, archetype, bracket,
                 selected_change_count, removals, additions,
                 before_snapshot, after_snapshot
          FROM deck_optimization_events
          WHERE id = @eventId
            AND deck_id = @deckId
            AND user_id = @userId
          FOR UPDATE
        '''),
        parameters: {'eventId': eventId, 'deckId': deckId, 'userId': userId},
      );
      if (eventResult.isEmpty ||
          eventResult.first[0]?.toString() != 'optimize_apply') {
        throw const _RollbackRequestException(
          'optimization_event_not_found',
          'Optimization event not found or is not reversible.',
          HttpStatus.notFound,
        );
      }

      final alreadyRolledBack = await session.execute(
        Sql.named('''
          SELECT id
          FROM deck_optimization_events
          WHERE deck_id = @deckId
            AND user_id = @userId
            AND event_type = 'optimize_rollback'
            AND report_payload ->> 'rollback_of_event_id' = @eventId
          LIMIT 1
        '''),
        parameters: {'eventId': eventId, 'deckId': deckId, 'userId': userId},
      );
      if (alreadyRolledBack.isNotEmpty) {
        throw const _RollbackRequestException(
          'optimization_already_rolled_back',
          'This optimization was already rolled back.',
          HttpStatus.conflict,
        );
      }

      final eventRow = eventResult.first;
      final beforeSnapshot = _asMap(eventRow[8]);
      final afterSnapshot = _asMap(eventRow[9]);
      final restoreCards = DeckOptimizationHistoryService.cardsFromSnapshot(
        beforeSnapshot,
      );
      final expectedCurrentCards =
          DeckOptimizationHistoryService.cardsFromSnapshot(afterSnapshot);
      if (beforeSnapshot['cards'] is! List ||
          afterSnapshot['cards'] is! List ||
          expectedCurrentCards.isEmpty) {
        throw const _RollbackRequestException(
          'optimization_snapshot_unavailable',
          'This optimization predates reversible snapshots and cannot be rolled back.',
          HttpStatus.conflict,
        );
      }

      final currentResult = await session.execute(
        Sql.named('''
          SELECT card_id::text, quantity::int, is_commander, condition
          FROM deck_cards
          WHERE deck_id = @deckId
        '''),
        parameters: {'deckId': deckId},
      );
      final currentCards = <Map<String, dynamic>>[
        for (final row in currentResult)
          {
            'card_id': row[0] as String,
            'quantity': row[1] as int,
            'is_commander': row[2] as bool? ?? false,
            'condition': row[3]?.toString() ?? 'NM',
          },
      ];
      final currentSignature =
          DeckOptimizationHistoryService.buildDeckSignature(currentCards);
      final expectedSignature =
          DeckOptimizationHistoryService.buildDeckSignature(
            expectedCurrentCards,
          );
      if (currentSignature != expectedSignature) {
        throw const _RollbackRequestException(
          'optimization_rollback_conflict',
          'Deck changed after this optimization. Rollback was refused to preserve newer edits.',
          HttpStatus.conflict,
        );
      }

      await DeckRulesService(
        session,
      ).validateAndThrow(format: format, cards: restoreCards, strict: false);
      var strictValidationOk = true;
      String? strictValidationError;
      try {
        await DeckRulesService(
          session,
        ).validateAndThrow(format: format, cards: restoreCards, strict: true);
      } on DeckRulesException catch (error) {
        strictValidationOk = false;
        strictValidationError = error.message;
      }

      await session.execute(
        Sql.named('DELETE FROM deck_cards WHERE deck_id = @deckId'),
        parameters: {'deckId': deckId},
      );
      if (restoreCards.isNotEmpty) {
        await _insertCards(session, deckId: deckId, cards: restoreCards);
      }

      final storedValidation =
          DeckOptimizationHistoryService.validationFromSnapshot(beforeSnapshot);
      final restoreMetadata =
          DeckOptimizationHistoryService.metadataFromSnapshot(beforeSnapshot);
      final currentMetadata =
          DeckOptimizationHistoryService.metadataFromSnapshot(afterSnapshot);
      final restoredValidation = _normalizeRestoredValidation(
        storedValidation,
        strictValidationOk: strictValidationOk,
      );
      await session.execute(
        Sql.named('''
          UPDATE decks
          SET validation_state = @validationState,
              validation_reasons = @validationReasons::jsonb,
              validation_updated_at =
                CAST(NULLIF(@validationUpdatedAt, '') AS timestamptz)
          WHERE id = @deckId AND user_id = @userId
        '''),
        parameters: {
          'deckId': deckId,
          'userId': userId,
          'validationState': restoredValidation['validation_state'],
          'validationReasons': _jsonArray(
            restoredValidation['validation_reasons'],
          ),
          'validationUpdatedAt':
              restoredValidation['validation_updated_at']?.toString() ?? '',
        },
      );
      if (restoreMetadata.isNotEmpty) {
        await session.execute(
          Sql.named('''
            UPDATE decks
            SET archetype = @archetype,
                bracket = CAST(NULLIF(@bracket, '') AS int)
            WHERE id = @deckId AND user_id = @userId
          '''),
          parameters: {
            'deckId': deckId,
            'userId': userId,
            'archetype': restoreMetadata['archetype'],
            'bracket': restoreMetadata['bracket']?.toString() ?? '',
          },
        );
      }

      final appliedEvent = <String, dynamic>{
        'mode': eventRow[1],
        'intensity': eventRow[2],
        'archetype': eventRow[3],
        'bracket': eventRow[4],
        'selected_change_count': eventRow[5],
        'removals': eventRow[6],
        'additions': eventRow[7],
      };
      final rollbackEvent = await DeckOptimizationHistoryService(
        pool,
      ).recordRollback(
        session: session,
        userId: userId,
        deckId: deckId,
        appliedEventId: eventId,
        appliedEvent: appliedEvent,
        beforeCardsPayload: currentCards,
        afterCardsPayload: restoreCards,
        afterValidation: restoredValidation,
        beforeDeckMetadata: currentMetadata,
        afterDeckMetadata: restoreMetadata,
      );

      return {
        'ok': true,
        'deck_id': deckId,
        'rolled_back_event_id': eventId,
        'rollback_event': rollbackEvent,
        'validation': {
          'deck_state': restoredValidation['validation_state'],
          'review_reasons': restoredValidation['validation_reasons'],
          'validation_updated_at': restoredValidation['validation_updated_at'],
          'strict_validation_ok': strictValidationOk,
          if (strictValidationError != null)
            'strict_validation_error': strictValidationError,
        },
      };
    });

    return Response.json(body: result);
  } on _RollbackRequestException catch (error) {
    return Response.json(
      statusCode: error.statusCode,
      body: {'ok': false, 'error_code': error.code, 'error': error.message},
    );
  } on DeckRulesException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'ok': false,
        'error_code': 'optimization_snapshot_invalid',
        'error': error.message,
      },
    );
  } catch (error) {
    print('[ERROR] optimization rollback failed: $error');
    return internalServerError('Failed to roll back optimization');
  }
}

Future<void> _insertCards(
  Session session, {
  required String deckId,
  required List<Map<String, dynamic>> cards,
}) async {
  final values = <String>[];
  final parameters = <String, dynamic>{'deckId': deckId};
  for (var index = 0; index < cards.length; index++) {
    final card = cards[index];
    values.add(
      '(@deckId, @card$index, @quantity$index, @commander$index, @condition$index)',
    );
    parameters['card$index'] = card['card_id'];
    parameters['quantity$index'] = card['quantity'];
    parameters['commander$index'] = card['is_commander'] == true;
    parameters['condition$index'] = card['condition'] ?? 'NM';
  }
  await session.execute(
    Sql.named('''
      INSERT INTO deck_cards (
        deck_id, card_id, quantity, is_commander, condition
      ) VALUES ${values.join(', ')}
    '''),
    parameters: parameters,
  );
}

Map<String, dynamic> _normalizeRestoredValidation(
  Map<String, dynamic> stored, {
  required bool strictValidationOk,
}) {
  final state = stored['validation_state']?.toString();
  final reasons = stored['validation_reasons'];
  final timestamp = deckValidationTimestampToJson(
    stored['validation_updated_at'],
  );
  if (state == 'unknown') {
    return const {
      'validation_state': 'unknown',
      'validation_reasons': [deckValidationReasonNotRecorded],
      'validation_updated_at': null,
    };
  }
  if (state == 'draft') {
    final normalizedReasons = normalizeDeckValidationReasons(reasons);
    return {
      'validation_state': 'draft',
      'validation_reasons':
          normalizedReasons.isEmpty
              ? const [deckValidationReasonStrictFailed]
              : normalizedReasons,
      'validation_updated_at': timestamp ?? DateTime.now().toIso8601String(),
    };
  }
  if (state == 'validated' && strictValidationOk) {
    return {
      'validation_state': 'validated',
      'validation_reasons': const <String>[],
      'validation_updated_at': timestamp ?? DateTime.now().toIso8601String(),
    };
  }
  return {
    'validation_state': strictValidationOk ? 'validated' : 'draft',
    'validation_reasons':
        strictValidationOk
            ? const <String>[]
            : const [deckValidationReasonStrictFailed],
    'validation_updated_at': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

String _jsonArray(Object? value) {
  final values =
      value is List
          ? value.map((item) => item.toString()).toList(growable: false)
          : const <String>[];
  return jsonEncode(values);
}

class _RollbackRequestException implements Exception {
  const _RollbackRequestException(this.code, this.message, this.statusCode);

  final String code;
  final String message;
  final int statusCode;
}
