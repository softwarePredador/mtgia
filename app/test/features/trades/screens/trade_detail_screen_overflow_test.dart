import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/trade_detail_screen.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}
class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(apiClient: _NoopApiClient());
  @override User? get user => User(id: 'test', username: 'test', email: 'test@test.com');
}
class _FakeTradeProvider extends TradeProvider {
  @override Future<void> fetchTradeDetail(String id) async {}
  @override Future<void> fetchMessages(String tradeId, {int page = 1, int limit = 50}) async {}
}

Widget _buildScreen() {
  return MaterialApp(
    home: Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuthProvider()),
          ChangeNotifierProvider<TradeProvider>(create: (_) => _FakeTradeProvider()),
        ],
        child: TradeDetailScreen(tradeId: 'test-id'),
      ),
    ),
  );
}

Future<void> _pumpWithSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(_buildScreen());
  await tester.pumpAndSettle();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets('TradeDetailScreen no overflow at 320px', (tester) async {
    await _pumpWithSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TradeDetailScreen no overflow at 375px', (tester) async {
    await _pumpWithSize(tester, const Size(375, 812));
    expect(tester.takeException(), isNull);
  });
}
