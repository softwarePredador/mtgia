import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/deck_validation_route_support.dart';
import '../../../../lib/deck_rules_service.dart';
import '../../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  try {
    final result = await pool.runTx((session) async {
      final deckResult = await session.execute(
        Sql.named(deckValidationOwnerScopeSql),
        parameters: {'deckId': deckId, 'userId': userId},
      );
      if (deckResult.isEmpty) {
        return buildDeckValidationNotFoundBody();
      }

      final format = (deckResult.first[1] as String).toLowerCase();

      final cardsResult = await session.execute(
        Sql.named(deckValidationCardsSql),
        parameters: {'deckId': deckId},
      );

      final cards =
          cardsResult
              .map(
                (row) => {
                  'card_id': row[0] as String,
                  'quantity': row[1] as int,
                  'is_commander': row[2] as bool? ?? false,
                },
              )
              .toList();

      try {
        await DeckRulesService(
          session,
        ).validateAndThrow(format: format, cards: cards, strict: true);

        final stateResult = await session.execute(
          Sql.named(deckValidationMarkSuccessSql),
          parameters: {'deckId': deckId, 'userId': userId},
        );
        final state = stateResult.first.toColumnMap();

        return buildDeckValidationSuccessBody(
          deckId: deckId,
          format: format,
          validationUpdatedAt: state['validation_updated_at'],
        );
      } on DeckRulesException catch (error) {
        final stateResult = await session.execute(
          Sql.named(deckValidationMarkFailureSql),
          parameters: {'deckId': deckId, 'userId': userId},
        );
        final state = stateResult.first.toColumnMap();
        return buildDeckValidationRuleErrorBody(
          error,
          persistedReasons: state['validation_reasons'],
          validationUpdatedAt: state['validation_updated_at'],
        );
      }
    });

    if (isDeckValidationNotFoundBody(result)) {
      return Response.json(statusCode: HttpStatus.notFound, body: result);
    }
    if (result['ok'] == false) {
      return Response.json(statusCode: HttpStatus.badRequest, body: result);
    }
    return Response.json(body: result);
  } catch (e) {
    print('[ERROR] handler: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: buildDeckValidationHandlerErrorBody(e),
    );
  }
}
