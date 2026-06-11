import 'package:server/ai/optimize_route_payload_support.dart';
import 'package:test/test.dart';

void main() {
  test(
      'balanceOptimizeDetailedPayload truncates extra additions and rebuilds recommendations',
      () {
    final response = <String, dynamic>{
      'mode': 'optimize',
      'additions': ['Arcane Signet', 'Sol Ring'],
      'removals': ['Weak Card'],
      'additions_detailed': [
        {'name': 'Arcane Signet', 'card_id': 'add-1'},
        {'name': 'Sol Ring', 'card_id': 'add-2'},
      ],
      'removals_detailed': [
        {'name': 'Weak Card', 'card_id': 'rem-1'},
      ],
      'recommendations': [
        {'name': 'stale'},
      ],
    };

    balanceOptimizeDetailedPayload(
      responseBody: response,
      validAdditions: ['Arcane Signet', 'Sol Ring'],
      validRemovals: ['Weak Card'],
      validByNameLower: const {},
      isComplete: false,
    );

    expect(response['additions'], ['Arcane Signet']);
    expect((response['additions_detailed'] as List), hasLength(1));
    expect((response['removals_detailed'] as List), hasLength(1));
    expect(
      (response['recommendations'] as List)
          .map((entry) => (entry as Map)['name'])
          .toList(),
      ['Weak Card', 'Arcane Signet'],
    );
  });

  test(
      'balanceOptimizeDetailedPayload fills missing addition details when possible',
      () {
    final response = <String, dynamic>{
      'mode': 'optimize',
      'additions': ['Arcane Signet'],
      'removals': ['Weak Card'],
      'additions_detailed': <Map<String, dynamic>>[],
      'removals_detailed': [
        {'name': 'Weak Card', 'card_id': 'rem-1'},
      ],
    };

    balanceOptimizeDetailedPayload(
      responseBody: response,
      validAdditions: ['Arcane Signet'],
      validRemovals: ['Weak Card'],
      validByNameLower: {
        'arcane signet': {'name': 'Arcane Signet', 'id': 'add-1'},
      },
      isComplete: false,
    );

    expect(response['additions_detailed'], [
      {'name': 'Arcane Signet', 'card_id': 'add-1', 'quantity': 1},
    ]);
    expect(
      (response['recommendations'] as List)
          .map((entry) => (entry as Map)['name'])
          .toList(),
      ['Weak Card', 'Arcane Signet'],
    );
  });

  test(
      'enforceOptimizeFinalPayloadIntegrity removes duplicate nonbasic additions in commander',
      () {
    final response = <String, dynamic>{
      'additions': ['Sol Ring', 'Island'],
      'removals': ['Weak Card', 'Other Weak Card'],
      'additions_detailed': [
        {'name': 'Sol Ring', 'card_id': 'add-1'},
        {'name': 'Island', 'card_id': 'basic-1'},
      ],
      'removals_detailed': [
        {'name': 'Weak Card', 'card_id': 'rem-1'},
        {'name': 'Other Weak Card', 'card_id': 'rem-2'},
      ],
      'recommendations': [
        {'name': 'stale'},
      ],
    };

    enforceOptimizeFinalPayloadIntegrity(
      responseBody: response,
      deckNamesLower: {'sol ring', 'island'},
      deckFormat: 'commander',
      isComplete: false,
    );

    expect(response['additions'], ['Island']);
    expect(response['removals'], ['Weak Card']);
    expect(
      (response['recommendations'] as List)
          .map((entry) => (entry as Map)['name'])
          .toList(),
      ['Weak Card', 'Island'],
    );
  });

  test(
      'enforceOptimizeFinalPayloadIntegrity safety net rebuilds recommendations',
      () {
    final response = <String, dynamic>{
      'additions': ['A', 'B'],
      'removals': ['C'],
      'additions_detailed': [
        {'name': 'A'},
        {'name': 'B'},
      ],
      'removals_detailed': [
        {'name': 'C'},
      ],
      'recommendations': [
        {'name': 'stale'},
      ],
    };

    enforceOptimizeFinalPayloadIntegrity(
      responseBody: response,
      deckNamesLower: const {},
      deckFormat: 'standard',
      isComplete: false,
    );

    expect(response['additions'], ['A']);
    expect(response['removals'], ['C']);
    expect(
      (response['recommendations'] as List)
          .map((entry) => (entry as Map)['name'])
          .toList(),
      ['C', 'A'],
    );
  });
}
