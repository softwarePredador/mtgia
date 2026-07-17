import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/main.dart' as app;
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'authenticated mobile QA covers signup, navigation, commercial surfaces and AI paywall',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      await clearRuntimeAuth();
      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await pumpUntilFound(tester, find.byKey(const Key('login-email-field')));
      await _assertClean(tester, 'login');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_00_login');

      await tester.tap(find.byKey(const Key('login-open-register-button')));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('register-email-field')),
      );

      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final username = 'mobileqa$unique';
      final email = 'mobile-qa-$unique@example.invalid';
      const password = 'MobileQA123!';
      // Keep this marker stable: the shell runner uses it for DB cleanup.
      // ignore: avoid_print
      print('MOBILE_QA_USER_EMAIL=$email');

      await _enterVisible(
        tester,
        find.byKey(const Key('register-username-field')),
        username,
      );
      await _enterVisible(
        tester,
        find.byKey(const Key('register-email-field')),
        email,
      );
      await _enterVisible(
        tester,
        find.byKey(const Key('register-password-field')),
        password,
      );
      await _enterVisible(
        tester,
        find.byKey(const Key('register-confirm-password-field')),
        password,
      );
      await _assertClean(tester, 'register filled');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_01_register');

      await _tapVisible(
        tester,
        find.byKey(const Key('register-submit-button')),
      );
      await pumpUntilAnyFound(tester, [
        find.text('Construir deck'),
        find.text('Início'),
        find.text('Decks'),
      ], attempts: 140);
      await tester.pump(const Duration(seconds: 1));
      await _assertClean(tester, 'home after signup');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_02_home');

      await _goRoute(tester, '/decks');
      await pumpUntilAnyFound(tester, [
        find.text('Meus Decks'),
        find.text('Criar Deck'),
        find.text('Gerar com IA'),
      ], attempts: 80);
      await _assertClean(tester, 'decks');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_03_decks');

      await _goRoute(tester, '/collection');
      await pumpUntilFound(tester, find.text('Coleção'), attempts: 80);
      await _assertClean(tester, 'collection');
      await captureRuntimeCheckpoint(
        binding,
        tester,
        'mobile_qa_04_collection',
      );

      await _goRoute(tester, '/market');
      await pumpUntilFound(tester, find.text('Market'), attempts: 80);
      await _assertClean(tester, 'market');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_05_market');

      await _goRoute(tester, '/community');
      await pumpUntilFound(tester, find.text('Comunidade'), attempts: 80);
      await _assertClean(tester, 'community');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_06_community');

      await _goRoute(tester, '/profile');
      await pumpUntilFound(tester, find.text('Perfil'), attempts: 80);
      await _assertClean(tester, 'profile');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_07_profile');

      await _goRoute(tester, '/plans');
      await pumpUntilFound(tester, find.text('Beta gratuita'), attempts: 80);
      expect(find.byKey(const Key('beta-free-access-panel')), findsOneWidget);
      await _assertClean(tester, 'plans');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_08_plans');

      await _goRoute(tester, '/upgrade');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('upgrade-beta-notice')),
        attempts: 80,
      );
      expect(
        find.byKey(const Key('upgrade-start-checkout-button')),
        findsNothing,
      );
      await _assertClean(tester, 'upgrade');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_09_upgrade');

      await _goRoute(tester, '/checkout');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('checkout-beta-notice')),
        attempts: 80,
      );
      expect(find.byKey(const Key('checkout-confirm-button')), findsNothing);
      await _assertClean(tester, 'checkout');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_10_checkout');

      await _goRoute(tester, '/legal');
      await pumpUntilFound(tester, find.text('Legal'), attempts: 80);
      await _assertClean(tester, 'legal');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_11_legal');

      await _goRoute(tester, '/decks/generate');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-generate-prompt-field')),
        attempts: 80,
      );
      await _exhaustLocalAiQuota(tester);
      await _enterVisible(
        tester,
        find.byKey(const Key('deck-generate-prompt-field')),
        'Deck commander de teste para validar paywall local.',
      );
      await _tapVisible(
        tester,
        find.byKey(const Key('deck-generate-submit-button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('ai-paywall-dialog')),
        attempts: 40,
      );
      expect(find.textContaining('limite da beta atingido'), findsOneWidget);
      expect(find.byKey(const Key('ai-paywall-upgrade-button')), findsNothing);
      expect(
        find.byKey(const Key('ai-beta-limit-dismiss-button')),
        findsOneWidget,
      );
      await _assertClean(tester, 'ai paywall');
      await captureRuntimeCheckpoint(binding, tester, 'mobile_qa_12_paywall');
    },
  );
}

Future<void> _exhaustLocalAiQuota(WidgetTester tester) async {
  final context = _anyAppContext(tester);
  final provider = context.read<CommercialProvider>();
  await provider.clearRemoteSnapshot();
  for (var i = 0; i < ManaLoomPlan.free.monthlyAiLimit; i += 1) {
    await provider.consumeAiAction(AiUsageKind.deckGeneration);
  }
  await tester.pump();
}

BuildContext _anyAppContext(WidgetTester tester) {
  final scaffold = find.byType(Scaffold);
  expect(scaffold, findsWidgets);
  return tester.element(scaffold.first);
}

Future<void> _goRoute(WidgetTester tester, String route) async {
  final context = _anyAppContext(tester);
  GoRouter.of(context).go(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _enterVisible(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(finder, value);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
}

Future<void> _assertClean(WidgetTester tester, String surface) async {
  expectNoRawTechnicalErrorText(tester);
  expect(
    tester.takeException(),
    isNull,
    reason: 'Unexpected Flutter exception on $surface',
  );
}
