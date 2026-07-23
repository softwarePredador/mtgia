import 'package:test/test.dart';

import '../lib/ai/battle_engine_config.dart';
import '../lib/ai/battle_learning_evidence_support.dart';

Map<String, dynamic> completedResult(List<Map<String, dynamic>> events) => {
  'status': 'completed',
  'winner': 'deck_a',
  'turns': 7,
  'learning_contract': {
    'schema_version': externalBattleLearningSchema,
    'absence_proves_nonuse': false,
  },
  'events': events,
};

void main() {
  test('deck hash v1 matches the shared cross-language golden vector', () {
    final cards = <Map<String, dynamic>>[
      {
        'name': 'Lorehold, the Historian',
        'quantity': 1,
        'is_commander': true,
        'set_code': 'STX',
        'collector_number': '268',
      },
      {
        'name': 'The Mind Stone',
        'quantity': 1,
        'is_commander': false,
        'set_code': 'PIP',
        'collector_number': '145',
      },
      {
        'name': 'Mountain',
        'quantity': 98,
        'is_commander': false,
        'set_code': '',
        'collector_number': '',
      },
    ];
    const golden =
        '926d4864af12aa6d6bd9b57758df6249a3fbc49fdb2818ed5941a58f0c35e25b';

    expect(canonicalExternalBattleDeckHash({'cards': cards}), golden);
    expect(
      canonicalExternalBattleDeckHash({'cards': cards.reversed.toList()}),
      golden,
    );
  });

  test('generic waiting rows do not prove named card exposure', () {
    final evidence = buildBattleLearningEvidence(
      completedResult([
        {'event_type': 'waiting', 'card_name': 'Candidate'},
      ]),
      focusCards: const ['Candidate'],
      sameLane: true,
    );

    expect(evidence['all_focus_cards_exposed'], isFalse);
    expect(evidence['comparison_input_ready'], isFalse);
    expect(evidence['promotion_allowed'], isFalse);
  });

  test('typed source activity is positive exposure', () {
    final evidence = buildBattleLearningEvidence(
      completedResult([
        {
          'event_type': 'ability_activated',
          'source_card_name': 'Krenko, Mob Boss',
        },
      ]),
      focusCards: const ['Krenko, Mob Boss'],
      sameLane: true,
      naturalSample: true,
    );

    expect(evidence['positive_exposure_ready'], isTrue);
    expect(evidence['natural_same_lane_exposure'], isTrue);
    expect(evidence['typed_positive_event_count'], 1);
    expect(evidence['focus_cards'], [
      {
        'card_name': 'Krenko, Mob Boss',
        'normalized_name': 'krenko, mob boss',
        'positive_exposure': true,
        'exposure_state': 'positive',
        'evidence_kind': 'typed_event',
        'event_types': ['ability_activated'],
      },
    ]);
    expect(evidence['comparison_input_ready'], isFalse);
    expect(evidence['swap_superiority_proven'], isFalse);
  });

  test('text visibility and target-only rows leave exposure unknown', () {
    final evidence = buildBattleLearningEvidence(
      completedResult([
        {
          'type': 'add_to_stack',
          'message': 'Ai(1) cast Candidate',
          'card_name': 'Candidate',
        },
        {'action': 'visible_zone_entry', 'card_name': 'Candidate'},
        {'event_type': 'damage', 'target_card': 'Candidate'},
      ]),
      focusCards: const ['Candidate'],
      sameLane: true,
    );

    expect(evidence['positive_exposure_ready'], isFalse);
    expect(evidence['typed_positive_event_count'], 0);
    expect(evidence['unknown_focus_card_count'], 1);
    expect(evidence['focus_cards'], [
      {
        'card_name': 'Candidate',
        'normalized_name': 'candidate',
        'positive_exposure': false,
        'exposure_state': 'unknown',
        'evidence_kind': null,
        'event_types': <String>[],
      },
    ]);
    expect(evidence['comparison_input_ready'], isFalse);
  });

  test('missing learning contract cannot become learning evidence', () {
    final evidence = buildBattleLearningEvidence(
      {
        'status': 'completed',
        'events': [
          {'event_type': 'spell_cast', 'card_name': 'Candidate'},
        ],
      },
      focusCards: const ['Candidate'],
      sameLane: true,
    );

    expect(evidence['learning_contract_valid'], isFalse);
    expect(evidence['positive_exposure_ready'], isFalse);
  });

  test('zero-turn payload cannot become completed learning evidence', () {
    final result = completedResult([
      {'event_type': 'spell_cast', 'card_name': 'Candidate'},
    ]);
    result['turns'] = 0;

    final evidence = buildBattleLearningEvidence(
      result,
      focusCards: const ['Candidate'],
      sameLane: true,
    );

    expect(evidence['completed'], isFalse);
    expect(evidence['all_focus_cards_exposed'], isTrue);
    expect(evidence['positive_exposure_ready'], isFalse);
  });

  test('forced access diagnostic is not natural comparison input', () {
    final evidence = buildBattleLearningEvidence(
      completedResult([
        {'event_type': 'spell_cast', 'card_name': 'Candidate'},
      ]),
      focusCards: const ['Candidate'],
      sameLane: true,
      naturalSample: false,
    );

    expect(evidence['positive_exposure_ready'], isTrue);
    expect(evidence['comparison_input_ready'], isFalse);
  });

  test(
    'completed battle records generic named exposure without focus cards',
    () {
      final evidence = buildBattleLearningEvidence(
        completedResult([
          {'event_type': 'spell_cast', 'card': 'Aerialephant'},
        ]),
      );

      expect(evidence['positive_exposure_ready'], isTrue);
      expect(
        evidence['exposed_card_names_normalized'],
        contains('aerialephant'),
      );
    },
  );

  test('reviewed native learning contract is accepted', () {
    final result = completedResult([
      {'event_type': 'ability_resolved', 'source': 'Aerialephant'},
    ]);
    result['learning_contract'] = {
      'schema_version': nativeBattleLearningSchema,
      'absence_proves_nonuse': false,
    };

    final evidence = buildBattleLearningEvidence(result);

    expect(evidence['learning_contract_valid'], isTrue);
    expect(evidence['learning_contract_schema'], nativeBattleLearningSchema);
    expect(evidence['positive_exposure_ready'], isTrue);
  });
}
