import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/trades/widgets/trade_safety_notice.dart';

void main() {
  testWidgets('explica claramente o limite de intermediação do ManaLoom', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(width: 390, child: TradeSafetyNotice()),
        ),
      ),
    );

    expect(find.text('Combinação entre jogadores'), findsOneWidget);
    expect(
      find.textContaining('não recebe, guarda nem protege pagamentos'),
      findsOneWidget,
    );
    expect(
      find.textContaining('diretamente com o outro jogador'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
