import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:provider/provider.dart';

import 'support/manaloom_ui_audit_harness.dart';

class _NoopApiClient extends ApiClient {}

void main() {
  runManaLoomUiGoldenConfig(
    run: () {
      goldenTest(
        'login screen keeps the ManaLoom visual contract',
        fileName: 'manaloom_auth_login',
        constraints: manaloomFullScreenGoldenConstraints,
        builder: () => _authShell(const LoginScreen()),
      );

      goldenTest(
        'register screen keeps the ManaLoom visual contract',
        fileName: 'manaloom_auth_register',
        constraints: manaloomFullScreenGoldenConstraints,
        builder: () => _authShell(const RegisterScreen()),
      );
    },
  );

  testWidgets('auth entry screens pass baseline accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => AccessibilityTools.debugRunCheckersInTests = false);
    AccessibilityTools.debugRunCheckersInTests = true;

    try {
      setManaLoomMobileViewport(tester);

      await tester.pumpWidget(
        manaloomAccessibilityShell(child: _authShell(const LoginScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-email-field')), findsOneWidget);
      expect(find.byKey(const Key('login-password-field')), findsOneWidget);
      expect(find.byKey(const Key('login-submit-button')), findsOneWidget);
      await expectManaLoomBaselineAccessibility(tester);

      await tester.pumpWidget(
        manaloomAccessibilityShell(child: _authShell(const RegisterScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register-email-field')), findsOneWidget);
      expect(find.byKey(const Key('register-password-field')), findsOneWidget);
      expect(find.byKey(const Key('register-submit-button')), findsOneWidget);
      await expectManaLoomBaselineAccessibility(tester);
    } finally {
      semantics.dispose();
    }
  });
}

Widget _authShell(Widget child) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(apiClient: _NoopApiClient()),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}
