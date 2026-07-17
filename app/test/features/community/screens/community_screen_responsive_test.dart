import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
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
}

Future<void> _pumpCommunity(
  WidgetTester tester,
  Size size, {
  int initialTab = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final api = _CommunityGridApiFixture();
  await tester.pumpWidget(
    _CommunityProviders(
      api: api,
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
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/market/movers')) {
      return ApiResponse(200, {'data': const []});
    }
    if (endpoint.startsWith('/community/decks/following')) {
      return ApiResponse(200, {'data': const [], 'total': 0});
    }
    if (endpoint.startsWith('/community/decks?')) {
      return ApiResponse(200, {
        'data': List.generate(
          4,
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
        'total': 4,
      });
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }
}
