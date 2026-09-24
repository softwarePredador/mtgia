import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/deck_visibility_policy.dart';
import '../../../../../lib/logger.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// POST /decks/:id/cards/remove
///
/// Remove uma carta do deck (todas as cópias da linha), sem reenviar a lista
/// inteira (decisão D-27 do dono: edição incremental sob `decks_private`;
/// `deck_replace_all` segue fechado).
///
/// Body: { "card_id": "<uuid>" }
///
/// - 404 `deck_not_found` quando o deck não existe ou é de outra pessoa;
/// - 404 `card_not_in_deck` quando a carta não está no deck;
/// - 200 com a quantidade removida, o total que sobrou e a visibilidade: um
///   deck público que fica vazio vira privado na mesma transação.
///
/// O estado de validação do deck volta a rascunho pelo gatilho de
/// `deck_cards`, como em qualquer mudança de cartas.
Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  final Object? decoded;
  try {
    decoded = await context.request.json();
  } catch (_) {
    return _badRequest('deck_remove_body_invalid', 'JSON inválido.');
  }
  if (decoded is! Map) {
    return _badRequest(
      'deck_remove_body_invalid',
      'O corpo precisa ser um objeto JSON.',
    );
  }
  final rawCardId = decoded['card_id'];
  if (rawCardId is! String || !_uuidPattern.hasMatch(rawCardId.trim())) {
    return _badRequest('deck_remove_card_id_invalid', 'card_id inválido.');
  }
  final cardId = rawCardId.trim().toLowerCase();

  try {
    final result = await pool.runTx((session) async {
      final deck = await session.execute(
        Sql.named('''
          SELECT is_public
          FROM decks
          WHERE id = @deckId AND user_id = @userId
          FOR UPDATE
        '''),
        parameters: {'deckId': deckId, 'userId': userId},
      );
      if (deck.isEmpty) {
        return const _RemoveOutcome.notFound(
          'deck_not_found',
          'Deck não encontrado.',
        );
      }
      final wasPublic = deck.first[0] as bool? ?? false;

      final removed = await session.execute(
        Sql.named('''
          DELETE FROM deck_cards
          WHERE deck_id = @deckId AND card_id = @cardId
          RETURNING quantity::int, is_commander
        '''),
        parameters: {'deckId': deckId, 'cardId': cardId},
      );
      if (removed.isEmpty) {
        return const _RemoveOutcome.notFound(
          'card_not_in_deck',
          'Esta carta não está no deck.',
        );
      }

      final remaining = await session.execute(
        Sql.named('''
          SELECT COALESCE(SUM(quantity), 0)::int
          FROM deck_cards
          WHERE deck_id = @deckId
        '''),
        parameters: {'deckId': deckId},
      );
      final totalCards = remaining.first[0] as int? ?? 0;
      final isPublic = deckVisibilityAfterCardChange(
        isPublic: wasPublic,
        cardCountAfter: totalCards,
      );
      if (isPublic != wasPublic) {
        await session.execute(
          Sql.named('UPDATE decks SET is_public = FALSE WHERE id = @deckId'),
          parameters: {'deckId': deckId},
        );
      }

      return _RemoveOutcome.removed({
        'ok': true,
        'deck_id': deckId,
        'card_id': cardId,
        'removed_quantity': removed.first[0] as int? ?? 0,
        'was_commander': removed.first[1] as bool? ?? false,
        'total_cards': totalCards,
        'is_public': isPublic,
        if (isPublic != wasPublic) 'unpublished_because_empty': true,
      });
    });

    if (result.body != null) {
      return Response.json(body: result.body);
    }
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': result.message, 'error_code': result.code},
    );
  } catch (error) {
    Log.e('[ERROR] remove deck card failed: ${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'error': 'Não foi possível remover a carta agora.',
        'error_code': 'deck_remove_failed',
      },
    );
  }
}

Response _badRequest(String code, String message) => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'error': message, 'error_code': code},
);

class _RemoveOutcome {
  const _RemoveOutcome.removed(Map<String, Object?> this.body)
    : code = null,
      message = null;

  const _RemoveOutcome.notFound(String this.code, String this.message)
    : body = null;

  final Map<String, Object?>? body;
  final String? code;
  final String? message;
}
