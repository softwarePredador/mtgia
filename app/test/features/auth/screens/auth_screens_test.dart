import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

Widget _buildWithAuth(Widget child) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(apiClient: _NoopApiClient()),
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  testWidgets('login screen keeps CTA dominant and loads neutral shell', (
    tester,
  ) async {
    await tester.pumpWidget(_buildWithAuth(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ManaLoom'), findsOneWidget);
    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('register screen shows calmer onboarding header', (tester) async {
    await tester.pumpWidget(_buildWithAuth(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Comece no ManaLoom'), findsOneWidget);
    expect(find.text('Criar Conta'), findsNWidgets(2));
    expect(find.text('Comece sua jornada no ManaLoom'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
