import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';

/// Middleware de autenticação para rotas de IA
/// 
/// Reutiliza o middleware centralizado do AuthService
Handler middleware(Handler handler) {
  return handler.use(authMiddleware());
}
