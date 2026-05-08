import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/create_trade_screen.dart';
import 'package:manaloom/features/trades/screens/trade_detail_screen.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

class _FakeBinderProvider extends BinderProvider {
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
    return [];
  }
}

class _RecordingCreateTradeProvider extends TradeProvider {
  int createCalls = 0;

  @override
  Future<bool> createTrade({
    required String receiverId,
    String type = 'trade',
    String? message,
    List<Map<String, dynamic>> myItems = const [],
    List<Map<String, dynamic>> requestedItems = const [],
    double? paymentAmount,
    String? paymentMethod,
  }) async {
    createCalls++;
    return true;
  }
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this._user) : super(apiClient: _NoopApiClient());

  final User _user;

  @override
  User? get user => _user;
}

class _DetailTradeProvider extends TradeProvider {
  _DetailTradeProvider(this.trade);

  final TradeOffer trade;
  int respondCalls = 0;
  int updateCalls = 0;
  String? lastAction;
  String? lastStatus;

  @override
  TradeOffer? get selectedTrade => trade;

  @override
  bool get isLoading => false;

  @override
  List<TradeMessage> get chatMessages => const [];

  @override
  Future<void> fetchTradeDetail(
    String tradeId, {
    bool forceRefresh = false,
  }) async {}

  @override
  Future<void> fetchMessages(
    String tradeId, {
    int page = 1,
    int limit = 50,
  }) async {}

  @override
  void clearSelectedTrade() {}

  @override
  Future<bool> respondToTrade(String tradeId, String action) async {
    respondCalls++;
    lastAction = action;
    return true;
  }

  @override
  Future<bool> updateTradeStatus(
    String tradeId,
    String status, {
    String? trackingCode,
    String? deliveryMethod,
    String? notes,
  }) async {
    updateCalls++;
    lastStatus = status;
    return true;
  }
}

void main() {
  testWidgets('CreateTradeScreen opens final review before sending proposal', (
    tester,
  ) async {
    final tradeProvider = _RecordingCreateTradeProvider();
    final preselectedItem = BinderItem(
      id: 'binder-1',
      cardId: 'card-1',
      cardName: 'Doubling Season',
      quantity: 1,
      condition: 'LP',
      forSale: true,
      price: 100,
      currency: 'BRL',
      language: 'pt',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BinderProvider>(
            create: (_) => _FakeBinderProvider(),
          ),
          ChangeNotifierProvider<TradeProvider>.value(value: tradeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: CreateTradeScreen(
            receiverId: 'receiver-1',
            initialType: 'sale',
            preselectedItem: preselectedItem,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-trade-type-sale')), findsOneWidget);
    expect(find.byKey(const Key('create-trade-payment-field')), findsOneWidget);
    expect(
      find.byKey(const Key('create-trade-selected-item-requested-0')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('create-trade-payment-field')),
      '10',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('create-trade-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('create-trade-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-trade-review-dialog')), findsOneWidget);
    expect(find.text('Revisar proposta'), findsOneWidget);
    expect(find.textContaining('1x Doubling Season • LP • pt'), findsOneWidget);
    expect(find.textContaining('O valor pedido parece maior'), findsOneWidget);
    expect(tradeProvider.createCalls, 0);

    await tester.tap(
      find.byKey(const ValueKey('create-trade-review-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(tradeProvider.createCalls, 1);
  });

  testWidgets('TradeDetailScreen confirms accept before provider action', (
    tester,
  ) async {
    final provider = _DetailTradeProvider(
      _trade(status: 'pending', receiverId: 'user-1'),
    );

    await _pumpTradeDetail(tester, provider, currentUserId: 'user-1');

    final acceptButton = find.byKey(const Key('trade-action-accept'));
    await tester.ensureVisible(acceptButton);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    expect(find.text('Aceitar trade?'), findsOneWidget);
    expect(find.textContaining('A proposta passará para'), findsOneWidget);
    expect(provider.respondCalls, 0);

    await tester.tap(find.text('Aceitar trade'));
    await tester.pumpAndSettle();

    expect(provider.respondCalls, 1);
    expect(provider.lastAction, 'accept');
  });

  testWidgets('TradeDetailScreen confirms delivery before status update', (
    tester,
  ) async {
    final provider = _DetailTradeProvider(
      _trade(status: 'shipped', senderId: 'user-1'),
    );

    await _pumpTradeDetail(tester, provider, currentUserId: 'user-1');

    final confirmDeliveryButton = find.byKey(
      const Key('trade-action-confirm-delivery'),
    );
    await tester.ensureVisible(confirmDeliveryButton);
    await tester.tap(confirmDeliveryButton);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega?'), findsOneWidget);
    expect(find.textContaining('Você confirma que recebeu'), findsOneWidget);
    expect(provider.updateCalls, 0);

    await tester.tap(find.text('Confirmar entrega'));
    await tester.pumpAndSettle();

    expect(provider.updateCalls, 1);
    expect(provider.lastStatus, 'delivered');
  });
}

Future<void> _pumpTradeDetail(
  WidgetTester tester,
  _DetailTradeProvider provider, {
  required String currentUserId,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TradeProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(
          value: _FakeAuthProvider(
            User(
              id: currentUserId,
              username: 'qa_user',
              email: 'qa@example.com',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const TradeDetailScreen(tradeId: 'trade-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TradeOffer _trade({
  required String status,
  String senderId = 'sender-1',
  String receiverId = 'receiver-1',
}) {
  final now = DateTime(2026, 4, 30, 12);
  return TradeOffer(
    id: 'trade-123456',
    status: status,
    type: 'trade',
    sender: TradeUser(id: senderId, username: 'sender'),
    receiver: TradeUser(id: receiverId, username: 'receiver'),
    createdAt: now,
    updatedAt: now,
    myItems: [
      TradeItem(
        id: 'item-1',
        binderItemId: 'binder-1',
        direction: 'offering',
        quantity: 1,
        condition: 'NM',
        agreedPrice: 20,
        card: TradeItemCard(id: 'card-1', name: 'Sol Ring'),
      ),
    ],
    theirItems: [
      TradeItem(
        id: 'item-2',
        binderItemId: 'binder-2',
        direction: 'requesting',
        quantity: 1,
        condition: 'LP',
        agreedPrice: 22,
        card: TradeItemCard(id: 'card-2', name: 'Arcane Signet'),
      ),
    ],
  );
}
