import 'dart:convert';
import 'dart:io';

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

/// Delivers a reset link through a deployment-owned HTTPS webhook.
///
/// ManaLoom never logs or persists the raw token. Production rejects an absent
/// or non-HTTPS delivery target; local development may omit delivery and use
/// the explicitly guarded test response instead.
class PasswordResetDeliveryService {
  PasswordResetDeliveryService({Map<String, String>? environment})
    : _environment = environment ?? _loadEnvironment();

  final Map<String, String> _environment;

  static Map<String, String> _loadEnvironment() {
    final environment = loadRuntimeEnvironment();
    return {
      for (final key in const [
        'ENVIRONMENT',
        passwordResetWebhookUrlEnvironment,
        passwordResetWebhookTokenEnvironment,
        passwordResetAppUrlEnvironment,
        passwordResetTestResponseEnvironment,
      ])
        if (environment[key] case final String value) key: value,
    };
  }

  Future<bool> deliver({
    required String email,
    required String token,
    required DateTime expiresAt,
  }) async {
    final production =
        (_environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
        'production';
    final rawWebhook = _environment[passwordResetWebhookUrlEnvironment]?.trim();
    if (rawWebhook == null || rawWebhook.isEmpty) {
      if (production) {
        throw StateError('Entrega de recuperação não configurada.');
      }
      return false;
    }
    final webhook = Uri.tryParse(rawWebhook);
    if (webhook == null ||
        !webhook.hasScheme ||
        (production && webhook.scheme.toLowerCase() != 'https')) {
      throw StateError('Destino de recuperação inválido.');
    }
    final resetBase =
        _environment[passwordResetAppUrlEnvironment]?.trim() ??
        'http://localhost:8088/app/#/reset-password';
    final separator = resetBase.contains('?') ? '&' : '?';
    final resetUrl =
        '$resetBase${separator}token=${Uri.encodeQueryComponent(token)}';

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(webhook);
      request.headers.contentType = ContentType.json;
      final bearer = _environment[passwordResetWebhookTokenEnvironment]?.trim();
      if (bearer != null && bearer.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      }
      final payload = utf8.encode(
        jsonEncode({
          'template': 'password_reset',
          'recipient': email,
          'reset_url': resetUrl,
          'expires_at': expiresAt.toUtc().toIso8601String(),
        }),
      );
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Provedor de recuperação recusou a entrega.');
      }
      return true;
    } finally {
      client.close(force: true);
    }
  }
}
