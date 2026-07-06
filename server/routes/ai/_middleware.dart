import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/plan_middleware.dart';
import '../../lib/rate_limit_middleware.dart';

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
  final costlyAiHandler = handler
      .use(aiRateLimit())
      .use(aiPlanLimitMiddleware())
      .use(authMiddleware());

  return (context) {
    final path = context.request.uri.path;
    // Learned deck availability is a local PostgreSQL read used by the generate
    // screen. It must remain authenticated, but should not consume paid AI quota
    // or the cost-oriented AI rate-limit bucket.
    //
    // Async job polling is also a status read. The job routes still verify the
    // authenticated owner before returning data, but polling must not consume AI
    // quota or the rate-limit bucket that protects expensive generation calls.
    if (path == '/ai/commander-learning' ||
        path.startsWith('/ai/generate/jobs/') ||
        path.startsWith('/ai/optimize/jobs/')) {
      return authOnlyHandler(context);
    }
    return costlyAiHandler(context);
  };
}
