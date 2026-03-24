import 'package:dart_frog/dart_frog.dart';

import '../health/ready/index.dart' as health_ready;

/// GET /ready - Readiness check explícito para deploys e smoke operacional.
///
/// Mantém a mesma semântica de `/health/ready`, mas em um path curto
/// pensado para integração com plataforma, runbook e probes externos.
Future<Response> onRequest(RequestContext context) {
  return health_ready.onRequest(context);
}
