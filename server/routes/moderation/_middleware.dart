import 'package:dart_frog/dart_frog.dart';

import '../../lib/admin_access_support.dart';

Handler middleware(Handler handler) {
  return handler.use(operationalAdminMiddleware());
}
