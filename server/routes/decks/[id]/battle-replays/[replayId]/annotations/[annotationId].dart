import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/battle/battle_replay_annotation_service.dart';
import '../../../../../../lib/battle/battle_replay_read_service.dart';
import '../../../../../../lib/http_responses.dart';
import '../../../../../../lib/logger.dart';
import '../../../../../../lib/observability.dart';

Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String replayId,
  String annotationId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return methodNotAllowed();
  }
  if (!isBattleReplayUuid(deckId)) {
    return notFound('Deck nao encontrado.');
  }
  if (!isBattleReplayUuid(replayId) || !isBattleReplayUuid(annotationId)) {
    return notFound('Anotacao nao encontrada.');
  }

  final service = BattleReplayAnnotationService(context.read<Pool>());
  try {
    final deleted = await service.delete(
      userId: context.read<String>(),
      deckId: deckId,
      replayId: replayId,
      annotationId: annotationId,
    );
    if (!deleted) return notFound('Anotacao nao encontrada.');
    return Response(statusCode: HttpStatus.noContent);
  } catch (error, stackTrace) {
    Log.e('[battle-annotations] delete failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle annotation delete failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'battle_replay_annotations_delete',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao excluir anotacao do replay');
  }
}
