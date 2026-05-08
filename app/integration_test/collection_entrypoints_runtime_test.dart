import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/collection/screens/collection_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('collection hub exposes binder and sets entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => BinderProvider()),
          ChangeNotifierProvider(create: (_) => TradeProvider()),
          ChangeNotifierProvider(create: (_) => MessageProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: MaterialApp(
          title: 'ManaLoom Collection Runtime',
          theme: AppTheme.darkTheme,
          home: const CollectionScreen(),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Coleção'));
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Fichário'));
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Tenho'));

    await tester.tap(
      find.widgetWithText(Tab, 'Marketplace'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Buscar carta no marketplace...'));

    await tester.tap(find.widgetWithText(Tab, 'Trades'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Recebidas'));
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Enviadas'));
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Finalizadas'));

    await tester.tap(find.widgetWithText(Tab, 'Coleções'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Catálogo de Coleções'));
    await pumpUntilFound(tester, find.byKey(const Key('setsCatalogList')));

    await tester.tap(find.widgetWithText(Tab, 'Fichário'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.widgetWithText(Tab, 'Tenho'));
  });
}
