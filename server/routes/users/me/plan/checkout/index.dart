import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/auth_middleware.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/billing/payment_provider.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = getUserId(context);
  final pool = context.read<Pool>();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  final planName = body['plan_name']?.toString().trim().toLowerCase() ?? 'pro';
  if (planName != 'pro') {
    return badRequest('Somente upgrade para Pro esta disponivel neste fluxo.');
  }

  try {
    final result = await ManaLoomPaymentProvider(pool: pool).createCheckout(
      BillingCheckoutRequest(userId: userId, planName: planName),
    );
    return Response.json(statusCode: result.statusCode, body: result.body);
  } catch (error) {
    return internalServerError(
      'Falha ao iniciar checkout do plano Pro',
      details: error,
    );
  }
}
