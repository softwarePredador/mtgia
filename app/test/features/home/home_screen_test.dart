import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/widgets/card_artwork.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/home/home_screen.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/support/manaloom_ui_audit_harness.dart';

class _NoopApiClient extends ApiClient {}

class _IdleDeckProvider extends DeckProvider {
  _IdleDeckProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<void> fetchDecks({bool silent = false}) async {}
}

class _CountingDeckProvider extends _IdleDeckProvider {
  int fetchCalls = 0;

  @override
  Future<void> fetchDecks({bool silent = false}) async {
    fetchCalls += 1;
  }
}

class _SeededDeckProvider extends _IdleDeckProvider {
  _SeededDeckProvider(this.seededDecks);

  final List<Deck> seededDecks;

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(seededDecks);
}

class _RevisionDeckProvider extends _SeededDeckProvider {
  _RevisionDeckProvider(this.details) : super([details]);

  final DeckDetails details;
  int detailsCalls = 0;

  @override
  DeckDetails? get selectedDeck => details;

  @override
  Future<void> fetchDeckDetails(
    String deckId, {
    bool forceRefresh = false,
  }) async {
    detailsCalls += 1;
  }
}

class _ErrorDeckProvider extends _IdleDeckProvider {
  int retryCount = 0;

  @override
  String? get errorMessage => 'Verifique sua conexão e tente novamente.';

  @override
  Future<void> fetchDecks({bool silent = false}) async {
    retryCount += 1;
  }
}

class _CachedErrorDeckProvider extends _ErrorDeckProvider {
  _CachedErrorDeckProvider(this.cachedDecks);

  final List<Deck> cachedDecks;

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(cachedDecks);
}

class _LoadingDeckProvider extends _IdleDeckProvider {
  @override
  bool get isLoading => true;
}

class _SessionExpiredDeckProvider extends _IdleDeckProvider {
  @override
  String? get errorMessage => 'Sessão expirada. Faça login novamente.';

  @override
  int? get listStatusCode => 401;
}

class _IdleMarketProvider extends MarketProvider {
  _IdleMarketProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<void> fetchMovers({
    double minPrice = 1.0,
    int limit = 20,
    bool force = false,
  }) async {}
}

class _MemoryOnboardingRepository implements OnboardingStateRepository {
  _MemoryOnboardingRepository(this.state);

  OnboardingState state;
  final List<OnboardingDisposition> settlements = <OnboardingDisposition>[];

  @override
  Future<OnboardingState> load(String userId) async => state;

  @override
  Future<void> saveProgress(
    String userId, {
    required String selectedFormat,
    OnboardingGoal? selectedGoal,
    OnboardingExperience? experience,
    OnboardingBuildMode? buildMode,
  }) async {
    state = state.copyWith(
      selectedFormat: selectedFormat,
      selectedGoal: selectedGoal,
      experience: experience,
      buildMode: buildMode,
    );
  }

  @override
  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
    OnboardingGoal? selectedGoal,
    OnboardingExperience? experience,
    OnboardingBuildMode? buildMode,
  }) async {
    settlements.add(disposition);
    state = OnboardingState(
      disposition: disposition,
      selectedFormat: selectedFormat,
      selectedGoal: selectedGoal ?? state.selectedGoal,
      experience: experience ?? state.experience,
      buildMode: buildMode ?? state.buildMode,
    );
  }
}

const _homeFixtureCapabilities = <ReleaseCapability>{
  ReleaseCapability.catalogPrivate,
  ReleaseCapability.decksPrivate,
  ReleaseCapability.collectionPrivate,
  ReleaseCapability.aiAnalyzeOptimizeAdvisory,
  ReleaseCapability.aiGenerateRebuild,
  ReleaseCapability.lifeCounterLocal,
  ReleaseCapability.galleryPublic,
  ReleaseCapability.profilesPublic,
  ReleaseCapability.comments,
  ReleaseCapability.follows,
  ReleaseCapability.userSearch,
  ReleaseCapability.binderPublic,
  ReleaseCapability.trades,
  ReleaseCapability.marketplace,
  ReleaseCapability.learningWrites,
};

