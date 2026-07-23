import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/account_security_service.dart';
import 'package:manaloom/features/auth/screens/forgot_password_screen.dart';
import 'package:manaloom/features/auth/screens/reset_password_screen.dart';

class _ScreenSecurityApi extends ApiClient {
  int forgotCalls = 0;
  ApiResponse forgotResponse = ApiResponse(202, {
    'message': 'Se o email estiver cadastrado, enviaremos as instruções.',
  });
  ApiResponse resetResponse = ApiResponse(400, {
    'message': 'Link de recuperação inválido ou expirado.',
  });

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/auth/forgot-password') {
      forgotCalls++;
      return forgotResponse;
    }
    return resetResponse;
  }
}

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.darkTheme, home: child);

void main() {
  testWidgets('forgot validates email and shows neutral success', (
    tester,
  ) async {
    final api = _ScreenSecurityApi();
    await tester.pumpWidget(
      host(
        ForgotPasswordScreen(service: AccountSecurityService(apiClient: api)),
      ),
    );

    await tester.tap(find.byKey(const Key('forgot-password-submit-button')));
    await tester.pump();
    expect(find.text('Digite um email válido'), findsOneWidget);
    expect(api.forgotCalls, 0);

    await tester.enterText(
      find.byKey(const Key('forgot-password-email-field')),
      'player@example.com',
    );
    await tester.tap(find.byKey(const Key('forgot-password-submit-button')));
    await tester.pumpAndSettle();
    expect(api.forgotCalls, 1);
    expect(find.byKey(const Key('forgot-password-success')), findsOneWidget);
  });

  testWidgets('reset rejects missing and reused token with recovery copy', (
    tester,
  ) async {
    final api = _ScreenSecurityApi();
    final service = AccountSecurityService(apiClient: api);
    await tester.pumpWidget(
      host(ResetPasswordScreen(token: '', service: service)),
    );
    expect(find.textContaining('Link de recuperação inválido'), findsOneWidget);
    expect(find.byKey(const Key('reset-password-submit-button')), findsNothing);

    await tester.pumpWidget(
      host(ResetPasswordScreen(token: 'used-token', service: service)),
    );
    await tester.enterText(
      find.byKey(const Key('reset-password-field')),
      'Quartz!Dragon-2026-Azure',
    );
    await tester.enterText(
      find.byKey(const Key('reset-password-confirm-field')),
      'Quartz!Dragon-2026-Azure',
    );
    await tester.tap(find.byKey(const Key('reset-password-submit-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('Link de recuperação inválido ou expirado.'),
      findsOneWidget,
    );
  });
}
