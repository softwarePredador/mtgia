import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(apiClient: _NoopApiClient()),
      ),
      ChangeNotifierProvider<DeckProvider>(
        create:
            (_) =>
                deckProvider ??
                (decks.isEmpty
                    ? _IdleDeckProvider()
                    : _SeededDeckProvider(decks)),
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
      home: HomeScreen(lifeCounterAvailable: lifeCounterAvailable),
    ),
  );
}

Future<void> _loadGoldenFonts() async {
  await Future.wait([
    (FontLoader(AppTheme.uiFontFamily)
      ..addFont(rootBundle.load('assets/lotus/fonts/Inter.ttf'))).load(),
    (FontLoader(AppTheme.displayFontFamily)
      ..addFont(rootBundle.load('assets/lotus/fonts/Fraunces.ttf'))).load(),
    (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
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
