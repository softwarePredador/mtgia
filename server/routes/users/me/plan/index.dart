import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/auth_middleware.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/plan_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = getUserId(context);
  final pool = context.read<Pool>();

  try {
    final snapshot = await PlanService(pool).getSnapshot(userId);
    return Response.json(
      body: {
        'plan': snapshot.toJson(),
        'beta': {
          'is_free': true,
          'billing_enabled': false,
          'purchase_available': false,
          'message':
              'A beta pública atual é gratuita e não oferece compra ou assinatura.',
        },
      },
    );
  } catch (e) {
    return internalServerError(
      'Falha ao carregar plano do usuário',
      details: e,
    );
  }
}
