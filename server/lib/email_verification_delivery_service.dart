import 'account_email_delivery_transport.dart';
import 'email_verification_policy.dart';

class EmailVerificationDeliveryService {
  EmailVerificationDeliveryService({
    Map<String, String>? environment,
    AccountEmailHttpClientFactory? clientFactory,
    Duration requestTimeout = const Duration(seconds: 10),
  }) : _environment = environment ?? emailVerificationEnvironmentValues(),
       _clientFactory = clientFactory,
       _requestTimeout = requestTimeout;

  final Map<String, String> _environment;
  final AccountEmailHttpClientFactory? _clientFactory;
  final Duration _requestTimeout;

  Future<bool> deliver({
    required String email,
    required String token,
    required DateTime expiresAt,
  }) async {
    final appUrl =
        _environment['EMAIL_VERIFICATION_APP_URL']?.trim() ??
        'http://localhost:8088/app/#/verify-email';
    final separator = appUrl.contains('?') ? '&' : '?';
    final verificationUrl =
        '$appUrl${separator}token=${Uri.encodeQueryComponent(token)}';
    return AccountEmailDeliveryTransport(
      environment: _environment,
      clientFactory: _clientFactory,
      requestTimeout: _requestTimeout,
    ).deliver(
      message: AccountEmailDeliveryMessage(
        template: AccountEmailTemplate.emailVerification,
        recipient: email,
        actionUrl: verificationUrl,
        expiresAt: expiresAt,
      ),
      webhookUrlEnvironment: 'EMAIL_VERIFICATION_WEBHOOK_URL',
      webhookTokenEnvironment: 'EMAIL_VERIFICATION_WEBHOOK_TOKEN',
    );
  }
}
