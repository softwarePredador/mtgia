import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/community/providers/community_provider.dart';
import 'package:manaloom/features/community/screens/community_screen.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('explore keeps a single list with compact gutters at 390px', (
    tester,
  ) async {
    await _pumpCommunity(tester, const Size(390, 844));

    final collection = tester.widget(
      find.byKey(const Key('community-explore-deck-list')),
    );
    final controls = tester.getRect(
      find.byKey(const Key('community-explore-controls-frame')),
    );

    expect(collection, isA<ListView>());
    expect(controls.left, greaterThanOrEqualTo(0));
    expect(controls.width, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('explore uses a bounded two-column grid at 1280px', (
    tester,
  ) async {
    await _pumpCommunity(tester, const Size(1280, 900));

    final collection = tester.widget<GridView>(
      find.byKey(const Key('community-explore-deck-list')),
    );
    final delegate =
        collection.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final first = tester.getRect(
      find.byKey(const Key('community-explore-deck-row-deck-1')),
    );
    final second = tester.getRect(
      find.byKey(const Key('community-explore-deck-row-deck-2')),
    );

    expect(delegate.crossAxisCount, 2);
    expect(first.left, greaterThanOrEqualTo(AppTheme.pageGutter));
    expect(second.left, greaterThan(first.right));
    expect(second.right, lessThanOrEqualTo(1260));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one public deck becomes a full-width visual spotlight', (
    tester,
  ) async {
    await _pumpCommunity(
      tester,
      const Size(1280, 900),
      api: _CommunityGridApiFixture(deckCount: 1),
    );

    final collection = tester.widget(
      find.byKey(const Key('community-explore-deck-list')),
    );
    final card = find.byKey(const Key('community-explore-deck-row-deck-1'));
    final artwork = tester.widget<CachedCardImage>(
      find.descendant(of: card, matching: find.byType(CachedCardImage)),
    );
    expect(collection, isA<ListView>());
    expect(tester.getSize(card).width, greaterThan(1100));
    expect(artwork.width, 84);
    expect(artwork.height, 118);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide market uses a bounded two-column comparison grid', (
    tester,
  ) async {
    await _pumpCommunity(
      tester,
      const Size(1280, 900),
      initialTab: 3,
      api: _CommunityGridApiFixture(withMarketMovers: true),
    );

    expect(
      find.byKey(const Key('community-market-movers-grid')),
      findsOneWidget,
    );
    final first = tester.getRect(
      find.byKey(const Key('community-market-mover-card-market-1')),
    );
    final second = tester.getRect(
      find.byKey(const Key('community-market-mover-card-market-2')),
    );
    expect((first.top - second.top).abs(), lessThan(0.1));
    expect(second.left, greaterThan(first.right));
    expect(first.left, greaterThanOrEqualTo(AppTheme.pageGutter));
    expect(second.right, lessThanOrEqualTo(1260));
    expect(tester.takeException(), isNull);
  });

  testWidgets('can deep-link directly to the canonical market tab', (
    tester,
  ) async {
    await _pumpCommunity(tester, const Size(390, 844), initialTab: 3);

    final tabs = tester.widget<TabBar>(find.byKey(const Key('community-tabs')));
    expect(tabs.controller?.index, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps route query and selected tab synchronized without loops', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final api = _CommunityGridApiFixture();
    final router = GoRouter(
      initialLocation: '/community?tab=99',
      routes: [
        GoRoute(
          path: '/community',
          builder: (context, state) {
            final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
            return CommunityScreen(initialTab: tab ?? 0);
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _CommunityProviders(
        api: api,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    TabBar tabs = tester.widget(find.byKey(const Key('community-tabs')));
    expect(tabs.controller?.index, 3);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/community?tab=3',
    );

    router.go('/community?tab=1');
    await tester.pumpAndSettle();
    tabs = tester.widget(find.byKey(const Key('community-tabs')));
    expect(tabs.controller?.index, 1);

    tabs.controller!.animateTo(2);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/community?tab=2',
    );

    router.go('/community?tab=-4');
    await tester.pumpAndSettle();
    tabs = tester.widget(find.byKey(const Key('community-tabs')));
    expect(tabs.controller?.index, 0);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/community?tab=0',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not replace an active nested community route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final api = _CommunityGridApiFixture();
    final router = GoRouter(
      initialLocation: '/community/search-users',
      routes: [
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
          routes: [
            GoRoute(
              path: 'search-users',
              builder: (context, state) => const Scaffold(
                key: Key('nested-community-route'),
                body: Text('Buscar jogadores'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _CommunityProviders(
        api: api,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nested-community-route')), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/community/search-users',
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCommunity(
  WidgetTester tester,
  Size size, {
  int initialTab = 0,
  ApiClient? api,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final resolvedApi = api ?? _CommunityGridApiFixture();
  await tester.pumpWidget(
    _CommunityProviders(
      api: resolvedApi,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: CommunityScreen(initialTab: initialTab),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CommunityProviders extends StatelessWidget {
  const _CommunityProviders({required this.api, required this.child});

  final ApiClient api;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CommunityProvider(apiClient: api),
        ),
        ChangeNotifierProvider(create: (_) => SocialProvider(apiClient: api)),
        ChangeNotifierProvider(create: (_) => MarketProvider(apiClient: api)),
        ChangeNotifierProvider(create: (_) => MessageProvider(apiClient: api)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(apiClient: api),
        ),
      ],
      child: child,
    );
  }
}

class _CommunityGridApiFixture extends ApiClient {
  _CommunityGridApiFixture({this.deckCount = 4, this.withMarketMovers = false});

  final int deckCount;
  final bool withMarketMovers;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/market/movers')) {
      if (!withMarketMovers) {
        return ApiResponse(200, {
          'gainers': const [],
          'losers': const [],
          'total_tracked': 0,
          'message': 'Aguardando histórico de preços.',
        });
      }
      return ApiResponse(200, {
        'currency': 'USD',
        'date': '2026-08-07',
        'previous_date': '2026-08-06',
        'total_tracked': 2,
        'gainers': [
          _moverJson('card-market-1', 'Sol Ring', 2.5, 2.25),
          _moverJson('card-market-2', 'Arcane Signet', 1.8, 1.5),
        ],
        'losers': const [],
      });
    }
    if (endpoint.startsWith('/community/decks/following')) {
      return ApiResponse(200, {'data': const [], 'total': 0});
    }
    if (endpoint.startsWith('/community/decks?')) {
      return ApiResponse(200, {
        'data': List.generate(
          deckCount,
          (index) => {
            'id': 'deck-${index + 1}',
            'name': 'Deck público ${index + 1}',
            'format': 'commander',
            'description': 'Lista compartilhada para testes responsivos.',
            'owner_id': 'owner-${index + 1}',
            'owner_username': 'player_${index + 1}',
            'card_count': 100,
            'created_at': '2026-07-16T12:00:00Z',
          },
        ),
        'total': deckCount,
      });
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }

  static Map<String, dynamic> _moverJson(
    String id,
    String name,
    double today,
    double yesterday,
  ) {
    final change = today - yesterday;
    return {
      'card_id': id,
      'name': name,
      'set_code': 'CMM',
      'rarity': 'uncommon',
      'image_url': 'https://cards.scryfall.io/normal/front/a/b/$id.jpg',
      'price_today': today,
      'price_yesterday': yesterday,
      'change_usd': change,
      'change_pct': change / yesterday * 100,
    };
  }
}
