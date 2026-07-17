import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/auth/screens/register_screen.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/screens/checkout_screen.dart';
import 'package:manaloom/features/commercial/screens/legal_screen.dart';
import 'package:manaloom/features/commercial/screens/plan_screen.dart';
import 'package:manaloom/features/commercial/screens/upgrade_screen.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_gate.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_player_counter_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/profile/profile_screen.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Directory? _pathProviderTestTempDir;
var _sqfliteFfiInitialized = false;

void main() {
  setUp(() {
    _installPathProviderMock();
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    final tempDir = _pathProviderTestTempDir;
    if (tempDir != null && tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  patrolTest('auth login validates fields and reaches plans after success', (
    $,
  ) async {
    await _pumpProductApp($, initialLocation: '/login');

    expect($('ManaLoom'), findsOneWidget);

    await $(find.byKey(const Key('login-submit-button'))).tap();
    expect($('Digite seu email'), findsOneWidget);

    await $(
      find.byKey(const Key('login-email-field')),
    ).enterText('qa_user@example.com');
    await $(
      find.byKey(const Key('login-password-field')),
    ).enterText('Password123!');
    await $(find.byKey(const Key('login-submit-button'))).tap();

    await _expectTextEventually($, 'Beta gratuita');
    expect($(find.byKey(const Key('ai-usage-meter'))), findsOneWidget);
  });

  patrolTest('auth register validates mismatch and accepts corrected form', (
    $,
  ) async {
    await _pumpProductApp($, initialLocation: '/login');

    await $(find.byKey(const Key('login-open-register-button'))).tap();
    await _expectTextEventually($, 'Criar conta');
    expect($(find.byKey(const Key('register-submit-button'))), findsOneWidget);

    await $(
      find.byKey(const Key('register-username-field')),
    ).enterText('qa_register_user');
    await $(
      find.byKey(const Key('register-email-field')),
    ).enterText('qa_register_user@example.com');
    await $(
      find.byKey(const Key('register-password-field')),
    ).enterText('Password123!');
    await $(
      find.byKey(const Key('register-confirm-password-field')),
    ).enterText('Password124!');
    await _ensureVisibleAndTap($, const Key('register-submit-button'));
    expect($('Senhas não correspondem'), findsOneWidget);

    await $.tester.enterText(
      find.byKey(const Key('register-confirm-password-field')),
      'Password123!',
    );
    await $.pumpAndSettle();
    await _ensureVisibleAndTap($, const Key('register-submit-button'));
    await $.pumpAndSettle();
    if (kIsWeb) {
      // Patrol Web executa o submit corrigido, mas a assercao de rota pos-auth
      // fica instavel nesse runner. O runner local cobre a navegacao para /home.
      return;
    }

    await _expectTextEventually(
      $,
      'Beta gratuita',
      timeout: const Duration(seconds: 10),
    );
  });

  patrolTest(
    'commercial beta reports the AI limit without exposing a purchase route',
    ($) async {
      await _pumpProductApp(
        $,
        initialLocation: '/paywall-probe',
        initialPreferences: {
          'manaloom.commercial.plan': ManaLoomPlanTier.free.id,
          'manaloom.commercial.ai_usage_period': '2026-07',
          'manaloom.commercial.ai_usage_count': 120,
        },
      );

      await $(find.byKey(const Key('patrol-open-ai-paywall-button'))).tap();

      expect($(find.byKey(const Key('ai-paywall-dialog'))), findsOneWidget);
      expect($('Otimizar deck: limite da beta atingido'), findsOneWidget);
      expect(
        $(find.byKey(const Key('ai-paywall-upgrade-button'))),
        findsNothing,
      );

      await $(find.byKey(const Key('ai-beta-limit-dismiss-button'))).tap();

      expect($(find.byKey(const Key('ai-paywall-dialog'))), findsNothing);
    },
  );

  patrolTest('commercial beta keeps plan, upgrade and checkout routes honest', (
    $,
  ) async {
    await _pumpProductApp($, initialLocation: '/plans');

    expect($('Beta gratuita'), findsWidgets);
    expect($(find.byKey(const Key('beta-free-access-panel'))), findsOneWidget);
    expect($(find.byKey(const Key('plan-card-pro'))), findsNothing);

    await _scrollUntilVisibleAndTap($, const Key('plans-open-legal-button'));
    expect($('Termos de uso'), findsOneWidget);
    expect($('Disclaimer de IA'), findsOneWidget);
    expect($('Trocas entre usuários'), findsOneWidget);

    await _goTo($, '/upgrade');
    expect($(find.byKey(const Key('upgrade-beta-notice'))), findsOneWidget);
    expect(
      $(find.byKey(const Key('upgrade-start-checkout-button'))),
      findsNothing,
    );

    await _goTo($, '/checkout');
    expect($(find.byKey(const Key('checkout-beta-notice'))), findsOneWidget);
    expect($(find.byKey(const Key('checkout-confirm-button'))), findsNothing);
  });

  patrolTest('deckbuilder async generation previews and saves generated deck', (
    $,
  ) async {
    await _pumpDeckBuilderPatrolApp($);

    expect($('Gerar Deck'), findsOneWidget);

    await _enterVisibleText(
      $,
      const Key('deck-generate-commander-field'),
      'Talrand, Sky Summoner',
    );
    await _enterVisibleText(
      $,
      const Key('deck-generate-prompt-field'),
      'Deck Commander mono azul spellslinger com counters, cantrips e Drakes.',
    );
    await $(find.byKey(const Key('deck-generate-submit-button'))).tap();

    await _expectTextEventually(
      $,
      'Preview antes de salvar',
      timeout: const Duration(seconds: 12),
    );
    expect($('Talrand, Sky Summoner'), findsWidgets);

    await _enterVisibleText(
      $,
      const Key('deck-generate-name-field'),
      'Patrol Talrand Async',
    );
    await _scrollUntilVisibleAndTap($, const Key('deck-generate-save-button'));

    await _expectTextEventually(
      $,
      'Patrol Talrand Async',
      timeout: const Duration(seconds: 8),
    );
    expect($('100 cartas'), findsWidgets);
  });

  patrolTest('binder editor saves sale metadata and confirms deletion', (
    $,
  ) async {
    Map<String, dynamic>? savedData;
    var deleted = false;
    final item = BinderItem(
      id: 'binder-command-tower',
      cardId: 'card-command-tower',
      cardName: 'Command Tower',
      quantity: 1,
      condition: 'NM',
      forTrade: false,
      forSale: false,
      language: 'en',
      listType: 'have',
    );

    await $.pumpWidgetAndSettle(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('patrol-open-binder-editor-button'),
              onPressed: () {
                BinderItemEditor.show(
                  $.tester.element(
                    find.byKey(const Key('patrol-open-binder-editor-button')),
                  ),
                  item: item,
                  onSave: (data) async {
                    savedData = Map<String, dynamic>.from(data);
                    return true;
                  },
                  onDelete: () async {
                    deleted = true;
                    return true;
                  },
                );
              },
              child: const Text('Open binder editor'),
            ),
          ),
        ),
      ),
    );

    await $(find.byKey(const Key('patrol-open-binder-editor-button'))).tap();
    await _expectTextEventually($, 'Editar — Command Tower');
    await _scrollUntilVisibleAndTap(
      $,
      const Key('binder-editor-quantity-increment'),
    );
    await _scrollUntilVisibleAndTap($, const Key('binder-editor-condition-LP'));
    await _scrollUntilVisibleAndTap($, const Key('binder-editor-language-es'));
    await _scrollUntilVisibleAndTap(
      $,
      const Key('binder-editor-for-sale-switch'),
    );
    await _enterVisibleText($, const Key('binder-editor-price-field'), '4.56');
    await _enterVisibleText(
      $,
      const Key('binder-editor-notes-field'),
      'Patrol sale metadata',
    );
    await _scrollUntilVisibleAndTap($, const Key('binder-editor-save-button'));
    await $.pumpAndSettle();

    expect(savedData, isNotNull);
    expect(savedData!['quantity'], 2);
    expect(savedData!['condition'], 'LP');
    expect(savedData!['language'], 'es');
    expect(savedData!['for_sale'], isTrue);
    expect(savedData!['price'], 4.56);
    expect(savedData!['notes'], 'Patrol sale metadata');

    await $(find.byKey(const Key('patrol-open-binder-editor-button'))).tap();
    await _expectTextEventually($, 'Editar — Command Tower');
    await _scrollUntilVisibleAndTap(
      $,
      const Key('binder-editor-remove-button'),
    );
    await _expectTextEventually($, 'Remover do Fichário?');
    await $(find.widgetWithText(TextButton, 'Remover')).tap();
    await $.pumpAndSettle();

    expect(deleted, isTrue);
  });

  patrolTest('profile refreshes, updates and opens commercial route', (
    $,
  ) async {
    final authProvider = await _pumpProfilePatrolApp($);

    await _expectTextEventually($, 'Perfil');
    await _expectTextEventually($, 'Patrol Profile');

    await _enterVisibleText(
      $,
      const Key('profile-display-name-field'),
      'Patrol Edited',
    );
    await _enterVisibleText($, const Key('profile-city-field'), 'Sao Paulo');
    await _enterVisibleText(
      $,
      const Key('profile-trade-notes-field'),
      'Trocas em loja local.',
    );
    await _scrollUntilVisibleAndTap($, const Key('profile-save-button'));

    await _expectTextEventually($, 'Perfil atualizado');
    expect(authProvider.user?.displayName, 'Patrol Edited');
    expect(authProvider.user?.locationCity, 'Sao Paulo');
    expect(authProvider.user?.tradeNotes, 'Trocas em loja local.');

    await _scrollUntilVisibleAndTap($, const Key('profile-open-plans-button'));
    await _expectTextEventually($, 'Beta gratuita');
  });

  patrolTest('life counter native player counter applies poison changes', (
    $,
  ) async {
    LifeCounterSession? appliedSession;
    const initialSession = LifeCounterSession(
      playerCount: 4,
      startingLifeTwoPlayer: 20,
      startingLifeMultiPlayer: 40,
      lives: [40, 32, 25, 11],
      poison: [0, 0, 0, 0],
      energy: [0, 0, 0, 0],
      experience: [0, 0, 0, 0],
      commanderCasts: [0, 0, 0, 0],
      partnerCommanders: [false, false, false, false],
      playerSpecialStates: [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
      ],
      lastPlayerRolls: [null, null, null, null],
      lastHighRolls: [null, null, null, null],
      commanderDamage: [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ],
      stormCount: 0,
      monarchPlayer: null,
      initiativePlayer: null,
      firstPlayerIndex: null,
      turnTrackerActive: false,
      turnTrackerOngoingGame: false,
      turnTrackerAutoHighRoll: false,
      currentTurnPlayerIndex: null,
      currentTurnNumber: 1,
      turnTimerActive: false,
      turnTimerSeconds: 0,
      lastTableEvent: null,
    );

    await $.pumpWidgetAndSettle(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('patrol-open-player-counter-button'),
                  onPressed: () async {
                    appliedSession =
                        await showLifeCounterNativePlayerCounterSheet(
                          context,
                          initialSession: initialSession,
                          initialTargetPlayerIndex: 0,
                          counterKey: 'poison',
                        );
                  },
                  child: const Text('Open player counter'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await $(find.byKey(const Key('patrol-open-player-counter-button'))).tap();
    await _expectTextEventually($, 'Marcadores do jogador');
    await _scrollUntilVisible(
      $,
      const Key('life-counter-native-player-counter-value'),
    );

    Text currentCounterValue() {
      return $.tester.widget<Text>(
        find.byKey(const Key('life-counter-native-player-counter-value')),
      );
    }

    expect(currentCounterValue().data, '0');
    await _scrollUntilVisible(
      $,
      const Key('life-counter-native-player-counter-plus'),
    );
    await $(
      find.byKey(const Key('life-counter-native-player-counter-plus')),
    ).tap();
    expect(currentCounterValue().data, '1');
    await _scrollUntilVisible(
      $,
      const Key('life-counter-native-player-counter-apply'),
    );
    await $(
      find.byKey(const Key('life-counter-native-player-counter-apply')),
    ).tap();
    await $.pumpAndSettle();

    expect(appliedSession, isNotNull);
    expect(appliedSession!.poison[0], 1);
  });

  patrolTest('battle replay renders visual board with hand and battlefield', (
    $,
  ) async {
    await $.pumpWidgetAndSettle(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(
          deckId: 'deck-visual',
          gateway: _PatrolBattleReplayGateway(),
        ),
      ),
    );

    await _expectTextEventually($, 'Battle contra Atraxa Superfriends');
    await $(find.text('Battle contra Atraxa Superfriends')).tap();
    await $.pumpAndSettle();

    expect(
      $(find.byKey(const Key('battle-replay-visual-viewer'))),
      findsOneWidget,
    );
    expect($('Player A casts Arcane Signet'), findsOneWidget);
    expect(
      $(find.byKey(const Key('battle-visual-zone-hand-Player A'))),
      findsOneWidget,
    );
    expect(
      $(find.byKey(const Key('battle-visual-card-Arcane Signet'))),
      findsOneWidget,
    );
  });
}

