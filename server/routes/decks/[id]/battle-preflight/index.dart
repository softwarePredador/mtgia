import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/battle_preflight_service.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }
  final opponentDeckId =
      context.request.uri.queryParameters['opponent_deck_id']?.trim() ?? '';
  final mode =
      context.request.uri.queryParameters['mode']?.trim().toLowerCase() ??
      battlePreflightModeSimulation;
  if (!_uuidPattern.hasMatch(deckId)) {
    return notFound('Deck nao encontrado.');
  }
  if (!_uuidPattern.hasMatch(opponentDeckId)) {
    return badRequest('opponent_deck_id must be a valid UUID');
  }
  if (deckId.toLowerCase() == opponentDeckId.toLowerCase()) {
    return badRequest('opponent_deck_id must differ from deck_id');
  }
  if (!battlePreflightModes.contains(mode)) {
    return badRequest('mode must be simulation or interactive');
  }

  try {
    final payload = await BattlePreflightService(context.read<Pool>()).inspect(
      userId: context.read<String>(),
      deckId: deckId,
      opponentDeckId: opponentDeckId,
      environment: Platform.environment,
      mode: mode,
    );
    return Response.json(body: payload);
  } on BattlePreflightNotFound catch (error) {
    return notFound(
      error.target == 'opponent'
          ? 'Deck adversario nao encontrado.'
          : 'Deck nao encontrado.',
    );
  } catch (error, stackTrace) {
    Log.e('[battle-preflight] failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle preflight failed'),
      stackTrace: stackTrace,
      tags: {'route': 'battle_preflight', 'error_type': '${error.runtimeType}'},
    );
    return internalServerError('Falha ao verificar Battle');
  }
}
