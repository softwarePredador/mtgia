import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/rate_limit_middleware.dart';

/// Autenticação para `/users`, com o bucket de credenciais por fora.
///
/// `DELETE /users/me` e `POST /users/me/export` conferem a senha a cada
/// requisição (D-20), então contam como tentativa de credencial, junto com
/// as de `/auth` (D-19). As demais rotas de `/users` não consomem o bucket.
Handler middleware(Handler handler) {
  return handler.use(authMiddleware()).use(authRateLimit());
}