void _installPathProviderMock() {
  // sqflite_common_ffi is a VM-only test backend. Patrol Web runs this same
  // suite in Chromium, where initializing it throws before the requested test
  // can start. The web flows below use in-memory providers and the fake API,
  // so they do not need an SQLite or path_provider override.
  if (kIsWeb) {
    return;
  }

  if (!_sqfliteFfiInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _sqfliteFfiInitialized = true;
  }
  final tempDir =
      _pathProviderTestTempDir ??= Directory.systemTemp.createTempSync(
        'manaloom_patrol_path_provider_',
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          return switch (call.method) {
            'getTemporaryDirectory' => tempDir.path,
            'getApplicationSupportDirectory' => tempDir.path,
            'getApplicationDocumentsDirectory' => tempDir.path,
            _ => tempDir.path,
          };
        },
      );
}

Future<void> _pumpProductApp(
  PatrolIntegrationTester $, {
  required String initialLocation,
  Map<String, Object> initialPreferences = const {},
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(initialPreferences);
  // ignore: invalid_use_of_visible_for_testing_member
  ApiClient.resetForTesting(token: null, performanceUnavailable: true);

  final apiClient = _PatrolProductApiClient();
  final authProvider = AuthProvider(apiClient: apiClient);
  final commercialProvider = CommercialProvider(
    apiClient: apiClient,
    now: () => DateTime(2026, 7, 6),
  );
  await commercialProvider.load();

  late final GoRouter router;
  var redirectedAfterAuth = false;
  router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';
      if (authProvider.isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const PlanScreen()),
      GoRoute(path: '/plans', builder: (_, _) => const PlanScreen()),
      GoRoute(path: '/upgrade', builder: (_, _) => const UpgradeScreen()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/legal', builder: (_, _) => const CommercialLegalScreen()),
      GoRoute(
        path: '/paywall-probe',
        builder: (_, _) => const _PaywallProbeScreen(),
      ),
    ],
  );
  authProvider.addListener(() {
    if (!redirectedAfterAuth && authProvider.isAuthenticated) {
      redirectedAfterAuth = true;
      router.go('/home');
    }
  });

  await $.pumpWidgetAndSettle(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CommercialProvider>.value(
          value: commercialProvider,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );

  addTearDown(router.dispose);
  addTearDown(authProvider.dispose);
  addTearDown(commercialProvider.dispose);
}

Future<void> _pumpDeckBuilderPatrolApp(PatrolIntegrationTester $) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'manaloom.commercial.plan': ManaLoomPlanTier.free.id,
    'manaloom.commercial.ai_usage_period': '2026-07',
    'manaloom.commercial.ai_usage_count': 0,
  });
  // ignore: invalid_use_of_visible_for_testing_member
  ApiClient.resetForTesting(token: null, performanceUnavailable: true);

  final apiClient = _PatrolProductApiClient();
  final deckProvider = DeckProvider(
    apiClient: apiClient,
    trackActivationEvent:
        (
          String eventName, {
          String? format,
          String? deckId,
          String source = 'patrol',
          Map<String, dynamic>? metadata,
        }) async {},
  );
  final commercialProvider = CommercialProvider(
    apiClient: apiClient,
    now: () => DateTime(2026, 7, 6),
  );
  await commercialProvider.load();

  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/decks/generate',
    routes: [
      GoRoute(
        path: '/decks/generate',
        builder: (_, _) => const DeckGenerateScreen(),
      ),
      GoRoute(path: '/decks', builder: (_, _) => const _PatrolDeckListProbe()),
    ],
  );

  await $.pumpWidgetAndSettle(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
        ChangeNotifierProvider<CommercialProvider>.value(
          value: commercialProvider,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );

  addTearDown(router.dispose);
  addTearDown(deckProvider.dispose);
  addTearDown(commercialProvider.dispose);
}

