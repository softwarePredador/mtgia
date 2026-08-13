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
import 'package:manaloom/features/cards/widgets/card_printing_picker.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
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
const _auditBinderItemId = String.fromEnvironment(
  'MANALOOM_VISUAL_BINDER_ITEM_ID',
);
const _auditPeerBinderItemId = String.fromEnvironment(
  'MANALOOM_VISUAL_PEER_BINDER_ITEM_ID',
);
const _auditTradeId = String.fromEnvironment('MANALOOM_VISUAL_TRADE_ID');
const _auditFixtureImageUrl = String.fromEnvironment(
  'MANALOOM_VISUAL_FIXTURE_IMAGE_URL',
);
const _auditResumeFrom = String.fromEnvironment('MANALOOM_VISUAL_RESUME_FROM');
const _auditSegment = String.fromEnvironment(
  'MANALOOM_VISUAL_SEGMENT',
  defaultValue: 'all',
);
const _auditCheckpoint = String.fromEnvironment('MANALOOM_VISUAL_CHECKPOINT');
const _nativeDeckDetailCapture = bool.fromEnvironment(
  'MANALOOM_VISUAL_NATIVE_DECK_DETAIL_CAPTURE',
);
const _interactiveBattleEnabled = bool.fromEnvironment(
  'ENABLE_INTERACTIVE_BATTLE',
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _auditWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _auditHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

const _supportedAuditSegments = <String>{
  'all',
  'auth_home',
  'decks',
  'deck_list',
  'deck_detail',
  'catalog',
  'social',
  'community',
  'profile_battle',
  'trades_commercial',
  'ux_pack_01_completion',
};

const _supportedIsolatedCheckpoints = <String>{
  'deck_detail_top',
  'deck_detail_below_fold',
  'card_search_empty',
  'card_search_results',
  'card_search_printing_picker',
};

List<String> get _p0ProofCheckpoints => <String>[
  'battle_coach_welcome',
  'battle_live_disabled',
  'battle_replays_empty',
  'card_detail_error',
  'card_detail_success',
  'card_search_empty',
  'card_search_results',
  'chat_unavailable',
  'checkout_success',
  'collection_empty',
  'community_deck_success',
  'community_public_decks',
  'community_tab_1',
  'community_tab_2',
  'community_tab_3',
  'deck_create_modal',
  'deck_detail_below_fold',
  'deck_detail_top',
  'deck_generate_empty',
  'deck_import_detected',
  'decks_empty',
  'decks_seeded',
  'forgot_password_empty',
  if (_auditWidth < 900) 'home_quick_actions_scrolled',
  'home_top',
  'latest_set',
  'legal_privacy',
  'legal_success',
  'legal_terms',
  'life_counter_initial',
  'login_empty',
  'messages_inbox',
  'notifications',
  'onboarding_core_flow',
  'plans_success',
  'post_game_empty',
  'profile_success',
  'register_consent_accepted',
  'register_consent_error',
  'register_consent_unchecked',
  'register_empty',
  'reset_password_invalid_link',
  'set_detail_tst',
  'sets_catalog',
  'sets_catalog_route',
  'splash_boot',
  'trade_create',
  'trade_detail_unavailable',
  'trades_inbox',
  'upgrade_success',
  'user_profile_success',
  'user_search_empty',
  'user_search_results',
  'verify_email_signed_out',
];

List<String> get _focusedProofCheckpoints {
  if (_auditCheckpoint == 'card_search_printing_picker') {
    return const <String>[
      'card_search_printing_picker',
      'card_search_printing_selected',
    ];
  }
  if (_auditCheckpoint.isNotEmpty) return <String>[_auditCheckpoint];
  return switch (_auditSegment) {
    'catalog' => <String>[
      'post_game_empty',
      'deck_generate_empty',
      'deck_import_detected',
      'collection_empty',
      'sets_catalog',
      'sets_catalog_route',
      'latest_set',
      'set_detail_tst',
      'card_detail_success',
      'card_detail_error',
      'community_public_decks',
      'community_tab_1',
      'community_tab_2',
      'community_tab_3',
    ],
    'community' => <String>[
      'user_search_empty',
      'user_search_results',
      'user_profile_success',
      'community_deck_success',
    ],
    'ux_pack_01_completion' => <String>[
      'sample_hand_drawn',
      'optimize_card_reader',
      'binder_physical_identity',
      'binder_editor_identity',
      'binder_add_editor_identity',
      'marketplace_physical_identity',
      'trade_create_requested_identity',
      'trade_create_offered_identity',
      'trade_detail_items_identity',
    ],
    _ => const <String>[],
  };
}

bool get _capturesBoot =>
    _auditSegment == 'all' || _auditSegment == 'auth_home';

bool get _runsAuthHome =>
    _auditSegment == 'auth_home' ||
    (_auditSegment == 'all' && _auditResumeFrom.isEmpty);

bool get _runsDeckList =>
    _auditSegment == 'decks' ||
    _auditSegment == 'deck_list' ||
    (_auditSegment == 'all' && _auditResumeFrom.isEmpty);

bool get _runsDeckDetail =>
    _auditSegment == 'decks' ||
    _auditSegment == 'deck_detail' ||
    (_auditSegment == 'all' && _auditResumeFrom.isEmpty);

bool get _runsCatalog =>
    _auditSegment == 'catalog' ||
    (_auditSegment == 'all' && _auditResumeFrom != 'social');

bool get _runsCommunity =>
    _auditSegment == 'community' ||
    _auditSegment == 'social' ||
    _auditSegment == 'all';

bool get _runsProfileBattle =>
    _auditSegment == 'profile_battle' ||
    _auditSegment == 'social' ||
    _auditSegment == 'all';

bool get _runsTradesCommercial =>
    _auditSegment == 'trades_commercial' ||
    _auditSegment == 'social' ||
    _auditSegment == 'all';

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
      _supportedAuditSegments,
      contains(_auditSegment),
      reason:
          'MANALOOM_VISUAL_SEGMENT must be all, auth_home, decks, '
          'deck_list, deck_detail, catalog, social, community, '
          'profile_battle, trades_commercial or ux_pack_01_completion.',
    );
    expect(
      _interactiveBattleEnabled,
      isTrue,
      reason:
          'The P0 live matrix must compile the gated Battle Coach route so '
          'its welcome state and real Web focus can be audited.',
    );
    final proofCheckpoints = _auditSegment == 'all'
        ? _p0ProofCheckpoints
        : _focusedProofCheckpoints;
    if (_auditSegment == 'all' || proofCheckpoints.isNotEmpty) {
      expect(
        _uiSourceDigest,
        matches(RegExp(r'^[0-9a-f]{64}$')),
        reason: 'Runtime proof must be bound to the current UI digest.',
      );
      expect(_uiProofProfile, isNotEmpty);
      expect(const {
        'android_emulator',
        'android_physical',
        'web_real_build',
      }, contains(_uiProofTarget));
      expect(_uiProofDeviceContract, isNotEmpty);
      // Consumed by tool/ui_runtime_evidence.dart before existing PNGs can be
      // indexed into a current manifest.
      // ignore: avoid_print
      print(
        'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': _auditSegment == 'all' ? 'authenticated_p0_matrix' : 'authenticated_${_auditSegment}_ux_audit', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': proofCheckpoints})}',
      );
    }
    expect(
      _auditCheckpoint.isEmpty ||
          (_auditSegment == 'deck_detail' &&
              _supportedIsolatedCheckpoints.contains(_auditCheckpoint)),
      isTrue,
      reason:
          'MANALOOM_VISUAL_CHECKPOINT is only supported with the deck_detail '
          'segment and must identify one of its five runtime checkpoints.',
    );
    if (_auditSegment == 'ux_pack_01_completion') {
      expect(
        <String>[
          _auditBinderItemId,
          _auditPeerBinderItemId,
          _auditTradeId,
          _auditFixtureImageUrl,
        ],
        everyElement(isNotEmpty),
        reason:
            'UX-PACK-01 runtime proof requires the disposable binder, trade '
            'and local image fixture ids.',
      );
    }
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
    if (_capturesBoot) {
      await _capture(binding, tester, 'splash_boot');
    }
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
    if (_capturesBoot) {
      await _capture(binding, tester, 'login_empty');
    }

    if (_runsAuthHome) {
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
    if (_runsAuthHome) {
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
    }

    if (_auditSegment == 'auth_home') return;

    if (_auditSegment == 'ux_pack_01_completion') {
      await _runUxPack01Completion(binding, tester);
      return;
    }

    if (_runsDeckList) {
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
      await pumpUntilAbsent(
        tester,
        find.byKey(const Key('deck-create-dialog')),
      );
    }

    if (_auditSegment == 'deck_list') return;

    if (_runsDeckDetail) {
      final runsDeckOverview =
          _auditCheckpoint.isEmpty ||
          _auditCheckpoint == 'deck_detail_top' ||
          _auditCheckpoint == 'deck_detail_below_fold';
      if (runsDeckOverview) {
        await _goRoute(tester, '/decks/$_auditDeckId');
        await pumpUntilFound(
          tester,
          find.byKey(const Key('deck-overview-hero')),
          attempts: 120,
        );
        await tester.pump(const Duration(seconds: 1));
        if (_auditCheckpoint != 'deck_detail_below_fold') {
          await _captureDeckDetailRuntimeCheckpoint(
            binding,
            tester,
            'deck_detail_top',
          );
          if (_auditCheckpoint == 'deck_detail_top') return;
        }
        if (!kIsWeb &&
            _nativeDeckDetailCapture &&
            _auditCheckpoint == 'deck_detail_below_fold') {
          // The physical-device renderer can ANR when WidgetTester traverses
          // this complex sliver tree during a synthetic jump. Give the host
          // runner a bounded window to perform a real Android swipe before
          // the framebuffer checkpoint is announced.
          // ignore: avoid_print
          print('NATIVE_SCROLL_READY deck_detail_below_fold');
          await Future<void>.delayed(const Duration(seconds: 5));
          await tester.pump();
        } else {
          final deckOverviewMoved = await _scrollVerticalParentBy(
            tester,
            find.byKey(const Key('deck-overview-hero')),
            560,
          );
          expect(
            deckOverviewMoved,
            isTrue,
            reason:
                'Deck details must expose distinct content below the first '
                'viewport.',
          );
        }
        await _captureDeckDetailRuntimeCheckpoint(
          binding,
          tester,
          'deck_detail_below_fold',
        );
        if (_auditCheckpoint == 'deck_detail_below_fold') return;
      }

      final runsCardSearch =
          _auditCheckpoint.isEmpty ||
          _auditCheckpoint == 'card_search_empty' ||
          _auditCheckpoint == 'card_search_results' ||
          _auditCheckpoint == 'card_search_printing_picker';
      if (runsCardSearch) {
        await _goRoute(tester, '/decks/$_auditDeckId/search');
        await pumpUntilFound(
          tester,
          find.byKey(const Key('card-search-field')),
        );
        if (_auditCheckpoint != 'card_search_results' &&
            _auditCheckpoint != 'card_search_printing_picker') {
          await _captureDeckDetailRuntimeCheckpoint(
            binding,
            tester,
            'card_search_empty',
          );
          if (_auditCheckpoint == 'card_search_empty') return;
        }
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
        if (_auditCheckpoint != 'card_search_printing_picker') {
          await _captureDeckDetailRuntimeCheckpoint(
            binding,
            tester,
            'card_search_results',
          );
          if (_auditCheckpoint == 'card_search_results') return;
        }
        if (_auditCheckpoint == 'card_search_printing_picker') {
          await tester.tap(find.byTooltip('Escolher impressão'));
          await pumpUntilFound(
            tester,
            find.byKey(const Key('card-printing-picker-options')),
            attempts: 120,
          );
          final confirmation = find.byKey(
            const Key('card-printing-picker-confirm'),
          );
          expect(confirmation, findsOneWidget);
          expect(
            tester.getRect(confirmation).bottom,
            lessThanOrEqualTo(_auditHeight.toDouble()),
          );
          await _captureDeckDetailRuntimeCheckpoint(
            binding,
            tester,
            'card_search_printing_picker',
          );
          await tester.tap(find.byType(CardPrintingOptionTile).last);
          await tester.pumpAndSettle();
          expect(find.text('T2S #777 selecionada'), findsOneWidget);
          expect(
            tester.widget<FilledButton>(confirmation).onPressed,
            isNotNull,
          );
          await _captureDeckDetailRuntimeCheckpoint(
            binding,
            tester,
            'card_search_printing_selected',
          );
          return;
        }
      }
    }

    if (_auditSegment == 'decks' || _auditSegment == 'deck_detail') return;

    if (_runsCatalog) {
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
      await _prepareDeckImportDetectedState(tester);
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
      await _capture(binding, tester, 'community_public_decks');

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

    if (_auditSegment == 'catalog') return;
    if (!_runsCommunity && !_runsProfileBattle && !_runsTradesCommercial) {
      return;
    }

    if (_runsCommunity) {
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
    }

    if (_auditSegment == 'community') return;

    if (_runsProfileBattle) {
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

      // A build without Live support must not register/navigate to the
      // spectator route. Prove the safe Replays surface has no Live jobs strip
      // instead of depending on the obsolete in-route disabled placeholder.
      await _goRoute(tester, '/decks/$_auditDeckId/battle-replays');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-replays-empty-state')),
      );
      expect(find.byKey(const Key('battle-live-jobs-strip')), findsNothing);
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
    }

    if (_auditSegment == 'profile_battle') return;

    if (_runsTradesCommercial) {
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
      await pumpUntilFound(
        tester,
        find.byKey(const Key('beta-free-access-panel')),
      );
      expect(find.byKey(const Key('upgrade-beta-notice')), findsNothing);
      await _capture(binding, tester, 'upgrade_success');

      await _goRoute(tester, '/checkout');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('beta-free-access-panel')),
      );
      expect(find.byKey(const Key('checkout-beta-notice')), findsNothing);
      await _capture(binding, tester, 'checkout_success');

      await _goRoute(tester, '/legal');
      await pumpUntilFound(tester, find.byKey(const Key('legal-content')));
      await _capture(binding, tester, 'legal_success');
    }
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
  await captureRuntimeCheckpoint(
    binding,
    tester,
    name,
    beforeTakeScreenshot: () async {
      // A real Web release build can require more than one raster frame after
      // convertFlutterSurfaceToImage. Without this, the first host PNG can be
      // structurally valid but nearly black while later checkpoints are fine.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    },
  );
  await _assertClean(tester, name);
}

