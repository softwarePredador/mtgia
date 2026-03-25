import 'package:flutter/material.dart';
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
  Future<void> fetchDecks() async {}
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

void main() {
  testWidgets('shows calmer home CTA stack and neutral empty state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Criar e otimizar deck'), findsOneWidget);
    expect(find.text('Novo Deck'), findsOneWidget);
    expect(find.text('Importar lista'), findsNWidgets(2));
    expect(find.text('Gerar com IA'), findsOneWidget);
    expect(find.text('Minha Coleção'), findsOneWidget);
    expect(find.text('Vida'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);

    expect(find.text('Nenhum deck criado ainda'), findsOneWidget);
    expect(
      find.text(
        'Comece criando um deck manualmente ou importando uma lista que você já usa.',
      ),
      findsOneWidget,
    );
    expect(find.text('Abrir decks'), findsOneWidget);
    expect(find.text('Iniciar fluxo guiado'), findsNothing);
    expect(
      find.text('Crie seu primeiro deck ou gere um com IA!'),
      findsNothing,
    );
  });
}
