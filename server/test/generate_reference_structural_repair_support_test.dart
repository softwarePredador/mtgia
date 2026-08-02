import 'package:server/ai/generate_reference_structural_repair_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander reference structural repair bracket intent', () {
    test('uses visibly different mana targets across the bracket ladder', () {
      expect(commanderReferenceStructuralTargetLandCount(1), 38);
      expect(commanderReferenceStructuralTargetLandCount(2), 36);
      expect(commanderReferenceStructuralTargetLandCount(3), 36);
      expect(commanderReferenceStructuralTargetLandCount(4), 34);
      expect(commanderReferenceStructuralTargetLandCount(5), 34);
    });

    test('Exhibition omits speed signals while Core admits one fast rock', () {
      final candidates = _structuralCandidates();
      final exhibition = selectCommanderReferenceStructuralNonLands(
        candidates: candidates,
        nonLandTarget: 34,
        targetArchetype: 'midrange',
        requestedBracket: 1,
      );
      final core = selectCommanderReferenceStructuralNonLands(
        candidates: candidates,
        nonLandTarget: 35,
        targetArchetype: 'midrange',
        requestedBracket: 2,
      );

      expect(exhibition, isNotNull);
      expect(core, isNotNull);
      final exhibitionNames =
          exhibition!.cards.map((card) => card['name']).toSet();
      final coreNames = core!.cards.map((card) => card['name']).toSet();
      expect(
        exhibitionNames,
        isNot(containsAll(['Sol Ring', "Sensei's Divining Top", 'High Noon'])),
      );
      expect(exhibition.intentCounts['fastMana'] ?? 0, 0);
      expect(exhibition.intentCounts['infiniteCombo'] ?? 0, 0);
      expect(exhibition.intentCounts['stax'] ?? 0, 0);
      expect(coreNames, contains('Sol Ring'));
      expect(core.intentCounts['fastMana'], 1);
      expect(core.intentCounts['infiniteCombo'] ?? 0, 0);
      expect(core.intentCounts['stax'] ?? 0, 0);
    });

    test('cEDH prioritizes competitive pieces beyond the B4 ordering', () {
      final candidates = _structuralCandidates();
      final optimized = selectCommanderReferenceStructuralNonLands(
        candidates: candidates,
        nonLandTarget: 24,
        targetArchetype: 'midrange',
        requestedBracket: 4,
      );
      final competitive = selectCommanderReferenceStructuralNonLands(
        candidates: candidates,
        nonLandTarget: 24,
        targetArchetype: 'combo',
        requestedBracket: 5,
      );

      expect(optimized, isNotNull);
      expect(competitive, isNotNull);
      final optimizedNames =
          optimized!.cards.map((card) => card['name']).toSet();
      final competitiveNames =
          competitive!.cards.map((card) => card['name']).toSet();
      expect(optimizedNames, isNot(contains('Mana Vault')));
      expect(competitiveNames, contains('Mana Vault'));
      expect(competitive.intentCounts['gameChanger'], greaterThan(0));
      expect(competitive.intentCounts['fastMana'], greaterThan(0));
    });
  });
}

List<Map<String, dynamic>> _structuralCandidates() {
  return [
    for (var index = 1; index <= 8; index += 1)
      {
        'name': 'Safe Rock $index',
        'type_line': 'Artifact',
        'oracle_text': '{T}: Add {C}.',
        'cmc': 3,
      },
    for (var index = 1; index <= 8; index += 1)
      {
        'name': 'Safe Draw $index',
        'type_line': 'Instant',
        'oracle_text': 'Draw two cards.',
        'cmc': 3,
      },
    for (var index = 1; index <= 6; index += 1)
      {
        'name': 'Safe Removal $index',
        'type_line': 'Instant',
        'oracle_text': 'Exile target creature.',
        'cmc': 3,
      },
    for (var index = 1; index <= 2; index += 1)
      {
        'name': 'Safe Wipe $index',
        'type_line': 'Sorcery',
        'oracle_text': 'Destroy all creatures.',
        'cmc': 5,
      },
    for (var index = 1; index <= 10; index += 1)
      {
        'name': 'Theme Utility $index',
        'type_line': 'Creature — Wizard',
        'oracle_text': 'Whenever you cast a spell, scry 1.',
        'cmc': 4,
      },
    const {
      'name': 'Sol Ring',
      'type_line': 'Artifact',
      'oracle_text': '{T}: Add {C}{C}.',
      'cmc': 1,
    },
    const {
      'name': 'Mana Vault',
      'type_line': 'Artifact',
      'oracle_text': '{T}: Add {C}{C}{C}.',
      'cmc': 1,
    },
    const {
      'name': "Sensei's Divining Top",
      'type_line': 'Artifact',
      'oracle_text': 'Look at the top three cards of your library.',
      'cmc': 1,
    },
    const {
      'name': 'High Noon',
      'type_line': 'Enchantment',
      'oracle_text': "Each player can't cast more than one spell each turn.",
      'cmc': 2,
    },
  ];
}
