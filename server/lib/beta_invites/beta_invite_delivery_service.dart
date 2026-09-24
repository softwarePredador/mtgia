/// Entrega do e-mail de convite da beta (BT-AUTH-006), pelo mesmo transporte
/// dos e-mails de conta (webhook ou Resend).
library;

import '../account_email_delivery_config.dart';
import '../account_email_delivery_transport.dart';

/// Endereço do app que abre o cadastro com o código preenchido.
const betaInviteAppUrlEnvironment = 'BETA_INVITE_APP_URL';
const betaInviteWebhookUrlEnvironment = 'BETA_INVITE_WEBHOOK_URL';
const betaInviteWebhookTokenEnvironment = 'BETA_INVITE_WEBHOOK_TOKEN';

/// Parâmetro do link que leva o código até a tela de cadastro.
const betaInviteLinkParameter = 'invite_code';

/// Variáveis de ambiente que a entrega do convite lê.
const betaInviteDeliveryEnvironmentKeys = <String>{
  'ENVIRONMENT',
  betaInviteAppUrlEnvironment,
  betaInviteWebhookUrlEnvironment,
  betaInviteWebhookTokenEnvironment,
  ...accountEmailDeliveryEnvironmentKeys,
};

/// Monta o link do convite.
String betaInviteActionUrl(Map<String, String> environment, String code) {
  final appUrl =
      environment[betaInviteAppUrlEnvironment]?.trim() ??
      'http://localhost:8088/app/#/register';
  final separator = appUrl.contains('?') ? '&' : '?';
  return '$appUrl$separator$betaInviteLinkParameter='
      '${Uri.encodeQueryComponent(code)}';
}

class BetaInviteDeliveryService {
  BetaInviteDeliveryService({
    required Map<String, String> environment,
    AccountEmailHttpClientFactory? clientFactory,
    Duration requestTimeout = const Duration(seconds: 10),
  }) : _environment = environment,
       _clientFactory = clientFactory,
       _requestTimeout = requestTimeout;

  final Map<String, String> _environment;
  final AccountEmailHttpClientFactory? _clientFactory;
  final Duration _requestTimeout;

  /// Envia o convite. `false` quando a entrega não está configurada fora da
  /// produção; na produção isso vira [AccountEmailDeliveryException].
  Future<bool> deliver({
    required String email,
    required String code,
    required DateTime expiresAt,
  }) {
    return AccountEmailDeliveryTransport(
      environment: _environment,
      clientFactory: _clientFactory,
      requestTimeout: _requestTimeout,
    ).deliver(
      message: AccountEmailDeliveryMessage(
        template: AccountEmailTemplate.betaInvite,
        recipient: email,
        actionUrl: betaInviteActionUrl(_environment, code),
        expiresAt: expiresAt,
        code: code,
      ),
      webhookUrlEnvironment: betaInviteWebhookUrlEnvironment,
      webhookTokenEnvironment: betaInviteWebhookTokenEnvironment,
    );
  }
}
