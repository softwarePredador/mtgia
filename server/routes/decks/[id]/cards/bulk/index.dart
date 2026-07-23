import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/deck_cards_bulk_support.dart';
import '../../../../../lib/deck_rules_service.dart';
import '../../../../../lib/deck_validation_state_support.dart';
import '../../../../../lib/decks/deck_applied_analysis_support.dart';
import '../../../../../lib/decks/deck_optimization_history_service.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'JSON inválido'},
    );
  }

  final items = (body['cards'] as List?)?.whereType<Map>().toList() ?? const [];
  final mutationContext =
      body['mutation_context'] is Map
          ? (body['mutation_context'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  if (items.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'cards é obrigatório e deve ter itens'},
    );
  }
  try {
    validateNoUnsupportedDeckSections(
      cards: items.map((item) => item.cast<String, dynamic>()),
    );
  } on DeckRulesException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }

  final parsed =
      items.map((m) => m.cast<String, dynamic>()).map((m) {
        final cardId = m['card_id']?.toString();
        final qtyRaw = m['quantity'];
        final qty = qtyRaw is int ? qtyRaw : int.tryParse('${qtyRaw ?? ''}');
        final isCommander = m['is_commander'] == true;
        return {
          'card_id': cardId,
          'quantity': qty,
          'is_commander': isCommander,
        };
      }).toList();

  if (parsed.any(
    (e) => e['card_id'] == null || (e['card_id'] as String).isEmpty,
  )) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Todos os itens precisam de card_id válido'},
    );
  }
  if (parsed.any((e) => e['quantity'] == null || (e['quantity'] as int) <= 0)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Todos os itens precisam de quantity > 0'},
    );
  }
  if (parsed.any((e) => e['is_commander'] == true)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': 'bulk não aceita is_commander=true (use o endpoint single)',
      },
    );
  }

  try {
    final result = await pool.runTx((session) async {
      final isOptimizationMutation =
          DeckOptimizationHistoryService.normalizeMutationContext(
            mutationContext,
          ).isNotEmpty;
      final deckResult = await session.execute(
        Sql.named('''
            SELECT format, validation_state, validation_reasons,
                   validation_updated_at, archetype, bracket
            FROM decks
            WHERE id = @deckId AND user_id = @userId
            LIMIT 1
            FOR UPDATE
          '''),
        parameters: {'deckId': deckId, 'userId': userId},
      );
      if (deckResult.isEmpty) {
        throw Exception('Deck not found or permission denied.');
      }

      final format = (deckResult.first[0] as String).toLowerCase();
      final beforeValidation = <String, dynamic>{
        'validation_state': deckResult.first[1]?.toString() ?? 'unknown',
        'validation_reasons': deckResult.first[2] ?? const <dynamic>[],
        'validation_updated_at': deckValidationTimestampToJson(
          deckResult.first[3],
        ),
      };
      final existingArchetype = deckResult.first[4]?.toString();
      final existingBracket = deckResult.first[5] as int?;

      // Carrega estado atual
      final existingResult = await session.execute(
        Sql.named(
          'SELECT card_id::text, quantity::int, is_commander, condition FROM deck_cards WHERE deck_id = @deckId',
        ),
        parameters: {'deckId': deckId},
      );

      final current = [
        for (final row in existingResult)
          {
            'card_id': row[0] as String,
            'quantity': row[1] as int,
            'is_commander': row[2] as bool? ?? false,
            'condition': row[3] as String? ?? 'NM',
          },
      ];

      if (isOptimizationMutation) {
        final expectedSignature =
            mutationContext['expected_deck_signature']?.toString().trim() ?? '';
        final currentSignature =
            DeckOptimizationHistoryService.buildDeckSignature(current);
        if (expectedSignature.isEmpty) {
          return {
            'error_code': 'optimization_signature_required',
            'error': 'Optimization apply requires expected_deck_signature.',
          };
        }
        if (expectedSignature != currentSignature) {
          return {
            'error_code': 'optimization_preview_stale',
            'error':
                'Deck changed after preview. Refresh the analysis and try again.',
          };
        }
      }

      final normalized = mergeBulkCardIncrementsPreservingCondition(
        currentCards: current,
        increments: parsed,
      );
      final normalizedAfterCards = normalized
          .map((card) => Map<String, dynamic>.from(card))
          .toList(growable: false);

      // Valida regras (inclui identidade/banlist/limites)
      await DeckRulesService(session).validateAndThrow(
        format: format,
        cards: normalized,
        strict: isOptimizationMutation,
      );

      // Substitui o deck (em lote) – ok para bulk pois é uma operação rara.
      await session.execute(
        Sql.named('DELETE FROM deck_cards WHERE deck_id = @deckId'),
        parameters: {'deckId': deckId},
      );

      if (normalized.isNotEmpty) {
        final values = <String>[];
        final params = <String, dynamic>{'deckId': deckId};

        for (var i = 0; i < normalized.length; i++) {
          final card = normalized[i];
          final pId = 'c$i';
          final pQty = 'q$i';
          final pCmd = 'cmd$i';
          final pCond = 'cond$i';
          values.add('(@deckId, @$pId, @$pQty, @$pCmd, @$pCond)');
          params[pId] = card['card_id'];
          params[pQty] = card['quantity'];
          params[pCmd] = card['is_commander'] ?? false;
          params[pCond] = card['condition'] ?? 'NM';
        }

        final sql =
            'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition) VALUES ${values.join(', ')}';
        await session.execute(Sql.named(sql), parameters: params);
      }

      final total = normalized.fold<int>(
        0,
        (sum, c) => sum + (c['quantity'] as int),
      );
      if (!isOptimizationMutation) return {'total_cards': total};

      final stateResult = await session.execute(
        Sql.named('''
          UPDATE decks
          SET validation_state = 'validated',
              validation_reasons = '[]'::jsonb,
              validation_updated_at = CURRENT_TIMESTAMP
          WHERE id = @deckId AND user_id = @userId
          RETURNING validation_state, validation_reasons,
                    validation_updated_at
        '''),
        parameters: {'deckId': deckId, 'userId': userId},
      );
      final persistedState = stateResult.first.toColumnMap();
      final afterValidation = <String, dynamic>{
        'validation_state': persistedState['validation_state'],
        'validation_reasons': persistedState['validation_reasons'],
        'validation_updated_at': deckValidationTimestampToJson(
          persistedState['validation_updated_at'],
        ),
      };
      final optimizationArchetype =
          mutationContext['archetype']?.toString().trim() ?? '';
      final optimizationBracket = int.tryParse(
        mutationContext['bracket']?.toString() ?? '',
      );
      if (optimizationArchetype.isNotEmpty ||
          (optimizationBracket != null &&
              optimizationBracket >= 1 &&
              optimizationBracket <= 5)) {
        await session.execute(
          Sql.named('''
            UPDATE decks
            SET archetype = COALESCE(NULLIF(@archetype, ''), archetype),
                bracket = COALESCE(
                  CAST(NULLIF(@bracket, '') AS int),
                  bracket
                )
            WHERE id = @deckId AND user_id = @userId
          '''),
          parameters: {
            'deckId': deckId,
            'userId': userId,
            'archetype': optimizationArchetype,
            'bracket':
                optimizationBracket != null &&
                        optimizationBracket >= 1 &&
                        optimizationBracket <= 5
                    ? optimizationBracket.toString()
                    : '',
          },
        );
      }
      final appliedPostAnalysis = await loadAppliedDeckPostAnalysis(
        session: session,
        persistedCards: normalizedAfterCards,
      );
      final event = await DeckOptimizationHistoryService(
        pool,
      ).recordAppliedOptimization(
        userId: userId,
        deckId: deckId,
        context: mutationContext,
        session: session,
        beforeCardsPayload: current,
        afterCardsPayload: normalizedAfterCards,
        beforeValidation: beforeValidation,
        afterValidation: afterValidation,
        beforeDeckMetadata: {
          'archetype': existingArchetype,
          'bracket': existingBracket,
        },
        afterDeckMetadata: {
          'archetype':
              optimizationArchetype.isEmpty
                  ? existingArchetype
                  : optimizationArchetype,
          'bracket':
              optimizationBracket != null &&
                      optimizationBracket >= 1 &&
                      optimizationBracket <= 5
                  ? optimizationBracket
                  : existingBracket,
        },
        authoritativeAfterAnalysis: appliedPostAnalysis,
      );
      return {
        'total_cards': total,
        if (event != null) 'optimization_event': event,
        'post_analysis': appliedPostAnalysis,
        'validation': {
          'ok': true,
          'format': format,
          'deck_id': deckId,
          'deck_state': 'validated',
          'requires_review': false,
          'review_reasons': const <String>[],
          'validation_updated_at': afterValidation['validation_updated_at'],
        },
      };
    });

    if (result['error_code'] != null) {
      return Response.json(statusCode: HttpStatus.conflict, body: result);
    }

    return Response.json(body: {'ok': true, ...result});
  } on DeckRulesException catch (e) {
    print('[ERROR] handler: $e');
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  } catch (e) {
    print('[ERROR] handler: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
