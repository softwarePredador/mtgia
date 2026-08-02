import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/account_security_service.dart';
import 'package:manaloom/features/auth/models/email_verification_delivery_result.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/verify_email_screen.dart';
import 'package:provider/provider.dart';

class _VerifyService extends AccountSecurityService {
  _VerifyService() : super(apiClient: ApiClient());

  int verifyCalls = 0;
  final List<String> verifiedTokens = <String>[];

  @override
  Future<String> verifyEmail(String token) async {
    verifyCalls++;
    verifiedTokens.add(token);
    return 'Email verificado. Recursos liberados.';
  }
}

class _AuthenticatedAuthProvider extends AuthProvider {
  _AuthenticatedAuthProvider() : super(apiClient: ApiClient());

  @override
  bool get isAuthenticated => true;

  @override
  User get user =>
      User(id: 'user-1', username: 'e2e-user', email: 'e2e@example.com');
}

class _DeferredVerifyService extends AccountSecurityService {
  _DeferredVerifyService() : super(apiClient: ApiClient());

  final Completer<String> result = Completer<String>();

  @override
  Future<String> verifyEmail(String token) => result.future;
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

  testWidgets('new token on the same route verifies without a reload', (
    tester,
  ) async {
    final service = _VerifyService();
    final auth = AuthProvider(apiClient: ApiClient());

    Widget build(String token) => ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: VerifyEmailScreen(token: token, service: service),
      ),
    );

    await tester.pumpWidget(build(''));
    await tester.pumpAndSettle();
    expect(service.verifyCalls, 0);

    await tester.pumpWidget(build('arrived-later'));
    await tester.pumpAndSettle();

    expect(service.verifiedTokens, ['arrived-later']);
    expect(
      find.byKey(const Key('verify-email-continue-button')),
      findsOneWidget,
    );
  });

  testWidgets('removing the token clears stale verification state', (
    tester,
  ) async {
    final service = _VerifyService();
    final auth = AuthProvider(apiClient: ApiClient());

    Widget build(String token) => ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: VerifyEmailScreen(token: token, service: service),
      ),
    );

    await tester.pumpWidget(build('one-use'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('verify-email-continue-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(build(''));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verify-email-message')), findsNothing);
    expect(find.byKey(const Key('verify-email-continue-button')), findsNothing);
    expect(find.textContaining('Entre na sua conta'), findsOneWidget);
  });

  testWidgets('an old verification response cannot win after token removal', (
    tester,
  ) async {
    final service = _DeferredVerifyService();
    final auth = AuthProvider(apiClient: ApiClient());

    Widget build(String token) => ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: VerifyEmailScreen(token: token, service: service),
      ),
    );

    await tester.pumpWidget(build('one-use'));
    await tester.pump();
    await tester.pumpWidget(build(''));
    service.result.complete('Email verificado.');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verify-email-message')), findsNothing);
    expect(find.byKey(const Key('verify-email-continue-button')), findsNothing);
    expect(find.textContaining('Entre na sua conta'), findsOneWidget);
  });

  testWidgets('delivery failure never tells the user to check the inbox', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _AuthenticatedAuthProvider(),
        child: const MaterialApp(
          home: VerifyEmailScreen(
            token: '',
            initialDeliveryStatus: EmailVerificationDeliveryStatus.unavailable,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Confira a caixa'), findsNothing);
    expect(find.textContaining('ainda não foi enviado'), findsOneWidget);
  });
}
