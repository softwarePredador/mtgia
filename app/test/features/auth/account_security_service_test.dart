import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/account_security_service.dart';

class _SecurityApi extends ApiClient {
  ApiResponse forgotResponse = ApiResponse(202, {
    'message': 'Se o email estiver cadastrado, enviaremos as instruções.',
  });
  ApiResponse resetResponse = ApiResponse(200, {'password_reset': true});
  String? endpoint;
  Map<String, dynamic>? payload;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    this.endpoint = endpoint;
    payload = body;
    return endpoint == '/auth/forgot-password' ? forgotResponse : resetResponse;
  }
}

void main() {
  test('forgot password keeps the neutral server response', () async {
    final api = _SecurityApi();
    final service = AccountSecurityService(apiClient: api);

    final message = await service.requestPasswordReset(' PLAYER@example.com ');

    expect(api.endpoint, '/auth/forgot-password');
    expect(api.payload, {'email': 'PLAYER@example.com'});
    expect(message, contains('Se o email estiver cadastrado'));
  });

  test(
    'reset sends token and new password without transforming them',
    () async {
      final api = _SecurityApi();
      final service = AccountSecurityService(apiClient: api);

      await service.resetPassword(
        token: ' token-once ',
        newPassword: 'Safe!Deck-Password-2026',
      );

      expect(api.endpoint, '/auth/reset-password');
      expect(api.payload, {
        'token': 'token-once',
        'new_password': 'Safe!Deck-Password-2026',
      });
    },
  );

  test('reset exposes safe API copy and never a raw exception', () async {
    final api = _SecurityApi()
      ..resetResponse = ApiResponse(400, {
        'error': 'reset_token_invalid',
        'message': 'Link de recuperação inválido ou expirado.',
      });
    final service = AccountSecurityService(apiClient: api);

    await expectLater(
      service.resetPassword(token: 'used', newPassword: 'Any!Deck-2026-Safe'),
      throwsA(
        isA<AccountSecurityUiException>().having(
          (error) => error.message,
          'message',
          'Link de recuperação inválido ou expirado.',
        ),
      ),
    );
  });

  test('verification and resend use dedicated endpoints', () async {
    final api = _SecurityApi();
    final service = AccountSecurityService(apiClient: api);

    await service.verifyEmail(' verify-once ');
    expect(api.endpoint, '/auth/verify-email');
    expect(api.payload, {'token': 'verify-once'});

    await service.resendEmailVerification();
    expect(api.endpoint, '/auth/resend-verification');
    expect(api.payload, isEmpty);
  });
}
