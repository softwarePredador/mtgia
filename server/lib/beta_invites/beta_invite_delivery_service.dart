/// Entrega do e-mail de convite da beta (BT-AUTH-006), pelo mesmo transporte
/// dos e-mails de conta (webhook ou Resend).
library;

import 'package:http/http.dart' as http;

import '../account_email_delivery_config.dart';
import '../account_email_delivery_transport.dart';
import 'beta_invite_policy.dart';

/// Endereço do app que abre o cadastro com o código preenchido.
const betaInviteAppUrlEnvironment = 'BETA_INVITE_APP_URL';
const betaInviteWebhookUrlEnvironment = 'BETA_INVITE_WEBHOOK_URL';
const betaInviteWebhookTokenEnvironment = 'BETA_INVITE_WEBHOOK_TOKEN';

/// Parâmetro do link que leva o código até a tela de cadastro.
const betaInviteLinkParameter = 'invite_code';

/// Código de exemplo da prévia e do ensaio da entrega; nunca é um convite.
const betaInviteSampleCode = 'XXXX-XXXX-XXXX-XXXX';

/// Destinatário do ensaio da entrega; o ensaio nunca sai da máquina.
const betaInviteRehearsalRecipient = 'ensaio-da-entrega@example.invalid';

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

  /// Ensaio da entrega: passa uma mensagem de exemplo pelo mesmo transporte e
  /// pelas mesmas validações de [deliver] (provedor, configuração do Resend ou
  /// do webhook, link e regras da produção), com um cliente HTTP que nunca
  /// abre conexão. Diz se `--aplicar` conseguiria entregar, sem enviar nada.
  Future<BetaInviteDeliveryReadiness> rehearse({DateTime? now}) async {
    final String provider;
    try {
      provider = accountEmailDeliveryProvider(_environment).name;
    } on StateError {
      return const BetaInviteDeliveryReadiness(
        ready: false,
        provider: 'invalido',
        errorCode: 'email_delivery_provider_invalid',
      );
    }
    final link = betaInviteActionUrl(_environment, betaInviteSampleCode);
    Uri? target;
    final transport = AccountEmailDeliveryTransport(
      environment: _environment,
      clientFactory: () => _RehearsalClient((request) => target = request.url),
      requestTimeout: _requestTimeout,
    );
    BetaInviteDeliveryReadiness notReady(String code) =>
        BetaInviteDeliveryReadiness(
          ready: false,
          provider: provider,
          link: link,
          errorCode: code,
        );
    try {
      final accepted = await transport.deliver(
        message: AccountEmailDeliveryMessage(
          template: AccountEmailTemplate.betaInvite,
          recipient: betaInviteRehearsalRecipient,
          actionUrl: link,
          expiresAt: (now ?? DateTime.now().toUtc()).add(
            betaInviteDefaultValidity,
          ),
          code: betaInviteSampleCode,
        ),
        webhookUrlEnvironment: betaInviteWebhookUrlEnvironment,
        webhookTokenEnvironment: betaInviteWebhookTokenEnvironment,
      );
      if (!accepted) return notReady('email_delivery_not_configured');
    } on AccountEmailDeliveryException catch (error) {
      return notReady(error.code);
    } on StateError {
      return notReady('email_delivery_config_invalid');
    }
    return BetaInviteDeliveryReadiness(
      ready: true,
      provider: provider,
      link: link,
      target: target?.host,
      senderDomain:
          provider == AccountEmailDeliveryProvider.resend.name
              ? ResendEmailConfiguration.fromEnvironment(
                _environment,
              ).verifiedDomain
              : null,
    );
  }
}

/// Resultado do ensaio da entrega: só fatos que não são segredo (provedor,
/// host do destino, domínio do remetente e o link com o código de exemplo).
class BetaInviteDeliveryReadiness {
  const BetaInviteDeliveryReadiness({
    required this.ready,
    required this.provider,
    this.link,
    this.target,
    this.senderDomain,
    this.errorCode,
  });

  /// `true` quando o transporte aceitou a mensagem de exemplo.
  final bool ready;

  /// `webhook`, `resend` ou `invalido`.
  final String provider;

  /// Link do convite com o código de exemplo.
  final String? link;

  /// Host para onde o e-mail iria (o webhook ou o Resend).
  final String? target;

  /// Domínio verificado do remetente, no Resend.
  final String? senderDomain;

  /// Código do motivo quando não está pronta.
  final String? errorCode;

  Map<String, Object?> toJson() => {
    'pronta': ready,
    'provedor': provider,
    if (target != null) 'destino': target,
    if (senderDomain != null) 'remetente_dominio': senderDomain,
    if (link != null) 'link': link,
    if (errorCode != null) 'erro': errorCode,
  };
}

/// Cliente HTTP do ensaio: registra o pedido e responde 202 sem abrir
/// conexão nenhuma.
class _RehearsalClient extends http.BaseClient {
  _RehearsalClient(this._onRequest);

  final void Function(http.BaseRequest request) _onRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _onRequest(request);
    await request.finalize().drain<void>();
    return http.StreamedResponse(const Stream<List<int>>.empty(), 202);
  }
}
