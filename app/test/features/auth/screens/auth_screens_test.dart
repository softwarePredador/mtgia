import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

class _SuccessfulAuthProvider extends AuthProvider {
  _SuccessfulAuthProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async => true;
}

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
    expect(
      find.text('Acesse decks, coleção, trades e partidas.'),
      findsOneWidget,
    );
    expect(find.text('Tecendo estratégias lendárias'), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.byKey(const Key('login-password-field')), findsOneWidget);
    expect(find.byKey(const Key('login-submit-button')), findsOneWidget);
    expect(find.byKey(const Key('login-open-register-button')), findsOneWidget);
  });

  testWidgets('register screen shows calmer onboarding header', (tester) async {
    await tester.pumpWidget(_buildWithAuth(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Comece no ManaLoom'), findsNothing);
    expect(find.text('Criar conta'), findsNWidgets(2));
    expect(
      find.text('Configure seu acesso em menos de um minuto.'),
      findsOneWidget,
    );
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byKey(const Key('register-username-field')), findsOneWidget);
    expect(find.byKey(const Key('register-email-field')), findsOneWidget);
    expect(find.byKey(const Key('register-password-field')), findsOneWidget);
    expect(
      find.byKey(const Key('register-confirm-password-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('register-submit-button')), findsOneWidget);
    expect(find.byKey(const Key('register-open-login-button')), findsOneWidget);
  });

  testWidgets('login resumes the protected deep link after authentication', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation:
          Uri(
            path: '/login',
            queryParameters: {'redirect': '/decks/deck-1?tab=analysis'},
          ).toString(),
      routes: [
        GoRoute(
          path: '/login',
          builder:
              (context, state) => LoginScreen(
                redirectPath: state.uri.queryParameters['redirect'],
              ),
        ),
        GoRoute(
          path: '/decks/:id',
          builder:
              (context, state) => Scaffold(
                body: Text(
                  'Destino ${state.pathParameters['id']} '
                  '${state.uri.queryParameters['tab']}',
                ),
              ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _SuccessfulAuthProvider(),
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'qa@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'Qa123456!',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Destino deck-1 analysis'), findsOneWidget);
  });

  testWidgets('registration resumes the protected deep link', (tester) async {
    final router = GoRouter(
      initialLocation:
          Uri(
            path: '/register',
            queryParameters: {'redirect': '/trades/trade-9'},
          ).toString(),
      routes: [
        GoRoute(
          path: '/register',
          builder:
              (context, state) => RegisterScreen(
                redirectPath: state.uri.queryParameters['redirect'],
              ),
        ),
        GoRoute(
          path: '/trades/:id',
          builder:
              (context, state) =>
                  Scaffold(body: Text('Trade ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _SuccessfulAuthProvider(),
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-username-field')),
      'qa-user',
    );
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'qa@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'Qa123456!',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password-field')),
      'Qa123456!',
    );
    final submit = find.byKey(const Key('register-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Trade trade-9'), findsOneWidget);
  });
}
