import 'package:server/beta_invites/beta_invite_cli.dart';
import 'package:server/beta_invites/beta_invite_delivery_service.dart';
import 'package:test/test.dart';

/// Ensaio da entrega do convite (BT-AUTH-006, BT-COH-001): passa pelo mesmo
/// transporte do envio real, sem abrir conexão, e diz se o `--aplicar` do
/// script do dono conseguiria entregar. O script para antes de gravar quando
/// a entrega não está pronta, porque o código do convite só existe no e-mail.
void main() {
  // Porta 9 (discard) em loopback: ninguém escuta. Se o ensaio abrisse
  // conexão, a entrega falharia com email_delivery_unavailable.
  const closedWebhook = 'http://127.0.0.1:9/convites';
  const resendKey = 're_test_only_never_real_123456789';

  Future<BetaInviteDeliveryReadiness> rehearse(Map<String, String> env) =>
      BetaInviteDeliveryService(environment: env).rehearse();

  group('ensaio da entrega', () {
    test('sem webhook fora da produção: não pronta, nada a enviar', () async {
      final readiness = await rehearse(const {'ENVIRONMENT': 'development'});

      expect(readiness.ready, isFalse);
      expect(readiness.provider, 'webhook');
      expect(readiness.errorCode, 'email_delivery_not_configured');
    });

    test('webhook configurado: pronta sem abrir conexão', () async {
      final readiness = await rehearse(const {
        'ENVIRONMENT': 'development',
        'BETA_INVITE_WEBHOOK_URL': closedWebhook,
        'BETA_INVITE_APP_URL': 'https://app.example.test/app/#/register',
      });

      expect(readiness.ready, isTrue, reason: '${readiness.errorCode}');
      expect(readiness.provider, 'webhook');
      expect(readiness.target, '127.0.0.1');
      expect(
        readiness.link,
        'https://app.example.test/app/#/register?invite_code='
        'XXXX-XXXX-XXXX-XXXX',
      );
      expect(readiness.toJson(), {
        'pronta': true,
        'provedor': 'webhook',
        'destino': '127.0.0.1',
        'link':
            'https://app.example.test/app/#/register?invite_code='
            'XXXX-XXXX-XXXX-XXXX',
      });
    });

    test('produção recusa webhook http, sem token e link localhost', () async {
      const production = {
        'ENVIRONMENT': 'production',
        'BETA_INVITE_WEBHOOK_URL': 'https://hooks.example.test/convites',
        'BETA_INVITE_WEBHOOK_TOKEN': 'webhook-test-token-not-production',
        'BETA_INVITE_APP_URL': 'https://app.example.test/app/#/register',
      };
      final ready = await rehearse(production);
      expect(ready.ready, isTrue, reason: '${ready.errorCode}');
      expect(ready.target, 'hooks.example.test');

      final httpWebhook = await rehearse({
        ...production,
        'BETA_INVITE_WEBHOOK_URL': 'http://hooks.example.test/convites',
      });
      expect(httpWebhook.errorCode, 'email_delivery_target_invalid');

      final noToken = await rehearse(
        {...production}..remove('BETA_INVITE_WEBHOOK_TOKEN'),
      );
      expect(noToken.errorCode, 'email_delivery_auth_invalid');

      final defaultLink = await rehearse(
        {...production}..remove('BETA_INVITE_APP_URL'),
      );
      expect(defaultLink.ready, isFalse);
      expect(defaultLink.errorCode, 'email_action_url_invalid');
      expect(defaultLink.link, startsWith('http://localhost:'));

      final noWebhook = await rehearse(
        {...production}..remove('BETA_INVITE_WEBHOOK_URL'),
      );
      expect(noWebhook.errorCode, 'email_delivery_not_configured');
    });

    test('Resend: configuração inválida não fica pronta; válida mostra o '
        'domínio do remetente', () async {
      const resend = {
        'ENVIRONMENT': 'production',
        'MANALOOM_EMAIL_DELIVERY_PROVIDER': 'resend',
        'RESEND_API_KEY': resendKey,
        'RESEND_FROM_EMAIL': 'convites@mail.example.test',
        'RESEND_VERIFIED_DOMAIN': 'mail.example.test',
        'BETA_INVITE_APP_URL': 'https://app.example.test/app/#/register',
      };
      final ready = await rehearse(resend);
      expect(ready.ready, isTrue, reason: '${ready.errorCode}');
      expect(ready.provider, 'resend');
      expect(ready.target, 'api.resend.com');
      expect(ready.senderDomain, 'mail.example.test');
      expect(ready.toJson().toString(), isNot(contains(resendKey)));

      final wrongDomain = await rehearse({
        ...resend,
        'RESEND_FROM_EMAIL': 'convites@outro.example.test',
      });
      expect(wrongDomain.ready, isFalse);
      expect(wrongDomain.provider, 'resend');
      expect(wrongDomain.errorCode, 'email_delivery_config_invalid');

      final badKey = await rehearse({...resend, 'RESEND_API_KEY': 'x'});
      expect(badKey.errorCode, 'email_delivery_config_invalid');
      expect(badKey.toJson().toString(), isNot(contains('RESEND_API_KEY=')));
    });

    test('provedor desconhecido: inválido, sem tentar entregar', () async {
      final readiness = await rehearse(const {
        'MANALOOM_EMAIL_DELIVERY_PROVIDER': 'smtp',
        'BETA_INVITE_WEBHOOK_URL': closedWebhook,
      });

      expect(readiness.ready, isFalse);
      expect(readiness.provider, 'invalido');
      expect(readiness.errorCode, 'email_delivery_provider_invalid');
    });
  });

  group('bloqueio do --aplicar pela entrega', () {
    const ready = BetaInviteDeliveryReadiness(
      ready: true,
      provider: 'webhook',
      target: '127.0.0.1',
    );
    const notReady = BetaInviteDeliveryReadiness(
      ready: false,
      provider: 'webhook',
      errorCode: 'email_delivery_not_configured',
    );

    test('entrega pronta no banco local: liberado', () {
      expect(
        betaInviteDeliveryBlockedReason(
          readiness: ready,
          environment: const {'ENVIRONMENT': 'development'},
        ),
        isNull,
      );
    });

    test('entrega que não está pronta bloqueia e diz o motivo', () {
      final reason = betaInviteDeliveryBlockedReason(
        readiness: notReady,
        environment: const {'ENVIRONMENT': 'development'},
      );

      expect(reason, contains('email_delivery_not_configured'));
      expect(reason, contains('nada foi gravado'));
    });

    test('banco da produção (wrapper) exige ENVIRONMENT=production', () {
      final development = betaInviteDeliveryBlockedReason(
        readiness: ready,
        environment: const {
          'MANALOOM_PG_WRAPPER_MODE': 'write-approved',
          'ENVIRONMENT': 'development',
        },
      );
      expect(development, contains('ENVIRONMENT=development'));

      final missing = betaInviteDeliveryBlockedReason(
        readiness: ready,
        environment: const {'MANALOOM_PG_WRAPPER_MODE': 'write-approved'},
      );
      expect(missing, contains('ENVIRONMENT=development'));

      expect(
        betaInviteDeliveryBlockedReason(
          readiness: ready,
          environment: const {
            'MANALOOM_PG_WRAPPER_MODE': 'write-approved',
            'ENVIRONMENT': 'production',
          },
        ),
        isNull,
      );
    });
  });
}
