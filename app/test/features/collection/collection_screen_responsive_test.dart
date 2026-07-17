import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/collection/screens/collection_screen.dart';
import 'package:manaloom/features/collection/screens/latest_set_collection_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:provider/provider.dart';

class _CollectionBinderProvider extends BinderProvider {
  @override
  Future<void> fetchStats() async {}

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
  }) async => const [];

  @override
  Future<void> fetchMarketplace({
    String? search,
    String? condition,
    bool? forTrade,
    bool? forSale,
    bool reset = false,
  }) async {}
}

class _CollectionTradeProvider extends TradeProvider {
  @override
  Future<void> fetchTrades({
    String? status,
    String role = 'all',
    int page = 1,
    int limit = 20,
  }) async {}
}

class _LatestSetApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/sets?')) {
      return ApiResponse(200, {
        'data': [
          {
            'code': 'TST',
            'name': 'Test Set',
            'release_date': '2026-01-01',
            'type': 'expansion',
            'card_count': 1,
            'status': 'current',
          },
        ],
      });
    }
    if (endpoint.startsWith('/cards?set=TST')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'latest-card',
            'name': 'Latest Card',
            'type_line': 'Artifact',
            'set_code': 'tst',
            'rarity': 'rare',
          },
        ],
      });
    }
    return ApiResponse(404, {'error': 'not found'});
  }
}

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget collectionScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BinderProvider>(
          create: (_) => _CollectionBinderProvider(),
        ),
        ChangeNotifierProvider<TradeProvider>(
          create: (_) => _CollectionTradeProvider(),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CollectionScreen(),
      ),
    );
  }

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    testWidgets('collection hub is bounded without overflow at ${size.width}', (
      tester,
    ) async {
      setViewport(tester, size);
      await tester.pumpWidget(collectionScreen());
      await tester.pumpAndSettle();

      final tabsCanvas = tester.getSize(
        find.byKey(const Key('collection-hub-tabs-canvas')),
      );
      final expectedGutter = size.width < 600 ? 16.0 : 24.0;
      expect(tabsCanvas.width, closeTo(size.width - expectedGutter * 2, 0.1));
      expect(tabsCanvas.width, lessThanOrEqualTo(1280));
      expect(tester.takeException(), isNull);
    });

    testWidgets('latest set preserves bounded content at ${size.width}', (
      tester,
    ) async {
      setViewport(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: LatestSetCollectionScreen(apiClient: _LatestSetApiClient()),
        ),
      );
      await tester.pumpAndSettle();

      final canvas = tester.getSize(
        find.byKey(const Key('set-cards-responsive-canvas')),
      );
      expect(canvas.width, lessThanOrEqualTo(1280));
      expect(
        find.byKey(Key(size.width < 960 ? 'setCardsList' : 'setCardsGrid')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
