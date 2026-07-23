import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/mana_symbols.dart';

void main() {
  test('ships every symbol family required by the product contract', () {
    const requiredAssets = <String>[
      'W',
      'U',
      'B',
      'R',
      'G',
      'C',
      '0',
      '1',
      '10',
      'X',
      'W-U',
      '2-R',
      'W-P',
      'B-G-P',
      'S',
      'T',
      'Q',
      'E',
    ];

    for (final symbol in requiredAssets) {
      expect(
        File('assets/symbols/$symbol.svg').existsSync(),
        isTrue,
        reason: 'Missing canonical mana/rules asset $symbol.svg',
      );
    }

    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/symbols/'),
    );
  });

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

  testWidgets('keeps hybrid, Phyrexian, snow, tap and energy semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ManaCostRow(cost: '{W/U}{B/P}{S}{T}{E}')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(5));
    expect(find.bySemanticsLabel('símbolo de mana W/U'), findsOneWidget);
    expect(find.bySemanticsLabel('símbolo de mana B/P'), findsOneWidget);
    expect(find.bySemanticsLabel('mana de neve'), findsOneWidget);
    expect(find.bySemanticsLabel('virar'), findsOneWidget);
    expect(find.bySemanticsLabel('energia'), findsOneWidget);
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
