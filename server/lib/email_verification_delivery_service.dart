import 'dart:convert';
import 'dart:io';

import 'email_verification_policy.dart';

class EmailVerificationDeliveryService {
  EmailVerificationDeliveryService({Map<String, String>? environment})
    : _environment = environment ?? emailVerificationEnvironmentValues();

  final Map<String, String> _environment;

  Future<bool> deliver({
    required String email,
    required String token,
    required DateTime expiresAt,
  }) async {
    final production = isProductionEmailEnvironment(_environment);
    final rawWebhook = _environment['EMAIL_VERIFICATION_WEBHOOK_URL']?.trim();
    if (rawWebhook == null || rawWebhook.isEmpty) {
      if (production) {
        throw StateError('Entrega de verificação não configurada.');
      }
      return false;
    }
    final webhook = Uri.tryParse(rawWebhook);
    if (webhook == null ||
        !webhook.hasScheme ||
        (production && webhook.scheme.toLowerCase() != 'https')) {
      throw StateError('Destino de verificação inválido.');
    }
    final appUrl =
        _environment['EMAIL_VERIFICATION_APP_URL']?.trim() ??
        'http://localhost:8088/app/#/verify-email';
    final separator = appUrl.contains('?') ? '&' : '?';
    final verificationUrl =
        '$appUrl${separator}token=${Uri.encodeQueryComponent(token)}';

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(webhook);
      request.headers.contentType = ContentType.json;
      final bearer = _environment['EMAIL_VERIFICATION_WEBHOOK_TOKEN']?.trim();
      if (bearer != null && bearer.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      }
      final payload = utf8.encode(
        jsonEncode({
          'template': 'email_verification',
          'recipient': email,
          'verification_url': verificationUrl,
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
        throw StateError('Provedor de verificação recusou a entrega.');
      }
      return true;
    } finally {
      client.close(force: true);
    }
  }
}
