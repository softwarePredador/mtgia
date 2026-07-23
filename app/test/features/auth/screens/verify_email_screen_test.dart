import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/account_security_service.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/verify_email_screen.dart';
import 'package:provider/provider.dart';

class _VerifyService extends AccountSecurityService {
  _VerifyService() : super(apiClient: ApiClient());

  int verifyCalls = 0;

  @override
  Future<String> verifyEmail(String token) async {
    verifyCalls++;
    return 'Email verificado. Recursos liberados.';
  }
}

void main() {
  testWidgets('token link verifies automatically with live-region success', (
    tester,
  ) async {
    final service = _VerifyService();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(apiClient: ApiClient()),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: VerifyEmailScreen(token: 'one-use', service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.verifyCalls, 1);
    expect(find.byKey(const Key('verify-email-message')), findsOneWidget);
    expect(
      find.byKey(const Key('verify-email-continue-button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'missing token explains login requirement without false success',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiClient: ApiClient()),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const VerifyEmailScreen(token: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Entre na sua conta'), findsOneWidget);
      expect(find.byKey(const Key('verify-email-message')), findsNothing);
      expect(find.byKey(const Key('verify-email-resend-button')), findsNothing);
    },
  );
}