Future<AuthProvider> _pumpProfilePatrolApp(PatrolIntegrationTester $) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'manaloom.commercial.plan': ManaLoomPlanTier.free.id,
    'manaloom.commercial.ai_usage_period': '2026-07',
    'manaloom.commercial.ai_usage_count': 3,
  });
  // ignore: invalid_use_of_visible_for_testing_member
  ApiClient.resetForTesting(token: null, performanceUnavailable: true);

  final apiClient = _PatrolProductApiClient();
  final authProvider = AuthProvider(apiClient: apiClient);
  final commercialProvider = CommercialProvider(
    apiClient: apiClient,
    now: () => DateTime(2026, 7, 6),
  );
  await commercialProvider.load();
  final loggedIn = await authProvider.login(
    'qa_user@example.com',
    'Password123!',
  );
  expect(loggedIn, isTrue);

  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/plans', builder: (_, _) => const PlanScreen()),
      GoRoute(path: '/legal', builder: (_, _) => const CommercialLegalScreen()),
      GoRoute(
        path: '/collection',
        builder: (_, _) => const Scaffold(body: Center(child: Text('Coleção'))),
      ),
      GoRoute(
        path: '/messages',
        builder:
            (_, _) => const Scaffold(body: Center(child: Text('Mensagens'))),
      ),
      GoRoute(
        path: '/notifications',
        builder:
            (_, _) => const Scaffold(body: Center(child: Text('Notificações'))),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    ],
  );

  await $.pumpWidgetAndSettle(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CommercialProvider>.value(
          value: commercialProvider,
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );

  addTearDown(router.dispose);
  addTearDown(authProvider.dispose);
  addTearDown(commercialProvider.dispose);

  return authProvider;
}

