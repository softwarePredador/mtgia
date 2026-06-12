import 'dart:convert';

import 'package:server/card_identity_backfill_support.dart';
import 'package:test/test.dart';

void main() {
  group('card identity backfill support', () {
    test('caps Scryfall collection batches at 75 identifiers', () {
      expect(normalizeScryfallCollectionBatchSize(0), 1);
      expect(normalizeScryfallCollectionBatchSize(10), 10);
      expect(normalizeScryfallCollectionBatchSize(100), 75);

      final chunks = chunkForScryfallCollection(
        List<int>.generate(151, (index) => index),
        batchSize: 100,
      );
      expect(chunks.map((chunk) => chunk.length), [75, 75, 1]);
    });

    test('builds Scryfall collection payload with printing ids', () {
      final decoded = jsonDecode(buildScryfallCollectionRequestBody([
        '11111111-1111-1111-1111-111111111111',
        ' ',
        '22222222-2222-2222-2222-222222222222',
      ])) as Map<String, dynamic>;

      expect(decoded['identifiers'], hasLength(2));
      expect(decoded['identifiers'].first['id'],
          '11111111-1111-1111-1111-111111111111');
    });

    test('builds Scryfall collection payload with oracle ids', () {
      final decoded = jsonDecode(buildScryfallCollectionOracleRequestBody([
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      ])) as Map<String, dynamic>;

      expect(decoded['identifiers'].single['oracle_id'],
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    });

    test('parses collection response preserving oracle identity and faces', () {
      final parsed = parseScryfallCollectionIdentities({
        'data': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'oracle_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'layout': 'modal_dfc',
            'card_faces': [
              {'name': 'Front'},
              {'name': 'Back'},
            ],
          },
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'oracle_id': '',
          },
        ],
      });

      expect(parsed.keys, ['11111111-1111-1111-1111-111111111111']);
      final payload = parsed.values.single;
      expect(payload.oracleId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(payload.layout, 'modal_dfc');
      expect(jsonDecode(payload.cardFacesJson!) as List<dynamic>, hasLength(2));
    });

    test('can key parsed response by oracle id for legacy rows', () {
      final parsed = parseScryfallCollectionIdentitiesByOracleId({
        'data': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'oracle_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'layout': 'normal',
          },
        ],
      });

      expect(parsed.keys, ['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa']);
      expect(parsed.values.single.scryfallId,
          '11111111-1111-1111-1111-111111111111');
    });
  });
}
