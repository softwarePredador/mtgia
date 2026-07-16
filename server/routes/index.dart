import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  return Response.json(
    body: {
      'service': 'manaloom-api',
      'status': 'ok',
      'health': '/health',
      'readiness': '/ready',
    },
  );
}
