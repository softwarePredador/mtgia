import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/utils/scryfall_image_helper.dart';

void main() {
  group('ScryfallImageHelper', () {
    test('rewrites persisted card CDN URLs without an API lookup', () {
      const normal =
          'https://cards.scryfall.io/normal/front/a/b/abc.jpg?1700000000';
      expect(
        ScryfallImageHelper.withVersion(normal, version: 'art_crop'),
        'https://cards.scryfall.io/art_crop/front/a/b/abc.jpg?1700000000',
      );
    });

    test('updates named image rendition while preserving the exact name', () {
      final normal = ScryfallImageHelper.namedImageUrl('Atraxa, Grand Unifier');
      final small = ScryfallImageHelper.withVersion(normal, version: 'small');

      expect(
        Uri.parse(small!).queryParameters['exact'],
        'Atraxa, Grand Unifier',
      );
      expect(Uri.parse(small).queryParameters['version'], 'small');
    });

    test('rewrites direct printing API image URLs', () {
      const direct =
          'https://api.scryfall.com/cards/41c83142-b948-4ee5-a486-41306d2bb411?format=image&version=normal';
      final small = ScryfallImageHelper.withVersion(direct, version: 'small');

      final uri = Uri.parse(small!);
      expect(uri.path, '/cards/41c83142-b948-4ee5-a486-41306d2bb411');
      expect(uri.queryParameters['format'], 'image');
      expect(uri.queryParameters['version'], 'small');
    });

    test('rewrites set and collector image routes without losing identity', () {
      const direct =
          '//api.scryfall.com/cards/mom/65?format=image&version=large';
      final normal = ScryfallImageHelper.withVersion(direct, version: 'normal');

      final uri = Uri.parse(normal!);
      expect(uri.scheme, 'https');
      expect(uri.path, '/cards/mom/65');
      expect(uri.queryParameters['version'], 'normal');
    });

    test('canonical card image replaces unknown hosts when name is known', () {
      final canonical = ScryfallImageHelper.canonicalCardImageUrl(
        explicitUrl: 'https://cdn.example.test/full-card.jpg',
        cardName: 'Auntie Ool, Cursewretch',
      );

      final uri = Uri.parse(canonical!);
      expect(uri.host, 'api.scryfall.com');
      expect(uri.path, '/cards/named');
      expect(uri.queryParameters['exact'], 'Auntie Ool, Cursewretch');
      expect(uri.queryParameters['version'], 'normal');
    });

    test('canonical card image rejects unknown geometry without a name', () {
      expect(
        ScryfallImageHelper.canonicalCardImageUrl(
          explicitUrl: 'https://cdn.example.test/full-card.jpg',
          cardName: null,
        ),
        isNull,
      );
    });

    test('keeps non-Scryfall persisted artwork as the preferred source', () {
      expect(
        ScryfallImageHelper.preferredImageUrl(
          explicitUrl: 'https://cdn.example.test/card.jpg',
          cardName: 'Card',
          version: 'art_crop',
        ),
        'https://cdn.example.test/card.jpg',
      );
    });
  });
}
