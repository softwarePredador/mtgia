import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/card_artwork.dart';

void main() {
  test('full-card variants preserve the printed card geometry', () {
    for (final variant in const [
      CardArtworkVariant.gallery,
      CardArtworkVariant.spotlight,
      CardArtworkVariant.recentDeck,
      CardArtworkVariant.fullCard,
    ]) {
      final spec = CardArtworkSpec.forVariant(variant);
      expect(spec.aspectRatio, CardArtworkSpec.mtgCardAspectRatio);
      expect(spec.fit, BoxFit.contain);
    }
  });

  test('crop variants are intentional and have stable ratios', () {
    final artCrop = CardArtworkSpec.forVariant(CardArtworkVariant.artCrop);
    final setArt = CardArtworkSpec.forVariant(CardArtworkVariant.setArt);

    expect(artCrop.aspectRatio, 16 / 9);
    expect(artCrop.fit, BoxFit.cover);
    expect(setArt.aspectRatio, 3 / 2);
    expect(setArt.fit, BoxFit.cover);
  });

  testWidgets('renders semantic alt text and forwards focal alignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 315,
            child: CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: 'https://cards.scryfall.io/normal/front/a/b/card.jpg',
              semanticLabel: 'Carta de teste',
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Carta de teste'), findsOneWidget);

    final ratio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(CardArtwork),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(ratio.aspectRatio, CardArtworkSpec.mtgCardAspectRatio);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.topCenter);
  });
}
