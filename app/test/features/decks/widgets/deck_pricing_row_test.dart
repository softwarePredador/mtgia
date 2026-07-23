import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/widgets/deck_details_aux_widgets.dart';

void main() {
  Widget subject(Map<String, dynamic>? pricing) {
    return MaterialApp(
      home: Scaffold(
        body: DeckPricingRow(
          pricing: pricing,
          isLoading: false,
          onForceRefresh: () {},
          onShowDetails: () {},
        ),
      ),
    );
  }

  testWidgets('shows an unavailable total without inventing zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject({
        'estimated_total_usd': null,
        'currency': 'USD',
        'missing_price_cards': 100,
        'pricing_updated_at': '2026-07-22T00:00:00Z',
        'items': const [],
      }),
    );

    expect(find.textContaining('Nenhum preço disponível'), findsOneWidget);
    expect(find.textContaining('100 sem preço'), findsOneWidget);
    expect(find.textContaining('0,00'), findsNothing);
    expect(find.text('Detalhes'), findsNothing);
  });

  testWidgets('labels partial total and provenance', (tester) async {
    await tester.pumpWidget(
      subject({
        'estimated_total_usd': 42.5,
        'currency': 'USD',
        'missing_price_cards': 2,
        'price_source': 'scryfall',
        'items': const [
          {'name': 'Sol Ring'},
        ],
      }),
    );

    expect(find.textContaining('Parcial: US\$ 42,50'), findsOneWidget);
    expect(find.textContaining('2 sem preço'), findsOneWidget);
    expect(find.textContaining('Fonte Scryfall'), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);
  });
}
