import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/rate_limit_middleware.dart';

Handler middleware(Handler handler) => handler.use(aiRateLimit());
