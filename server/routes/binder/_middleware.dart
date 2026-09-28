import 'package:dart_frog/dart_frog.dart';
import '../../lib/auth_middleware.dart';
import '../../lib/legal_acceptance_middleware.dart';
import '../../lib/verified_email_middleware.dart';

Handler middleware(Handler handler) {
  return handler
      .use(legalAcceptanceForWrites(appliesTo: isLegalGatedBinderRequest))
      .use(verifiedEmailForMutations())
      .use(authMiddleware());
}
