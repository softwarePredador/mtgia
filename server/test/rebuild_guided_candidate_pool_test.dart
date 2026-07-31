import 'package:server/ai/rebuild_guided_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'safe catalog extends sparse references without replacing provenance',
    () {
      final merged = mergeRebuildGuidedCandidateCards(
        referenceCards: const [
          {
            'name': 'Arcane Signet',
            'card_id': 'reference-printing',
            'oracle_text': 'Reference metadata',
          },
        ],
        catalogCards: const [
          {
            'name': 'arcane signet',
            'card_id': 'catalog-printing',
            'oracle_text': 'Catalog metadata',
          },
          {
            'name': 'Wayfarer\'s Bauble',
            'card_id': 'catalog-bauble',
            'oracle_text': 'Search your library for a basic land card.',
          },
        ],
      );

      expect(merged, hasLength(2));
      expect(merged.first['card_id'], 'reference-printing');
      expect(
        merged.map((card) => card['name']),
        contains('Wayfarer\'s Bauble'),
      );
    },
  );

  test('structural wipe contribution follows the exact optimizer contract', () {
    expect(
      rebuildGuidedStructuralRoleContributions(const {
        'name': 'Benign Anthem',
        'type_line': 'Enchantment',
        'oracle_text': 'Each creature you control gets +1/+1.',
        'quantity': 1,
      })['wipe'],
      0,
    );
    expect(
      rebuildGuidedStructuralRoleContributions(const {
        'name': 'Clean Slate',
        'type_line': 'Sorcery',
        'oracle_text': 'Destroy all creatures.',
        'quantity': 1,
      })['wipe'],
      1,
    );
  });
}
