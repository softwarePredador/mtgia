import 'package:dart_frog/dart_frog.dart';

import '../../lib/admin_access_support.dart';

Handler middleware(Handler handler) {
  final operationalHandler = handler.use(operationalAdminMiddleware());
  return (context) {
    if (isPublicHealthPath(context.request.uri.path)) {
      return handler(context);
    }
    return operationalHandler(context);
  };
}
