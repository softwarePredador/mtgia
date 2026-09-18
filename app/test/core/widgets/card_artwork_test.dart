import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/card_artwork.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'cached_card_image_test.dart'
    show
        ArtworkTestCache,
        artworkDecoded,
        artworkTestHost,
        withArtworkCache,
        pumpArtworkUntil,
        settleArtwork;

void main() {
  CachedNetworkImageProvider.defaultCacheManager = ArtworkTestCache(
    allowUnconfigured: true,
  );
  testWidgets('real fallback and exhausted error preserve artwork semantics', (
    tester,
  ) async {
    for (final succeeds in [true, false]) {
      await withArtworkCache(tester, (cache) async {
        const primary = 'https://artwork-lifecycle.invalid/normal/primary.webp';
        const fallback =
            'https://artwork-lifecycle.invalid/normal/fallback.webp';
        cache.register(primary);
        cache.register(fallback);
        await tester.pumpWidget(
          artworkTestHost(
            const CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: primary,
              fallbackImageUrl: fallback,
              semanticLabel: 'Fallback card',
            ),
          ),
        );
        cache.complete(primary, success: false);
        await pumpArtworkUntil(tester, () => cache.requests.contains(fallback));
        cache.complete(fallback, success: succeeds);
        final badge = Key(
          succeeds
              ? 'card-artwork-status-reference'
              : 'card-artwork-status-error',
        );
        await pumpArtworkUntil(
          tester,
          () => find.byKey(badge).evaluate().isNotEmpty,
        );
        if (succeeds) {
          await pumpArtworkUntil(tester, () => artworkDecoded(tester));
        }
        await settleArtwork(tester);
        expect(
          find.bySemanticsLabel(
            succeeds
                ? 'Fallback card, arte de referência'
                : 'Fallback card, falha ao carregar imagem',
          ),
          findsOneWidget,
        );
      });
    }
  });
  testWidgets(
    'decoded artwork settles and retains readiness across reference changes',
    (tester) async {
      await withArtworkCache(tester, (cache) async {
        const url = 'https://artwork-lifecycle.invalid/normal/artwork.webp';
        cache.register(url);
        const key = ValueKey('artwork');
        Widget image({bool reference = false, bool offline = false}) =>
            artworkTestHost(
              CardArtwork(
                key: key,
                variant: CardArtworkVariant.fullCard,
                imageUrl: url,
                semanticLabel: 'Loaded card',
                imageIsReference: reference,
                offline: offline,
              ),
            );
        await tester.pumpWidget(image());
        expect(artworkDecoded(tester), isFalse);
        cache.complete(url);
        await pumpArtworkUntil(tester, () => artworkDecoded(tester));
        await settleArtwork(tester);
        expect(find.bySemanticsLabel('Loaded card'), findsOneWidget);
        final requests = cache.requests.length;
        final originalState = tester.state(find.byKey(key));
        await tester.pumpWidget(image(reference: true));
        await settleArtwork(tester);
        expect(
          find.byKey(const Key('card-artwork-status-reference')),
          findsOneWidget,
        );
        await tester.pumpWidget(image());
        await settleArtwork(tester);
        expect(tester.state(find.byKey(key)), same(originalState));
        expect(find.bySemanticsLabel('Loaded card'), findsOneWidget);
        expect(cache.requests.length, requests);
        await tester.pumpWidget(image(offline: true));
        await settleArtwork(tester);
        expect(
          find.byKey(const Key('card-artwork-status-offline')),
          findsOneWidget,
        );
        expect(cache.requests.length, requests);
      });
    },
  );

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

  test('classifies declared Scryfall image resolution without guessing', () {
    expect(
      cardArtworkResolutionForUrl(
        'https://cards.scryfall.io/small/front/a/b/card.jpg',
      ),
      CardArtworkResolution.low,
    );
    expect(
      cardArtworkResolutionForUrl(
        'https://cards.scryfall.io/normal/front/a/b/card.jpg',
      ),
      CardArtworkResolution.standard,
    );
    expect(
      cardArtworkResolutionForUrl(
        'https://cards.scryfall.io/large/front/a/b/card.jpg',
      ),
      CardArtworkResolution.high,
    );
    expect(
      cardArtworkResolutionForUrl(
        'https://api.scryfall.com/cards/named?exact=Opt&version=small',
      ),
      CardArtworkResolution.low,
    );
    expect(
      cardArtworkResolutionForUrl('https://images.example.test/card.jpg'),
      CardArtworkResolution.unknown,
    );
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

    expect(
      find.bySemanticsLabel('Carta de teste, carregando imagem'),
      findsOneWidget,
    );

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

  testWidgets('labels known reference art without duplicating semantics', (
    tester,
  ) async {
    const reference =
        'https://api.scryfall.com/cards/named?exact=Opt&format=image';
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            child: CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: reference,
              fallbackImageUrl: reference,
              semanticLabel: 'Arte de referência de Opt',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('card-artwork-status-reference')),
      findsOneWidget,
    );
    expect(find.text('Referência'), findsOneWidget);
    expect(find.bySemanticsLabel('Arte de referência de Opt'), findsOneWidget);
  });

  testWidgets('compact reference art keeps the status inside its frame', (
    tester,
  ) async {
    const reference =
        'https://api.scryfall.com/cards/named?exact=Opt&format=image';
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 92,
            child: CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: reference,
              semanticLabel: 'Arte compacta de referência de Opt',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('card-artwork-status-reference')),
      findsOneWidget,
    );
    expect(find.text('Referência'), findsNothing);
    expect(
      find.bySemanticsLabel('Arte compacta de referência de Opt'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('distinguishes missing, explicit offline and load failure', (
    tester,
  ) async {
    Future<void> pumpArtwork({String? imageUrl, bool offline = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 180,
              child: CardArtwork(
                variant: CardArtworkVariant.fullCard,
                imageUrl: imageUrl,
                semanticLabel: 'Carta de teste',
                offline: offline,
              ),
            ),
          ),
        ),
      );
    }

    await pumpArtwork();
    expect(
      find.byKey(const Key('card-artwork-status-missing')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Carta de teste, imagem não disponível'),
      findsOneWidget,
    );

    await pumpArtwork(
      imageUrl: 'https://cards.scryfall.io/normal/front/a/b/card.jpg',
      offline: true,
    );
    expect(
      find.byKey(const Key('card-artwork-status-offline')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Carta de teste, imagem não disponível sem conexão',
      ),
      findsOneWidget,
    );

    await pumpArtwork(
      imageUrl: 'https://cards.scryfall.io/normal/front/a/b/card.jpg',
    );
    final image = tester.widget<CachedCardImage>(find.byType(CachedCardImage));
    image.onLoadStateChanged!(CardImageLoadState.failed);
    await tester.pump();
    expect(find.byKey(const Key('card-artwork-status-error')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Carta de teste, falha ao carregar imagem'),
      findsOneWidget,
    );
  });

  testWidgets('surfaces low resolution only after exact art becomes ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            child: CardArtwork(
              variant: CardArtworkVariant.fullCard,
              imageUrl: 'https://cards.scryfall.io/small/front/a/b/card.jpg',
              semanticLabel: 'Carta de teste',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('card-artwork-status-low-resolution')),
      findsNothing,
    );
    final image = tester.widget<CachedCardImage>(find.byType(CachedCardImage));
    image.onLoadStateChanged!(CardImageLoadState.primaryReady);
    await tester.pump();

    expect(
      find.byKey(const Key('card-artwork-status-low-resolution')),
      findsOneWidget,
    );
    expect(find.text('Baixa resolução'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Carta de teste, imagem em baixa resolução'),
      findsOneWidget,
    );
  });
}
