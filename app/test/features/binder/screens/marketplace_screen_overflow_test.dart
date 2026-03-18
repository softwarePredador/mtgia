import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/marketplace_screen.dart';
import 'package:provider/provider.dart';

class _FakeBinderProvider extends BinderProvider {
  _FakeBinderProvider(this._items);

  final List<MarketplaceItem> _items;

  @override
  List<MarketplaceItem> get marketItems => _items;

  @override
  bool get isLoadingMarket => false;

  @override
  String? get marketError => null;

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
      expect(tester.takeException(), isNull);
    },
  );
}
