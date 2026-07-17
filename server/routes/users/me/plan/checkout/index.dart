import 'package:dart_frog/dart_frog.dart';

import '../../../../../lib/auth_middleware.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/billing/payment_provider.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  getUserId(context);

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  final planName = body['plan_name']?.toString().trim().toLowerCase() ?? 'pro';
  if (planName != 'pro') {
    return badRequest('Nenhum plano pago está disponível durante a beta.');
  }

  try {
    final result = await const ManaLoomPaymentProvider().createCheckout(
      BillingCheckoutRequest(planName: planName),
    );
    return Response.json(statusCode: result.statusCode, body: result.body);
  } catch (error) {
    return internalServerError(
      'Falha ao processar solicitação de plano durante a beta',
      details: error,
    );
  }
}
