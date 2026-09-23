import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/verified_email_middleware.dart';

/// Middleware de autenticação para rotas de importação
///
/// Reutiliza o middleware centralizado do AuthService e, como o fichário,
/// exige e-mail verificado nas escritas (`/import` e `/import/*` são todas
/// POST), porque importar cria ou substitui deck (BT-AUTH-010).
Handler middleware(Handler handler) {
  return handler.use(verifiedEmailForMutations()).use(authMiddleware());
}