Future<void> _captureDeckDetailRuntimeCheckpoint(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (!kIsWeb && _nativeDeckDetailCapture) {
    // Flutter's screenshot API replaces Android's live rendering surface with
    // an ImageView. Restore the live surface before every host-side screencap;
    // otherwise a later route can be recorded with the previous checkpoint's
    // pixels even while the widget tree is already correct.
    await restoreVisualCaptureSurface();
    await tester.pump(const Duration(milliseconds: 500));
    // Announce a bounded host-side adb screencap window so the proof uses the
    // actual Android framebuffer instead of timing out or accepting no image.
    // ignore: avoid_print
    print('NATIVE_SCREENSHOT_READY $name');
    await Future<void>.delayed(const Duration(seconds: 8));
    await tester.pump();
    // ignore: avoid_print
    print('NATIVE_SCREENSHOT_WINDOW_CLOSED $name');
    await _assertClean(tester, name);
    return;
  }
  await _capture(binding, tester, name);
}

Future<void> _runUxPack01Completion(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  await _goRoute(tester, '/decks/$_auditDeckId');
  await pumpUntilFound(
    tester,
    find.byKey(const Key('deck-overview-hero')),
    attempts: 120,
  );
  // The Overview keeps the playtest below its diagnostics. Exercise that
  // discoverable copy instead of depending on TabBarView offstage ordering.
  final drawHand = find.byKey(const Key('sample-hand-draw')).first;
  await pumpUntilFound(tester, drawHand);
  await tester.ensureVisible(drawHand);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(drawHand);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('sample-hand-focused-printing')),
  );
  // The draw expands below the original viewport. Frame the complete decision
  // flow so the governed capture proves both the exact art and Keep/Mulligan,
  // instead of preserving the pre-draw scroll offset and cutting the actions.
  final keepHand = find.byKey(const Key('sample-hand-keep'));
  await pumpUntilFound(tester, keepHand);
  await tester.ensureVisible(keepHand);
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'sample_hand_drawn');

  final deckContext = tester.element(
    find.byKey(const Key('sample-hand-focused-printing')),
  );
  unawaited(
    showOptimizationPreviewDialog(
      deckContext,
      mode: 'optimize',
      archetype: 'Controle de artefatos',
      keepTheme: true,
      preservedTheme: 'valor e interação',
      reasoning:
          'A troca preserva o plano do deck e torna a aceleração mais estável.',
      intensity: OptimizeIntensity.focused,
      optimizeIntensity: const <String, dynamic>{
        'label': 'Equilibrado',
        'target_swaps': <String, int>{'min': 1, 'max': 3},
      },
      qualityWarning: null,
      deckAnalysis: const <String, dynamic>{
        'average_cmc': 3.2,
        'total_cards': 100,
      },
      postAnalysis: const <String, dynamic>{
        'average_cmc': 3.1,
        'total_cards': 100,
      },
      warnings: const <String, dynamic>{},
      metaReferenceContext: const <String, dynamic>{
        'label': 'Fixture UX isolada',
      },
      displayRemovals: const <Map<String, dynamic>>[
        <String, dynamic>{
          'card_id': 'visual-removal-wastes',
          'name': 'Wastes',
          'quantity': 1,
          'reason': 'Abrir um espaço sem alterar a identidade de cor.',
          'set_code': 'TST',
          'collector_number': '184',
          'set_name': 'S3-07 Visual Fixture Set',
          'set_release_date': '2026-07-21',
          'rarity': 'common',
        },
      ],
      displayAdditions: <Map<String, dynamic>>[
        <String, dynamic>{
          'card_id': _auditCardId,
          'name': 'Sol Ring',
          'quantity': 1,
          'reason': 'Aceleração reconhecível e verificável antes de aplicar.',
          'set_code': 'TST',
          'collector_number': '001',
          'set_name': 'S3-07 Visual Fixture Set',
          'set_release_date': '2026-07-21',
          'rarity': 'uncommon',
          'image_url': _auditFixtureImageUrl,
        },
      ],
      loadCard: (_) async => DeckCardItem(
        id: _auditCardId,
        name: 'Sol Ring',
        manaCost: '{1}',
        typeLine: 'Artifact',
        oracleText: '{T}: Add {C}{C}.',
        imageUrl: _auditFixtureImageUrl,
        setCode: 'TST',
        setName: 'S3-07 Visual Fixture Set',
        setReleaseDate: '2026-07-21',
        rarity: 'uncommon',
        quantity: 1,
        isCommander: false,
        collectorNumber: '001',
      ),
    ),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const Key('optimize-preview-dialog')),
  );
  final readerButton = find.byKey(
    const Key('optimize-suggestion-add-0-preview-button'),
  );
  await tester.ensureVisible(readerButton);
  await tester.tap(readerButton);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('recommendation-reader-card-artwork')),
  );
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'optimize_card_reader');
  await tester.tap(find.byTooltip('Fechar').last);
  await tester.pumpAndSettle();
  Navigator.of(
    tester.element(find.byKey(const Key('optimize-preview-dialog'))),
    rootNavigator: true,
  ).pop();
  await tester.pumpAndSettle();

  await _goRoute(tester, '/collection?tab=0');
  final binderCard = find.byKey(Key('binder-item-card-$_auditBinderItemId'));
  await pumpUntilFound(tester, binderCard, attempts: 120);
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'binder_physical_identity');
  await tester.tap(binderCard);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('binder-editor-save-button')),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await _capture(binding, tester, 'binder_editor_identity');
  Navigator.of(
    tester.element(find.byKey(const Key('binder-editor-save-button'))),
    rootNavigator: true,
  ).pop();
  await tester.pumpAndSettle();

  final addBinderCard = find.byKey(const Key('binder-add-card-action'));
  await pumpUntilFound(tester, addBinderCard);
  await tester.ensureVisible(addBinderCard);
  await tester.tap(addBinderCard);
  final binderSearchField = find.byKey(const Key('card-search-field'));
  await pumpUntilFound(tester, binderSearchField, attempts: 120);
  await _enterTextField(tester, binderSearchField, 'Sol Ring');
  final binderSearchResult = find.byKey(
    Key('card-search-result-$_auditCardId'),
  );
  await pumpUntilFound(tester, binderSearchResult, attempts: 120);
  final addExactPrinting = find.byKey(Key('card-search-add-$_auditCardId'));
  await tester.ensureVisible(addExactPrinting);
  await tester.tap(addExactPrinting);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('binder-editor-save-button')),
    attempts: 120,
  );
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'binder_add_editor_identity');
  Navigator.of(
    tester.element(find.byKey(const Key('binder-editor-save-button'))),
    rootNavigator: true,
  ).pop();
  await tester.pumpAndSettle();

  await _goRoute(tester, '/collection?tab=1');
  final marketCard = find.byKey(
    Key('marketplace-item-card-$_auditPeerBinderItemId'),
  );
  await pumpUntilFound(tester, marketCard, attempts: 120);
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'marketplace_physical_identity');

  await _goRoute(tester, '/trades/create/$_auditPeerUserId');
  await pumpUntilFound(
    tester,
    find.byKey(const Key('create-trade-content')),
    attempts: 120,
  );
  final addRequested = find.byKey(const Key('create-trade-add-item-requested'));
  await tester.ensureVisible(addRequested);
  await tester.tap(addRequested);
  await pumpUntilFound(tester, find.text('Itens do outro jogador'));
  await tester.tap(find.text('Sol Ring').last);
  final requestedCard = find.byKey(
    const Key('create-trade-selected-item-requested-0'),
  );
  await pumpUntilFound(tester, requestedCard);
  await tester.ensureVisible(requestedCard);
  await tester.pump(const Duration(milliseconds: 500));
  await _capture(binding, tester, 'trade_create_requested_identity');

  final addOffered = find.byKey(const Key('create-trade-add-item-offered'));
  await tester.ensureVisible(addOffered);
  await tester.tap(addOffered);
  await pumpUntilFound(tester, find.text('Meus itens para oferecer'));
  await tester.tap(find.text('Sol Ring').last);
  final offeredCard = find.byKey(
    const Key('create-trade-selected-item-offered-0'),
  );
  await pumpUntilFound(tester, offeredCard);
  await tester.ensureVisible(offeredCard);
  await tester.pump(const Duration(milliseconds: 500));
  await _capture(binding, tester, 'trade_create_offered_identity');

  await _goRoute(tester, '/trades/$_auditTradeId');
  final tradeItems = find.byKey(const Key('trade-detail-outgoing-items'));
  await pumpUntilFound(tester, tradeItems, attempts: 120);
  await tester.ensureVisible(tradeItems);
  await tester.pump(const Duration(milliseconds: 750));
  await _capture(binding, tester, 'trade_detail_items_identity');
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

