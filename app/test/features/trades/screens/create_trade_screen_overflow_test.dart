import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/create_trade_screen.dart';
import 'package:provider/provider.dart';

class _FakeTradeBinderProvider extends BinderProvider {
  _FakeTradeBinderProvider({this.failDirect = false, this.failPublic = false});

  final bool failDirect;
  final bool failPublic;
  int directCalls = 0;
  int publicCalls = 0;

  @override
  Future<List<BinderItem>?> fetchBinderDirect({
    required String listType,
    int page = 1,
    int limit = 20,
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
    String? setCode,
    String? rarity,
    String? language,
    bool? foil,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    directCalls++;
    return failDirect ? null : [];
  }

  @override
  Future<List<BinderItem>?> fetchPublicBinderDirect({
    required String userId,
    required String listType,
    int page = 1,
    int limit = 20,
  }) async {
    publicCalls++;
    return failPublic ? null : [];
  }
}

void main() {
  Widget buildTestWidget({
    required double width,
    required BinderItem preselectedItem,
    _FakeTradeBinderProvider? binderProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BinderProvider>(
          create: (_) => binderProvider ?? _FakeTradeBinderProvider(),
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
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
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
        buildTestWidget(width: 390, preselectedItem: preselectedItem),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipo de Negociação'), findsOneWidget);
      expect(find.text('Pagamento'), findsOneWidget);
      expect(find.byKey(const Key('create-trade-desktop-panes')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CreateTradeScreen usa panes e CTA contido em 1280px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final preselectedItem = BinderItem(
      id: 'binder-1',
      cardId: 'card-1',
      cardName: 'Atraxa, Praetors\' Voice',
      quantity: 1,
      condition: 'Near Mint',
      isFoil: false,
      forTrade: true,
      price: 100,
      currency: 'BRL',
      listType: 'have',
    );

    await tester.pumpWidget(
      buildTestWidget(width: 1280, preselectedItem: preselectedItem),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-trade-desktop-panes')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('create-trade-content'))).width,
      lessThanOrEqualTo(1120),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('create-trade-submit-button')))
          .width,
      240,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha do fichario nao vira lista vazia e oferece retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final binder = _FakeTradeBinderProvider(failDirect: true);
    final preselectedItem = BinderItem(
      id: 'binder-1',
      cardId: 'card-1',
      cardName: 'Sol Ring',
      forTrade: true,
    );

    await tester.pumpWidget(
      buildTestWidget(
        width: 390,
        preselectedItem: preselectedItem,
        binderProvider: binder,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-trade-binder-error')), findsOneWidget);
    expect(find.text('Você não tem itens marcados para troca'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('create-trade-binder-retry')),
    );
    await tester.tap(find.byKey(const Key('create-trade-binder-retry')));
    await tester.pumpAndSettle();
    expect(binder.directCalls, 2);
  });

  testWidgets('falha ao buscar itens publicos oferece nova tentativa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final binder = _FakeTradeBinderProvider(failPublic: true);
    final preselectedItem = BinderItem(
      id: 'binder-1',
      cardId: 'card-1',
      cardName: 'Sol Ring',
      forTrade: true,
    );

    await tester.pumpWidget(
      buildTestWidget(
        width: 390,
        preselectedItem: preselectedItem,
        binderProvider: binder,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-trade-add-item-requested')));
    await tester.pump();

    expect(
      find.text('Não foi possível carregar os itens do outro jogador.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('seletores customizados expõem estado e alvo mínimo de toque', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preselectedItem = BinderItem(
      id: 'binder-1',
      cardId: 'card-1',
      cardName: 'Sol Ring',
      forTrade: true,
    );

    await tester.pumpWidget(
      buildTestWidget(width: 390, preselectedItem: preselectedItem),
    );
    await tester.pumpAndSettle();

    final typeSemantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('create-trade-type-mixed')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(typeSemantics.properties.button, isTrue);
    expect(typeSemantics.properties.selected, isTrue);

    final paymentSemantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('create-trade-payment-method-pix')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(paymentSemantics.properties.button, isTrue);
    expect(paymentSemantics.properties.selected, isTrue);
    expect(
      tester
          .getSize(find.byKey(const Key('create-trade-payment-method-pix')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}
