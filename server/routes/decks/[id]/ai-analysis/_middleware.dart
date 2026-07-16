import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/auth_middleware.dart';
import '../../../../lib/plan_middleware.dart';
import '../../../../lib/rate_limit_middleware.dart';

Handler middleware(Handler handler) => handler
    .use(aiRateLimit())
    .use(aiPlanLimitMiddleware())
    .use(authMiddleware());
