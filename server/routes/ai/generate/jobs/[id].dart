import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/ai_generate_job.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final job = await AiGenerateJobStore.get(pool, id);
    if (job == null || job.userId.isEmpty || job.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Job nao encontrado ou expirado.', 'job_id': id},
      );
    }

    return Response.json(body: job.toJson());
  } catch (error, stackTrace) {
    Log.e('[ai-generate-job] polling failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_generate_job'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Não foi possível consultar o job agora.'},
    );
  }
}
