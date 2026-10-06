import 'package:server/scryfall_image_url.dart';
import 'package:test/test.dart';

void main() {
  const printingId = '00000000-0000-4000-8000-000000000011';
  const oracleId = '00000000-0000-4000-8000-000000000010';
  const directUrl =
      'https://cards.scryfall.io/normal/front/0/0/'
      '$printingId.jpg?123';

  group('Scryfall printing image resolution', () {
    test(
      'prefers MTGJSON identifiers.scryfallId over a generic payload id',
      () {
        final payload = <String, dynamic>{
          'id': '00000000-0000-4000-8000-000000000099',
          'identifiers': {
            'scryfallId': printingId,
            'scryfallOracleId': oracleId,
          },
        };

        expect(scryfallPrintingIdFromPayload(payload), printingId);
        expect(
          scryfallNormalImageUrlFromPayload(payload),
          'https://cards.scryfall.io/normal/front/0/0/$printingId.jpg',
        );
      },
    );

    test('persists payload image_uris.normal for the same printing', () {
      final payload = <String, dynamic>{
        'id': printingId,
        'oracle_id': oracleId,
        'image_uris': {'normal': directUrl},
      };

      expect(scryfallNormalImageUrlFromPayload(payload), directUrl);
    });

    test('uses first matching card face normal image', () {
      final payload = <String, dynamic>{
        'id': printingId,
        'oracle_id': oracleId,
        'card_faces': [
          {
            'image_uris': {'normal': directUrl},
          },
        ],
      };

      expect(scryfallNormalImageUrlFromPayload(payload), directUrl);
    });

    test('never treats oracle identity as a printing image key', () {
      final payload = <String, dynamic>{
        'identifiers': {'scryfallOracleId': oracleId},
      };

      expect(scryfallPrintingIdFromPayload(payload), isNull);
      expect(scryfallNormalImageUrlFromPayload(payload), isNull);
      expect(
        scryfallNamedImageFallback('Fire // Ice', setCode: 'DMR'),
        allOf(
          startsWith('https://api.scryfall.com/cards/named?'),
          contains('exact=Fire'),
          isNot(contains(oracleId)),
          contains('set=dmr'),
        ),
      );
    });
  });

  group('persisted URL compatibility', () {
    const legacy =
        'https://api.scryfall.com/cards/named'
        '?exact=Test%20Card&set=TST&format=image';

    test(
      'upgrades legacy lookup only with distinct printing/oracle evidence',
      () {
        expect(
          normalizeScryfallImageUrl(
            legacy,
            printingId: printingId,
            oracleId: oracleId,
          ),
          'https://cards.scryfall.io/normal/front/0/0/$printingId.jpg',
        );
      },
    );

    test(
      'preserves legacy lookup when scryfall_id is the old oracle alias',
      () {
        final normalized = normalizeScryfallImageUrl(
          legacy,
          printingId: oracleId,
          oracleId: oracleId,
        );

        expect(normalized, startsWith('https://api.scryfall.com/cards/named?'));
        expect(normalized, contains('set=tst'));
      },
    );

    test('repairs direct CDN scheme without routing through API', () {
      expect(
        normalizeScryfallImageUrl(
          '//cards.scryfall.io/normal/front/0/0/$printingId.jpg',
        ),
        'https://cards.scryfall.io/normal/front/0/0/$printingId.jpg',
      );
    });

    test('refuses card art from any host other than Scryfall (BT-ART-01)', () {
      for (final foreign in const [
        'https://evil.example/card.jpg',
        'https://cards.scryfall.io.example.test/normal/front/0/0/x.jpg',
        'http://images.example.test/card.jpg',
        'ftp://cards.scryfall.io/normal/front/0/0/x.jpg',
      ]) {
        expect(normalizeScryfallImageUrl(foreign), isNull, reason: foreign);
        expect(
          normalizeScryfallImageUrl(
            foreign,
            printingId: printingId,
            oracleId: oracleId,
          ),
          'https://cards.scryfall.io/normal/front/0/0/$printingId.jpg',
          reason: foreign,
        );
      }
    });

    test('keeps loopback fixture art only in the isolated E2E runtime', () {
      const fixtureUrl =
          'http://127.0.0.1:53167/app/assets/assets/branding/'
          'visual_fixture_arcane_ring.webp';
      const isolated = {
        'MANALOOM_E2E_ISOLATED_RUNTIME': '1',
        'MANALOOM_E2E_VALIDATION_RUN_TOKEN': 'server-contract-run_1',
      };
      expect(
        normalizeScryfallImageUrl(
          fixtureUrl,
          printingId: printingId,
          oracleId: oracleId,
          environment: isolated,
        ),
        fixtureUrl,
      );
      expect(
        normalizeScryfallImageUrl(
          'http://localhost:8080/card.webp',
          environment: isolated,
        ),
        'http://localhost:8080/card.webp',
      );
      expect(
        normalizeScryfallImageUrl(
          'https://evil.example/card.jpg',
          environment: isolated,
        ),
        isNull,
      );
      for (final environment in const <Map<String, String>>[
        {},
        {'MANALOOM_E2E_ISOLATED_RUNTIME': '1'},
        {
          'MANALOOM_E2E_ISOLATED_RUNTIME': '0',
          'MANALOOM_E2E_VALIDATION_RUN_TOKEN': 'server-contract-run_1',
        },
      ]) {
        expect(
          normalizeScryfallImageUrl(fixtureUrl, environment: environment),
          isNull,
          reason: '$environment',
        );
      }
    });
  });
}
