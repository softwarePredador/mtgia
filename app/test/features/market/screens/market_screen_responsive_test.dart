import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/market/screens/market_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class _MarketApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    return ApiResponse(200, {
      'date': '2026-07-16',
      'previous_date': '2026-07-15',
      'total_tracked': 1,
      'gainers': [
        {
          'card_id': 'card-1',
          'name': 'Black Lotus',
          'set_code': 'lea',
          'rarity': 'rare',
          'price_today': 100,
          'price_yesterday': 90,
          'change_usd': 10,
          'change_pct': 11.1,
        },
      ],
      'losers': <Map<String, dynamic>>[],
    });
  }
}

void main() {
  testWidgets('MarketScreen preserva mobile e limita lista no desktop', (
    tester,
  ) async {
    final provider = MarketProvider(apiClient: _MarketApiClient());
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in const [Size(390, 844), Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MarketProvider>.value(value: provider),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(),
            ),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider(),
            ),
          ],
          child: const MaterialApp(home: MarketScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final contentWidth =
          tester.getSize(find.byKey(const Key('market-content'))).width;
      expect(contentWidth, lessThanOrEqualTo(960));
      expect(contentWidth, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
    }
  });
}
