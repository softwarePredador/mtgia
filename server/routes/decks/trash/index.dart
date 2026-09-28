import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/decks/deck_trash_support.dart';
import '../../../lib/logger.dart';

/// GET /decks/trash
///
/// A lixeira do dono (DCK-P0-06; decisão D-30 do dono), do deck apagado
/// mais recente para o mais antigo: `id`, `name`, `format`, `revision`,
/// `card_count`, `deleted_at` e `purge_after` (a partir de quando a limpeza
/// por prazo pode apagá-lo de vez). Só o dono lê a própria lixeira.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();
  try {
    final decks = await listDeckTrash(pool, userId: userId);
    return Response.json(
      body: {'retention_days': deckTrashRetention.inDays, 'decks': decks},
    );
  } catch (error) {
    Log.e('[ERROR] list deck trash failed: ${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'ok': false,
        'error': 'Não foi possível ler a lixeira agora.',
        'error_code': 'deck_trash_failed',
      },
    );
  }
}
