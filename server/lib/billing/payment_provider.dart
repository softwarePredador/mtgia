import 'dart:io';

class BillingCheckoutRequest {
  const BillingCheckoutRequest({required this.planName});

  final String planName;
}

class BillingResult {
  const BillingResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

/// Billing is deliberately unavailable while ManaLoom is a free beta.
///
/// This provider has no environment escape hatch. Re-enabling purchases must
/// introduce a reviewed provider adapter, signed checkout sessions, idempotent
/// webhooks and end-to-end payment tests in code.
class ManaLoomPaymentProvider {
  const ManaLoomPaymentProvider();

  Future<BillingResult> createCheckout(BillingCheckoutRequest request) async {
    final planName = request.planName.trim().toLowerCase();
    if (planName != 'pro') {
      return const BillingResult(
        statusCode: HttpStatus.badRequest,
        body: {
          'checkout_status': 'invalid_plan',
          'message': 'Nenhum plano pago está disponível durante a beta.',
        },
      );
    }

    return const BillingResult(
      statusCode: HttpStatus.forbidden,
      body: {
        'checkout_status': 'beta_free_only',
        'beta_mode': true,
        'billing_enabled': false,
        'purchase_available': false,
        'message':
            'O ManaLoom está em beta gratuita. Nenhuma compra ou cobrança está disponível.',
      },
    );
  }

  BillingResult verifyWebhook() {
    return const BillingResult(
      statusCode: HttpStatus.gone,
      body: {
        'webhook_status': 'beta_free_only',
        'beta_mode': true,
        'billing_enabled': false,
        'message': 'Webhooks de cobrança estão desativados na beta gratuita.',
      },
    );
  }
}
