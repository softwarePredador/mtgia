import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:manaloom/main.dart' as app;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';

const _email = String.fromEnvironment('MANALOOM_ONBOARDING_EMAIL');
const _password = String.fromEnvironment('MANALOOM_ONBOARDING_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'first login resumes offline progress and remains settled after relogin',
    (tester) async {
      expect(_email, isNotEmpty);
      expect(_password, isNotEmpty);

      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      await AuthTokenStore().delete();
      ApiClient.setToken(null);
      addTearDown(() async {
        await AuthTokenStore().delete();
        await preferences.clear();
        ApiClient.setToken(null);
      });

      await tester.pumpWidget(const app.ManaLoomApp());
      await _login(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('onboarding-format-dropdown')),
        attempts: 90,
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('onboarding-format-dropdown')),
      );
      dropdown.onChanged?.call('modern');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(app.ManaLoomApp(key: UniqueKey()));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('onboarding-format-dropdown')),
        attempts: 90,
      );
      final resumedDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('onboarding-format-dropdown')),
      );
      expect(resumedDropdown.initialValue, 'modern');

      final skip = find.byKey(const Key('onboarding-skip-action'));
      await tester.scrollUntilVisible(
        skip,
        240,
        scrollable: find.descendant(
          of: find.byKey(const Key('onboarding-scroll-view')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(skip);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-hero-frame')),
        attempts: 90,
      );

      final userId = tester
          .element(find.byKey(const Key('home-hero-frame')))
          .read<AuthProvider>()
          .user!
          .id;
      final stored = await OnboardingStateStore().load(userId);
      expect(stored.disposition, OnboardingDisposition.skipped);
      expect(stored.selectedFormat, 'modern');

      final auth = tester
          .element(find.byKey(const Key('home-hero-frame')))
          .read<AuthProvider>();
      await auth.logout();
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('login-email-field')),
        attempts: 90,
      );
      await _login(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-hero-frame')),
        attempts: 90,
      );
      expect(find.byKey(const Key('onboarding-format-dropdown')), findsNothing);
      expectNoRawTechnicalErrorText(tester);
    },
  );
}

Future<void> _login(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    find.byKey(const Key('login-email-field')),
    attempts: 90,
  );
  final emailField = find.byKey(const Key('login-email-field'));
  final passwordField = find.byKey(const Key('login-password-field'));
  tester.widget<TextFormField>(emailField).controller!.text = _email;
  tester.widget<TextFormField>(passwordField).controller!.text = _password;
  await tester.pump();
  expect(tester.widget<TextFormField>(emailField).controller?.text, _email);
  expect(
    tester.widget<TextFormField>(passwordField).controller?.text,
    _password,
  );

  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));

  final submit = find.byKey(const Key('login-submit-button'));
  await tester.ensureVisible(submit);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(submit);
  await tester.pump();
}
