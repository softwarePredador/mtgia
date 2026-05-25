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

Widget _buildSubject() {
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
    child: MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
  );
}

Future<void> _loadGoldenFonts() async {
  await Future.wait([
    (FontLoader(AppTheme.uiFontFamily)
      ..addFont(rootBundle.load('assets/lotus/fonts/Manrope.ttf'))).load(),
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
    await tester.pumpAndSettle();

    expect(find.text('ManaLoom'), findsOneWidget);
    expect(find.text('Olá,\nPlaneswalker'), findsOneWidget);
    expect(find.text('Acesso rápido'), findsOneWidget);
    expect(find.text('Jogar agora'), findsWidgets);
    expect(find.text('Abrir contador de vida'), findsOneWidget);
    expect(find.text('Construir deck'), findsOneWidget);
    expect(find.text('Criar, importar ou ajustar'), findsOneWidget);
    expect(find.text('Ver e gerenciar seus decks'), findsOneWidget);
    expect(find.text('Suas cartas e coleções'), findsOneWidget);
    expect(find.text('Marketplace e propostas'), findsOneWidget);

    expect(find.text('Decks recentes'), findsOneWidget);
    expect(find.text('Você ainda não tem decks'), findsOneWidget);
    expect(
      find.text('Crie seu primeiro deck e comece sua jornada em Magic.'),
      findsOneWidget,
    );
    expect(find.text('Criar novo deck'), findsOneWidget);
    expect(find.text('Gerar com IA'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(find.text('Iniciar fluxo guiado'), findsNothing);
    expect(
      find.text('Crie seu primeiro deck ou gere um com IA!'),
      findsNothing,
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
    await precacheImage(
      const AssetImage('assets/branding/home_hero_banner.png'),
      tester.element(find.byType(HomeScreen)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('home-hero-frame')),
      matchesGoldenFile('goldens/home_hero_sma135m.png'),
    );
  });
}
