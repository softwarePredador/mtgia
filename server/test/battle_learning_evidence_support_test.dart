import 'package:test/test.dart';

import '../lib/ai/battle_learning_evidence_support.dart';

Map<String, dynamic> completedResult(List<Map<String, dynamic>> events) => {
      'status': 'completed',
      'winner': 'deck_a',
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
}
