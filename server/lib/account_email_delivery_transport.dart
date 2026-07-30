import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'account_email_delivery_config.dart';

const resendSendEmailEndpoint = 'https://api.resend.com/emails';

typedef AccountEmailHttpClientFactory = http.Client Function();

enum AccountEmailTemplate {
  passwordReset(
    wireName: 'password_reset',
    actionField: 'reset_url',
    subject: 'Redefina sua senha no ManaLoom',
    heading: 'Redefinição de senha',
    introduction:
        'Recebemos uma solicitação para redefinir a senha da sua conta.',
    actionLabel: 'Redefinir senha',
  ),
  emailVerification(
    wireName: 'email_verification',
    actionField: 'verification_url',
    subject: 'Verifique seu email no ManaLoom',
    heading: 'Verifique seu email',
    introduction:
        'Confirme este endereço para liberar os recursos da sua conta.',
    actionLabel: 'Verificar email',
  );

  const AccountEmailTemplate({
    required this.wireName,
    required this.actionField,
    required this.subject,
    required this.heading,
    required this.introduction,
    required this.actionLabel,
  });

  final String wireName;
  final String actionField;
  final String subject;
  final String heading;
  final String introduction;
  final String actionLabel;
}

class AccountEmailDeliveryMessage {
  const AccountEmailDeliveryMessage({
    required this.template,
    required this.recipient,
    required this.actionUrl,
    required this.expiresAt,
  });

  final AccountEmailTemplate template;
  final String recipient;
  final String actionUrl;
  final DateTime expiresAt;
}

class AccountEmailDeliveryException implements Exception {
  const AccountEmailDeliveryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AccountEmailDeliveryException($code): $message';
}

class AccountEmailDeliveryTransport {
  AccountEmailDeliveryTransport({
    required Map<String, String> environment,
    AccountEmailHttpClientFactory? clientFactory,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _environment = environment,
       _clientFactory = clientFactory ?? _defaultClientFactory,
       _resendEndpoint = Uri.parse(resendSendEmailEndpoint) {
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        'requestTimeout',
        'deve ser positivo',
      );
    }
  }

  final Map<String, String> _environment;
  final AccountEmailHttpClientFactory _clientFactory;
  final Duration requestTimeout;
  final Uri _resendEndpoint;

  Future<bool> deliver({
    required AccountEmailDeliveryMessage message,
    required String webhookUrlEnvironment,
    required String webhookTokenEnvironment,
  }) async {
    _validateMessage(message);
    final provider = accountEmailDeliveryProvider(_environment);
    return switch (provider) {
      AccountEmailDeliveryProvider.webhook => _deliverWebhook(
        message,
        webhookUrlEnvironment: webhookUrlEnvironment,
        webhookTokenEnvironment: webhookTokenEnvironment,
      ),
      AccountEmailDeliveryProvider.resend => _deliverResend(message),
    };
  }

  Future<bool> _deliverWebhook(
    AccountEmailDeliveryMessage message, {
    required String webhookUrlEnvironment,
    required String webhookTokenEnvironment,
  }) async {
    final production = _isProduction(_environment);
    final rawWebhook = _environment[webhookUrlEnvironment]?.trim();
    if (rawWebhook == null || rawWebhook.isEmpty) {
      if (production) {
        throw const AccountEmailDeliveryException(
          'email_delivery_not_configured',
          'Entrega de email não configurada.',
        );
      }
      return false;
    }
    final webhook = Uri.tryParse(rawWebhook);
    if (webhook == null ||
        !webhook.hasScheme ||
        webhook.host.isEmpty ||
        webhook.userInfo.isNotEmpty ||
        (production && webhook.scheme.toLowerCase() != 'https')) {
      throw const AccountEmailDeliveryException(
        'email_delivery_target_invalid',
        'Destino de entrega de email inválido.',
      );
    }
    final bearer = _environment[webhookTokenEnvironment];
    if (production &&
        (bearer == null || bearer != bearer.trim() || bearer.length < 16)) {
      throw const AccountEmailDeliveryException(
        'email_delivery_auth_invalid',
        'Autenticação da entrega de email inválida.',
      );
    }

    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      'Idempotency-Key': _idempotencyKey(message),
      if (bearer != null && bearer.trim().isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer ${bearer.trim()}',
    };
    final body = jsonEncode({
      'template': message.template.wireName,
      'recipient': message.recipient,
      message.template.actionField: message.actionUrl,
      'expires_at': message.expiresAt.toUtc().toIso8601String(),
    });
    await _send(
      uri: webhook,
      headers: headers,
      body: body,
      rejectedCode: 'email_webhook_rejected',
    );
    return true;
  }

