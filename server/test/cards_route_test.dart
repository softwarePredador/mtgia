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

    test('cards route keeps default dedupe and token exclusion explicit', () {
      final source = File('routes/cards/index.dart').readAsStringSync();

      expect(
        source,
        contains("params['include_tokens']?.toLowerCase() == 'true'"),
      );
      expect(
        source,
        contains("params['dedupe']?.toLowerCase() != 'false'"),
      );
      expect(source, contains('final safeLimit = limit.clamp(1, 200)'));
      expect(source, contains("params['limit'] ?? '50'"));
      expect(source, contains("params['page'] ?? '1'"));
      expect(source, contains("'is_reserved': map['is_reserved'] == true"));
      expect(source, contains('c.is_reserved'));
    });

    test('printings sync boundary is explicit and write-capable', () {
      final source =
          File('routes/cards/printings/index.dart').readAsStringSync();

      expect(source,
          contains("final syncFromScryfall = params['sync'] == 'true'"));
      expect(
        source,
        contains('if (syncFromScryfall && data.length <= 1)'),
      );
      expect(source, contains('_syncPrintingsFromScryfall'));
      expect(source, contains('INSERT INTO cards'));
      expect(source, contains('is_reserved'));
      expect(source, contains("p['reserved']"));
      expect(source, contains('ON CONFLICT (scryfall_id) DO UPDATE SET'));
      expect(source, contains('INSERT INTO sets'));
    });

    test('resolve route preserves reserved-list metadata', () {
      final source = File('routes/cards/resolve/index.dart').readAsStringSync();

      expect(source, contains("'is_reserved': m['is_reserved'] == true"));
      expect(source, contains("card['reserved']"));
      expect(source, contains('is_reserved = COALESCE'));
    });
  });
}