Future<void> _goTo(PatrolIntegrationTester $, String location) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await $.pumpAndSettle();
}

Future<void> _expectTextEventually(
  PatrolIntegrationTester $,
  String text, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    await $.tester.pump(const Duration(milliseconds: 100));
    if (find.text(text).evaluate().isNotEmpty) {
      expect($(text), findsWidgets);
      return;
    }
  }
  expect($(text), findsWidgets);
}

Future<void> _scrollUntilVisible(PatrolIntegrationTester $, Key key) async {
  final finder = find.byKey(key);
  await $.tester.scrollUntilVisible(
    finder,
    280,
    scrollable: find.byType(Scrollable).first,
  );
  await $.pumpAndSettle();
}

Future<void> _scrollUntilVisibleAndTap(
  PatrolIntegrationTester $,
  Key key,
) async {
  await _scrollUntilVisible($, key);
  await $(find.byKey(key)).tap();
}

Future<void> _ensureVisibleAndTap(PatrolIntegrationTester $, Key key) async {
  final finder = find.byKey(key);
  await $.tester.ensureVisible(finder);
  await $.pumpAndSettle();
  await $(finder).tap();
}

Future<void> _enterVisibleText(
  PatrolIntegrationTester $,
  Key key,
  String value,
) async {
  final finder = find.byKey(key);
  await $.tester.ensureVisible(finder);
  await $.pumpAndSettle();
  await $.tester.tap(finder, warnIfMissed: false);
  await $.tester.enterText(finder, value);
  await $.tester.testTextInput.receiveAction(TextInputAction.done);
  await $.pumpAndSettle();
}

