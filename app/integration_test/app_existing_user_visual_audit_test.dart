import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/splash_screen.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/main.dart' as app;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart' show restoreVisualCaptureSurface;

const _auditEmail = String.fromEnvironment('MANALOOM_VISUAL_EMAIL');
const _auditPassword = String.fromEnvironment('MANALOOM_VISUAL_PASSWORD');
const _auditEmptyEmail = String.fromEnvironment('MANALOOM_VISUAL_EMPTY_EMAIL');
const _auditEmptyPassword = String.fromEnvironment(
  'MANALOOM_VISUAL_EMPTY_PASSWORD',
);
const _auditDeckId = String.fromEnvironment('MANALOOM_VISUAL_DECK_ID');
const _auditCardId = String.fromEnvironment('MANALOOM_VISUAL_CARD_ID');
const _auditUserId = String.fromEnvironment('MANALOOM_VISUAL_USER_ID');
const _auditPeerUserId = String.fromEnvironment('MANALOOM_VISUAL_PEER_USER_ID');
const _auditPeerUsername = String.fromEnvironment(
  'MANALOOM_VISUAL_PEER_USERNAME',
);
const _auditResumeFrom = String.fromEnvironment('MANALOOM_VISUAL_RESUME_FROM');
const _interactiveBattleEnabled = bool.fromEnvironment(
  'ENABLE_INTERACTIVE_BATTLE',
);
const _auditWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _auditHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

