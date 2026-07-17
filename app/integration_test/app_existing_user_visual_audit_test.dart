import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/main.dart' as app;

import 'runtime_test_helpers.dart';

const _auditEmail = String.fromEnvironment('MANALOOM_VISUAL_EMAIL');
const _auditPassword = String.fromEnvironment('MANALOOM_VISUAL_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'authenticated visual audit covers main and commercial surfaces',
    (tester) async {
      expect(
        _auditEmail,
        isNotEmpty,
        reason: 'Pass MANALOOM_VISUAL_EMAIL with --dart-define.',
      );
      expect(
        _auditPassword,
        isNotEmpty,
        reason: 'Pass MANALOOM_VISUAL_PASSWORD with --dart-define.',
      );

      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      await clearRuntimeAuth();
      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _assertClean(tester, 'splash initial');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_00_splash');
      await tester.pump(const Duration(seconds: 2));

      await pumpUntilFound(tester, find.byKey(const Key('login-email-field')));
      await _assertClean(tester, 'login initial');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_01_login');

      await tester.enterText(
        find.byKey(const Key('login-email-field')),
        _auditEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login-password-field')),
        _auditPassword,
      );
      await tester.pump(const Duration(milliseconds: 250));
      await _assertClean(tester, 'login filled');

      await tester.tap(find.byKey(const Key('login-submit-button')));
      await tester.pump();
      await pumpUntilAnyFound(tester, [
        find.text('Construir deck'),
        find.text('Início'),
        find.text('Decks'),
      ], attempts: 120);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'home authenticated');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_02_home');

      await _tapMainDestination(tester, 'Decks');
      await pumpUntilAnyFound(tester, [
        find.text('Meus Decks'),
        find.text('Criar Deck'),
        find.text('Gerar com IA'),
      ], attempts: 80);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'decks');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_03_decks');

      await _tapMainDestination(tester, 'Coleção');
      await pumpUntilFound(tester, find.text('Coleção'), attempts: 80);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'collection');
      await captureRuntimeCheckpoint(
        binding,
        tester,
        'auth_audit_04_collection',
      );

      await _tapMainDestination(tester, 'Comunidade');
      await pumpUntilFound(tester, find.text('Comunidade'), attempts: 80);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'community');
      await captureRuntimeCheckpoint(
        binding,
        tester,
        'auth_audit_05_community',
      );

      await _tapMainDestination(tester, 'Perfil');
      await pumpUntilFound(tester, find.text('Perfil'), attempts: 80);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'profile');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_06_profile');

      await _tapIfPresent(
        tester,
        find.byKey(const Key('profile-open-plans-button')),
      );
      await pumpUntilFound(tester, find.text('Beta gratuita'), attempts: 80);
      expect(find.byKey(const Key('beta-free-access-panel')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'plans');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_07_plans');

      await _goRoute(tester, '/upgrade');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('upgrade-beta-notice')),
        attempts: 80,
      );
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'upgrade');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_08_upgrade');

      await _goRoute(tester, '/checkout');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('checkout-beta-notice')),
        attempts: 80,
      );
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'checkout');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_09_checkout');

      await _goRoute(tester, '/upgrade');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('upgrade-beta-notice')),
        attempts: 80,
      );

      await _tapIfPresent(
        tester,
        find.byKey(const Key('upgrade-open-legal-button')),
      );
      await _goRoute(tester, '/legal');
      await pumpUntilFound(tester, find.text('Legal'), attempts: 80);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'legal');
      await captureRuntimeCheckpoint(binding, tester, 'auth_audit_10_legal');
    },
  );
}

Future<void> _tapMainDestination(WidgetTester tester, String label) async {
  final destination = find.text(label).last;
  await tester.tap(destination);
  await tester.pump();
}

Future<bool> _tapIfPresent(WidgetTester tester, Finder finder) async {
  await tester.pump();
  if (finder.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: scrollables.last,
          maxScrolls: 8,
        );
        await tester.pump(const Duration(milliseconds: 250));
      } catch (_) {
        // Optional CTAs can be absent for accounts that already have a plan.
      }
    }
  }
  if (finder.evaluate().isEmpty) {
    return false;
  }
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump();
  return true;
}

Future<void> _goRoute(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pump();
}

Future<void> _assertClean(WidgetTester tester, String checkpoint) async {
  expectNoRawTechnicalErrorText(tester);
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: 'Unexpected Flutter exception at $checkpoint',
  );
}
