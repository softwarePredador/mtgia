import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/battle/battle_job_contract.dart';
import '../../../../../lib/battle/battle_job_service.dart';
import '../../../../../lib/battle/battle_job_store.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/logger.dart';
import '../../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get &&
      context.request.method != HttpMethod.delete) {
    return methodNotAllowed();
  }
  if (!battleJobUuidPattern.hasMatch(id)) {
    return notFound('Battle job nao encontrado.');
  }

  final service = BattleJobService(
    BattleJobStore(context.read<Pool>()),
    quotaPolicy: BattleJobQuotaPolicy.fromEnvironment(Platform.environment),
  );
  try {
    if (context.request.method == HttpMethod.get) {
      final job = await service.get(context.read<String>(), id.toLowerCase());
      return Response.json(body: job.toJson());
    }

    final result = await service.cancel(
      context.read<String>(),
      id.toLowerCase(),
    );
    return Response.json(
      statusCode:
          result.job.status == BattleJobStatus.cancelPending
              ? HttpStatus.accepted
              : HttpStatus.ok,
      body: {'job': result.job.toJson(), 'accepted': result.accepted},
    );
  } on BattleJobNotFoundException {
    // Owner-scoped lookup deliberately uses the same response for unknown and
    // other-user UUIDs, preventing IDOR enumeration.
    return notFound('Battle job nao encontrado.');
  } on BattleJobNotCancellableException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'battle_job_not_cancellable',
        'message': 'Este Battle job ja terminou.',
        'job': error.job.toJson(),
      },
    );
  } catch (error, stackTrace) {
    Log.e('[battle-job] lifecycle failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle job lifecycle failed'),
      stackTrace: stackTrace,
      tags: {'route': 'ai_battle_job', 'error_type': '${error.runtimeType}'},
    );
    return internalServerError('Falha ao consultar Battle job.');
  }
}
