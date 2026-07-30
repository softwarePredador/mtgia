import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/account_email_delivery_transport.dart';
import 'package:server/email_verification_delivery_service.dart';
import 'package:server/password_reset_delivery_service.dart';
import 'package:test/test.dart';

void main() {
  const resetToken = 'reset-token-test-only';
  const verificationToken = 'verification-token-test-only';
  const resendApiKey = 're_test_only_never_real_123456789';
  final expiresAt = DateTime.utc(2026, 7, 30, 18, 30);

  test('generic webhook keeps Authorization and canonical payload', () async {
    late http.Request captured;
    final service = PasswordResetDeliveryService(
      environment: const {
        'ENVIRONMENT': 'production',
        'PASSWORD_RESET_WEBHOOK_URL': 'https://hooks.example.test/email',
        'PASSWORD_RESET_WEBHOOK_TOKEN': 'webhook-test-token-not-production',
        'PASSWORD_RESET_APP_URL':
            'https://app.example.test/app/#/reset-password',
      },
      clientFactory:
          () => MockClient((request) async {
            captured = request;
            return http.Response('{"accepted":true}', 202);
          }),
    );

    final sent = await service.deliver(
      email: 'player@example.test',
      token: resetToken,
      expiresAt: expiresAt,
    );

    expect(sent, isTrue);
    expect(captured.method, 'POST');
    expect(captured.url, Uri.parse('https://hooks.example.test/email'));
    expect(
      captured.headers['authorization'],
      'Bearer webhook-test-token-not-production',
    );
    final idempotencyKey = captured.headers['idempotency-key']!;
    expect(idempotencyKey, startsWith('manaloom/password_reset/'));
    expect(idempotencyKey.length, lessThanOrEqualTo(256));
    expect(idempotencyKey, isNot(contains(resetToken)));
    expect(idempotencyKey, isNot(contains('player@example.test')));
    expect(jsonDecode(captured.body), {
      'template': 'password_reset',
      'recipient': 'player@example.test',
      'reset_url':
          'https://app.example.test/app/#/reset-password'
          '?token=reset-token-test-only',
      'expires_at': expiresAt.toIso8601String(),
    });
  });

  test('Resend uses official POST contract and safe idempotency', () async {
    late http.Request captured;
    final service = EmailVerificationDeliveryService(
      environment: const {
        'ENVIRONMENT': 'production',
        'MANALOOM_EMAIL_DELIVERY_PROVIDER': 'resend',
        'RESEND_API_KEY': resendApiKey,
        'RESEND_FROM_EMAIL': 'conta@mail.example.test',
        'RESEND_FROM_NAME': 'ManaLoom Conta',
        'RESEND_VERIFIED_DOMAIN': 'mail.example.test',
        'EMAIL_VERIFICATION_APP_URL':
            'https://app.example.test/app/#/verify-email?source=account',
      },
      clientFactory:
          () => MockClient((request) async {
            captured = request;
            return http.Response('{"id":"email-test-id"}', 200);
          }),
    );

    final sent = await service.deliver(
      email: 'player@example.test',
      token: verificationToken,
      expiresAt: expiresAt,
    );

    expect(sent, isTrue);
    expect(captured.method, 'POST');
    expect(captured.url.toString(), resendSendEmailEndpoint);
    expect(captured.headers['authorization'], 'Bearer $resendApiKey');
    final idempotencyKey = captured.headers['idempotency-key']!;
    expect(idempotencyKey, startsWith('manaloom/email_verification/'));
    expect(idempotencyKey, isNot(contains(verificationToken)));
    expect(idempotencyKey, isNot(contains('player@example.test')));

    final payload = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(payload['from'], 'ManaLoom Conta <conta@mail.example.test>');
    expect(payload['to'], ['player@example.test']);
    expect(payload['subject'], 'Verifique seu email no ManaLoom');
    expect(payload, isNot(contains('template')));
    expect(payload, isNot(contains('recipient')));
    expect(
      payload['html'],
      contains('source=account&amp;token=verification-token-test-only'),
    );
    expect(
      payload['text'],
      contains('source=account&token=verification-token-test-only'),
    );
  });

  test('non-2xx provider error never reflects response or secrets', () async {
    const responseSecret =
        'player@example.test token=verification-token-test-only';
    final service = EmailVerificationDeliveryService(
      environment: const {
        'ENVIRONMENT': 'production',
        'MANALOOM_EMAIL_DELIVERY_PROVIDER': 'resend',
        'RESEND_API_KEY': resendApiKey,
        'RESEND_FROM_EMAIL': 'conta@mail.example.test',
        'RESEND_FROM_NAME': 'ManaLoom',
        'RESEND_VERIFIED_DOMAIN': 'mail.example.test',
        'EMAIL_VERIFICATION_APP_URL':
            'https://app.example.test/app/#/verify-email',
      },
      clientFactory:
          () => MockClient((_) async => http.Response(responseSecret, 422)),
    );

    Object? failure;
    try {
      await service.deliver(
        email: 'player@example.test',
        token: verificationToken,
        expiresAt: expiresAt,
      );
    } catch (error) {
      failure = error;
    }

    expect(failure, isA<AccountEmailDeliveryException>());
    final exception = failure! as AccountEmailDeliveryException;
    expect(exception.code, 'resend_email_rejected');
    expect(exception.toString(), isNot(contains(responseSecret)));
    expect(exception.toString(), isNot(contains(resendApiKey)));
    expect(exception.toString(), isNot(contains(verificationToken)));
    expect(exception.toString(), isNot(contains('player@example.test')));
  });

  test('deadline includes a response body that never finishes', () async {
    final hangingClient = _HangingBodyClient();
    final service = PasswordResetDeliveryService(
      environment: const {
        'ENVIRONMENT': 'production',
        'MANALOOM_EMAIL_DELIVERY_PROVIDER': 'resend',
        'RESEND_API_KEY': resendApiKey,
        'RESEND_FROM_EMAIL': 'conta@mail.example.test',
        'RESEND_FROM_NAME': 'ManaLoom',
        'RESEND_VERIFIED_DOMAIN': 'mail.example.test',
        'PASSWORD_RESET_APP_URL':
            'https://app.example.test/app/#/reset-password',
      },
      clientFactory: () => hangingClient,
      requestTimeout: const Duration(milliseconds: 40),
    );

    await expectLater(
      service.deliver(
        email: 'player@example.test',
        token: resetToken,
        expiresAt: expiresAt,
      ),
      throwsA(
        isA<AccountEmailDeliveryException>().having(
          (error) => error.code,
          'code',
          'email_delivery_timeout',
        ),
      ),
    );
    expect(hangingClient.closed, isTrue);
  });
}

class _HangingBodyClient extends http.BaseClient {
  final StreamController<List<int>> _body = StreamController<List<int>>();
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(_body.stream, 202);
  }

  @override
  void close() {
    closed = true;
    unawaited(_body.close());
  }
}