  Future<bool> _deliverResend(AccountEmailDeliveryMessage message) async {
    final configuration = ResendEmailConfiguration.fromEnvironment(
      _environment,
    );
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      HttpHeaders.authorizationHeader: 'Bearer ${configuration.apiKey}',
      'Idempotency-Key': _idempotencyKey(message),
    };
    final body = jsonEncode({
      'from': configuration.formattedFrom,
      'to': [message.recipient],
      'subject': message.template.subject,
      'html': _htmlBody(message),
      'text': _textBody(message),
    });
    await _send(
      uri: _resendEndpoint,
      headers: headers,
      body: body,
      rejectedCode: 'resend_email_rejected',
    );
    return true;
  }

  Future<void> _send({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required String rejectedCode,
  }) async {
    final client = _clientFactory();
    try {
      final statusCode = await (() async {
        final request =
            http.Request('POST', uri)
              ..headers.addAll(headers)
              ..encoding = utf8
              ..body = body;
        final response = await client.send(request);
        await response.stream.drain<void>();
        return response.statusCode;
      })().timeout(requestTimeout);
      if (statusCode < 200 || statusCode >= 300) {
        throw AccountEmailDeliveryException(
          rejectedCode,
          'O provedor de email recusou a entrega.',
        );
      }
    } on TimeoutException {
      throw const AccountEmailDeliveryException(
        'email_delivery_timeout',
        'O provedor de email excedeu o tempo limite.',
      );
    } on AccountEmailDeliveryException {
      rethrow;
    } catch (_) {
      throw const AccountEmailDeliveryException(
        'email_delivery_unavailable',
        'O provedor de email está indisponível.',
      );
    } finally {
      client.close();
    }
  }

  static http.Client _defaultClientFactory() {
    final ioClient =
        HttpClient()..connectionTimeout = const Duration(seconds: 8);
    return IOClient(ioClient);
  }

  void _validateMessage(AccountEmailDeliveryMessage message) {
    final recipient = message.recipient.trim();
    if (recipient.isEmpty ||
        !recipient.contains('@') ||
        recipient.contains('\r') ||
        recipient.contains('\n')) {
      throw const AccountEmailDeliveryException(
        'email_recipient_invalid',
        'Destinatário de email inválido.',
      );
    }
    if (!_isProduction(_environment)) return;

    final actionUri = Uri.tryParse(message.actionUrl);
    if (actionUri == null ||
        actionUri.scheme.toLowerCase() != 'https' ||
        actionUri.host.isEmpty ||
        actionUri.userInfo.isNotEmpty) {
      throw const AccountEmailDeliveryException(
        'email_action_url_invalid',
        'Link de ação de email inválido.',
      );
    }
  }
}

String _idempotencyKey(AccountEmailDeliveryMessage message) {
  final digest = sha256.convert(
    utf8.encode(
      [
        message.template.wireName,
        message.recipient.trim().toLowerCase(),
        message.actionUrl,
        message.expiresAt.toUtc().toIso8601String(),
      ].join('\n'),
    ),
  );
  return 'manaloom/${message.template.wireName}/$digest';
}

String _htmlBody(AccountEmailDeliveryMessage message) {
  final safeUrl = const HtmlEscape(
    HtmlEscapeMode.attribute,
  ).convert(message.actionUrl);
  final safeExpiry = const HtmlEscape().convert(
    message.expiresAt.toUtc().toIso8601String(),
  );
  return '''
<!doctype html>
<html lang="pt-BR">
<body>
  <h1>${message.template.heading}</h1>
  <p>${message.template.introduction}</p>
  <p><a href="$safeUrl">${message.template.actionLabel}</a></p>
  <p>Este link expira em $safeExpiry.</p>
  <p>Se você não fez esta solicitação, ignore este email.</p>
</body>
</html>
''';
}

String _textBody(AccountEmailDeliveryMessage message) => '''
${message.template.heading}

${message.template.introduction}

${message.template.actionLabel}: ${message.actionUrl}

Este link expira em ${message.expiresAt.toUtc().toIso8601String()}.
Se você não fez esta solicitação, ignore este email.
''';

bool _isProduction(Map<String, String> environment) =>
    (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
    'production';
