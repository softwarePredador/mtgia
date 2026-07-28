import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';

void main() {
  testWidgets('uses an original card-frame fallback when artwork is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: CachedCardImage(imageUrl: null, width: 80, height: 112),
        ),
      ),
    );

    expect(
      find.byKey(const Key('cached-card-image-placeholder')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ManaLoomGlyph && widget.kind == ManaLoomGlyphKind.card,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.style), findsNothing);
    expect(find.byIcon(Icons.image_not_supported), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

    if (kIsWeb) {
      await tester.pump(const Duration(milliseconds: 200));
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      final uri = Uri.parse(provider.url);
      expect(uri.queryParameters['exact'], 'Jin-Gitaxias');
      expect(uri.queryParameters.containsKey('set'), isFalse);
      expect(uri.queryParameters['version'], 'normal');
      expect(provider.headers, isNull);
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
    } else {
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final uri = Uri.parse(image.imageUrl);
      expect(uri.queryParameters['exact'], 'Jin-Gitaxias');
      expect(uri.queryParameters.containsKey('set'), isFalse);
      expect(uri.queryParameters['version'], 'normal');
      expect(image.httpHeaders?['User-Agent'], 'ManaLoom/1.0');
      expect(image.httpHeaders?['Accept'], 'image/*');
    }
  });

  testWidgets('uses the HTML element strategy for direct Scryfall CDN art', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CachedCardImage(
          imageUrl: 'https://cards.scryfall.io/normal/front/a/b/card.jpg',
        ),
      ),
    );

    if (kIsWeb) {
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers, isNull);
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
    } else {
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    }
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

    if (kIsWeb) {
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
      expect(provider.headers, isNull);
    } else {
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.memCacheWidth, 256);
      expect(image.memCacheHeight, isNull);
      expect(image.maxWidthDiskCache, isNull);
      expect(image.maxHeightDiskCache, isNull);
    }
  });
}