class _PatrolDeckListProbe extends StatelessWidget {
  const _PatrolDeckListProbe();

  @override
  Widget build(BuildContext context) {
    final decks = context.watch<DeckProvider>().decks;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Decks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Meus Decks'),
          for (final deck in decks) ...[
            const SizedBox(height: 12),
            ListTile(
              title: Text(deck.name),
              subtitle: Text('${deck.cardCount} cartas'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaywallProbeScreen extends StatelessWidget {
  const _PaywallProbeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paywall Patrol')),
      body: Center(
        child: ElevatedButton(
          key: const Key('patrol-open-ai-paywall-button'),
          onPressed: () {
            reserveAiActionOrShowPaywall(
              context,
              kind: AiUsageKind.deckOptimization,
            );
          },
          child: const Text('Usar IA'),
        ),
      ),
    );
  }
}

class _PatrolBattleReplayGateway implements BattleReplayGateway {
  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async {
    return [
      BattleReplaySummary.fromJson(const {
        'id': 'patrol-replay-1',
        'deck_id': 'deck-visual',
        'type': 'battle',
        'opponent_name': 'Atraxa Superfriends',
        'winner_name': 'Player A',
        'turns_played': 1,
        'event_count': 1,
      }, fallbackDeckId: deckId),
    ];
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async {
    return BattleReplayDetail.fromJson(
      {
        'replay': {
          'id': replayId,
          'deck_id': deckId,
          'type': 'battle',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 1,
          'events': const [
            {
              'turn': 1,
              'player': 'Player A',
              'phase': 'main',
              'action': 'casts',
              'card': 'Arcane Signet',
            },
          ],
          'visual_snapshots': const [
            {
              'turn': 1,
              'phase': 'main',
              'action': 'casts',
              'active_player': 'Player A',
              'event': {
                'turn': 1,
                'player': 'Player A',
                'phase': 'main',
                'action': 'casts',
                'card': 'Arcane Signet',
              },
              'players': [
                {
                  'name': 'Player A',
                  'life': 40,
                  'mana': 1,
                  'hand': [
                    {
                      'id': 'arcane-signet',
                      'name': 'Arcane Signet',
                      'type_line': 'Artifact',
                    },
                  ],
                  'battlefield': [
                    {
                      'id': 'plains',
                      'name': 'Plains',
                      'type_line': 'Basic Land - Plains',
                    },
                  ],
                  'graveyard': [],
                  'library_size': 91,
                },
              ],
            },
          ],
        },
      },
      fallbackDeckId: deckId,
      fallbackId: replayId,
    );
  }

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) {
    throw UnimplementedError();
  }
}

class _PatrolProductApiClient extends ApiClient {
  final List<Map<String, dynamic>> _createdDecks = [];
  Map<String, dynamic> _profileUser = {
    'id': 'patrol-user-1',
    'username': 'qa_user',
    'email': 'qa_user@example.com',
    'display_name': 'Patrol Profile',
    'avatar_url': null,
    'location_state': 'SP',
    'location_city': 'Sao Paulo',
    'trade_notes': 'Trade notes from patrol fake API.',
  };

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/ai/generate') {
      if (body['async'] == true) {
        return ApiResponse(202, {
          'job_id': 'patrol-generate-job',
          'poll_url': '/ai/generate/jobs/patrol-generate-job',
          'status': 'accepted',
          'poll_interval_ms': 5000,
        });
      }
      return ApiResponse(200, _patrolGeneratedDeckPayload());
    }

    if (endpoint == '/decks') {
      final deck = {
        'id': 'patrol-generated-deck',
        'name': body['name']?.toString() ?? 'Patrol Generated Deck',
        'format': body['format']?.toString() ?? 'commander',
        'description': body['description']?.toString(),
        'archetype': body['archetype']?.toString(),
        'bracket': body['bracket'] as int? ?? 2,
        'synergy_score': 82,
        'strengths': 'Spellslinger engine with token payoff.',
        'weaknesses': 'Needs protection against sweepers.',
        'commander_name': 'Talrand, Sky Summoner',
        'commander_image_url': null,
        'pricing_currency': 'BRL',
        'pricing_total': 120.0,
        'pricing_missing_cards': 0,
        'pricing_updated_at': '2026-07-06T12:00:00.000Z',
        'is_public': false,
        'created_at': '2026-07-06T12:00:00.000Z',
        'card_count': 100,
        'color_identity': ['U'],
      };
      _createdDecks
        ..removeWhere((item) => item['id'] == deck['id'])
        ..insert(0, deck);
      return ApiResponse(201, deck);
    }

    if (endpoint == '/auth/register') {
      return ApiResponse(201, {
        'token': 'patrol-register-token',
        'user': {
          'id': 'patrol-user-2',
          'username': body['username']?.toString() ?? 'qa_register_user',
          'email': body['email']?.toString() ?? 'qa_register_user@example.com',
        },
      });
    }

    return switch (endpoint) {
      '/auth/login' => ApiResponse(200, {
        'token': 'patrol-login-token',
        'user': _profileUser,
      }),
      '/users/me/plan/checkout' => ApiResponse(403, {
        'checkout_status': 'beta_free_only',
        'beta_mode': true,
        'billing_enabled': false,
        'purchase_available': false,
        'message': 'A beta gratuita não aceita pagamentos.',
      }),
      '/cards/resolve/batch' => ApiResponse(200, {
        'data':
            ((body['names'] as List?) ?? const [])
                .map(
                  (name) => {
                    'input_name': name.toString(),
                    'card_id': 'card-${name.toString().toLowerCase()}',
                  },
                )
                .toList(),
        'unresolved': const [],
        'ambiguous': const [],
      }),
      _ => ApiResponse(404, {'error': 'unexpected patrol POST $endpoint'}),
    };
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/ai/generate/jobs/patrol-generate-job') {
      return ApiResponse(200, {
        'status': 'completed',
        'result_status_code': 200,
        'result': _patrolGeneratedDeckPayload(),
      });
    }

    return switch (endpoint) {
      '/ai/commander-learning' => ApiResponse(200, {'commanders': const []}),
      '/decks' => ApiResponse(
        200,
        List<Map<String, dynamic>>.from(_createdDecks),
      ),
      '/users/me' => ApiResponse(200, {'user': _profileUser}),
      '/users/me/plan' => ApiResponse(200, {
        'plan': {
          'plan_name': 'free',
          'ai_requests_used': 0,
          'ai_monthly_limit': 120,
        },
      }),
      _ => ApiResponse(404, {'error': 'unexpected patrol GET $endpoint'}),
    };
  }

