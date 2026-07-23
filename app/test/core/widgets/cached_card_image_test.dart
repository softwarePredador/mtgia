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
}
