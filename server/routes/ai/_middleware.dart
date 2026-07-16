import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/plan_middleware.dart';
import '../../lib/rate_limit_middleware.dart';

enum AiEndpointAccessPolicy { meteredAction, rateLimitedLocal, authOnly }

const meteredAiActionPaths = <String>{
  '/ai/generate',
  '/ai/optimize',
  '/ai/explain',
  '/ai/rebuild',
};

AiEndpointAccessPolicy aiEndpointAccessPolicyForPath(String path) {
  if (path == '/ai/commander-learning' ||
      path.startsWith('/ai/generate/jobs/') ||
      path.startsWith('/ai/optimize/jobs/')) {
    return AiEndpointAccessPolicy.authOnly;
  }
  if (meteredAiActionPaths.contains(path)) {
    return AiEndpointAccessPolicy.meteredAction;
  }
  return AiEndpointAccessPolicy.rateLimitedLocal;
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
  final rateLimitedLocalHandler = handler
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
      case AiEndpointAccessPolicy.rateLimitedLocal:
        return rateLimitedLocalHandler(context);
      case AiEndpointAccessPolicy.authOnly:
        return authOnlyHandler(context);
    }
  };
}
