import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:manaloom/features/commercial/legal_policy.dart';
import 'package:manaloom/features/commercial/screens/legal_screen.dart';
import 'package:provider/provider.dart';

class _CountingRegisterProvider extends AuthProvider {
  _CountingRegisterProvider() : super(apiClient: ApiClient());

  int calls = 0;

  @override
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required bool legalAccepted,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    calls++;
    return true;
  }
}

void main() {
  testWidgets('legal content is readable without an authenticated provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CommercialLegalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Termos de uso'), findsOneWidget);
    expect(find.text('Privacidade'), findsOneWidget);
    expect(find.textContaining(currentTermsVersion), findsOneWidget);
  });

  testWidgets('unchecked consent blocks registration before API mutation', (
    tester,
  ) async {
    final provider = _CountingRegisterProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register-username-field')),
      'legal-user',
    );
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'legal@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'BetaQa!2026-Deck',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password-field')),
      'BetaQa!2026-Deck',
    );
    final submit = find.byKey(const Key('register-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(provider.calls, 0);
    expect(find.byKey(const Key('register-legal-error')), findsOneWidget);
  });

  test('router source keeps legal and verification outside protected set', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, isNot(contains("location.startsWith('/legal')")));
    expect(source, contains("path: '/legal'"));
    expect(source, contains("path: '/verify-email'"));
  });
}
