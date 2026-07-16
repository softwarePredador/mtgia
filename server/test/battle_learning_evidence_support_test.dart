import 'package:test/test.dart';

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
    expect(evidence['comparison_input_ready'], isFalse);
    expect(evidence['swap_superiority_proven'], isFalse);
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