  @override
  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == '/users/me') {
      _profileUser = {
        ..._profileUser,
        if (body.containsKey('display_name'))
          'display_name': body['display_name'],
        if (body.containsKey('avatar_url')) 'avatar_url': body['avatar_url'],
        if (body.containsKey('location_state'))
          'location_state': body['location_state'],
        if (body.containsKey('location_city'))
          'location_city': body['location_city'],
        if (body.containsKey('trade_notes')) 'trade_notes': body['trade_notes'],
      };
      return ApiResponse(200, {'user': _profileUser});
    }
    return ApiResponse(404, {'error': 'unexpected patrol PATCH $endpoint'});
  }

  Map<String, dynamic> _patrolGeneratedDeckPayload() {
    return {
      'generated_deck': {
        'name': 'Patrol Talrand Async',
        'format': 'commander',
        'archetype': 'spellslinger',
        'bracket': 2,
        'commander': {
          'name': 'Talrand, Sky Summoner',
          'card_id': 'card-talrand-sky-summoner',
        },
        'cards': const [
          {
            'name': 'Counterspell',
            'card_id': 'card-counterspell',
            'quantity': 1,
          },
          {'name': 'Ponder', 'card_id': 'card-ponder', 'quantity': 1},
          {'name': 'Preordain', 'card_id': 'card-preordain', 'quantity': 1},
          {
            'name': 'Arcane Signet',
            'card_id': 'card-arcane-signet',
            'quantity': 1,
          },
          {'name': 'Island', 'card_id': 'card-island', 'quantity': 35},
          {
            'name': "Talrand's Invocation",
            'card_id': 'card-talrands-invocation',
            'quantity': 1,
          },
        ],
      },
      'validation': {'is_valid': true, 'issues': const []},
      'diagnostics': {
        'reference_profile_used': true,
        'reference_card_stats_used': true,
        'on_theme_candidate_count': 42,
      },
      'warnings': {'invalid_cards': const []},
    };
  }
}