Future<void> _prepareDeckImportDetectedState(WidgetTester tester) async {
  const importedList = '1 Sol Ring';
  const detectedLabel = '1 carta detectada';
  final listField = find.byKey(const Key('deck-import-screen-list-field'));
  final countStatus = find.byKey(const Key('deck-import-screen-count-status'));
  final detectedText = find.descendant(
    of: countStatus,
    matching: find.text(detectedLabel),
  );

  // TextInput emulation can focus the real field without committing text on
  // every host/device combination. Drive the same controller-backed path used
  // by the other governed checkpoints and fail before capture if the promised
  // state is not actually present in the widget tree.
  await _enterTextField(tester, listField, importedList);
  await pumpUntil(
    tester,
    () {
      final field = tester.widget<TextField>(listField);
      return field.controller?.text == importedList &&
          finderExists(detectedText);
    },
    description: 'the deck import text and detected-card status',
    attempts: 20,
    step: const Duration(milliseconds: 100),
  );

  await tester.ensureVisible(countStatus);
  await tester.pump(const Duration(milliseconds: 300));

  final field = tester.widget<TextField>(listField);
  expect(
    field.controller?.text,
    importedList,
    reason: 'deck_import_detected must visibly retain the imported list',
  );
  expect(
    detectedText,
    findsOneWidget,
    reason: 'deck_import_detected must prove the detected-card count',
  );
  final viewportHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final statusRect = tester.getRect(countStatus);
  expect(statusRect.top, greaterThanOrEqualTo(0));
  expect(
    statusRect.bottom,
    lessThanOrEqualTo(viewportHeight),
    reason: 'the detected-card status must be inside the captured viewport',
  );
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
