import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/growth/models/trade_match_summary.dart';
import 'package:manaloom/features/growth/widgets/community_trade_growth_panel.dart';
import 'package:flutter/material.dart';

void main() {
  test('summarizes binder stats into trade match signal', () {
    final summary = TradeMatchSummary.fromBinderStats(
      BinderStats(
        wishlistUniqueCards: 4,
        missingCardsCount: 3,
        forTradeCount: 5,
        duplicateCopies: 2,
      ),
    );

    expect(summary.hasTradeLoop, isTrue);
    expect(summary.tradePotentialScore, 10);
    expect(
      summary.primaryInsight,
      'Você já tem cartas faltantes e cartas para oferecer em troca.',
    );
  });

  testWidgets('community trade panel renders without BinderProvider', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CommunityTradeGrowthPanel())),
    );

    expect(
      find.byKey(const Key('community-trade-growth-panel')),
      findsOneWidget,
    );
    expect(find.text('Rede de decks e trocas'), findsOneWidget);
  });
}
