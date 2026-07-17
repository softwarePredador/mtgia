import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';

DeckCardItem _sampleCard() {
  return DeckCardItem(
    id: 'card-responsive-1',
    name: 'Bilbo, Luckwearer // Burglar\'s Plot',
    manaCost: '{1}{U}',
    typeLine: 'Legendary Creature — Halfling Rogue',
    oracleText: 'Whenever Bilbo attacks, draw a card.',
    setCode: 'ltr',
    setName: 'The Lord of the Rings',
    rarity: 'rare',
    quantity: 1,
    isCommander: false,
  );
}

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: CardDetailScreen(card: _sampleCard()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop constrains card preview and keeps details alongside', (
    tester,
  ) async {
    await _pumpAtSize(tester, const Size(1440, 900));

    final imageSize = tester.getSize(
      find.byKey(const Key('card-detail-image-frame')),
    );

    expect(imageSize.width, 400);
    expect(imageSize.height, closeTo(400 * 88 / 63, 0.1));
    expect(find.text('Texto de Regras'), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.byTooltip('Ampliar imagem'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Ampliar imagem de Bilbo, Luckwearer // Burglar\'s Plot',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet caps preview while mobile keeps the available width', (
    tester,
  ) async {
    await _pumpAtSize(tester, const Size(800, 1000));
    expect(
      tester.getSize(find.byKey(const Key('card-detail-image-frame'))).width,
      420,
    );

    await _pumpAtSize(tester, const Size(390, 844));
    final mobileSize = tester.getSize(
      find.byKey(const Key('card-detail-image-frame')),
    );
    expect(mobileSize.width, 390);
    expect(mobileSize.height, closeTo(390 * 88 / 63, 0.1));
    expect(tester.takeException(), isNull);
  });
}
