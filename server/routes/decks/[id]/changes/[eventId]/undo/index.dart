import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/deck_rules_service.dart';
import '../../../../../../lib/deck_visibility_policy.dart';
import '../../../../../../lib/decks/deck_revision_support.dart';
import '../../../../../../lib/logger.dart';

/// POST /decks/:id/changes/:eventId/undo
///
/// Desfazer universal (DCK-P0-01): devolve o deck ao estado de antes de uma
/// mudança do ledger, cartas e metadados, como mudança nova (revisão nova e
/// evento `undo`, que também pode ser desfeito). Só desfaz a mudança mais
/// nova: se o deck mudou depois dela, responde 409 `deck_undo_conflict` sem
/// escrever (o desfazer recusa HEAD novo). `If-Match` e `Idempotency-Key`
/// valem como nas outras mudanças do deck.
///
/// Desfazer nunca publica: publicar é sempre um pedido explícito, sob a regra
/// da galeria. Se a mudança desfeita tirou o deck da galeria, ele volta
/// privado (`visibility_kept_private`). O estado devolvido passa pela
/// validação não estrita das regras de hoje; se não passar (uma carta banida
/// depois, por exemplo), responde 409 `deck_undo_invalid` sem escrever.
Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String eventId,
) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  try {
    final request = DeckMutationRequest.fromContext(
      context,
      operation: 'undo',
      deckId: deckId,
      target: eventId,
    );
    final result = await pool.runTx((session) async {
      final baseline = await lockDeckForMutation(
        session,
        deckId: deckId,
        userId: userId,
        request: request,
      );
      if (baseline == null) {
        throw const _UndoRefusal(
          HttpStatus.notFound,
          'deck_not_found',
          'Deck não encontrado.',
        );
      }
      final event =
          isDeckUuid(eventId)
              ? await session.execute(
                Sql.named('''
                  SELECT revision_after, cards_before, cards_after,
                         metadata_before
                  FROM deck_change_events
                  WHERE id = CAST(@eventId AS uuid)
                    AND deck_id = CAST(@deckId AS uuid)
                '''),
                parameters: {'eventId': eventId, 'deckId': deckId},
              )
              : null;
      if (event == null || event.isEmpty) {
        throw const _UndoRefusal(
          HttpStatus.notFound,
          'deck_change_not_found',
          'Mudança não encontrada neste deck.',
        );
      }
      final row = event.first.toColumnMap();
      if ((row['revision_after'] as num).toInt() != baseline.revision) {
        throw _UndoRefusal(
          HttpStatus.conflict,
          'deck_undo_conflict',
          'O deck mudou depois desta mudança. Desfaça a mais recente primeiro.',
          currentRevision: baseline.revision,
        );
      }

      // Cartas: tira as que a mudança tocou e devolve o estado de antes.
      final cardsBefore =
          row['cards_before'] == null ? null : _jsonList(row['cards_before']);
      final touched = <String>{
        for (final card in cardsBefore ?? const <Map<String, dynamic>>[])
          '${card['card_id']}',
        for (final card in _jsonList(row['cards_after'])) '${card['card_id']}',
      };
      final restoredCards = <Map<String, dynamic>>[
        for (final card in baseline.cards)
          if (!touched.contains(card['card_id'])) {...card},
        for (final card in cardsBefore ?? const <Map<String, dynamic>>[])
          {...card},
      ];

      // Metadados: devolve os de antes, menos publicar.
      final metadataBefore = _jsonMap(row['metadata_before']);
      final restored = {...baseline.metadata};
      var visibilityKeptPrivate = false;
      for (final field in deckLedgerMetadataFields) {
        if (!metadataBefore.containsKey(field)) continue;
        if (field == 'is_public' && metadataBefore[field] == true) {
          visibilityKeptPrivate = baseline.metadata['is_public'] != true;
          continue;
        }
        restored[field] = metadataBefore[field];
      }
      final cardCount = restoredCards.fold<int>(
        0,
        (sum, card) => sum + ((card['quantity'] as num?)?.toInt() ?? 0),
      );
      restored['is_public'] = deckVisibilityAfterCardChange(
        isPublic: restored['is_public'] == true,
        cardCountAfter: cardCount,
      );

      await DeckRulesService(session).validateAndThrow(
        format: '${restored['format']}',
        cards: [
          for (final card in restoredCards)
            {
              'card_id': card['card_id'],
              'quantity': (card['quantity'] as num).toInt(),
              'is_commander': card['is_commander'] == true,
            },
        ],
      );

      if (touched.isNotEmpty) {
        await session.execute(
          Sql.named('''
            DELETE FROM deck_cards
            WHERE deck_id = CAST(@deckId AS uuid)
              AND card_id = ANY(CAST(@cardIds AS uuid[]))
          '''),
          parameters: {'deckId': deckId, 'cardIds': touched.toList()},
        );
        for (final card in cardsBefore ?? const <Map<String, dynamic>>[]) {
          await session.execute(
            Sql.named('''
              INSERT INTO deck_cards (
                deck_id, card_id, quantity, is_commander, condition
              ) VALUES (
                CAST(@deckId AS uuid), CAST(@cardId AS uuid), @quantity,
                @isCommander, @condition
              )
            '''),
            parameters: {
              'deckId': deckId,
              'cardId': '${card['card_id']}',
              'quantity': (card['quantity'] as num).toInt(),
              'isCommander': card['is_commander'] == true,
              'condition': card['condition']?.toString() ?? 'NM',
            },
          );
        }
      }
      await session.execute(
        Sql.named('''
          UPDATE decks
          SET name = @name,
              format = @format,
              description = @description,
              archetype = @archetype,
              bracket = @bracket,
              is_public = @isPublic
          WHERE id = CAST(@deckId AS uuid)
        '''),
        parameters: {
          'deckId': deckId,
          'name': restored['name'],
          'format': restored['format'],
          'description': restored['description'],
          'archetype': restored['archetype'],
          'bracket': (restored['bracket'] as num?)?.toInt(),
          'isPublic': restored['is_public'] == true,
        },
      );
      final receipt = await recordDeckMutation(
        session,
        baseline,
        undoOfEventId: eventId,
      );
      return (receipt: receipt, visibilityKeptPrivate: visibilityKeptPrivate);
    });

    return Response.json(
      body: {
        'ok': true,
        'deck_id': deckId,
        'undo_of_event_id': eventId,
        if (result.visibilityKeptPrivate) 'visibility_kept_private': true,
        ...result.receipt.toJson(),
      },
      headers: result.receipt.headers,
    );
  } on DeckMutationInterrupt catch (interrupt) {
    return interrupt.toResponse();
  } on _UndoRefusal catch (refusal) {
    return Response.json(
      statusCode: refusal.statusCode,
      body: {
        'ok': false,
        'error': refusal.message,
        'error_code': refusal.code,
        if (refusal.currentRevision != null)
          'current_revision': refusal.currentRevision,
      },
      headers: {
        if (refusal.currentRevision != null)
          'ETag': deckRevisionEtag(refusal.currentRevision!),
      },
    );
  } on DeckRulesException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'ok': false,
        'error':
            'O deck de antes desta mudança não passa nas regras de hoje: '
            '${error.message}',
        'error_code': 'deck_undo_invalid',
      },
    );
  } catch (error) {
    Log.e('[ERROR] undo deck change failed: ${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'ok': false,
        'error': 'Não foi possível desfazer agora.',
        'error_code': 'deck_undo_failed',
      },
    );
  }
}

List<Map<String, dynamic>> _jsonList(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) item.cast<String, dynamic>(),
  ];
}

Map<String, dynamic> _jsonMap(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}

class _UndoRefusal implements Exception {
  const _UndoRefusal(
    this.statusCode,
    this.code,
    this.message, {
    this.currentRevision,
  });

  final int statusCode;
  final String code;
  final String message;
  final int? currentRevision;
}
