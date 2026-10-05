import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/ai/optimize_job.dart';
import '../../../../lib/ai/optimize_request_support.dart'
    show OptimizeDeckContextException, verifyOptimizeDeckAccess;
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

/// GET /ai/optimize/jobs/:id
///
/// Polling endpoint — o cliente chama a cada 2s para acompanhar o
/// progresso de um job assíncrono de otimização de deck.
///
/// Responses:
///   200 + status=processing → job ainda rodando (com stage/progress)
///   200 + status=completed  → job pronto (com result)
///   200 + status=failed     → job falhou (com error)
///   404                     → job_id inválido ou expirado
///
/// GET /ai/optimize/jobs/latest?deck_id=&active=
///
/// O job mais recente da conta, ou do deck dela. Não ter job é resposta
/// normal: 200 com `{"job": null}`. Só dá 404 (`deck_not_found`) o `deck_id`
/// que não é da conta, não existe ou nem é UUID. Antes, a falta de job também
/// era 404, e o navegador registrava um erro no console toda vez que a folha
/// de otimização abria.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get &&
      context.request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }
  if (id == 'latest' && context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    if (id == 'latest') {
      return await _latest(context, pool, userId);
    }
    final job =
        context.request.method == HttpMethod.delete
            ? await OptimizeJobStore.cancel(pool, id, userId: userId)
            : await OptimizeJobStore.get(pool, id);
    if (job == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Job não encontrado ou expirado.', 'job_id': id},
      );
    }

    if (job.userId.isEmpty || job.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Job não encontrado ou expirado.', 'job_id': id},
      );
    }

    if (context.request.method == HttpMethod.delete &&
        job.status != 'cancelled') {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'Este job ja terminou e nao pode mais ser cancelado.',
          'error_code': 'ai_job_not_cancellable',
          'job': job.toJson(),
        },
      );
    }

    return Response.json(body: job.toJson());
  } catch (error, stackTrace) {
    Log.e('[ai-optimize-job] polling failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_optimize_job'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Não foi possível consultar o job agora.'},
    );
  }
}

final _deckIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

Response _deckNotFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: const {'error': 'Deck não encontrado.', 'error_code': 'deck_not_found'},
);

Future<Response> _latest(
  RequestContext context,
  Pool pool,
  String userId,
) async {
  final query = context.request.uri.queryParameters;
  final rawDeckId = query['deck_id']?.trim();
  final deckId = rawDeckId == null || rawDeckId.isEmpty ? null : rawDeckId;
  if (deckId != null) {
    // A mesma conferência de dono do POST /ai/optimize.
    if (!_deckIdPattern.hasMatch(deckId)) return _deckNotFound();
    try {
      await verifyOptimizeDeckAccess(
        pool: pool,
        deckId: deckId,
        userId: userId,
      );
    } on OptimizeDeckContextException catch (error) {
      if (error.code == 'DECK_NOT_FOUND') return _deckNotFound();
      rethrow;
    }
  }
  final job = await OptimizeJobStore.latestForUser(
    pool,
    userId,
    deckId: deckId,
    activeOnly: query['active'] == 'true',
  );
  if (job == null) return Response.json(body: const {'job': null});
  if (job.userId.isEmpty || job.userId != userId) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Job não encontrado ou expirado.', 'job_id': 'latest'},
    );
  }
  return Response.json(body: job.toJson());
}