Future<LotusUiSnapshot> _waitForNativeLifeCounterVisualReady(
  WidgetTester tester,
  LotusUiSnapshotStore snapshotStore,
) async {
  LotusUiSnapshot? snapshot;
  await pumpUntil(
    tester,
    () async {
      snapshot = await snapshotStore.load();
      return snapshot != null &&
          snapshot!.visualSkinApplied &&
          snapshot!.playerCardCount == 4 &&
          snapshot!.viewportWidth > snapshot!.viewportHeight &&
          snapshot!.documentFontsStatus == 'loaded' &&
          snapshot!.uiFontReady &&
          snapshot!.displayFontReady &&
          snapshot!.horizontalOverflowPx <= 1.5 &&
          snapshot!.verticalOverflowPx <= 1.5;
    },
    description:
        'a stable landscape Life Counter DOM with four players and loaded fonts',
    attempts: 80,
    step: const Duration(milliseconds: 250),
  );

  final readySnapshot = snapshot ?? await snapshotStore.load();
  expect(readySnapshot, isNotNull);
  // ignore: avoid_print
  print(
    'NATIVE_LIFE_DOM_READY '
    'viewport=${readySnapshot!.viewportWidth}x${readySnapshot.viewportHeight} '
    'players=${readySnapshot.playerCardCount} '
    'fonts=${readySnapshot.documentFontsStatus} '
    'overflow=${readySnapshot.horizontalOverflowPx}x'
    '${readySnapshot.verticalOverflowPx}',
  );
  return readySnapshot;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('live visual audit covers every active P0 route and Battle Coach', (
    tester,
  ) async {
    expect(
      <String>[
        _auditEmail,
        _auditPassword,
        _auditEmptyEmail,
        _auditEmptyPassword,
        _auditDeckId,
        _auditCardId,
        _auditUserId,
        _auditPeerUserId,
        _auditPeerUsername,
      ],
      everyElement(isNotEmpty),
      reason:
          'Pass the visual users, passwords, seeded deck and seeded card with '
          '--dart-define. The dedicated empty user must not own a deck.',
    );

    expect(_auditWidth, greaterThanOrEqualTo(320));
    expect(_auditHeight, greaterThanOrEqualTo(568));
    expect(
      _interactiveBattleEnabled,
      isTrue,
      reason:
          'The P0 live matrix must compile the gated Battle Coach route so '
          'its welcome state and real Web focus can be audited.',
    );
    if (kIsWeb) {
      await binding.setSurfaceSize(
        Size(_auditWidth.toDouble(), _auditHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await clearRuntimeAuth();
    final holdingAuth = _HoldingAuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: holdingAuth,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await _capture(binding, tester, 'splash_boot');
    await tester.pumpWidget(const SizedBox.shrink());
    holdingAuth.dispose();

    await tester.pumpWidget(const app.ManaLoomApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await pumpUntilFound(tester, find.byKey(const Key('login-email-field')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('login-submit-button')),
      attempts: 120,
    );
    expect(find.text('Entrar'), findsOneWidget);
    await _capture(binding, tester, 'login_empty');

    if (_auditResumeFrom.isEmpty) {
      await _goRoute(tester, '/register');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('register-username-field')),
      );
      await _capture(binding, tester, 'register_empty');

      await _enterField(
        tester,
        find.byKey(const Key('register-username-field')),
        'visualproof',
      );
      await _enterField(
        tester,
        find.byKey(const Key('register-email-field')),
        'visual-proof@example.invalid',
      );
      await _enterField(
        tester,
        find.byKey(const Key('register-password-field')),
        'BattleReady!2026',
      );
      await _enterField(
        tester,
        find.byKey(const Key('register-confirm-password-field')),
        'BattleReady!2026',
      );
      expect(
        <String?>[
          tester
              .widget<TextFormField>(
                find.byKey(const Key('register-username-field')),
              )
              .controller
              ?.text,
          tester
              .widget<TextFormField>(
                find.byKey(const Key('register-email-field')),
              )
              .controller
              ?.text,
          tester
              .widget<TextFormField>(
                find.byKey(const Key('register-password-field')),
              )
              .controller
              ?.text,
          tester
              .widget<TextFormField>(
                find.byKey(const Key('register-confirm-password-field')),
              )
              .controller
              ?.text,
        ],
        <String>[
          'visualproof',
          'visual-proof@example.invalid',
          'BattleReady!2026',
          'BattleReady!2026',
        ],
      );
      final registerSubmit = find.byKey(const Key('register-submit-button'));
      await tester.ensureVisible(registerSubmit);
      await tester.pump(const Duration(milliseconds: 250));
      await _capture(binding, tester, 'register_consent_unchecked');
      await tester.tap(registerSubmit);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('register-legal-error')),
      );
      await _capture(binding, tester, 'register_consent_error');
      await tester.tap(find.byKey(const Key('register-legal-acceptance')));
      await tester.pump();
      await _capture(binding, tester, 'register_consent_accepted');

      await _goRoute(tester, '/forgot-password');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('forgot-password-email-field')),
      );
      await _capture(binding, tester, 'forgot_password_empty');

      await _goRoute(tester, '/reset-password');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('reset-password-error')),
      );
      await _capture(binding, tester, 'reset_password_invalid_link');

      await _goRoute(tester, '/verify-email');
      await pumpUntilFound(tester, find.text('Verifique seu email'));
      await _capture(binding, tester, 'verify_email_signed_out');

      await _goRoute(tester, '/legal?section=terms');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('legal-terms-section')),
      );
      await _capture(binding, tester, 'legal_terms');

      await _goRoute(tester, '/legal?section=privacy');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('legal-privacy-section')),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await _capture(binding, tester, 'legal_privacy');

      await _goRoute(tester, '/login');
      await pumpUntilFound(tester, find.byKey(const Key('login-email-field')));
    }

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
    if (_auditResumeFrom.isEmpty) {
      await _capture(binding, tester, 'home_top');

      if (_auditWidth < 760) {
        await tester.drag(
          find.byKey(const Key('home-quick-actions-list')),
          const Offset(-260, 0),
        );
        await tester.pump(const Duration(milliseconds: 350));
        await _capture(binding, tester, 'home_quick_actions_scrolled');
      }

      await _goRoute(tester, '/onboarding/core-flow');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('onboarding-format-dropdown')),
        attempts: 100,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _capture(binding, tester, 'onboarding_core_flow');

      final lifeCounterUiSnapshotStore = LotusUiSnapshotStore();
      if (!kIsWeb) {
        // The Flutter screenshot API swaps the Android rendering surface for
        // an ImageView. Restore the real surface before mounting the WebView;
        // otherwise adb can capture a stale Flutter frame over a ready Lotus
        // DOM and produce a convincing but invalid transition screenshot.
        await restoreVisualCaptureSurface();
        await lifeCounterUiSnapshotStore.clear();
      }
      await _goRoute(tester, '/life-counter');
      if (kIsWeb) {
        await tester.pump(const Duration(seconds: 3));
        await _capture(binding, tester, 'life_counter_initial');
      } else {
        final readySnapshot = await _waitForNativeLifeCounterVisualReady(
          tester,
          lifeCounterUiSnapshotStore,
        );
        expect(readySnapshot.firstPlayerLifeBoxWidth, greaterThan(60));
        expect(readySnapshot.firstPlayerLifeBoxHeight, greaterThan(80));
        await tester.pump(const Duration(seconds: 1));
        // Android's Flutter screenshot API does not composite the embedded
        // WebView and returns an all-black PNG. Keep a bounded window for the
        // host runner to take the real device framebuffer with `adb screencap`
        // instead of accepting a false visual proof.
        // ignore: avoid_print
        print('NATIVE_SCREENSHOT_READY life_counter_initial');
        await Future<void>.delayed(const Duration(seconds: 12));
        await tester.pump();
        // ignore: avoid_print
        print('NATIVE_SCREENSHOT_WINDOW_CLOSED life_counter_initial');
      }

      await _goRoute(tester, '/home');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-hero-frame')),
        attempts: 100,
      );
      if (!kIsWeb) {
        await _waitForPortraitViewportAfterLifeCounter(tester);
      }

      await _authenticateVisualUser(
        email: _auditEmptyEmail,
        password: _auditEmptyPassword,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(app.ManaLoomApp(key: UniqueKey()));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('home-hero-frame')),
        attempts: 120,
      );
      await _tapMainDestination(tester, 'Decks');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-list-empty-state')),
        attempts: 100,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, 'decks_empty');

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
      await tester.tap(find.byKey(const Key('deck-create-submit-button')));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-create-name-error')),
      );
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
      final deckOverviewMoved = await _scrollVerticalParentBy(
        tester,
        find.byKey(const Key('deck-overview-hero')),
        560,
      );
      expect(
        deckOverviewMoved,
        isTrue,
        reason:
            'Deck details must expose distinct content below the first viewport.',
      );
      await _capture(binding, tester, 'deck_detail_below_fold');

      await _goRoute(tester, '/decks/$_auditDeckId/search');
      await pumpUntilFound(tester, find.byKey(const Key('card-search-field')));
      await _capture(binding, tester, 'card_search_empty');
      await _enterTextField(
        tester,
        find.byKey(const Key('card-search-field')),
        'Sol Ring',
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('card-search-results-frame')),
        attempts: 120,
      );
      await _capture(binding, tester, 'card_search_results');
    }

    if (_auditResumeFrom != 'social') {
      await _goRoute(tester, '/decks/$_auditDeckId/post-game');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('post-game-responsive-frame')),
        attempts: 100,
      );
      await _capture(binding, tester, 'post_game_empty');

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

      await _goRoute(tester, '/collection/sets');
      await pumpUntilAnyFound(tester, <Finder>[
        find.byKey(const Key('setsCatalogGrid')),
        find.byKey(const Key('setsCatalogList')),
      ], attempts: 120);
      await _capture(binding, tester, 'sets_catalog_route');

      await _goRoute(tester, '/collection/latest-set');
      await pumpUntilAnyFound(tester, <Finder>[
        find.byKey(const Key('setCardsGrid')),
        find.byKey(const Key('setCardsList')),
        find.byKey(const Key('setCardsEmptyState')),
      ], attempts: 120);
      await _capture(binding, tester, 'latest_set');

      await _goRoute(tester, '/collection/sets/TST');
      await pumpUntilAnyFound(tester, <Finder>[
        find.byKey(const Key('setCardsGrid')),
        find.byKey(const Key('setCardsList')),
        find.byKey(const Key('setCardsEmptyState')),
      ], attempts: 120);
      await _capture(binding, tester, 'set_detail_tst');

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

      const communityTabCheckpoints = <String>[
        'community_tab_1',
        'community_tab_2',
        'community_tab_3',
      ];
      for (var tab = 1; tab <= 3; tab += 1) {
        await _goRoute(tester, '/community?tab=$tab');
        await pumpUntilFound(
          tester,
          find.byKey(const Key('community-tabs')),
          attempts: 100,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await _capture(binding, tester, communityTabCheckpoints[tab - 1]);
      }
    }

    await _goRoute(tester, '/community/search-users');
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, 'user_search_empty');
    await _enterTextField(
      tester,
      find.byKey(const Key('user-search-field')),
      _auditPeerUsername,
    );
    await pumpUntilFound(
      tester,
      find.byKey(Key('user-search-row-$_auditPeerUserId')),
      attempts: 100,
    );
    await _capture(binding, tester, 'user_search_results');

    await _goRoute(tester, '/community/user/$_auditPeerUserId');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('user-profile-content')),
      attempts: 120,
    );
    await _capture(binding, tester, 'user_profile_success');

    await _goRoute(tester, '/community/decks/$_auditDeckId');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('community-deck-detail-frame')),
      attempts: 120,
    );
    await _capture(binding, tester, 'community_deck_success');

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

    await _goRoute(tester, '/decks/$_auditDeckId/battle-coach');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-coach-welcome-state')),
      attempts: 100,
    );
    await _capture(binding, tester, 'battle_coach_welcome');

    await _goRoute(
      tester,
      '/decks/$_auditDeckId/battle-live/00000000-0000-0000-0000-000000000000',
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-live-disabled-state')),
    );
    await _capture(binding, tester, 'battle_live_disabled');

    await _goRoute(tester, '/messages');
    await pumpUntilAnyFound(tester, <Finder>[
      find.byKey(const Key('messages-inbox-empty')),
      find.byKey(const Key('messages-inbox-list')),
    ], attempts: 100);
    await _capture(binding, tester, 'messages_inbox');

    await _goRoute(tester, '/messages/00000000-0000-0000-0000-000000000000');
    await pumpUntilAnyFound(tester, <Finder>[
      find.byKey(const Key('chat-error-state')),
      find.byKey(const Key('chat-empty-state')),
    ], attempts: 100);
    await _capture(binding, tester, 'chat_unavailable');

    await _goRoute(tester, '/notifications');
    await pumpUntilAnyFound(tester, <Finder>[
      find.byKey(const Key('notifications-empty')),
      find.byKey(const Key('notifications-list')),
    ], attempts: 100);
    await _capture(binding, tester, 'notifications');

    await _goRoute(tester, '/trades');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('trade-inbox-tab-bar')),
      attempts: 100,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(binding, tester, 'trades_inbox');

    await _goRoute(tester, '/trades/create/$_auditPeerUserId');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('create-trade-content')),
      attempts: 100,
    );
    await _capture(binding, tester, 'trade_create');

    await _goRoute(tester, '/trades/00000000-0000-0000-0000-000000000000');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('trade-detail-error-state')),
      attempts: 100,
    );
    await _capture(binding, tester, 'trade_detail_unavailable');

    await _goRoute(tester, '/plans');
    await pumpUntilFound(
      tester,
      find.byKey(const Key('beta-free-access-panel')),
    );
    await _capture(binding, tester, 'plans_success');

    await _goRoute(tester, '/upgrade');
    await pumpUntilFound(tester, find.byKey(const Key('upgrade-beta-notice')));
    await _capture(binding, tester, 'upgrade_success');

    await _goRoute(tester, '/checkout');
    await pumpUntilFound(tester, find.byKey(const Key('checkout-beta-notice')));
    await _capture(binding, tester, 'checkout_success');

    await _goRoute(tester, '/legal');
    await pumpUntilFound(tester, find.byKey(const Key('legal-content')));
    await _capture(binding, tester, 'legal_success');
  });
}

