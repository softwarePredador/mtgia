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
  });
}
