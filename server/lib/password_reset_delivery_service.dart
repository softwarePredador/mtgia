import 'account_email_delivery_config.dart';
import 'account_email_delivery_transport.dart';
import 'runtime_environment.dart';

const passwordResetWebhookUrlEnvironment = 'PASSWORD_RESET_WEBHOOK_URL';
const passwordResetWebhookTokenEnvironment = 'PASSWORD_RESET_WEBHOOK_TOKEN';
const passwordResetAppUrlEnvironment = 'PASSWORD_RESET_APP_URL';
const passwordResetTestResponseEnvironment =
    'MANALOOM_PASSWORD_RESET_TEST_RESPONSE';
const passwordResetTestResponseApproval =
    'I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY';

bool mayExposePasswordResetTokenForTesting(Map<String, String> environment) {
  final production =
      (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
      'production';
  return !production &&
      environment[passwordResetTestResponseEnvironment] ==
          passwordResetTestResponseApproval;
}

/// Delivers a reset link through the configured account-email provider.
///
/// ManaLoom never logs or persists the raw token. Production rejects an absent
/// or invalid delivery target; local development may omit delivery and use the
/// explicitly guarded test response instead.
class PasswordResetDeliveryService {
  PasswordResetDeliveryService({
    Map<String, String>? environment,
    AccountEmailHttpClientFactory? clientFactory,
    Duration requestTimeout = const Duration(seconds: 10),
  }) : _environment = environment ?? _loadEnvironment(),
       _clientFactory = clientFactory,
       _requestTimeout = requestTimeout;

  final Map<String, String> _environment;
  final AccountEmailHttpClientFactory? _clientFactory;
  final Duration _requestTimeout;

  static Map<String, String> _loadEnvironment() {
    final environment = loadRuntimeEnvironment();
    return {
      for (final key in const [
        'ENVIRONMENT',
        passwordResetWebhookUrlEnvironment,
        passwordResetWebhookTokenEnvironment,
        passwordResetAppUrlEnvironment,
        passwordResetTestResponseEnvironment,
        ...accountEmailDeliveryEnvironmentKeys,
      ])
        if (environment[key] case final String value) key: value,
    };
  }

  Future<bool> deliver({
    required String email,
    required String token,
    required DateTime expiresAt,
  }) async {
    final resetBase =
        _environment[passwordResetAppUrlEnvironment]?.trim() ??
        'http://localhost:8088/app/#/reset-password';
    final separator = resetBase.contains('?') ? '&' : '?';
    final resetUrl =
        '$resetBase${separator}token=${Uri.encodeQueryComponent(token)}';
    return AccountEmailDeliveryTransport(
      environment: _environment,
      clientFactory: _clientFactory,
      requestTimeout: _requestTimeout,
    ).deliver(
      message: AccountEmailDeliveryMessage(
        template: AccountEmailTemplate.passwordReset,
        recipient: email,
        actionUrl: resetUrl,
        expiresAt: expiresAt,
      ),
      webhookUrlEnvironment: passwordResetWebhookUrlEnvironment,
      webhookTokenEnvironment: passwordResetWebhookTokenEnvironment,
    );
  }
}
