import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/deck_write_verification_policy.dart';

/// Middleware de autenticação para rotas de decks
///
/// Reutiliza o middleware centralizado do AuthService e, por decisão do dono
/// em 2026-09-23, exige e-mail verificado para gravar conteúdo de deck, com a
/// mesma resposta do fichário e do import. Leitura e apagar o próprio deck
/// não mudam; a regra e as exceções estão em
/// `lib/deck_write_verification_policy.dart`.
Handler middleware(Handler handler) {
  return handler.use(verifiedEmailForDeckContentWrites()).use(authMiddleware());
}
