import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/mana_symbols.dart';

void main() {
  test('normalizes Scryfall symbol filenames and parses a mana cost', () {
    expect(ManaSymbol.assetFilename('{w/u}'), 'W-U');
    expect(ManaCostRow.parse('{1}{G}{W/U}{W/P}{S}{T}'), [
      '1',
      'G',
      'W/U',
      'W/P',
      'S',
      'T',
    ]);
  });

  test('normalizes, deduplicates and orders color identity as WUBRG', () {
    expect(ColorIdentityPips.normalizeColors(['g', 'W', 'U', 'G', 'invalid']), [
      'W',
      'U',
      'G',
    ]);
    expect(ColorIdentityPips.normalizeColors([], colorlessWhenEmpty: true), [
      'C',
    ]);
    expect(ColorIdentityPips.normalizeColors([]), isEmpty);
  });

  testWidgets('renders mana cost and oracle symbols as SVG assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ManaCostRow(cost: '{2}{W/U}{R}'),
              OracleTextWidget('{T}: Adicione {G}.'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(5));
    expect(find.text('W/U'), findsNothing);
    expect(find.text('R'), findsNothing);
    expect(find.text('G'), findsNothing);
  });

  testWidgets('distinguishes pending identity from known colorless identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ColorIdentityPips(colors: []),
              ColorIdentityPips(colors: [], colorlessWhenEmpty: true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('C'), findsNothing);
  });
}
