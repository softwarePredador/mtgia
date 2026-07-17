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

      await DeckRulesService(
        session,
      ).validateAndThrow(format: format, cards: cards, strict: true);

      await session.execute(
        Sql.named(deckValidationMarkSuccessSql),
        parameters: {'deckId': deckId, 'userId': userId},
      );

      return buildDeckValidationSuccessBody(deckId: deckId, format: format);
    });

    if (isDeckValidationNotFoundBody(result)) {
      return Response.json(statusCode: HttpStatus.notFound, body: result);
    }
    return Response.json(body: result);
  } on DeckRulesException catch (e) {
    print('[ERROR] handler: $e');
    try {
      await pool.execute(
        Sql.named(deckValidationMarkFailureSql),
        parameters: {'deckId': deckId, 'userId': userId},
      );
    } catch (stateError) {
      print('[ERROR] Failed to persist deck validation failure: $stateError');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: buildDeckValidationHandlerErrorBody(stateError),
      );
    }
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: buildDeckValidationRuleErrorBody(e),
    );
  } catch (e) {
    print('[ERROR] handler: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: buildDeckValidationHandlerErrorBody(e),
    );
  }
}
