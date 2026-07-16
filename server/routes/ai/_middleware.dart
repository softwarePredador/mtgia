import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/plan_middleware.dart';
import '../../lib/rate_limit_middleware.dart';

enum AiEndpointAccessPolicy {
  meteredAction,
  rateLimitedAuxiliary,
  polling,
  authOnly,
}

const meteredAiActionPaths = <String>{
  '/ai/archetypes',
  '/ai/generate',
  '/ai/optimize',
  '/ai/explain',
  '/ai/rebuild',
};

const rateLimitedAuxiliaryAiPaths = <String>{
  '/ai/simulate',
  '/ai/simulate-matchup',
  '/ai/weakness-analysis',
  '/ai/commander-reference',
  '/ai/ml-status',
  '/ai/optimize/telemetry',
};

AiEndpointAccessPolicy aiEndpointAccessPolicyForPath(String path) {
  if (path.startsWith('/ai/generate/jobs/') ||
      path.startsWith('/ai/optimize/jobs/')) {
    return AiEndpointAccessPolicy.polling;
  }
  if (path == '/ai/commander-learning') {
    return AiEndpointAccessPolicy.authOnly;
  }
  if (meteredAiActionPaths.contains(path)) {
    return AiEndpointAccessPolicy.meteredAction;
  }
  if (rateLimitedAuxiliaryAiPaths.contains(path)) {
    return AiEndpointAccessPolicy.rateLimitedAuxiliary;
  }
  // New AI routes are metered by default. A route may bypass quota only when
  // it is explicitly classified above and covered by the policy tests.
  return AiEndpointAccessPolicy.meteredAction;
}

/// Middleware de autenticação e rate limiting para rotas de IA
///
/// Aplica:
/// 1. Autenticação (JWT token obrigatório)
/// 2. Rate limiting (10 requisições por minuto por usuário)
///
/// Rate limiting é mais restritivo nas rotas de IA porque:
/// - Chamadas à OpenAI são custosas ($$$)
/// - Tempo de resposta é longo (5-10s)
/// - Previne uso abusivo do sistema
Handler middleware(Handler handler) {
  final authOnlyHandler = handler.use(authMiddleware());
  final pollingHandler = handler
      .use(aiPollingRateLimit())
      .use(authMiddleware());
  final rateLimitedAuxiliaryHandler = handler
      .use(aiRateLimit())
      .use(authMiddleware());
  final costlyAiHandler = handler
      .use(aiRateLimit())
      .use(aiPlanLimitMiddleware())
      .use(authMiddleware());

  return (context) {
    final path = context.request.uri.path;
    switch (aiEndpointAccessPolicyForPath(path)) {
      case AiEndpointAccessPolicy.meteredAction:
        return costlyAiHandler(context);
      case AiEndpointAccessPolicy.rateLimitedAuxiliary:
        return rateLimitedAuxiliaryHandler(context);
      case AiEndpointAccessPolicy.polling:
        return pollingHandler(context);
      case AiEndpointAccessPolicy.authOnly:
        return authOnlyHandler(context);
    }
  };
}
