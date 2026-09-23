import 'dart:io';

import 'package:server/card_query_contract.dart';
import 'package:test/test.dart';

void main() {
  group('cards set filter contract', () {
    test('preserva codigo informado e remove espacos', () {
      expect(normalizeCardSetFilter(' ECC '), 'ECC');
      expect(normalizeCardSetFilter('ecc'), 'ecc');
    });

    test('trata filtro vazio como ausente para manter busca geral intacta', () {
      expect(normalizeCardSetFilter(null), isNull);
      expect(normalizeCardSetFilter(''), isNull);
      expect(normalizeCardSetFilter('   '), isNull);
    });

    test('dedupe parser preserves legacy, identity, and printing grains', () {
      expect(parseCardDedupeMode(null), CardDedupeMode.set);
      expect(parseCardDedupeMode('true'), CardDedupeMode.set);
      expect(parseCardDedupeMode(' identity '), CardDedupeMode.identity);
      expect(parseCardDedupeMode('false'), CardDedupeMode.none);
      expect(parseCardDedupeMode('invalid'), isNull);
    });

    test('cards route keeps identity and commander filters explicit', () {
      final source = File('routes/cards/index.dart').readAsStringSync();

      expect(
        source,
        contains("params['include_tokens']?.toLowerCase() == 'true'"),
      );
      expect(source, contains("parseCardDedupeMode(params['dedupe'])"));
      expect(source, contains("params['commander_format']"));
      expect(source, contains('CardDedupeMode.identity'));
      expect(source, contains(r'PARTITION BY $identityExpression'));
      expect(source, contains('commanderEligibilitySql'));
      expect(source, contains("COALESCE(c.type_line, '') NOT ILIKE '%Token%'"));
      expect(source, contains('final safeLimit = limit.clamp(1, 200)'));
      expect(source, contains("params['limit'] ?? '50'"));
      expect(source, contains("params['page'] ?? '1'"));
      expect(source, contains("final idFilter = params['id']?.trim()"));
      expect(source, contains("conditions.add('c.id::text = @id')"));
      expect(source, contains("'is_reserved': map['is_reserved'] == true"));
      expect(source, contains("'power': map['power']"));
      expect(source, contains("'toughness': map['toughness']"));
      expect(source, contains('c.oracle_text,'));
      expect(source, contains('c.power,'));
      expect(source, contains('c.toughness,'));
      expect(source, contains('c.is_reserved'));
      expect(source, contains("'printing_count': map['printing_count']"));
      expect(source, contains('canonical_sets'));
    });

    // BT-CAT-04 (D-35): a rota só lê. A prova de comportamento está em
    // `cards_printings_read_only_test.dart`; esta guarda barra a volta do
    // cliente HTTP, da escrita e do interruptor `sync` na fonte.
    test('printings route stays read-only and ignores sync', () {
      final source =
          File('routes/cards/printings/index.dart').readAsStringSync();
      final dml = RegExp(
        r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|TRUNCATE|ON\s+CONFLICT)\b',
        caseSensitive: false,
      );

      expect(source, isNot(contains('package:http/')));
      expect(source, isNot(contains('api.scryfall.com')));
      expect(source, isNot(contains("params['sync']")));
      expect(source, isNot(matches(dml)));
      expect(source, contains('LEFT JOIN canonical_sets s'));
      expect(source, contains("'is_reserved': m['is_reserved'] == true"));
    });

    test('resolve route preserves reserved-list metadata', () {
      final source = File('routes/cards/resolve/index.dart').readAsStringSync();

      expect(source, contains("'is_reserved': m['is_reserved'] == true"));
      expect(source, contains("card['reserved']"));
      expect(source, contains('is_reserved = COALESCE'));
      expect(source, contains('power = COALESCE(EXCLUDED.power, cards.power)'));
      expect(
        source,
        contains('toughness = COALESCE(EXCLUDED.toughness, cards.toughness)'),
      );
      expect(source, contains('scryfallNormalImageUrlFromPayload(card)'));
      expect(
        source,
        contains('image_url = COALESCE(EXCLUDED.image_url, cards.image_url)'),
      );
    });

    test(
      'legacy seed uses direct printing art without rekeying oracle rows',
      () {
        final source = File('bin/seed_database.dart').readAsStringSync();

        expect(
          source,
          contains('scryfallNormalImageUrlFromPayload(cardPayload)'),
        );
        expect(source, contains('scryfallNamedImageFallback'));
        expect(source, contains('oracleId,'));
        expect(
          source,
          contains("WHEN cards.image_url LIKE 'https://cards.scryfall.io/%'"),
        );
      },
    );
  });
}
