import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/marketplace_screen.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:provider/provider.dart';

class _FakeBinderProvider extends BinderProvider {
  _FakeBinderProvider(
    this._items, {
    this.loading = false,
    this.marketErrorOverride,
  });

  final List<MarketplaceItem> _items;
  final bool loading;
  final String? marketErrorOverride;

  @override
  List<MarketplaceItem> get marketItems => _items;

  @override
  bool get isLoadingMarket => loading;

  @override
  String? get marketError => marketErrorOverride;

  @override
  bool get hasMoreMarket => false;

  @override
  Future<void> fetchMarketplace({
    String? search,
    String? condition,
    bool? forTrade,
    bool? forSale,
    bool reset = false,
  }) async {}
}

void main() {
  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildTestWidget(double width, BinderProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BinderProvider>.value(value: provider),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: const TextScaler.linear(1.25),
          ),
          child: Scaffold(
            body: SizedBox(width: width, child: const MarketplaceTabContent()),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'MarketplaceTabContent nao sofre overflow com badges e preco em largura estreita',
    (tester) async {
      final provider = _FakeBinderProvider([
        MarketplaceItem(
          id: 'market-1',
          cardId: 'card-1',
          cardName: 'Kenrith, the Returned King',
          quantity: 12,
          condition: 'Near Mint',
          isFoil: true,
          forTrade: true,
          forSale: true,
          price: 1234.56,
          currency: 'BRL',
          ownerId: 'user-1',
          ownerUsername: 'usuario_teste',
          ownerDisplayName: 'Usuario Teste',
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(320, provider));
      await tester.pumpAndSettle();

      expect(find.text('Kenrith, the Returned King'), findsOneWidget);
      expect(find.byTooltip('Limpar busca'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('marketplace-search-field')),
        'Kenrith',
      );
      await tester.pump();
      expect(find.byTooltip('Limpar busca'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Marketplace bounds desktop canvas and search width', (
    tester,
  ) async {
    await setViewport(tester, const Size(1280, 900));
    final provider = _FakeBinderProvider([
      MarketplaceItem(
        id: 'desktop-market',
        cardId: 'desktop-card',
        cardName: 'Command Tower',
        quantity: 1,
        condition: 'NM',
        forTrade: true,
        ownerId: 'desktop-owner',
        ownerUsername: 'desktop_user',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget(1280, provider));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const Key('marketplace-responsive-canvas')))
          .width,
      lessThanOrEqualTo(1280),
    );
    expect(
      tester.getSize(find.byKey(const Key('marketplace-search-field'))).width,
      lessThanOrEqualTo(760),
    );
    expect(
      tester.getSize(find.byKey(const Key('marketplace-list'))).width,
      lessThanOrEqualTo(900),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Marketplace item abre detalhe da carta', (tester) async {
    final provider = _FakeBinderProvider([
      MarketplaceItem(
        id: 'market-detail-1',
        cardId: 'card-detail-1',
        cardName: 'Arcane Signet',
        cardSetCode: 'cmm',
        cardManaCost: '{2}',
        cardRarity: 'common',
        cardTypeLine: 'Artifact',
        quantity: 1,
        condition: 'NM',
        forTrade: true,
        ownerId: 'user-1',
        ownerUsername: 'usuario_teste',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget(390, provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arcane Signet'));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailScreen), findsOneWidget);
    expect(find.text('Arcane Signet'), findsWidgets);
    expect(find.text('Artifact'), findsOneWidget);
  });

  testWidgets(
    'MarketplaceTabContent exposes keyed loading, error and empty states',
    (tester) async {
      await tester.pumpWidget(
        buildTestWidget(390, _FakeBinderProvider(const [], loading: true)),
      );
      await tester.pump();
      expect(find.byKey(const Key('marketplace-list-loading')), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          390,
          _FakeBinderProvider(
            const [],
            marketErrorOverride: 'Falha controlada',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('marketplace-list-error')), findsOneWidget);
      expect(find.byKey(const Key('marketplace-list-empty')), findsNothing);

      await tester.pumpWidget(
        buildTestWidget(390, _FakeBinderProvider(const [])),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('marketplace-list-empty')), findsOneWidget);
    },
  );
}
