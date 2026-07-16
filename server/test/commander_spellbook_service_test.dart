import 'package:server/ai/commander_spellbook_service.dart';
import 'package:test/test.dart';

Map<String, dynamic> comboRow({
  String id = 'combo-1',
  List<String> oracleIds = const ['card-a', 'card-b'],
  List<String> requiredCommanderOracleIds = const [],
  String prerequisites = commanderSpellbookVerifiedNoPrerequisitesMarker,
  String colorIdentity = 'UR',
  int? cardCount,
}) {
  return {
    'id': id,
    'color_identity': colorIdentity,
    'mana_needed': '{1}{U}{R}',
    'prerequisites': prerequisites,
    'description': 'Execute the loop.',
    'produces': ['Infinite damage'],
    'card_oracle_ids': oracleIds,
    'card_names': oracleIds.map((id) => 'Name $id').toList(),
    'card_count': cardCount ?? oracleIds.length,
    'required_commander_oracle_ids': requiredCommanderOracleIds,
  };
}

void main() {
  group('Commander Spellbook fail-closed matching', () {
    test('returns an ordinary fully present combo as complete', () {
      final result = matchCommanderSpellbookRows(
        rows: [comboRow()],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: const {},
        commanderColorIdentity: {'U', 'R'},
      );

      expect(result.complete, hasLength(1));
      expect(result.nearMisses, isEmpty);
    });

    test('must-be-commander card in the 99 does not satisfy the combo', () {
      final result = matchCommanderSpellbookRows(
        rows: [
          comboRow(requiredCommanderOracleIds: const ['card-a']),
        ],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: {'different-commander'},
      );

      expect(result.complete, isEmpty);
      expect(result.nearMisses, isEmpty);
    });

    test('must-be-commander requirement is accepted only for commander id', () {
      final result = matchCommanderSpellbookRows(
        rows: [
          comboRow(requiredCommanderOracleIds: const ['card-a']),
        ],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: {'card-a'},
      );

      expect(result.complete, hasLength(1));
      expect(result.complete.single.combo.requiredCommanderOracleIds, [
        'card-a',
      ]);
    });

    test('unverified textual prerequisites never become complete', () {
      final result = matchCommanderSpellbookRows(
        rows: [comboRow(prerequisites: 'A creature entered this turn.')],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: const {},
      );

      expect(result.complete, isEmpty);
      expect(result.nearMisses, isEmpty);
    });

    test('legacy blank prerequisite provenance fails closed', () {
      final result = matchCommanderSpellbookRows(
        rows: [comboRow(prerequisites: '')],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: const {},
      );

      expect(result.isEmpty, isTrue);
    });

    test('unverified template requirement marker never becomes complete', () {
      final result = matchCommanderSpellbookRows(
        rows: [comboRow(prerequisites: '[unverified_template_requirements:1]')],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: const {},
      );

      expect(result.complete, isEmpty);
    });

    test(
      'one missing card remains a near miss when requirements are proven',
      () {
        final result = matchCommanderSpellbookRows(
          rows: [comboRow()],
          deckOracleIds: {'card-a'},
          commanderOracleIds: const {},
        );

        expect(result.complete, isEmpty);
        expect(result.nearMisses, hasLength(1));
        expect(result.nearMisses.single.missingOracleIds, ['card-b']);
      },
    );

    test('inconsistent persisted card count fails closed', () {
      final result = matchCommanderSpellbookRows(
        rows: [comboRow(cardCount: 3)],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: const {},
      );

      expect(result.isEmpty, isTrue);
    });

    test('orphan must-be-commander identity fails closed', () {
      final result = matchCommanderSpellbookRows(
        rows: [
          comboRow(requiredCommanderOracleIds: const ['not-a-combo-card']),
        ],
        deckOracleIds: {'card-a', 'card-b'},
        commanderOracleIds: {'not-a-combo-card'},
      );

      expect(result.isEmpty, isTrue);
    });
  });
}