class _HoldingAuthProvider extends AuthProvider {
  final Completer<void> _initialization = Completer<void>();

  @override
  Future<void> initialize() => _initialization.future;
}

Future<void> _authenticateExistingUser() =>
    _authenticateVisualUser(email: _auditEmail, password: _auditPassword);

Future<void> _authenticateVisualUser({
  required String email,
  required String password,
}) async {
  final api = ApiClient();
  final response = await api.post('/auth/login', <String, String>{
    'email': email,
    'password': password,
  });
  expect(response.statusCode, 200);
  final payload = (response.data as Map).cast<String, dynamic>();
  final token = payload['token']?.toString();
  final user = (payload['user'] as Map?)?.cast<String, dynamic>();
  expect(token, isNotNull);
  expect(user, isNotNull);

  ApiClient.setToken(token);
  final prefs = await SharedPreferences.getInstance();
  await AuthTokenStore().write(token!);
  await prefs.setString('user_data', jsonEncode(user));
  await markRuntimeOnboardingSettled(user!['id']?.toString() ?? '');
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 250));
  await captureRuntimeCheckpoint(binding, tester, name);
  await _assertClean(tester, name);
}

Future<void> _tapMainDestination(WidgetTester tester, String label) async {
  final destination = find.text(label).last;
  await tester.tap(destination);
  await tester.pump();
}

