import 'package:test/test.dart';

import '../bin/commander_reference_profile_lorehold.dart';
import 'package:server/ai/commander_reference_profile_support.dart';

void main() {
  test('Lorehold profile runner summary reflects current generate contract', () {
    final summary = buildGenerateContractSummary();

    expect(summary['request_field'], equals('commander_name'));
    expect(
      summary['regression_fixture_commander'],
      equals(loreholdReferenceCommanderName),
    );
    expect(
      summary['exact_profile_activation'],
      equals('persisted_profile_confidence_gte_medium'),
    );
    expect(
      summary['runtime_built_in_fallback_scope'],
      equals(loreholdReferenceCommanderName),
    );
    expect(summary['archetype_reuse_when_no_exact_profile'], isTrue);
    expect(summary['learned_decks_direct_input_to_ai_generate'], isFalse);
    expect(summary['learned_decks_product_route'], equals('/ai/commander-learning'));
    expect(summary['diagnostics'], contains('runtime_profile_origin'));
    expect(summary['diagnostics'], contains('runtime_profile_reason'));
    expect(summary['diagnostics'], contains('reference_profile_source'));
  });
}
