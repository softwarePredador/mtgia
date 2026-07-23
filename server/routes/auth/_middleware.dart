import 'package:dart_frog/dart_frog.dart';
import '../../lib/rate_limit_middleware.dart';

/// Middleware para as rotas de autenticação.
///
/// Aplica rate limiting restritivo somente às submissões de credenciais:
/// - 5 tentativas de login/registro por minuto por cliente em produção.
///
/// Leituras de sessão, como `GET /auth/me`, não são tentativas de credenciais e
/// não consomem nem sofrem o bucket de brute force.
Handler middleware(Handler handler) {
  return handler.use(authRateLimit());
}