Future<void> _enterField(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 120));
  final field = tester.widget<TextFormField>(finder);
  field.controller?.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
  await tester.pump(const Duration(milliseconds: 120));
  expect(
    field.controller?.text,
    value,
    reason: 'The real field must retain text before the next interaction.',
  );
}

Future<void> _enterTextField(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 120));
  final field = tester.widget<TextField>(finder);
  field.controller?.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
  field.onChanged?.call(value);
  await tester.pump(const Duration(milliseconds: 120));
  expect(field.controller?.text, value);
}

Future<bool> _scrollVerticalParentBy(
  WidgetTester tester,
  Finder target,
  double delta,
) async {
  if (target.evaluate().isEmpty) return false;
  final scrollable = Scrollable.maybeOf(tester.element(target.first));
  if (scrollable == null ||
      axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
    return false;
  }
  final position = scrollable.position;
  final destination = (position.pixels + delta)
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();
  if ((destination - position.pixels).abs() < 1) return false;
  position.jumpTo(destination);
  await tester.pump(const Duration(milliseconds: 350));
  return true;
}

Future<void> _goRoute(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pump();
}

Future<void> _waitForPortraitViewportAfterLifeCounter(
  WidgetTester tester,
) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    final context = tester.element(find.byType(Scaffold).first);
    final physicalSize = View.of(context).physicalSize;
    if (physicalSize.height > physicalSize.width) return;
    await tester.pump(const Duration(milliseconds: 100));
  }

  final context = tester.element(find.byType(Scaffold).first);
  final physicalSize = View.of(context).physicalSize;
  expect(
    physicalSize.height,
    greaterThan(physicalSize.width),
    reason:
        'Leaving Life Counter must restore a portrait phone viewport before '
        'the remaining Android P0 matrix is captured. Observed '
        '${physicalSize.width}x${physicalSize.height}.',
  );
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
