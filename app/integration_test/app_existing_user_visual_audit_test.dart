import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';

const _auditEmail = String.fromEnvironment('MANALOOM_VISUAL_EMAIL');
const _auditPassword = String.fromEnvironment('MANALOOM_VISUAL_PASSWORD');
const _auditDeckId = String.fromEnvironment('MANALOOM_VISUAL_DECK_ID');
const _auditCardId = String.fromEnvironment('MANALOOM_VISUAL_CARD_ID');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'authenticated visual audit covers the canonical 20 checkpoints',
    (tester) async {
      expect(
        <String>[_auditEmail, _auditPassword, _auditDeckId, _auditCardId],
        everyElement(isNotEmpty),
        reason:
            'Pass the visual user, password, seeded deck and seeded card with '
            '--dart-define.',
      );

      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      await clearRuntimeAuth();
      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await pumpUntilFound(tester, find.byKey(const Key('login-email-field')));
      await _capture(binding, tester, 'login_empty');

      await _authenticateExistingUser();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(app.ManaLoomApp(key: UniqueKey()));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-hero-frame')),
        attempts: 120,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'home_top');

      await _scrollTo(tester, find.byKey(const Key('home-recent-decks-rail')));
      await _capture(binding, tester, 'home_below_fold');

      await _tapMainDestination(tester, 'Decks');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-list-fab-menu')),
        attempts: 100,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'decks_seeded');

      await tester.tap(find.byKey(const Key('deck-list-fab-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deck-list-menu-create')));
      await pumpUntilFound(tester, find.byKey(const Key('deck-create-dialog')));
      await _capture(binding, tester, 'deck_create_modal');
      Navigator.of(
        tester.element(find.byKey(const Key('deck-create-dialog'))),
      ).pop();
      await tester.pumpAndSettle();

      await _goRoute(tester, '/decks/$_auditDeckId');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-overview-hero')),
        attempts: 120,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'deck_detail_top');
      await _scrollTo(
        tester,
        find.byKey(const Key('deck-overview-primary-pane')),
      );
      await _capture(binding, tester, 'deck_detail_below_fold');

      await _goRoute(tester, '/decks/generate');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-generate-prompt-field')),
      );
      await _capture(binding, tester, 'deck_generate_empty');

      await _goRoute(tester, '/decks/import');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-import-screen-list-field')),
      );
      await tester.enterText(
        find.byKey(const Key('deck-import-screen-list-field')),
        '1 Sol Ring',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(binding, tester, 'deck_import_detected');

      await _goRoute(tester, '/collection?tab=0');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('collection-hub-tabs')),
        attempts: 100,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'collection_empty');

      await _goRoute(tester, '/collection?tab=3');
      await pumpUntilAnyFound(tester, <Finder>[
        find.byKey(const Key('setsCatalogGrid')),
        find.byKey(const Key('setsCatalogList')),
      ], attempts: 120);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('S3-07 Visual Fixture Set'), findsOneWidget);
      await _capture(binding, tester, 'sets_catalog');

      await _goRoute(tester, '/cards/$_auditCardId');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('card-detail-image-frame')),
        attempts: 120,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'card_detail_success');

      await _goRoute(tester, '/cards/00000000-0000-0000-0000-000000000000');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('card-detail-route-state')),
        attempts: 120,
      );
      await pumpUntilFound(tester, find.text('Carta indisponível'));
      await _capture(binding, tester, 'card_detail_error');

      await _goRoute(tester, '/community?tab=0');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('community-tabs')),
        attempts: 100,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'community_empty');

      await _goRoute(tester, '/profile');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile-content')),
        attempts: 100,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'profile_success');

      await _goRoute(tester, '/decks/$_auditDeckId/battle-replays');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-replays-empty-state')),
        attempts: 120,
      );
      await _capture(binding, tester, 'battle_replays_empty');

      await _goRoute(tester, '/plans');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('beta-free-access-panel')),
      );
      await _capture(binding, tester, 'plans_success');

      await _goRoute(tester, '/upgrade');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('upgrade-beta-notice')),
      );
      await _capture(binding, tester, 'upgrade_success');

      await _goRoute(tester, '/checkout');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('checkout-beta-notice')),
      );
      await _capture(binding, tester, 'checkout_success');

      await _goRoute(tester, '/legal');
      await pumpUntilFound(tester, find.byKey(const Key('legal-content')));
      await _capture(binding, tester, 'legal_success');
    },
  );
}

Future<void> _authenticateExistingUser() async {
  final api = ApiClient();
  final response = await api.post('/auth/login', <String, String>{
    'email': _auditEmail,
    'password': _auditPassword,
  });
  expect(response.statusCode, 200);
  final payload = (response.data as Map).cast<String, dynamic>();
  final token = payload['token']?.toString();
  final user = (payload['user'] as Map?)?.cast<String, dynamic>();
  expect(token, isNotNull);
  expect(user, isNotNull);

  ApiClient.setToken(token);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token!);
  await prefs.setString('user_data', jsonEncode(user));
  await markRuntimeOnboardingSettled(user!['id']?.toString() ?? '');
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 250));
  await _assertClean(tester, name);
  await captureRuntimeCheckpoint(binding, tester, name);
}

Future<void> _tapMainDestination(WidgetTester tester, String label) async {
  final destination = find.text(label).last;
  await tester.tap(destination);
  await tester.pump();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) return;
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    await tester.ensureVisible(target.first);
  } else {
    await tester.scrollUntilVisible(
      target.first,
      240,
      scrollable: scrollables.last,
      maxScrolls: 12,
    );
  }
  await tester.pump(const Duration(milliseconds: 350));
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
