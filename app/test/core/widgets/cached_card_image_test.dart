import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';

void main() {
  test('HTTP image URLs stay secure outside an explicit loopback fixture', () {
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://images.example.test/card.png',
      ),
      'https://images.example.test/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://127.0.0.1:8080/card.png',
      ),
      'https://127.0.0.1:8080/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://127.0.0.1:8080/card.png',
        allowLoopbackHttp: true,
      ),
      'http://127.0.0.1:8080/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://images.example.test/card.png',
        allowLoopbackHttp: true,
      ),
      'https://images.example.test/card.png',
    );
  });

  test('selects a bounded Scryfall CDN variant for the decode target', () {
    const normal =
        'https://cards.scryfall.io/normal/front/a/b/card.jpg?version=1';
    const artCrop =
        'https://cards.scryfall.io/art_crop/front/a/b/card.jpg?version=1';

    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 128),
      'https://cards.scryfall.io/small/front/a/b/card.jpg?version=1',
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 384),
      normal,
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 1024),
      'https://cards.scryfall.io/large/front/a/b/card.jpg?version=1',
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(artCrop, decodeWidth: 128),
      artCrop,
    );
  });

  testWidgets('removes fragile set filter from Scryfall named image URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CachedCardImage(
          imageUrl:
              'https://api.scryfall.com/cards/named?exact=Jin-Gitaxias&set=mom&format=image',
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final uri = Uri.parse(image.imageUrl);
    expect(uri.queryParameters['exact'], 'Jin-Gitaxias');
    expect(uri.queryParameters.containsKey('set'), isFalse);
    expect(uri.queryParameters['version'], 'normal');
    expect(image.httpHeaders?['User-Agent'], 'ManaLoom/1.0');
    expect(image.httpHeaders?['Accept'], 'image/*');
  });

  testWidgets('bounds thumbnail decode without a second disk resize', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 3),
          child: Center(
            child: SizedBox(
              width: 60,
              height: 84,
              child: CachedCardImage(
                imageUrl: 'https://cards.scryfall.io/large/front/a/b/card.png',
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 256);
    expect(image.memCacheHeight, isNull);
    expect(image.maxWidthDiskCache, isNull);
    expect(image.maxHeightDiskCache, isNull);
  });
}
