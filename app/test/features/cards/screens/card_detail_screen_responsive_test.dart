import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/screens/card_detail_screen.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';

import '../../../ui/support/manaloom_ui_audit_harness.dart';

DeckCardItem _sampleCard({
  String name = 'Bilbo, Luckwearer // Burglar\'s Plot',
  String? imageUrl,
  String oracleText = 'Whenever Bilbo attacks, draw a card.',
}) {
  return DeckCardItem(
    id: 'card-responsive-1',
    name: name,
    manaCost: '{1}{U}',
    typeLine: 'Legendary Creature — Halfling Rogue',
    oracleText: oracleText,
    imageUrl: imageUrl,
    setCode: 'ltr',
    setName: 'The Lord of the Rings',
    rarity: 'rare',
    quantity: 1,
    isCommander: false,
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size, {
  DeckCardItem? card,
  double textScale = 1,
}) async {
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: CardDetailScreen(card: card ?? _sampleCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('card detail location is canonical and URL-safe', () {
    expect(
      cardDetailRouteLocation('card id/printing'),
      '/cards/card%20id%2Fprinting',
    );
  });

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
    final semantics = tester.ensureSemantics();
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
    await expectManaLoomBaselineAccessibility(tester);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ultra-wide keeps a readable canvas and a 400px full card', (
    tester,
  ) async {
    await _pumpAtSize(tester, const Size(1920, 1080));

    final imageSize = tester.getSize(
      find.byKey(const Key('card-detail-image-frame')),
    );
    expect(imageSize.width, 400);
    expect(imageSize.height, closeTo(400 * 88 / 63, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing and failed artwork keep stable card geometry', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const Size(390, 844),
      card: _sampleCard(
        imageUrl: 'https://invalid.example.test/missing-card.jpg',
      ),
    );
    final failedImage = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final failedFrameHeight = tester
        .getSize(find.byKey(const Key('card-detail-image-frame')))
        .height;
    final failure = failedImage.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      failedImage.imageUrl,
      Exception('fixture 404'),
    );
    await tester.pumpWidget(MaterialApp(home: failure));
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    expect(failedFrameHeight, closeTo(390 * 88 / 63, 0.1));

    await _pumpAtSize(
      tester,
      const Size(390, 844),
      card: DeckCardItem(
        id: 'missing-art',
        name: '',
        typeLine: 'Carta sem imagem',
        setCode: '',
        rarity: 'common',
        quantity: 1,
        isCommander: false,
      ),
    );
    expect(find.text('Sem imagem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double-faced card renders the complete front face by default', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const Size(390, 844),
      card: DeckCardItem(
        id: 'dfc-detail',
        name: 'Front Face // Back Face',
        typeLine: 'Creature // Land',
        layout: 'modal_dfc',
        cardFaces: const [
          CardFaceArtwork(
            name: 'Front Face',
            imageUrl: 'https://cards.scryfall.io/normal/front/dfc-detail.jpg',
          ),
          CardFaceArtwork(
            name: 'Back Face',
            imageUrl: 'https://cards.scryfall.io/normal/back/dfc-detail.jpg',
          ),
        ],
        setCode: 'tst',
        rarity: 'rare',
        quantity: 1,
        isCommander: false,
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(
      image.imageUrl,
      'https://cards.scryfall.io/normal/front/dfc-detail.jpg',
    );
    expect(image.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long split-card content remains reachable at 200% text', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const Size(390, 844),
      textScale: 2,
      card: _sampleCard(
        name:
            'Uma Frente Extraordinariamente Longa // Um Verso Ainda Mais Longo',
        oracleText: List.filled(
          8,
          'Quando esta mágica resolver, compre uma carta e escolha até um alvo.',
        ).join(' '),
      ),
    );

    expect(find.text('Texto de Regras'), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