Widget _buildSubject({
  bool? lifeCounterAvailable,
  List<Deck> decks = const [],
  DeckProvider? deckProvider,
  bool disableAnimations = false,
  double textScale = 1,
  Set<ReleaseCapability> allowedCapabilities = _homeFixtureCapabilities,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ReleaseCapabilitiesProvider.seeded(allowedCapabilities),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(apiClient: _NoopApiClient()),
      ),
      ChangeNotifierProvider<DeckProvider>(
        create: (_) =>
            deckProvider ??
            (decks.isEmpty ? _IdleDeckProvider() : _SeededDeckProvider(decks)),
      ),
      ChangeNotifierProvider<MarketProvider>(
        create: (_) => _IdleMarketProvider(),
      ),
      ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: HomeScreen(lifeCounterAvailable: lifeCounterAvailable),
        ),
      ),
    ),
  );
}

Future<GoRouter> _pumpNavigationSubject(
  WidgetTester tester, {
  List<Deck> decks = const [],
  DeckProvider? deckProvider,
  bool lifeCounterAvailable = false,
  String userId = '',
  OnboardingStateRepository? onboardingStateRepository,
  VoidCallback? onOnboardingSettled,
  Set<ReleaseCapability> allowedCapabilities = _homeFixtureCapabilities,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => HomeScreen(
          lifeCounterAvailable: lifeCounterAvailable,
          userId: userId,
          onboardingStateRepository: onboardingStateRepository,
          onOnboardingSettled: onOnboardingSettled,
        ),
      ),
      for (final path in [
        '/life-counter',
        '/community',
        '/onboarding/core-flow',
        '/decks',
        '/decks/generate',
        '/decks/import',
        '/collection',
        '/collection/import',
        '/profile',
        '/login',
      ])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(
            body: Text(
              state.uri.toString(),
              key: const Key('home-navigation-destination'),
            ),
          ),
        ),
      GoRoute(
        path: '/decks/:id/post-game',
        builder: (_, state) => Scaffold(
          body: Text(
            state.uri.toString(),
            key: const Key('home-navigation-destination'),
          ),
        ),
      ),
      GoRoute(
        path: '/decks/:id',
        builder: (_, state) => Scaffold(
          body: Text(
            state.uri.toString(),
            key: const Key('home-navigation-destination'),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      key: ValueKey<GoRouter>(router),
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ReleaseCapabilitiesProvider.seeded(allowedCapabilities),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiClient: _NoopApiClient()),
        ),
        ChangeNotifierProvider<DeckProvider>(
          create: (_) => deckProvider ?? _SeededDeckProvider(decks),
        ),
        ChangeNotifierProvider<MarketProvider>(
          create: (_) => _IdleMarketProvider(),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  return router;
}

Future<void> _loadGoldenFonts() async {
  await Future.wait([
    (FontLoader(
      AppTheme.uiFontFamily,
    )..addFont(rootBundle.load('assets/lotus/fonts/Inter.ttf'))).load(),
    (FontLoader(
      AppTheme.displayFontFamily,
    )..addFont(rootBundle.load('assets/lotus/fonts/Fraunces.ttf'))).load(),
    (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
  ]);
}

void main() {
  setUpAll(_loadGoldenFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows premium home dashboard and empty deck state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('BrewTact'), findsOneWidget);
    expect(find.text('Olá,\nPlaneswalker'), findsOneWidget);
    expect(find.text('Acesso rápido'), findsOneWidget);
    expect(find.text('Jogar agora'), findsWidgets);
    expect(find.text('Construir deck'), findsOneWidget);
    expect(find.byTooltip('Perfil'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ManaLoomGlyph && widget.kind == ManaLoomGlyphKind.brand,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ManaLoomGlyph &&
            widget.kind == ManaLoomGlyphKind.lifeCounter,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.construction_rounded), findsNothing);
    expect(find.byIcon(Icons.public_rounded), findsNothing);

    expect(find.text('Decks recentes'), findsOneWidget);
    expect(find.text('Você ainda não tem decks'), findsOneWidget);
    expect(
      find.text('Crie seu primeiro deck e comece sua jornada em Magic.'),
      findsOneWidget,
    );
    expect(find.text('Criar novo deck'), findsOneWidget);
    expect(find.text('Atividade recente'), findsNothing);
    expect(find.text('Nova proposta recebida'), findsNothing);
    expect(find.text('Iniciar fluxo guiado'), findsNothing);
    expect(
      find.text('Crie seu primeiro deck ou gere um com IA!'),
      findsNothing,
    );
  });

  testWidgets(
    'all-off release exposes no product CTA and starts no deck fetch',
    (tester) async {
      final deckProvider = _CountingDeckProvider();

      await tester.pumpWidget(
        _buildSubject(
          deckProvider: deckProvider,
          allowedCapabilities: const {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Beta em preparação'), findsOneWidget);
      expect(
        find.text(
          'Os recursos desta versão ainda não foram liberados para uso.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home-hero-frame')), findsNothing);
      expect(find.text('Jogar agora'), findsNothing);
      expect(find.text('Construir deck'), findsNothing);
      expect(find.text('Abrir coleção'), findsNothing);
      expect(find.text('Comunidade'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(deckProvider.fetchCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion skips the home entrance animation', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(disableAnimations: true));
    await tester.pump();

    final transition = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(transition.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web capability replaces unavailable life counter actions', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(lifeCounterAvailable: false));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Jogar agora'), findsNothing);
    expect(find.text('Abrir decks'), findsOneWidget);
    expect(find.text('Comunidade'), findsOneWidget);
    expect(find.text('Construir deck'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('distinguishes deck loading failure from an empty account', (
    tester,
  ) async {
    final provider = _ErrorDeckProvider();
    await tester.pumpWidget(
      _buildSubject(lifeCounterAvailable: false, deckProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const Key('home-decks-error-state')), findsOneWidget);
    expect(find.text('Você ainda não tem decks'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);

    final callsBeforeTap = provider.retryCount;
    await tester.tap(find.byKey(const Key('home-decks-retry')));
    await tester.pump();
    expect(provider.retryCount, callsBeforeTap + 1);
  });

  testWidgets('shows an explicit loading state without hiding the hero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(
        lifeCounterAvailable: false,
        deckProvider: _LoadingDeckProvider(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const Key('home-hero-frame')), findsOneWidget);
    expect(find.byKey(const Key('home-decks-loading-state')), findsOneWidget);
    expect(find.text('Carregando seus decks...'), findsOneWidget);
    expect(find.byKey(const Key('home-decks-empty-state')), findsNothing);
  });

  testWidgets('keeps cached decks visible and labels a cached-only refresh', (
    tester,
  ) async {
    final deck = Deck(
      id: 'cached-deck',
      name: 'Deck salvo',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime(2026, 7, 20),
      cardCount: 100,
    );
    final provider = _CachedErrorDeckProvider([deck]);

    await tester.pumpWidget(
      _buildSubject(lifeCounterAvailable: false, deckProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(
      find.byKey(const Key('home-decks-cached-read-only-state')),
      findsOneWidget,
    );
    expect(find.text('Deck salvo'), findsOneWidget);
    expect(find.textContaining('Mostrando decks salvos.'), findsOneWidget);

    final callsBeforeTap = provider.retryCount;
    await tester.tap(find.byKey(const Key('home-decks-cache-retry')));
    await tester.pump();
    expect(provider.retryCount, callsBeforeTap + 1);
  });

  testWidgets('does not expose cached deck content after session expiry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(
        lifeCounterAvailable: false,
        deckProvider: _SessionExpiredDeckProvider(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(
      find.byKey(const Key('home-decks-session-expired-state')),
      findsOneWidget,
    );
    expect(find.text('Sua sessão expirou'), findsOneWidget);
    expect(find.text('Entrar novamente'), findsOneWidget);
    expect(find.byKey(const Key('home-decks-empty-state')), findsNothing);
  });

  testWidgets('all web home shortcuts resolve to their canonical routes', (
    tester,
  ) async {
    final cases = <({Finder finder, String route})>[
      (finder: find.text('Abrir decks'), route: '/decks'),
      (finder: find.text('Comunidade'), route: '/community'),
      (finder: find.text('Construir deck'), route: '/onboarding/core-flow'),
      (finder: find.text('Meus Decks'), route: '/decks'),
      (finder: find.text('Coleção'), route: '/collection'),
      (finder: find.text('Trocas'), route: '/collection?tab=2'),
      (finder: find.text('Ver todos'), route: '/decks'),
      (finder: find.byTooltip('Perfil'), route: '/profile'),
    ];

    for (final testCase in cases) {
      final router = await _pumpNavigationSubject(tester);
      await tester.tap(testCase.finder);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        testCase.route,
        reason: 'shortcut did not resolve to ${testCase.route}',
      );
      expect(
        find.byKey(const Key('home-navigation-destination')),
        findsOneWidget,
      );
    }
  });

  testWidgets('native play action and recent deck open canonical routes', (
    tester,
  ) async {
    var router = await _pumpNavigationSubject(
      tester,
      lifeCounterAvailable: true,
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('home-primary-action')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Qual partida você vai abrir?'), findsOneWidget);
    expect(find.byKey(const Key('home-play-quick-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-play-quick-mode')));
    await tester.pumpAndSettle();
    expect(find.text('/life-counter'), findsOneWidget);

    final deck = Deck(
      id: 'recent-deck',
      name: 'Deck recente real',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime(2026, 7, 20),
      cardCount: 100,
    );
    router = await _pumpNavigationSubject(tester, decks: [deck]);
    await tester.tap(find.byKey(const Key('home-recent-deck-recent-deck')));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/decks/recent-deck',
    );
  });

  testWidgets('pending build intent stays contextual and resumes exact task', (
    tester,
  ) async {
    final repository = _MemoryOnboardingRepository(
      const OnboardingState(
        selectedGoal: OnboardingGoal.buildDeck,
        experience: OnboardingExperience.returning,
        selectedFormat: 'pioneer',
        buildMode: OnboardingBuildMode.manual,
      ),
    );
    final unrelatedDeck = Deck(
      id: 'existing-deck',
      name: 'Deck anterior',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime(2026, 7, 20),
      cardCount: 100,
    );
    final router = await _pumpNavigationSubject(
      tester,
      decks: [unrelatedDeck],
      userId: 'intent-build',
      onboardingStateRepository: repository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Seu primeiro\ndeck começa aqui'), findsOneWidget);
    expect(find.text('Criar deck'), findsWidgets);
    expect(find.text('Continue\nDeck anterior'), findsNothing);

    await tester.tap(find.byKey(const Key('home-primary-action')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri,
      Uri.parse('/decks?create=1&format=pioneer&from=onboarding'),
    );
    expect(repository.settlements, isEmpty);
  });

  testWidgets('completed import intent returns to the created deck', (
    tester,
  ) async {
    final repository = _MemoryOnboardingRepository(
      const OnboardingState(
        disposition: OnboardingDisposition.completed,
        selectedGoal: OnboardingGoal.importDeck,
        experience: OnboardingExperience.experienced,
        selectedFormat: 'modern',
      ),
    );
    final deck = Deck(
      id: 'imported-deck',
      name: 'Murktide revisado',
      format: 'modern',
      isPublic: false,
      createdAt: DateTime(2026, 8, 6),
      cardCount: 60,
    );
    final router = await _pumpNavigationSubject(
      tester,
      decks: [deck],
      userId: 'intent-import',
      onboardingStateRepository: repository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Revise\nMurktide revisado'), findsOneWidget);
    expect(find.text('Abrir deck'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-primary-action')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/decks/imported-deck',
    );
    expect(repository.settlements, isEmpty);
  });

  testWidgets('pending play intent settles only when the table is opened', (
    tester,
  ) async {
    final repository = _MemoryOnboardingRepository(
      const OnboardingState(
        selectedGoal: OnboardingGoal.play,
        experience: OnboardingExperience.firstSteps,
        selectedFormat: 'commander',
      ),
    );
    var settledCalls = 0;
    await _pumpNavigationSubject(
      tester,
      lifeCounterAvailable: true,
      userId: 'intent-play',
      onboardingStateRepository: repository,
      onOnboardingSettled: () => settledCalls += 1,
    );
    await tester.pumpAndSettle();

    expect(find.text('Sua mesa\nestá pronta'), findsOneWidget);
    expect(repository.settlements, isEmpty);
    await tester.tap(find.byKey(const Key('home-primary-action')));
    await tester.pumpAndSettle();

    expect(repository.settlements, [OnboardingDisposition.completed]);
    expect(repository.state.disposition, OnboardingDisposition.completed);
    expect(settledCalls, 1);
    expect(find.text('Qual partida você vai abrir?'), findsOneWidget);
  });

  testWidgets('play entry separates resume, end, new deck and quick mode', (
    tester,
  ) async {
    final session = LifeCounterSession.initial(
      playSessionId: 'play-active',
      deckId: 'deck-active',
      deckName: 'Alela em mesa',
      deckSnapshotHash:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      deckVersionAtEpochMs: DateTime(2026, 8, 5).millisecondsSinceEpoch,
      startedAtEpochMs: DateTime(2026, 8, 5, 12).millisecondsSinceEpoch,
    );
    SharedPreferences.setMockInitialValues({
      legacyLifeCounterSessionPrefsKey: session.toJsonString(),
    });

    await _pumpNavigationSubject(tester, lifeCounterAvailable: true);
    tester
        .widget<FilledButton>(find.byKey(const Key('home-primary-action')))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-play-active-session')), findsOneWidget);
    expect(find.text('Alela em mesa'), findsOneWidget);
    expect(find.text('Retomar'), findsOneWidget);
    expect(find.text('Encerrar e registrar'), findsOneWidget);
    expect(find.text('Nova partida rápida · sem deck'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-play-end-session')));
    await tester.pumpAndSettle();

    final endedLocation = tester
        .widget<Text>(find.byKey(const Key('home-navigation-destination')))
        .data!;
    final endedUri = Uri.parse(endedLocation);
    expect(endedUri.path, '/decks/deck-active/post-game');
    expect(endedUri.queryParameters['playSessionId'], 'play-active');
    expect(
      endedUri.queryParameters['deckSnapshotHash'],
      session.deckSnapshotHash,
    );
  });

  testWidgets('deck play entry confirms and carries an exact revision', (
    tester,
  ) async {
    final details = DeckDetails(
      id: 'deck-revision',
      name: 'Alela Artefatos',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime(2026, 8, 1),
      cardCount: 100,
      stats: const {'total_cards': 100},
      commander: const [],
      mainBoard: const {},
      deckSnapshotHash:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      deckVersionAt: DateTime(2026, 8, 5, 13),
    );
    final provider = _RevisionDeckProvider(details);
    await _pumpNavigationSubject(
      tester,
      lifeCounterAvailable: true,
      deckProvider: provider,
    );

    tester
        .widget<FilledButton>(find.byKey(const Key('home-primary-action')))
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-play-deck-deck-revision')));
    await tester.pumpAndSettle();

    final displayedLocation = tester
        .widget<Text>(find.byKey(const Key('home-navigation-destination')))
        .data!;
    final uri = Uri.parse(displayedLocation);
    expect(uri.path, '/life-counter');
    expect(uri.queryParameters['deckId'], details.id);
    expect(uri.queryParameters['deckName'], details.name);
    expect(uri.queryParameters['deckSnapshotHash'], details.deckSnapshotHash);
    expect(
      uri.queryParameters['deckVersionAt'],
      details.deckVersionAt!.millisecondsSinceEpoch.toString(),
    );
    expect(provider.detailsCalls, 1);
  });

  testWidgets('keeps home intent cards readable on SM A135M width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Construir deck'), findsOneWidget);
    expect(
      find.byKey(const Key('home-quick-action-2'), skipOffstage: false),
      findsOneWidget,
    );

    final quickActionsList = find.byKey(const Key('home-quick-actions-list'));
    expect(quickActionsList, findsOneWidget);
    final listRect = tester.getRect(quickActionsList);
    final firstRect = tester.getRect(
      find.byKey(const Key('home-quick-action-0')),
    );
    final secondRect = tester.getRect(
      find.byKey(const Key('home-quick-action-1')),
    );
    final itemStride = secondRect.left - firstRect.left;

    expect(firstRect.left, greaterThanOrEqualTo(listRect.left + 3.5));
    expect(secondRect.right, lessThanOrEqualTo(listRect.right - 3.5));

    await tester.drag(quickActionsList, const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('Coleção'), findsOneWidget);
    expect(find.text('Trocas'), findsOneWidget);
    final scrollable = find.descendant(
      of: quickActionsList,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    final remainder = position.pixels % itemStride;
    expect(
      math.min(remainder, itemStride - remainder),
      lessThan(0.6),
      reason: 'quick actions must settle on complete card boundaries',
    );

    for (var index = 0; index < 5; index++) {
      final item = find.byKey(
        Key('home-quick-action-$index'),
        skipOffstage: false,
      );
      if (item.evaluate().isEmpty) continue;
      final rect = tester.getRect(item);
      if (!rect.overlaps(listRect.deflate(3.5))) continue;
      expect(
        rect.left,
        greaterThanOrEqualTo(listRect.left + 3.5),
        reason: 'card $index left fragment remained after snap',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(listRect.right - 3.5),
        reason: 'card $index right fragment remained after snap',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the SM A135M hero visual baseline', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSubject());
    var imageLoaded = false;
    Object? imageError;
    precacheImage(
      const AssetImage('assets/branding/home_hero.png'),
      tester.element(find.byType(HomeScreen)),
    ).then<void>(
      (_) => imageLoaded = true,
      onError: (Object error, StackTrace stackTrace) => imageError = error,
    );
    for (
      var attempt = 0;
      attempt < 50 && !imageLoaded && imageError == null;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(imageError, isNull);
    expect(imageLoaded, isTrue, reason: 'home hero asset did not load');
    await tester.pump(const Duration(milliseconds: 900));

    await expectLater(
      find.byKey(const Key('home-hero-frame')),
      matchesGoldenFile('goldens/home_hero_sma135m.png'),
    );
  });

  testWidgets('hero artwork uses a contained crop and foreground frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSubject(lifeCounterAvailable: false));
    await tester.pump(const Duration(milliseconds: 900));

    final artwork = tester.widget<Image>(
      find.byKey(const Key('home-hero-artwork')),
    );
    expect(artwork.fit, BoxFit.contain);
    expect(
      (artwork.image as AssetImage).assetName,
      'assets/branding/home_hero.png',
    );

    final surface = tester.widget<Container>(
      find.byKey(const Key('home-hero-surface')),
    );
    final foreground = surface.foregroundDecoration! as BoxDecoration;
    expect(foreground.border, isNotNull);
    expect(foreground.borderRadius, isNotNull);
  });

  testWidgets('hero frame stays clipped and bounded across target widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(412, 915),
      Size(599, 844),
      Size(600, 844),
      Size(768, 1024),
      Size(839, 1024),
      Size(840, 1024),
      Size(1024, 768),
      Size(1199, 900),
      Size(1200, 900),
      Size(1280, 900),
      Size(1440, 900),
      Size(1599, 900),
      Size(1600, 900),
      Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _buildSubject(lifeCounterAvailable: false, disableAnimations: true),
      );
      await tester.pump();

      final frame = tester.getRect(find.byKey(const Key('home-hero-frame')));
      expect(frame.left, greaterThanOrEqualTo(0), reason: '$size left');
      expect(frame.right, lessThanOrEqualTo(size.width), reason: '$size right');
      expect(frame.height, 190, reason: '$size height');
      expect(find.byKey(const Key('home-quick-actions-list')), findsOneWidget);
      expect(find.text('Abrir decks'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size overflow');
    }
  });

  testWidgets('home remains usable with 200% text on compact width', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSubject(
        lifeCounterAvailable: false,
        disableAnimations: true,
        textScale: 2,
      ),
    );
    await tester.pump();

    expect(find.text('Abrir decks'), findsOneWidget);
    expect(find.text('Decks recentes'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('home-hero-frame'))).height,
      280,
    );
    await expectManaLoomBaselineAccessibility(tester);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the desktop hero visual baseline', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSubject(lifeCounterAvailable: false));
    var imageLoaded = false;
    Object? imageError;
    precacheImage(
      const AssetImage('assets/branding/home_hero.png'),
      tester.element(find.byType(HomeScreen)),
    ).then<void>(
      (_) => imageLoaded = true,
      onError: (Object error, StackTrace stackTrace) => imageError = error,
    );
    for (
      var attempt = 0;
      attempt < 50 && !imageLoaded && imageError == null;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(imageError, isNull);
    expect(imageLoaded, isTrue, reason: 'home hero asset did not load');
    await tester.pump(const Duration(milliseconds: 900));

    await expectLater(
      find.byKey(const Key('home-hero-frame')),
      matchesGoldenFile('goldens/home_hero_web.png'),
    );
  });

  testWidgets('matches the wide and ultra-wide hero visual baselines', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final fixture in const [
      (size: Size(1440, 900), golden: 'goldens/home_hero_1440.png'),
      (size: Size(1920, 1080), golden: 'goldens/home_hero_1920.png'),
    ]) {
      tester.view.physicalSize = fixture.size;
      await tester.pumpWidget(_buildSubject(lifeCounterAvailable: false));

      var imageLoaded = false;
      Object? imageError;
      precacheImage(
        const AssetImage('assets/branding/home_hero.png'),
        tester.element(find.byType(HomeScreen)),
      ).then<void>(
        (_) => imageLoaded = true,
        onError: (Object error, StackTrace stackTrace) => imageError = error,
      );
      for (
        var attempt = 0;
        attempt < 50 && !imageLoaded && imageError == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(imageError, isNull, reason: '${fixture.size} asset error');
      expect(imageLoaded, isTrue, reason: '${fixture.size} asset not loaded');
      await tester.pump(const Duration(milliseconds: 900));

      await expectLater(
        find.byKey(const Key('home-hero-frame')),
        matchesGoldenFile(fixture.golden),
      );
    }
  });

  testWidgets('recent deck art is inset on every side and keeps card ratio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deck = Deck(
      id: 'deck-padding',
      name: 'Deck com acabamento',
      format: 'commander',
      commanderName: 'Jace, the Mind Sculptor',
      commanderImageUrl: 'https://cards.scryfall.io/normal/front/test.jpg',
      isPublic: false,
      createdAt: DateTime(2026, 7, 15),
      cardCount: 100,
      colorIdentity: const ['U'],
    );

    await tester.pumpWidget(
      _buildSubject(lifeCounterAvailable: false, decks: [deck]),
    );
    await tester.pump(const Duration(milliseconds: 900));

    final railRect = tester.getRect(
      find.byKey(const Key('home-recent-decks-rail')),
    );
    final cardRect = tester.getRect(
      find.byKey(const Key('home-recent-deck-deck-padding')),
    );
    final artRect = tester.getRect(
      find.byKey(const Key('home-recent-deck-art-deck-padding')),
    );

    expect(cardRect.top, greaterThan(railRect.top));
    expect(cardRect.bottom, lessThan(railRect.bottom));
    expect(artRect.left - cardRect.left, greaterThanOrEqualTo(8));
    expect(artRect.top - cardRect.top, greaterThanOrEqualTo(8));
    expect(cardRect.right - artRect.right, greaterThan(8));
    expect(cardRect.bottom - artRect.bottom, greaterThanOrEqualTo(8));
    expect(artRect.width / artRect.height, closeTo(72 / 102, 0.01));

    final image = tester.widget<CachedCardImage>(
      find.descendant(
        of: find.byKey(const Key('home-recent-deck-art-deck-padding')),
        matching: find.byType(CachedCardImage),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent deck resolves governed commander reference art', (
    tester,
  ) async {
    final deck = Deck(
      id: 'deck-reference-art',
      name: 'Deck sem URL persistida',
      format: 'commander',
      commanderName: 'Atraxa, Grand Unifier',
      isPublic: false,
      createdAt: DateTime(2026, 8, 7),
      cardCount: 100,
      colorIdentity: const ['W', 'U', 'B', 'G'],
    );

    await tester.pumpWidget(
      _buildSubject(lifeCounterAvailable: false, decks: [deck]),
    );
    await tester.pump();

    final artworkFrame = find.byKey(
      const Key('home-recent-deck-art-deck-reference-art'),
    );
    expect(
      find.descendant(of: artworkFrame, matching: find.byType(CardArtwork)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: artworkFrame,
        matching: find.byKey(const Key('card-artwork-status-reference')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
