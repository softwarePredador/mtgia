import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/community/providers/community_provider.dart';
import 'package:manaloom/features/trades/screens/trade_matches_screen.dart';
import 'package:provider/provider.dart';

class _TradeMatchesProvider extends CommunityProvider {
  _TradeMatchesProvider(this.result);

  CommunityTradeMatchSearchResult result;
  int calls = 0;

  @override
  Future<CommunityTradeMatchSearchResult> fetchTradeMatchResult({
    String? deckId,
  }) async {
    calls++;
    return result;
  }
}

CommunityTradeMatch _match() => CommunityTradeMatch(
  item: BinderItem(
    id: 'binder-1',
    cardId: 'printing-1',
    cardName: 'Sol Ring',
    cardSetCode: 'cmm',
    cardCollectorNumber: '396',
    cardSetName: 'Commander Masters',
    cardSetReleaseDate: '2023-08-04',
    cardRarity: 'uncommon',
    quantity: 1,
    availableQuantity: 1,
    condition: 'LP',
    language: 'pt-br',
    forTrade: true,
    price: 12.5,
    updatedAt: '2026-08-06T10:00:00Z',
  ),
  wantedQuantity: 1,
  ownerId: 'owner-1',
  ownerName: 'Nissa',
  ownerUsername: 'planeswalker',
  ownerLocationCity: 'São Paulo',
  ownerLocationState: 'SP',
  sources: const ['deck_missing'],
);

void main() {
  testWidgets(
    'uses local card width so mobile metadata and action are not squeezed',
    (tester) async {
      final provider = _TradeMatchesProvider(
        CommunityTradeMatchSearchResult(
          matches: [_match()],
          source: 'deck_missing_and_wishlist',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CommunityProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1440, 900)),
              child: const Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 390,
                  height: 844,
                  child: TradeMatchesScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final proposal = find.byKey(const Key('trade-match-propose-binder-1'));
      final card = find.byKey(const Key('trade-match-card-binder-1'));
      await tester.ensureVisible(card);
      await tester.pump();

      expect(tester.getSize(proposal).width, greaterThan(300));
      expect(find.text('CMM #396'), findsOneWidget);
      expect(find.text('1 disponível'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single match becomes a master-detail workspace on wide screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final provider = _TradeMatchesProvider(
        CommunityTradeMatchSearchResult(
          matches: [_match()],
          source: 'deck_missing_and_wishlist',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CommunityProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const TradeMatchesScreen(deckId: 'deck-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final workbench = find.byKey(const Key('trade-matches-single-workbench'));
      final header = find.byKey(const Key('trade-matches-header'));
      final card = find.byKey(const Key('trade-match-card-binder-1'));
      final headerRect = tester.getRect(header);
      final cardRect = tester.getRect(card);

      expect(workbench, findsOneWidget);
      expect(headerRect.right, lessThan(cardRect.left));
      expect(cardRect.width, greaterThan(700));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('match exposes exact copy and opens a recoverable proposal URL', (
    tester,
  ) async {
    final provider = _TradeMatchesProvider(
      CommunityTradeMatchSearchResult(
        matches: [_match()],
        source: 'all_deck_missing_and_wishlist',
      ),
    );
    final router = GoRouter(
      initialLocation: '/collection/matches',
      routes: [
        GoRoute(
          path: '/collection/matches',
          builder: (_, _) => const TradeMatchesScreen(),
        ),
        GoRoute(
          path: '/trades/create/:receiverId',
          builder: (_, state) => Scaffold(
            body: Text(state.uri.toString(), key: const Key('route-location')),
          ),
        ),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, state) => Text(state.uri.toString()),
        ),
        GoRoute(path: '/collection', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<CommunityProvider>.value(
        value: provider,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sol Ring'), findsOneWidget);
    expect(find.text('CMM #396'), findsOneWidget);
    expect(find.text('LP'), findsOneWidget);
    expect(find.text('PT-BR'), findsOneWidget);
    expect(find.text('1 disponível'), findsOneWidget);
    expect(find.text('Nissa'), findsOneWidget);
    expect(find.text('São Paulo, SP'), findsOneWidget);

    final proposal = find.byKey(const Key('trade-match-propose-binder-1'));
    await tester.ensureVisible(proposal);
    await tester.tap(proposal);
    await tester.pumpAndSettle();

    final location = tester.widget<Text>(
      find.byKey(const Key('route-location')),
    );
    expect(location.data, contains('/trades/create/owner-1'));
    expect(location.data, contains('item=binder-1'));
    expect(location.data, contains('type=trade'));
    expect(location.data, contains('source=deck_missing'));
  });

  testWidgets('empty match state offers the canonical Marketplace action', (
    tester,
  ) async {
    final provider = _TradeMatchesProvider(
      const CommunityTradeMatchSearchResult(
        matches: [],
        source: 'all_deck_missing_and_wishlist',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CommunityProvider>.value(
        value: provider,
        child: const MaterialApp(home: TradeMatchesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trade-matches-empty')), findsOneWidget);
    expect(
      find.byKey(const Key('trade-matches-empty-marketplace')),
      findsOneWidget,
    );
  });

  testWidgets('match failure is explicit and retryable', (tester) async {
    final provider = _TradeMatchesProvider(
      const CommunityTradeMatchSearchResult(
        matches: [],
        source: 'error',
        error: 'Falha controlada.',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CommunityProvider>.value(
        value: provider,
        child: const MaterialApp(home: TradeMatchesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trade-matches-error')), findsOneWidget);
    expect(find.text('Falha controlada.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trade-matches-retry')));
    await tester.pumpAndSettle();
    expect(provider.calls, 2);
  });
}
