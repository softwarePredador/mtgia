import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/ai_generate_job.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();
  final job = await AiGenerateJobStore.get(pool, id);
  if (job == null || (job.userId != null && job.userId != userId)) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {
        'error': 'Job nao encontrado ou expirado.',
        'job_id': id,
      },
    );
  }

  return Response.json(body: job.toJson());
}
