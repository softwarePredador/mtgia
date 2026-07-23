import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/verified_email_middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(verifiedEmailForMutations()).use(authMiddleware());
}
