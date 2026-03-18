import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/create_trade_screen.dart';
import 'package:provider/provider.dart';

class _FakeTradeBinderProvider extends BinderProvider {
  @override
  Future<List<BinderItem>?> fetchBinderDirect({
    required String listType,
    int page = 1,
    int limit = 20,
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
  }) async {
    return [];
  }
}

void main() {
  Widget buildTestWidget({
    required double width,
    required BinderItem preselectedItem,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BinderProvider>(
          create: (_) => _FakeTradeBinderProvider(),
        ),
        ChangeNotifierProvider<TradeProvider>(create: (_) => TradeProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: const TextScaler.linear(1.3),
          ),
          child: CreateTradeScreen(
            receiverId: 'user-2',
            initialType: 'mixed',
            preselectedItem: preselectedItem,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'CreateTradeScreen nao sofre overflow com chips e item selecionado em largura estreita',
    (tester) async {
      final preselectedItem = BinderItem(
        id: 'binder-1',
        cardId: 'card-1',
        cardName: 'Atraxa, Praetors\' Voice with Very Long Commander Title',
        quantity: 3,
        condition: 'Near Mint',
        isFoil: true,
        forTrade: true,
        price: 987.65,
        currency: 'BRL',
        listType: 'have',
      );

      await tester.pumpWidget(
        buildTestWidget(width: 320, preselectedItem: preselectedItem),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo de Negociação'), findsOneWidget);
      expect(find.text('Pagamento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
