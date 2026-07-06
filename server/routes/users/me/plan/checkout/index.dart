import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/auth_middleware.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/plan_service.dart';

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

  final internalCheckoutEnabled =
      _envFlag('MANALOOM_INTERNAL_CHECKOUT_ENABLED') ||
          _envFlag('ALLOW_INTERNAL_PRO_ACTIVATION');

  if (internalCheckoutEnabled) {
    try {
      final snapshot = await PlanService(pool).activatePro(userId);
      return Response.json(
        body: {
          'checkout_status': 'activated',
          'message': 'Plano Pro ativado.',
          'plan': snapshot.toJson(),
        },
      );
    } catch (error) {
      return internalServerError(
        'Falha ao ativar o plano Pro',
        details: error,
      );
    }
  }

  final externalCheckoutUrl =
      Platform.environment['MANALOOM_PRO_CHECKOUT_URL']?.trim() ?? '';
  if (externalCheckoutUrl.isNotEmpty) {
    return Response.json(
      statusCode: HttpStatus.paymentRequired,
      body: {
        'checkout_status': 'external_payment_required',
        'message':
            'Finalize o pagamento no checkout externo para ativar o Pro.',
        'checkout_url': externalCheckoutUrl,
      },
    );
  }

  return Response.json(
    statusCode: HttpStatus.notImplemented,
    body: {
      'checkout_status': 'payment_provider_not_configured',
      'message':
          'Checkout real ainda nao esta configurado. Configure MANALOOM_PRO_CHECKOUT_URL ou habilite MANALOOM_INTERNAL_CHECKOUT_ENABLED em ambiente controlado.',
    },
  );
}

bool _envFlag(String name) {
  final value = Platform.environment[name]?.trim().toLowerCase();
  return value == '1' || value == 'true' || value == 'yes' || value == 'on';
}
