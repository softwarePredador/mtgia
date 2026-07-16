import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('commercial gate preserves explicit false readiness values', () {
    final source =
        File(
          '../scripts/manaloom_commercial_quality_gate.sh',
        ).readAsStringSync();

    expect(source, isNot(contains('mock_fallbacks_allowed // true')));
    expect(source, contains('has("mock_fallbacks_allowed")'));
  });

  test('AI generation benchmark gates validated non-mock decks', () {
    final source =
        File(
          '../scripts/manaloom_ai_generation_benchmark.sh',
        ).readAsStringSync();

    expect(source, contains('.validation_is_valid == true'));
    expect(source, contains('.deckbuilding_contract_present == true'));
    expect(source, contains('.generated_card_count >= 60'));
    expect(source, contains('.is_mock == false'));
    expect(source, isNot(contains('is_mock //')));
    expect(source, contains('repaired_run_count'));
  });
}
