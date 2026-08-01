import 'dart:io';

import 'package:test/test.dart';

import '../lib/ai/optimize_filler_loader_support.dart';
import '../lib/ai/optimize_functional_role_support.dart';

void main() {
  group('optimize filler ramp floor support', () {
    const stableRamp = {
      'name': 'Arcane Signet',
      'type_line': 'Artifact',
      'oracle_text':
          '{T}: Add one mana of any color in your commander\'s color identity.',
      'functional_tags': ['ramp'],
      'quantity': 4,
    };
    const contextualRamp = {
      'name': 'Ruby Medallion',
      'type_line': 'Artifact',
      'oracle_text': 'Red spells you cast cost {1} less to cast.',
      'functional_tags': ['ramp'],
      'quantity': 6,
    };

    test('slot deficit counts only generic-floor ramp', () {
      final needs = buildSlotNeedsForDeck(
        currentDeckCards: const [stableRamp, contextualRamp],
        targetArchetype: 'midrange',
      );

      expect(needs['ramp'], equals(6));
    });

    test(
      'structural recovery need keeps contextual ramp outside the floor',
      () {
        final contextualNeeds = buildStructuralRecoveryFunctionalNeeds(
          allCardData: const [contextualRamp],
          targetArchetype: 'midrange',
          limit: 58,
        );
        final mixedNeeds = buildStructuralRecoveryFunctionalNeeds(
          allCardData: const [stableRamp, contextualRamp],
          targetArchetype: 'midrange',
          limit: 58,
        );

        expect(contextualNeeds.where((need) => need == 'ramp'), hasLength(10));
        expect(mixedNeeds.where((need) => need == 'ramp'), hasLength(6));
      },
    );
  });

  group('deterministic Complete slot allocation', () {
    test('does not add all missing nonlands again as utility deficit', () {
      final needs = buildSlotNeedsForDeck(
        currentDeckCards: const [],
        targetArchetype: 'midrange',
      );

      expect(needs.values.fold<int>(0, (sum, value) => sum + value), 58);
      expect(needs['utility'], 10);
      expect(needs['wipe'], 2);
    });

    test('consumes role deficits instead of saturating the first role', () {
      final selected = selectDeterministicSlotCandidates(
        candidates: const [
          {
            'name': 'Ramp One',
            'type_line': 'Artifact',
            'functional_tags': ['ramp'],
          },
          {
            'name': 'Ramp Two',
            'type_line': 'Artifact',
            'functional_tags': ['ramp'],
          },
          {
            'name': 'Ramp Three',
            'type_line': 'Artifact',
            'functional_tags': ['ramp'],
          },
          {
            'name': 'Wrath One',
            'type_line': 'Sorcery',
            'functional_tags': ['board_wipe'],
          },
          {
            'name': 'Wrath Two',
            'type_line': 'Sorcery',
            'functional_tags': ['board_wipe'],
          },
          {
            'name': 'Draw One',
            'type_line': 'Sorcery',
            'functional_tags': ['draw'],
          },
        ],
        slotNeeds: const {'ramp': 2, 'wipe': 2, 'draw': 1},
        limit: 5,
        bracket: 2,
      );

      final roles = selected.map(inferFunctionalRoleForCard).toList();
      expect(roles.where((role) => role == 'ramp'), hasLength(2));
      expect(roles.where((role) => role == 'wipe'), hasLength(2));
      expect(roles.where((role) => role == 'draw'), hasLength(1));
    });

    test('all fallback candidates use the same Core hard filter', () {
      final filtered = filterCandidatesByBracketPolicy(
        bracket: 2,
        currentDeckCards: const [],
        candidates: const [
          {'name': 'Grim Monolith', 'type_line': 'Artifact'},
          {'name': 'Mox Diamond', 'type_line': 'Artifact'},
          {'name': 'Cori-Steel Cutter', 'type_line': 'Artifact — Equipment'},
        ],
      );

      expect(filtered.map((card) => card['name']), ['Cori-Steel Cutter']);
    });

    test('wipe floor lane bypasses generic ranking without bypassing bracket', () {
      final selected = selectCommanderWipeFloorCandidates(
        bracket: 2,
        currentDeckCards: const [],
        limit: 3,
        candidates: const [
          {
            'name': 'Generic High Rank',
            'type_line': 'Artifact',
            'oracle_text': '{T}: Add {U}.',
            'meta_deck_count': 9999,
          },
          {
            'name': 'Cyclonic Rift',
            'type_line': 'Instant',
            'oracle_text':
                "Return all nonland permanents you don't control to their owners' hands.",
            'meta_deck_count': 9998,
          },
          {
            'name': 'Devastation Tide',
            'type_line': 'Sorcery',
            'oracle_text':
                "Return all nonland permanents to their owners' hands.",
            'meta_deck_count': 30,
          },
          {
            'name': 'Consuming Tide',
            'type_line': 'Sorcery',
            'oracle_text':
                'Each player chooses a nonland permanent they control. '
                "Return all nonland permanents not chosen this way to their owners' hands.",
            'functional_tags': ['board_wipe'],
            'meta_deck_count': 20,
          },
          {
            'name': 'Crush of Tentacles',
            'type_line': 'Sorcery',
            'oracle_text':
                "Return all nonland permanents to their owners' hands.",
            'meta_deck_count': 10,
          },
          {
            'name': 'Friendly Formation',
            'type_line': 'Instant',
            'oracle_text': 'All creatures you control get +2/+2.',
            'meta_deck_count': 5000,
          },
          {
            'name': 'False Persisted Wipe Tag',
            'type_line': 'Artifact',
            'oracle_text': 'Exile all cards from your library.',
            'functional_tags': ['board_wipe'],
            'meta_deck_count': 6000,
          },
        ],
      );

      expect(selected.map((card) => card['name']), [
        'Devastation Tide',
        'Consuming Tide',
        'Crush of Tentacles',
      ]);
    });
  });

  test(
    'basic land loader resolves canonical split aliases through identity bridge',
    () {
      final source =
          File('lib/ai/optimize_filler_loader_support.dart').readAsStringSync();

      expect(source, contains('JOIN card_identity_bridge cib'));
      expect(source, contains("input_names.normalized_input_name || ' // %'"));
      expect(source, contains('SELECT input_name, card_id'));
      expect(source, contains('WHERE resolution_rank = 1'));
    },
  );

  test('emergency filler maps metadata and enforces commander identity', () {
    final source =
        File('lib/ai/optimize_filler_loader_support.dart').readAsStringSync();

    expect(source, contains('required Set<String> commanderColorIdentity'));
    expect(source, contains("'mana_cost': (row[4] as String?) ?? ''"));
    expect(source, contains("'colors': (row[5] as List?)"));
    expect(source, contains('(row[6] as List?)?.cast<String>()'));
    expect(source, contains('enforceCommanderIdentity: true'));
  });

  test('Complete fallback pools carry the cumulative bracket snapshot', () {
    final fillerSource =
        File('lib/ai/optimize_filler_loader_support.dart').readAsStringSync();
    final completeSource =
        File('lib/ai/optimize_complete_support.dart').readAsStringSync();

    expect(
      fillerSource,
      contains('List<Map<String, dynamic>> bracketSnapshot'),
    );
    expect(fillerSource, contains('...aggregated'));
    expect(completeSource, contains('...selectedSpells'));
    expect(completeSource, contains('bracket: bracket'));
    expect(
      completeSource,
      contains('currentDeckCards: state.virtualDeck'),
      reason:
          'The first pool starts from the actual virtual deck; later pools use the cumulative snapshot.',
    );
  });

  test(
    'Complete fills the wipe floor before generic top-ranked candidates',
    () {
      final fillerSource =
          File('lib/ai/optimize_filler_loader_support.dart').readAsStringSync();
      final completeSource =
          File('lib/ai/optimize_complete_support.dart').readAsStringSync();
      final remainderSource = completeSource.substring(
        completeSource.indexOf('Future<void> fillCompleteDeckRemainder'),
      );

      expect(fillerSource, contains('loadCommanderWipeFloorCandidates'));
      expect(fillerSource, contains('LIMIT 600'));
      expect(
        fillerSource,
        isNot(contains('ORDER BY RANDOM()\\n      LIMIT 600')),
      );
      expect(
        remainderSource.indexOf('loadCommanderWipeFloorCandidates'),
        lessThan(remainderSource.indexOf('findSynergyReplacements')),
      );
      expect(remainderSource, contains('cards: bracketSnapshot()'));
      expect(
        remainderSource,
        contains('excludeNames: existingNames.union(selectedSpellNames)'),
      );
    },
  );
}
