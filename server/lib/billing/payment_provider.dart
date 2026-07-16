import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../plan_service.dart';

class BillingCheckoutRequest {
  const BillingCheckoutRequest({required this.userId, required this.planName});

  final String userId;
  final String planName;
}

class BillingResult {
  const BillingResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

class ManaLoomPaymentProvider {
  ManaLoomPaymentProvider({
    required Pool pool,
    Map<String, String>? environment,
  }) : _planService = PlanService(pool),
       _environment = environment ?? Platform.environment;

  final PlanService _planService;
  final Map<String, String> _environment;

  Future<BillingResult> createCheckout(BillingCheckoutRequest request) async {
    final planName = request.planName.trim().toLowerCase();
    if (planName != 'pro') {
      return const BillingResult(
        statusCode: HttpStatus.badRequest,
        body: {
          'checkout_status': 'invalid_plan',
          'message': 'Somente upgrade para Pro esta disponivel neste fluxo.',
        },
      );
    }

    if (_envFlag('MANALOOM_INTERNAL_CHECKOUT_ENABLED') ||
        _envFlag('ALLOW_INTERNAL_PRO_ACTIVATION')) {
      final snapshot = await _planService.activatePro(request.userId);
      return BillingResult(
        statusCode: HttpStatus.ok,
        body: {
          'checkout_status': 'activated',
          'message': 'Plano Pro ativado.',
          'plan': snapshot.toJson(),
        },
      );
    }

    final externalCheckoutUrl = _env('MANALOOM_PRO_CHECKOUT_URL');
    final externalCheckoutUri = secureBillingCheckoutUri(externalCheckoutUrl);
    if (externalCheckoutUri != null) {
      return BillingResult(
        statusCode: HttpStatus.paymentRequired,
        body: {
          'checkout_status': 'external_payment_required',
          'message':
              'Finalize o pagamento no checkout externo para ativar o Pro.',
          'checkout_url': externalCheckoutUri.toString(),
        },
      );
    }

    if (externalCheckoutUrl.isNotEmpty) {
      return const BillingResult(
        statusCode: HttpStatus.internalServerError,
        body: {
          'checkout_status': 'invalid_payment_configuration',
          'message':
              'O checkout de pagamento está com uma configuração inválida.',
        },
      );
    }

    return const BillingResult(
      statusCode: HttpStatus.notImplemented,
      body: {
        'checkout_status': 'payment_provider_not_configured',
        'message':
            'Checkout real ainda nao esta configurado. Configure MANALOOM_PRO_CHECKOUT_URL ou habilite MANALOOM_INTERNAL_CHECKOUT_ENABLED em ambiente controlado.',
      },
    );
  }

  BillingResult verifyWebhook({
    required String rawBody,
    required Map<String, String> headers,
  }) {
    final provider = _env('MANALOOM_BILLING_PROVIDER').toLowerCase();
    final secret = _env('MANALOOM_BILLING_WEBHOOK_SECRET');

    if (provider.isEmpty || provider == 'none' || secret.isEmpty) {
      return const BillingResult(
        statusCode: HttpStatus.notImplemented,
        body: {
          'webhook_status': 'payment_provider_not_configured',
          'message':
              'Webhook de pagamento indisponivel ate MANALOOM_BILLING_PROVIDER e MANALOOM_BILLING_WEBHOOK_SECRET serem configurados.',
        },
      );
    }

    final signature =
        headers['x-manaloom-webhook-signature'] ?? headers['x-signature'] ?? '';
    if (!_verifyHmacSha256(rawBody, signature, secret)) {
      return const BillingResult(
        statusCode: HttpStatus.unauthorized,
        body: {
          'webhook_status': 'invalid_signature',
          'message': 'Assinatura do webhook invalida.',
        },
      );
    }

    return BillingResult(
      statusCode: HttpStatus.notImplemented,
      body: {
        'webhook_status': 'provider_adapter_not_implemented',
        'provider': provider,
        'message':
            'Webhook autenticado, mas o adaptador do provedor ainda precisa ser implementado antes de ativar planos automaticamente.',
      },
    );
  }

  String _env(String key) => _environment[key]?.trim() ?? '';

  bool _envFlag(String key) {
    final value = _env(key).toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }
}

Uri? secureBillingCheckoutUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

bool _verifyHmacSha256(String rawBody, String signature, String secret) {
  final normalized = signature.trim().replaceFirst(RegExp(r'^sha256='), '');
  if (normalized.isEmpty) return false;

  final digest =
      Hmac(
        sha256,
        utf8.encode(secret),
      ).convert(utf8.encode(rawBody)).toString();
  return _constantTimeEquals(normalized.toLowerCase(), digest.toLowerCase());
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
