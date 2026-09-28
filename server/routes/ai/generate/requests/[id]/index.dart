import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/ai/ai_generate_materialize_support.dart';
import '../../../../../lib/ai/ai_generate_request_store.dart';
import '../../../../../lib/decks/deck_review_artifact.dart';
import '../../../../../lib/logger.dart';

/// GET /ai/generate/requests/:id (ou `latest`)
///
/// O pedido durável do Generate (DCK-P0-04): a entrada original (o prompt,
/// enquanto não passaram os 30 dias da D-29, e os controles), o estado, o
/// resultado e o deck materializado. É o que outro aparelho usa para
/// reidratar a entrada. Com resultado que pode virar deck, traz o
/// `review_artifact` que a materialização exige.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: const {'error': 'Method not allowed'},
    );
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();
  if (id != 'latest' && !_uuid.hasMatch(id)) return _notFound();
  try {
    final row = await AiGenerateRequestStore.read(pool, userId: userId, id: id);
    if (row == null) return _notFound();
    return Response.json(
      body: AiGenerateRequestStore.toJson(
        row,
        reviewArtifact: issueAiGenerateMaterializeArtifact(
          signingSecret: resolveDeckReviewSigningSecret(),
          userId: userId,
          row: row,
        ),
      ),
    );
  } catch (error) {
    Log.e('[ai-generate-request] read failed type=${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {'error': 'Não foi possível ler o pedido agora.'},
    );
  }
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: const {
    'error': 'Pedido de geração não encontrado.',
    'error_code': 'generate_request_not_found',
  },
);
