import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
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

class _IdleMarketProvider extends MarketProvider {
  _IdleMarketProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<void> fetchMovers({
    double minPrice = 1.0,
    int limit = 20,
    bool force = false,
  }) async {}
}

Widget _buildSubject({bool? lifeCounterAvailable}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(apiClient: _NoopApiClient()),
      ),
      ChangeNotifierProvider<DeckProvider>(create: (_) => _IdleDeckProvider()),
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
      const AssetImage('assets/branding/home_hero_banner.png'),
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
}
