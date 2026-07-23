import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/home/home_screen.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import '../../ui/support/manaloom_ui_audit_harness.dart';

class _NoopApiClient extends ApiClient {}

class _IdleDeckProvider extends DeckProvider {
  _IdleDeckProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<void> fetchDecks({bool silent = false}) async {}
}

class _SeededDeckProvider extends _IdleDeckProvider {
  _SeededDeckProvider(this.seededDecks);

  final List<Deck> seededDecks;

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(seededDecks);
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

Widget _buildSubject({
  bool? lifeCounterAvailable,
  List<Deck> decks = const [],
  DeckProvider? deckProvider,
  bool disableAnimations = false,
  double textScale = 1,
}) {
  return MultiProvider(
    providers: [
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
  bool lifeCounterAvailable = false,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) =>
            HomeScreen(lifeCounterAvailable: lifeCounterAvailable),
      ),
      for (final path in [
        '/life-counter',
        '/community',
        '/onboarding/core-flow',
        '/decks',
        '/collection',
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
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiClient: _NoopApiClient()),
        ),
        ChangeNotifierProvider<DeckProvider>(
          create: (_) => _SeededDeckProvider(decks),
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

  testWidgets('shows premium home dashboard and empty deck state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('ManaLoom'), findsOneWidget);
    expect(find.text('Olá,\nPlaneswalker'), findsOneWidget);
    expect(find.text('Acesso rápido'), findsOneWidget);
    expect(find.text('Jogar agora'), findsWidgets);
    expect(find.text('Construir deck'), findsOneWidget);
    expect(find.byTooltip('Perfil'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsNothing);

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
    expect(find.text('Montar deck'), findsOneWidget);
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

  testWidgets('keeps cached decks visible and labels an offline refresh', (
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
      find.byKey(const Key('home-decks-offline-cache-state')),
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
      (finder: find.text('Montar deck'), route: '/onboarding/core-flow'),
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
    expect(find.text('Meus Decks'), findsOneWidget);

    final quickActionsList = find.byKey(const Key('home-quick-actions-list'));
    expect(quickActionsList, findsOneWidget);

    await tester.drag(quickActionsList, const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(find.text('Coleção'), findsOneWidget);
    expect(find.text('Trocas'), findsOneWidget);
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
      expect(find.text('Montar deck'), findsOneWidget);
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

    expect(find.text('Montar deck'), findsOneWidget);
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
}
